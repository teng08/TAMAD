# TAMAD v1.2.4 verification

Checked on 5 November 2026. Source: [commit ddd6e4c](https://github.com/teng08/TAMAD/commit/ddd6e4c5bf24e9ee05006d106beaacd4e639bce3). Downloads: [GitHub release v1.2.4](https://github.com/teng08/TAMAD/releases/tag/v1.2.4).

## What changed

Scanned and imported image pages now have a manual **Crop page** editor. Drag its corners to select the part to keep, then save; the document PDF is rebuilt. Cropping a page with an image filter also crops its saved original color copy, so switching back to Original color stays aligned. Cropping removes the area outside the selection from the stored page. Imported PDF files keep their original pages and do not have image-page editing controls.

## Android downloads

| File | Purpose | Size | SHA-256 |
| --- | --- | ---: | --- |
| [TAMAD-v1.2.4-arm64.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.4/TAMAD-v1.2.4-arm64.apk) | OPPO A96 and other ARM64 phones | 32,879,867 bytes | `49E49D03867ED4209B01E262FD020E4C32B51BAEC18ED2C9935CF43493423BEA` |
| [TAMAD-v1.2.4-android.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.4/TAMAD-v1.2.4-android.apk) | Universal Android build | 88,492,474 bytes | `FF9BF1F79BC48DA60215B6704CD6D9891A4BDCA3D499881F73848732E6A1BEE9` |

GitHub reports the same SHA-256 digests for the uploaded assets. Android's APK verifier accepts both v2 signatures. The package ID is `com.tamad.tamad`, version name is `1.2.4`, and minimum Android version is 7.0 (API 24). The universal build uses version code 7 and includes ARM64, ARMv7, and x86-64 native binaries. The smaller split build uses version code 2007 and contains ARM64 native binaries only. The ARM64 APK has the same signing certificate as v1.2.3 ARM64 and a higher version code, so its package metadata supports an in-place update.

The [Android 7/11/13/15 emulator test](https://github.com/teng08/TAMAD/actions/runs/42041197262) passed all four jobs. Each downloaded the **exact published universal APK**, checked its SHA-256, installed it, launched it, and confirmed the app process stayed alive. This checks installation and startup, not the camera or every document action. The [Android 13 ARM64 emulator attempt](https://github.com/teng08/TAMAD/actions/runs/42041235557) failed before installing the APK: GitHub's Mac runner reported `HV_UNSUPPORTED` while starting the virtual machine. The release's ARM64 signature and ABI were checked locally, but runtime installation on ARM64 remains unverified.

## Code and iPad checks

- Flutter analysis found no issues. All 15 automated tests passed, including PDF and PNG import, image filters, rotation, manual crop with a saved original color copy, invalid crop bounds, failed-import cleanup, damaged saved metadata, and phone/tablet layouts. The small-phone UI test opens the crop editor.
- The Android launcher icon extracted from the published ARM64 APK visibly matches the supplied blue TAMAD artwork. The iOS icon asset uses that artwork too.
- The [iOS verification run](https://github.com/teng08/TAMAD/actions/runs/42040521433) passed analysis and tests, built without signing, and installed and launched the app in an iPad simulator. The captured home-screen screenshot visibly shows the supplied logo, Scan a document, Import photos, and Add file. Physical camera capture was not exercised.
- Flutter/Dart handles the interface, local documents, image editing, and PDF generation. [Google ML Kit's native Android scanner](https://pub.dev/packages/google_mlkit_document_scanner) handles Android camera document capture; [Apple VisionKit](https://pub.dev/documentation/apple_vision_document_scanner/latest/) handles the native iOS camera. Native ML Kit text recognition is also used. These dependencies are why GitHub's language chart alone does not describe the whole app.

## Limits

The earlier OPPO A96 Android 13 installation error has not been diagnosed on that phone because it was not connected. The APK metadata, signature, and release checksum are verified, but installation, scanning, and performance on the physical OPPO A96 remain unverified. An earlier ARM64 emulator attempt [failed before installation](https://github.com/teng08/TAMAD/actions/runs/42037600682) because GitHub's Mac runner reported `HV_UNSUPPORTED` when starting the emulator. This was an emulator infrastructure failure, not an app installation result. Camera capture, native OCR, file-picker behavior, sharing, and large batches were not exercised on real hardware. Emulator and automated checks cannot guarantee the same behavior on every device.

The physical iPad mini 6 was not connected. [VisionKit document scanning requires a real iOS device](https://pub.dev/documentation/apple_vision_document_scanner/latest/). There is no installable iPhone/iPad download because Apple signing and a distribution path such as TestFlight or the App Store are not configured. The source ZIP and unsigned simulator build cannot be installed on a physical iPad. [Apple's distribution guidance](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) describes the required setup.

TAMAD is not yet feature-equivalent to CamScanner. It lacks searchable PDF text layers, annotations and signatures, cloud sync, and other advanced features. The existing local OCR text is searchable in TAMAD's library, but it is not embedded in exported PDFs.

If an older TAMAD app is installed, back up its saved documents before uninstalling it. Removing the app may erase its private local library. If an ARM64 split APK is already installed, update with the ARM64 APK because the universal APK uses a lower version-code sequence.
