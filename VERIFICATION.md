# TAMAD verification report

This file records reproducible checks and their limits. The Android 1.0.0 results below refer to the original APK. The Android and iOS 1.1.0 changes are recorded separately.

## Scope

The release is a compileable scanner MVP, not a claim that every item from the long-term product specification is complete. Device-only flows such as camera capture, Play-services edge detection, the Android share sheet, and on-device OCR require a compatible Android phone for end-to-end functional testing.

## Commands

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

## Verified environment

- Flutter 3.47.9 stable, Dart 3.13.7.
- Eclipse Temurin JDK 17.0.21.
- Android compile/target SDK 36; minimum SDK 24.

## Results

- `flutter analyze --no-pub`: **passed**, no issues found.
- `flutter test --no-pub`: **passed**, 2/2 tests.
- `flutter build apk --release --no-pub`: **passed** after adding the Android-generated R8 warning rules for optional non-Latin OCR modules that are intentionally not shipped.
- APK package: `com.tamad.tamad`, version `1.0.0` (`versionCode 1`), application label `TAMAD`.
- APK architectures: `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
- APK size: 87,495,153 bytes (83.4 MB as reported by Flutter).
- APK SHA-256: `8DCFB9C23DFB139CB6792003E3E3C2C2F40E61F8E0A3A25F1CFD735CB7483725`.
- Android `apksigner verify`: **passed** with APK Signature Scheme v2 and one RSA signer.
- Signing certificate: Android Debug, SHA-256 `b72f2c39d2da994c448c22ffce8ae52419155e70c1b26621dceca2b0437755f5`.

## Runtime-test boundary

No Android phone was connected. A matching Android 36 Google Play emulator image was installed and two launch paths were attempted. The host reported `Android Emulator hypervisor driver is not installed on this machine`; the software-only fallback exited before appearing in `adb devices`. Installing or enabling a Windows hypervisor driver would change system virtualization/security configuration, so it was not done implicitly.

Consequently, the APK's installation signature, manifest, package metadata, dependency resolution, static analysis, unit tests, release compilation, and archive integrity are verified. Camera capture, Play-services edge detection, physical-device OCR, file opening, and the Android share sheet still require a compatible Android device for end-to-end runtime verification.

## Version 1.1.0: iOS source and updated Android APK

- Added the generated Flutter iOS runner and Apple VisionKit document camera routing for iPhone. The minimum iOS version is 15.5 for the OCR plugin.
- Added multi-photo gallery import on Android and iOS. Gallery photos are not automatically perspective-corrected.
- `flutter pub get`: passed.
- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub`: passed, 2/2 tests. These tests cover metadata and filename handling; they are not camera or OCR integration tests.
- `flutter build apk --release --no-pub`: passed. Updated APK size: 87,648,330 bytes.
- Android `apksigner verify`: passed (v2 signature, debug certificate).
- Android package: `com.tamad.tamad`, version `1.1.0` (`versionCode 2`), minimum SDK 24, target SDK 36.
- Updated APK SHA-256: `DED10B7D0977EB1FD114B43D48CFE7C02102B8725ECC4E8172FF2E701E7B480E`.

The iOS target cannot be built locally on Windows. [macOS verification run 41997967516](https://github.com/teng08/TAMAD/actions/runs/41997967516) for commit `087bf26` passed package resolution, Dart analysis, unit tests, and `flutter build ios --release --no-codesign`. This verifies that the iOS runner and native plugins compile on macOS. A no-signing compilation cannot test physical camera behavior, photo permissions, document crop quality, OCR quality, PDF opening, or sharing. Those need a real iPhone and Apple development signing.

## Version 1.2.0: Add file on Android and iOS

- Added **Add file** on Home and Library using the native file picker for PDF, JPG, JPEG, and PNG. Imported PDFs are kept intact and can be opened or shared. Images become one-page PDFs with page editing and OCR available.
- `flutter pub get`: passed.
- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test --no-pub`: passed, 3/3 tests. The new test covers saved metadata for an imported PDF; device file picking still needs on-device testing.
- `flutter build apk --release --no-pub`: passed.
- Android package: `com.tamad.tamad`, version `1.2.0` (`versionCode 3`), minimum SDK 24, target SDK 36.
- APK size: 87,858,328 bytes.
- APK SHA-256: `439024B64D93189F9FF12F5C4EDD15AFE8E32B932353C82803640FDB84F9168F`.
- Android `apksigner verify`: passed with APK Signature Scheme v2 and one Android Debug RSA signer.
- [macOS verification run 42000855201](https://github.com/teng08/TAMAD/actions/runs/42000855201) for commit `c256c36` passed package resolution, Dart analysis, 3/3 tests, and `flutter build ios --release --no-codesign`.

The Windows host has no usable Android emulator or connected phone, and no iPhone or Apple signing setup. Runtime behavior of file picking, camera scanning, OCR, opening, and sharing remains unverified on physical devices.

## Version 1.2.1: TAMAD logo and Android installation investigation

- Replaced Flutter's default Android and iOS launcher icons with the supplied TAMAD artwork. The Home screen header now shows the same artwork.
- The user reported **“App not installed as package appears to be invalid”** on an OPPO A96 running Android 13 for the 1.2.0 APK. This is a real device failure; the exact Android package-manager error is not available from the screenshot.
- The exact published 1.2.0 APK downloaded from GitHub passed checksum verification, installation, and launch in [Android 11 and 15 emulators](https://github.com/teng08/TAMAD/actions/runs/42010333376), then [Android 7, 11, and 15 emulators](https://github.com/teng08/TAMAD/actions/runs/42010885690). The OPPO failure remains unexplained by these tests.
- `flutter analyze --no-pub`: passed, no issues found. `flutter test --no-pub`: passed, 3/3 tests.
- Android release builds: passed for universal and ARM64-targeted outputs. Both use package `com.tamad.tamad`, version `1.2.1` (`versionCode 4`), minimum SDK 24, and the same signing certificate as versions 1.0.0–1.2.0.
- Universal APK: 88,131,882 bytes; SHA-256 `E593F830E0E501FCEB20D7197E70573AF69439F42C93FD20AC636B70B54908C4`.
- ARM64-targeted APK: 51,480,592 bytes; SHA-256 `808E8E288CCF0B997E39E6220D3248FF6A3F6EEC4BD20DC034EF13E91BBF1326`. It contains the ARM64 Flutter engine for phones such as the OPPO A96; it is not for x86 devices.
- `apksigner verify` and 16 KiB `zipalign` checks passed on both APKs. The packaged launcher icon was extracted and visually checked against the supplied logo.
- iOS macOS build for this version: pending.

Neither APK has been installed on the user's OPPO A96 yet. Do not treat emulator success as proof of a device-specific fix.
