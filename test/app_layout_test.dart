import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
