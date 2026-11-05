import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamad/document_services.dart';
import 'package:tamad/document_state.dart';

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

  test(
    'renaming a two-photo scan changes its saved and shared PDF filename',
    () async {
      final image = image_lib.Image(width: 3, height: 2);
      image.setPixelRgb(0, 0, 200, 20, 20);
      final first = File(path.join(temporaryDirectory.path, 'first.png'));
      final second = File(path.join(temporaryDirectory.path, 'second.png'));
      await first.writeAsBytes(image_lib.encodePng(image));
      await second.writeAsBytes(image_lib.encodePng(image));
      final record = await repository.importScan([first.path, second.path]);
      await repository.save([record]);
      final oldPath = record.pdfPath;
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(documentsProvider.future);

      await container
          .read(documentsProvider.notifier)
          .rename(record.id, 'Family papers.pdf');

      final renamed = (await repository.load()).single;
      expect(renamed.name, 'Family papers');
      expect(path.basename(renamed.pdfPath), 'Family papers.pdf');
      expect(await File(renamed.pdfPath).exists(), isTrue);
      expect(await File(oldPath).exists(), isFalse);
      expect(renamed.pages, hasLength(2));
      expect(
        ascii.decode(
          (await File(renamed.pdfPath).readAsBytes()).take(5).toList(),
        ),
        '%PDF-',
      );
      final rebuilt = await repository.rebuild(renamed);
      expect(path.basename(rebuilt.pdfPath), 'Family papers.pdf');
    },
  );

  test(
    'renaming an imported PDF preserves its bytes and persists the filename',
    () async {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (_) => pw.Text('Imported page')));
      final originalBytes = await pdf.save();
      final record = await repository.importFileStream(
        'Scanner.pdf',
        Stream.value(originalBytes),
      );
      final renamed = await repository.renamePdf(record, 'Project notes');
      await repository.save([renamed]);

      expect(path.basename(renamed.pdfPath), 'Project notes.pdf');
      expect(await File(record.pdfPath).exists(), isFalse);
      expect(await File(renamed.pdfPath).readAsBytes(), originalBytes);
      expect((await repository.load()).single.pdfPath, renamed.pdfPath);
    },
  );

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

  test('page filters use the original image and can restore it', () async {
    final original = image_lib.Image(width: 2, height: 1);
    original.setPixelRgb(0, 0, 200, 30, 30);
    original.setPixelRgb(1, 0, 30, 30, 200);
    final originalBytes = image_lib.encodePng(original);
    final record = await repository.importFileStream(
      'Color scan.png',
      Stream.value(originalBytes),
    );

    final grayRecord = await repository.applyFilter(
      record,
      0,
      PageFilter.grayscale,
    );
    final gray = image_lib.decodePng(
      await File(grayRecord.pages.single).readAsBytes(),
    )!;
    expect(gray.getPixel(0, 0).r, gray.getPixel(0, 0).g);
    expect(gray.getPixel(0, 0).g, gray.getPixel(0, 0).b);

    final enhanced = await repository.applyFilter(
      grayRecord,
      0,
      PageFilter.enhance,
    );
    final color = image_lib.decodePng(
      await File(enhanced.pages.single).readAsBytes(),
    )!;
    expect(color.getPixel(0, 0).r, greaterThan(color.getPixel(0, 0).g));

    final blackWhite = await repository.applyFilter(
      enhanced,
      0,
      PageFilter.blackWhite,
    );
    final binary = image_lib.decodePng(
      await File(blackWhite.pages.single).readAsBytes(),
    )!;
    for (final pixel in binary) {
      expect([0, 255], contains(pixel.r));
      expect(pixel.r, pixel.g);
      expect(pixel.g, pixel.b);
    }

    final restored = await repository.applyFilter(
      blackWhite,
      0,
      PageFilter.original,
    );
    expect(await File(restored.pages.single).readAsBytes(), originalBytes);
    expect(
      ascii.decode(
        (await File(restored.pdfPath).readAsBytes()).take(5).toList(),
      ),
      '%PDF-',
    );
  });

  test(
    'rotating a filtered page also rotates its restorable original',
    () async {
      final original = image_lib.Image(width: 2, height: 1);
      original.setPixelRgb(0, 0, 220, 10, 10);
      original.setPixelRgb(1, 0, 10, 10, 220);
      final record = await repository.importFileStream(
        'Page.png',
        Stream.value(image_lib.encodePng(original)),
      );
      final filtered = await repository.applyFilter(
        record,
        0,
        PageFilter.blackWhite,
      );
      final rotated = await repository.rotate(filtered, 0);
      final restored = await repository.applyFilter(
        rotated,
        0,
        PageFilter.original,
      );
      final decoded = image_lib.decodePng(
        await File(restored.pages.single).readAsBytes(),
      )!;

      expect(decoded.width, 1);
      expect(decoded.height, 2);
      expect(decoded.getPixel(0, 0).r, isNot(decoded.getPixel(0, 0).b));
    },
  );

  test(
    'manual crop keeps the same area in filtered and original pages',
    () async {
      final original = image_lib.Image(width: 4, height: 2);
      for (var y = 0; y < 2; y++) {
        for (var x = 0; x < 4; x++) {
          original.setPixelRgb(x, y, x < 2 ? 220 : 10, 20, x < 2 ? 10 : 220);
        }
      }
      final record = await repository.importFileStream(
        'Wide page.png',
        Stream.value(image_lib.encodePng(original)),
      );
      final filtered = await repository.applyFilter(
        record.copyWith(ocrText: 'Removed text'),
        0,
        PageFilter.grayscale,
      );
      final cropped = await repository.crop(
        filtered,
        0,
        const CropBounds(0, 0, 0.5, 1),
      );
      expect(cropped.ocrText, isEmpty);
      final restored = await repository.applyFilter(
        cropped,
        0,
        PageFilter.original,
      );
      final decoded = image_lib.decodePng(
        await File(restored.pages.single).readAsBytes(),
      )!;

      expect(decoded.width, 2);
      expect(decoded.height, 2);
      expect(decoded.getPixel(0, 0).r, greaterThan(decoded.getPixel(0, 0).b));
      expect(decoded.getPixel(1, 1).r, greaterThan(decoded.getPixel(1, 1).b));
      expect(
        ascii.decode(
          (await File(restored.pdfPath).readAsBytes()).take(5).toList(),
        ),
        '%PDF-',
      );
    },
  );

  test('manual crop rejects bounds outside the image', () async {
    final image = image_lib.Image(width: 2, height: 2);
    final record = await repository.importFileStream(
      'Page.png',
      Stream.value(image_lib.encodePng(image)),
    );
    await expectLater(
      repository.crop(record, 0, const CropBounds(-0.1, 0, 0.8, 1)),
      throwsArgumentError,
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
