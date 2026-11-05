# TAMAD v1.2.2 verification

Checked on 5 November 2026. App source: [commit 3109ed8](https://github.com/teng08/TAMAD/commit/3109ed8b749ee5a056f8adc84d07b079dcc5a388). Downloads: [GitHub release v1.2.2](https://github.com/teng08/TAMAD/releases/tag/v1.2.2).

## Android downloads

| File | Purpose | Size | SHA-256 |
| --- | --- | ---: | --- |
| [TAMAD-v1.2.2-arm64.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.2/TAMAD-v1.2.2-arm64.apk) | OPPO A96 and other ARM64 phones | 32,814,187 bytes | `E92864DF9C80A6973ADCBFA14B181E6F726A1A75982E259105578AC1C421B6F9` |
| [TAMAD-v1.2.2-android.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.2/TAMAD-v1.2.2-android.apk) | Universal Android build | 88,230,186 bytes | `7DC5F255008828FB5CA82AE339DE600ED01E3D50B9B5CDB8C8B40840318FC892` |

GitHub reports the same SHA-256 digests for both uploaded assets. Android's APK verifier accepts both v2 signatures. The package ID is `com.tamad.tamad`, version name is `1.2.2`, and minimum Android version is 7.0 (API 24). The universal build uses version code 5 and includes ARM64, ARMv7, and x86-64 Flutter binaries. The smaller split build uses version code 2005 and contains ARM64 native binaries only. Both use the same testing certificate as the earlier v1.2.1 APKs. The supplied TAMAD logo is embedded in the universal APK and appears in the launcher artwork.

The **exact universal file from the release page** downloaded with its checksum verified, then installed and launched on Android 7, 11, 13, and 15 emulators: [Android verification run](https://github.com/teng08/TAMAD/actions/runs/42026441827). This is an installation and startup check; it does not exercise the camera or every document action.

## Code and iPad checks

- Flutter analysis found no issues. All 10 automated tests passed, including PDF and PNG import, PNG rotation, failed-import cleanup, damaged saved metadata, and screen layouts at 320 × 640 and 744 × 1133 logical pixels.
- The iOS release target compiled without signing. The iPad simulator build installed and launched, the app process remained alive after 60 seconds, and the [home-screen screenshot](ipad-home-v1.2.2.png) visibly shows the logo, scan card, **Add file**, and navigation: [iOS verification run](https://github.com/teng08/TAMAD/actions/runs/42026446464).
- Flutter/Dart provides the interface, local document handling, and PDF generation. Native Android Google ML Kit and iOS Apple VisionKit integrations provide document camera scanning; ML Kit provides on-device text recognition.

## Still requiring physical devices or an Apple account

- The earlier OPPO A96 Android 13 installation error was not reproduced or diagnosed on that phone because it was not connected. The ARM64 APK has a valid signature and correct ABI, but its installation and scanning on the OPPO A96 are **not verified**.
- Camera capture, on-device OCR, photo/file picker behavior, PDF sharing, and performance with large batches were not exercised on real Android or Apple hardware. Simulator and unit checks cannot guarantee identical behavior on every device.
- The iPad mini 6th generation's screen dimensions were covered by a widget layout test, but the physical iPad was not connected. iOS camera scanning and installation on that iPad remain unverified.
- There is **no installable iPhone/iPad download**. The user has an iPad but no Apple Developer Program team; [Apple's distribution process](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) requires signing and a distribution path such as TestFlight or the App Store. An unsigned build or source ZIP cannot be installed like an Android APK.

If an older TAMAD app is already installed, back up its saved documents before uninstalling it. Removing the app may erase its private local library.
