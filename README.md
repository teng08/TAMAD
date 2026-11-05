# TAMAD

TAMAD is an original, ad-free Android document scanner built with Flutter. It keeps scanned pages, generated PDFs, metadata, and recognized text in the app's local private storage.

## Working in this release

- Google ML Kit document capture with automatic edge detection, perspective correction, rotation, cleanup filters, gallery import, and batches of up to 30 pages.
- Multi-page A4 PDF generation with no TAMAD watermark.
- Local document library with name and OCR-text search.
- Page reordering and 90-degree rotation with automatic PDF regeneration.
- On-device Latin text recognition for English and Filipino text.
- Open and share PDFs through Android apps.
- Two-page ID-card scanning mode.
- Original Material 3 UI with phone-controlled light and dark themes.

The scanner UI and model are provided by Google Play services and may need a one-time module download. Merge/split, signatures, annotation, password protection, recycle bin, QR scanning, and searchable PDF text layers are visibly marked as future work rather than shipped as non-working buttons.

## Build

Use Flutter 3.47.9 or newer, JDK 17, and Android SDK 36:

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The current release build uses Flutter's debug signing key so it is installable for testing; configure a private release keystore before Play Store distribution.
