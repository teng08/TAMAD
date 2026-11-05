import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamad/document_services.dart';
import 'package:tamad/document_state.dart';
import 'package:tamad/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in <Size>[const Size(320, 640), const Size(744, 1133)]) {
    testWidgets('main screens fit ${size.width} by ${size.height}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(DocumentRepository()),
          ],
          child: const TamadApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TAMAD'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);

      for (final destination in ['Library', 'Tools', 'Settings', 'Home']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(destination),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('page editing menu fits a small phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('tamad_page_ui_'),
    ))!;
    addTearDown(() => tester.runAsync(() => directory.delete(recursive: true)));
    final repository = DocumentRepository(
      documentsDirectory: () async => directory,
    );
    final image = image_lib.Image(width: 2, height: 1);
    image.setPixelRgb(0, 0, 200, 30, 30);
    image.setPixelRgb(1, 0, 30, 30, 200);
    await tester.runAsync(() async {
      final document = await repository.importFileStream(
        'Sample.png',
        Stream.value(image_lib.encodePng(image)),
      );
      await repository.save([document]);
    });

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const TamadApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Library'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sample'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit page'));
    await tester.pumpAndSettle();

    expect(find.text('Enhance contrast'), findsOneWidget);
    expect(find.text('Grayscale'), findsOneWidget);
    expect(find.text('Black and white'), findsOneWidget);
    expect(find.text('Original color'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Crop page'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Drag the corners to choose the part to keep.'),
      findsOneWidget,
    );
    expect(find.text('Save crop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
