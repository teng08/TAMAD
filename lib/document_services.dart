import 'dart:convert';
import 'dart:io';

import 'package:apple_vision_document_scanner/apple_vision_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'document_record.dart';

class ScannerService {
  Future<PlatformFile?> pickDocumentFile() => FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    dialogTitle: 'Add a PDF or image',
  );

  Future<List<String>> scan({int pageLimit = 30}) async {
    if (Platform.isIOS) {
      final images = await AppleVisionDocumentScanner().scan();
      if (images.length > pageLimit) {
        throw StateError(
          'This scan has ${images.length} pages. The limit is $pageLimit. Please scan fewer pages.',
        );
      }
      return images.map((file) => file.path).toList();
    }
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Document scanning is available on Android and iOS.',
      );
    }
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        pageLimit: pageLimit,
        mode: ScannerMode.full,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      return result.images ?? const [];
    } finally {
      await scanner.close();
    }
  }

  Future<List<String>> importFromGallery({int pageLimit = 30}) async {
    final images = await ImagePicker().pickMultiImage(
      limit: pageLimit,
      imageQuality: 90,
    );
    return images.map((file) => file.path).toList();
  }
}

class OcrService {
  Future<String> recognize(List<String> pages) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final output = StringBuffer();
    try {
      for (var index = 0; index < pages.length; index++) {
        final result = await recognizer.processImage(
          InputImage.fromFilePath(pages[index]),
        );
        if (result.text.trim().isNotEmpty) {
          if (output.isNotEmpty) output.writeln('\n— Page ${index + 1} —\n');
          output.write(result.text.trim());
        }
      }
      return output.toString();
    } finally {
      await recognizer.close();
    }
  }
}

class DocumentRepository {
  static const _metadataKey = 'tamad.documents.v1';
  static const _uuid = Uuid();

