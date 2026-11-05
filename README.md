# TAMAD

TAMAD is an original, ad-free Android and iOS document scanner built with Flutter. It keeps scanned pages, generated PDFs, metadata, and recognized text in the app's local private storage.

## Download the app

Use the app download below. GitHub's **Code → Download ZIP** contains source code, not an installable app.

| Phone | Download | Minimum system |
| --- | --- | --- |
| OPPO A96 and other ARM64 Android phones | [Download smaller Android app (.apk)](https://github.com/teng08/TAMAD/releases/download/v1.2.5/TAMAD-v1.2.5-arm64.apk) | Android 7.0 or newer |
| Other Android phones | [Download universal Android app (.apk)](https://github.com/teng08/TAMAD/releases/download/v1.2.5/TAMAD-v1.2.5-android.apk) | Android 7.0 or newer |
| iPhone and iPad | Installable download not available yet | iOS/iPadOS 15.5 or newer |

On an OPPO A96, choose the smaller ARM64 APK. Download it on your phone, open it from Downloads, and follow Android's installation prompt. These previews use an Android debug certificate, so they are for testing rather than Play Store distribution. [Checksums for both APKs](https://github.com/teng08/TAMAD/releases/tag/v1.2.5) are listed in the release.

The v1.2.5 APKs have verified Android signatures. The exact universal APK installed and launched in Android 7, 11, 13, and 15 emulators; see the [verification report](docs/verification-v1.2.5.md). Installation on the OPPO A96 still needs to be confirmed. If a TAMAD app is already on your phone, do not remove it before backing up any saved documents; removing it can erase the app's private files. If you installed an earlier ARM64 APK, keep using the ARM64 download when updating because split APKs have a different version-code sequence.

The iOS app passes a macOS build check and renders its home screen in an iPad simulator, but an installable iPhone or iPad release requires Apple code signing and distribution through TestFlight or the App Store. The source-code ZIP and the unsigned iOS build cannot be installed on an iPhone or iPad. See the [verification report](docs/verification-v1.2.5.md) and [GitHub Releases](https://github.com/teng08/TAMAD/releases).

## Working in this release

- Android: Google ML Kit document capture with automatic edge detection, perspective correction, rotation, cleanup filters, gallery import, and batches of up to 30 pages.
- iOS: Apple VisionKit multi-page document camera with automatic crop and perspective correction. The iOS page limit is enforced when the scan finishes.
- Separate multi-photo gallery import on both platforms. Imported photos are added as they appear; gallery import does not apply document edge detection.
- An **Add file** button on Home and Library opens the phone's file picker on Android and iOS. It imports PDF, JPG, JPEG, or PNG files into the private document library. Imported images become single-page PDFs; imported PDFs keep their original pages and can be opened or shared.
- Multi-page A4 PDF generation with no TAMAD watermark.
- Local document library with name and OCR-text search.
- Page reordering, manual image-page crop, 90-degree rotation, and reversible Enhance, Grayscale, and Black and White filters with automatic PDF regeneration. Cropping permanently removes the area outside the selection from that document page.
- On-device Latin text recognition for English and Filipino text.
- Cropping clears previously recognized text so the library does not search content that was cut away; run text recognition again after cropping.
- Open and share PDFs through the phone's installed apps.
- Two-page ID-card scanning mode.
- Original Material 3 UI with phone-controlled light and dark themes.

The Android scanner UI and model are provided by Google Play services and may need a one-time module download. iOS uses the native VisionKit document camera and requires a real iPhone or iPad for camera scanning. Imported PDFs retain their original pages; page editing and OCR are available for image scans and imported images. Applying a filter saves one extra local copy of that page so Original color can restore it. Merge/split, signatures, annotation, password protection, recycle bin, QR scanning, and searchable PDF text layers are visibly marked as future work rather than shipped as non-working buttons.

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

The iOS minimum is 15.5 because the ML Kit OCR plugin requires it. Add an Apple development team in Xcode to install the app on an iPhone or iPad, then test camera capture, photo import, OCR, PDF open/share, page rotation, and reorder. The GitHub macOS workflow compiles the iOS target and launches it in an iPad simulator; iOS is not verified on physical hardware.
