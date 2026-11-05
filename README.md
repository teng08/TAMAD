# TAMAD

TAMAD is an original, ad-free Android and iOS document scanner built with Flutter. It keeps scanned pages, generated PDFs, metadata, and recognized text in the app's local private storage.

## Download the app

Use the app download below. GitHub's **Code → Download ZIP** contains source code, not an installable app.

| Phone | Download | Minimum system |
| --- | --- | --- |
| Android | [Download TAMAD for Android (.apk)](https://github.com/teng08/TAMAD/releases/download/v1.2.0/TAMAD-v1.2.0-android.apk) | Android 7.0 or newer |
| iPhone | Installable download not available yet | iOS 15.5 or newer |

On Android, download the APK on your phone, open it from Downloads, and follow Android's installation prompt. This preview is signed with an Android debug certificate, so it is for testing rather than Play Store distribution. The [SHA-256 checksum](https://github.com/teng08/TAMAD/releases/download/v1.2.0/TAMAD-v1.2.0-android.apk.sha256) is provided alongside it.

The iOS app passes a macOS build check, but an installable iPhone release requires Apple code signing and distribution through TestFlight or the App Store. The source-code ZIP and the unsigned iOS build cannot be installed on an iPhone. See [GitHub Releases](https://github.com/teng08/TAMAD/releases) for published downloads.

## Working in this release

- Android: Google ML Kit document capture with automatic edge detection, perspective correction, rotation, cleanup filters, gallery import, and batches of up to 30 pages.
- iOS: Apple VisionKit multi-page document camera with automatic crop and perspective correction. The iOS page limit is enforced when the scan finishes.
- Separate multi-photo gallery import on both platforms. Imported photos are added as they appear; gallery import does not apply document edge detection.
- An **Add file** button on Home and Library opens the phone's file picker on Android and iOS. It imports PDF, JPG, JPEG, or PNG files into the private document library. Imported images become single-page PDFs; imported PDFs keep their original pages and can be opened or shared.
- Multi-page A4 PDF generation with no TAMAD watermark.
- Local document library with name and OCR-text search.
- Page reordering and 90-degree rotation with automatic PDF regeneration.
- On-device Latin text recognition for English and Filipino text.
- Open and share PDFs through the phone's installed apps.
- Two-page ID-card scanning mode.
- Original Material 3 UI with phone-controlled light and dark themes.

The Android scanner UI and model are provided by Google Play services and may need a one-time module download. iOS uses the native VisionKit document camera and requires a real iPhone for camera scanning. Imported PDFs retain their original pages; page rotation and OCR are available for image scans and imported images. Merge/split, signatures, annotation, password protection, recycle bin, QR scanning, and searchable PDF text layers are visibly marked as future work rather than shipped as non-working buttons.

## Build

Use Flutter 3.47.9 or newer, JDK 17, and Android SDK 36:

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The current release build uses Flutter's debug signing key so it is installable for testing; configure a private release keystore before Play Store distribution.

## iOS build and device check

On a Mac with Xcode, CocoaPods if required by Flutter, and an Apple development team configured:

```sh
flutter pub get
flutter analyze
flutter test
flutter build ios --release --no-codesign
flutter run -d <your-iphone-device-id>
```

The iOS minimum is 15.5 because the ML Kit OCR plugin requires it. Add your development team in Xcode to install the app on an iPhone, then test camera capture, photo import, OCR, PDF open/share, page rotation, and reorder. This Windows workspace cannot compile or run the iOS target, so iOS is prepared but not verified on hardware.
