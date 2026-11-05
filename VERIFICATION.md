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
- iOS compile: pending macOS GitHub Actions verification for this version.

The Windows host has no usable Android emulator or connected phone, and no iPhone or Apple signing setup. Runtime behavior of file picking, camera scanning, OCR, opening, and sharing remains unverified on physical devices.
