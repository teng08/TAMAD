# TAMAD verification report

This file records reproducible checks for the source currently in the repository. It is updated with the final command results after the release build.

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
