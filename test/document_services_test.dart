import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamad/document_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late DocumentRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temporaryDirectory = await Directory.systemTemp.createTemp('tamad_test_');
    repository = DocumentRepository(
      documentsDirectory: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('imports a real PDF and loads it after metadata is saved', () async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Text('Test document')));
    final originalBytes = await pdf.save();

    final record = await repository.importFileStream(
      'Contract.pdf',
      Stream.value(originalBytes),
    );
    await repository.save([record]);

    expect(record.isImportedPdf, isTrue);
    expect(await File(record.pdfPath).readAsBytes(), originalBytes);
    expect((await repository.load()).single.name, 'Contract');
  });

  test('imports and rotates PNG while keeping PNG file format', () async {
    final original = image_lib.Image(width: 2, height: 1);
    original.setPixelRgb(0, 0, 255, 0, 0);
    original.setPixelRgb(1, 0, 0, 0, 255);
    final pngBytes = image_lib.encodePng(original);

    final record = await repository.importFileStream(
      'Receipt.png',
      Stream.value(pngBytes),
    );
    final rotated = await repository.rotate(record, 0);
    final pageBytes = await File(rotated.pages.single).readAsBytes();
    final decoded = image_lib.decodePng(pageBytes);

    expect(path.extension(rotated.pages.single), '.png');
    expect(pageBytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(decoded?.width, 1);
    expect(decoded?.height, 2);
    expect(
      ascii.decode(
        (await File(rotated.pdfPath).readAsBytes()).take(5).toList(),
      ),
      '%PDF-',
    );
  });

  test(
    'invalid image import removes its temporary document directory',
    () async {
      await expectLater(
        repository.importFileStream('broken.png', Stream.value([1, 2, 3])),
        throwsFormatException,
      );

      final documentsRoot = Directory(
        path.join(temporaryDirectory.path, 'TAMAD'),
      );
      expect(await documentsRoot.list().toList(), isEmpty);
    },
  );

  test('failed scan import removes its temporary document directory', () async {
    await expectLater(
      repository.importScan([
        path.join(temporaryDirectory.path, 'missing.jpg'),
      ]),
      throwsA(isA<FileSystemException>()),
    );

    final documentsRoot = Directory(
      path.join(temporaryDirectory.path, 'TAMAD'),
    );
    expect(await documentsRoot.list().toList(), isEmpty);
  });

  test('damaged saved metadata does not crash the library', () async {
    SharedPreferences.setMockInitialValues({
      'tamad.documents.v1': '{not valid JSON',
    });

    expect(await repository.load(), isEmpty);
  });
}