  DocumentRepository({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;

  Future<List<DocumentRecord>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_metadataKey);
    if (raw == null || raw.isEmpty) return [];
    final dynamic values;
    try {
      values = jsonDecode(raw);
    } on FormatException {
      return [];
    }
    if (values is! List) return [];
    final records = <DocumentRecord>[];
    for (final value in values) {
      try {
        final item = DocumentRecord.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        if (File(item.pdfPath).existsSync() &&
            item.pages.every((page) => File(page).existsSync())) {
          records.add(item);
        }
      } catch (_) {
        // Skip damaged metadata while keeping other documents accessible.
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<void> save(List<DocumentRecord> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _metadataKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  Future<DocumentRecord> importScan(
    List<String> sourcePaths, {
    String? name,
  }) async {
    if (sourcePaths.isEmpty) {
      throw ArgumentError('At least one scanned page is required.');
    }
    final id = _uuid.v4();
    final root = await _documentsDirectory();
    final directory = Directory(path.join(root.path, 'TAMAD', id));
    await directory.create(recursive: true);
    try {
      final storedPages = <String>[];
      for (var index = 0; index < sourcePaths.length; index++) {
        final source = File(normalizeFilePath(sourcePaths[index]));
        final extension = path.extension(source.path).toLowerCase();
        final preserveFormat = const [
          '.jpg',
          '.jpeg',
          '.png',
        ].contains(extension);
        final destination = path.join(
          directory.path,
          'page_${(index + 1).toString().padLeft(3, '0')}${preserveFormat ? extension : '.jpg'}',
        );
        if (preserveFormat) {
          await source.copy(destination);
        } else {
          final decoded = image_lib.decodeImage(await source.readAsBytes());
          if (decoded == null) {
            throw const FormatException(
              'This photo format could not be imported. Choose a JPG or PNG instead.',
            );
          }
          await File(destination).writeAsBytes(
            image_lib.encodeJpg(decoded, quality: 92),
            flush: true,
          );
        }
        storedPages.add(destination);
      }
      final createdAt = DateTime.now();
      final safeName = sanitizeFileName(
        name?.trim().isNotEmpty == true
            ? name!.trim()
            : 'Scan ${DateFormat('yyyy-MM-dd HH.mm').format(createdAt)}',
      );
      final pdfPath = path.join(directory.path, '$safeName.pdf');
      await _writePdf(storedPages, pdfPath);
      return DocumentRecord(
        id: id,
        name: safeName,
        createdAt: createdAt,
        pages: storedPages,
        pdfPath: pdfPath,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<DocumentRecord> importPickedFile(PlatformFile picked) =>
      importFileStream(picked.name, picked.readAsByteStream());

  Future<DocumentRecord> importFileStream(
    String fileName,
    Stream<List<int>> bytes,
  ) async {
    final extension = path
        .extension(fileName)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!const ['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
      throw const FormatException('Choose a PDF, JPG, or PNG file.');
    }
    final id = _uuid.v4();
    final root = await _documentsDirectory();
    final directory = Directory(path.join(root.path, 'TAMAD', id));
    await directory.create(recursive: true);
    try {
      final name = sanitizeFileName(path.basenameWithoutExtension(fileName));
      final inputPath = path.join(directory.path, 'original.$extension');
      final input = File(inputPath);
      final sink = input.openWrite();
      try {
        await sink.addStream(bytes);
      } finally {
        await sink.close();
      }
      if (await input.length() == 0) {
        throw const FormatException('The selected file is empty.');
      }
      final pdfPath = path.join(directory.path, '$name.pdf');
      if (extension == 'pdf') {
        final header = await input
            .openRead(0, 5)
            .expand((bytes) => bytes)
            .toList();
        if (ascii.decode(header, allowInvalid: true) != '%PDF-') {
          throw const FormatException('This is not a readable PDF file.');
        }
        if (input.path != pdfPath) await input.rename(pdfPath);
        return DocumentRecord(
          id: id,
          name: name,
          createdAt: DateTime.now(),
          pages: const [],
          pdfPath: pdfPath,
        );
      }
      final decoded = image_lib.decodeImage(await input.readAsBytes());
      if (decoded == null) {
        throw const FormatException('This is not a readable image file.');
      }
      await _writePdf([inputPath], pdfPath);
      return DocumentRecord(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        pages: [inputPath],
        pdfPath: pdfPath,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<DocumentRecord> rebuild(
    DocumentRecord document, {
    List<String>? pages,
  }) async {
    final nextPages = pages ?? document.pages;
    await _writePdf(nextPages, document.pdfPath);
    return document.copyWith(pages: nextPages);
  }

  Future<DocumentRecord> rotate(DocumentRecord document, int pageIndex) async {
    final page = File(document.pages[pageIndex]);
    final decoded = image_lib.decodeImage(await page.readAsBytes());
    if (decoded == null) {
      throw StateError('Page ${pageIndex + 1} is not a readable image.');
    }
    final rotated = image_lib.copyRotate(decoded, angle: 90);
    final encoded = path.extension(page.path).toLowerCase() == '.png'
        ? image_lib.encodePng(rotated)
        : image_lib.encodeJpg(rotated, quality: 92);
    await page.writeAsBytes(encoded, flush: true);
    return rebuild(document);
  }

  Future<void> deleteFiles(DocumentRecord document) async {
    final directory = Directory(path.dirname(document.pdfPath));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static String normalizeFilePath(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') return uri.toFilePath();
    return value;
  }

  static String sanitizeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\u0000-\u001F]'), '_')
        .trim();
    return cleaned.isEmpty ? 'TAMAD scan' : cleaned;
  }

  Future<void> _writePdf(List<String> pages, String outputPath) async {
    final document = pw.Document(
      title: path.basenameWithoutExtension(outputPath),
      author: 'TAMAD',
      creator: 'TAMAD document scanner',
    );
    for (final pagePath in pages) {
      final image = pw.MemoryImage(await File(pagePath).readAsBytes());
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    await File(outputPath).writeAsBytes(await document.save(), flush: true);
  }
}
