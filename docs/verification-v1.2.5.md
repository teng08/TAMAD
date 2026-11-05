# TAMAD v1.2.5 verification

Checked on 5 November 2026. Source: [commit 210dffb](https://github.com/teng08/TAMAD/commit/210dffb2ba3dad3b222c8a4e6f1eb87100d6b76a). Downloads: [GitHub release v1.2.5](https://github.com/teng08/TAMAD/releases/tag/v1.2.5).

## Changes

Scanned and imported image pages have a **Crop page** editor with draggable corners. Saving a crop rebuilds the PDF and trims the saved original color copy if a filter was applied. Cropping clears old OCR text so the library does not keep searching words cut away from the page. Run text recognition again after cropping. Cropping permanently removes the area outside the selection from that document page. Imported PDF files retain their original pages and do not expose image-page editing controls.

## Android downloads and checks

| File | Intended device | Size | SHA-256 |
| --- | --- | ---: | --- |
| [TAMAD-v1.2.5-arm64.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.5/TAMAD-v1.2.5-arm64.apk) | OPPO A96 and other ARM64 phones | 32,879,867 bytes | `2B0BE2F6170E3707F2868B8BC9249E4DD306269FFF57DCE49319E1E36F0C0D77` |
| [TAMAD-v1.2.5-android.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.5/TAMAD-v1.2.5-android.apk) | Universal Android build | 88,492,474 bytes | `66853D1FB52CBA8B566B26818F90F9C65253622AA5F4F8F02804277D126389E9` |

GitHub reports the same digests for both published files. Android's APK verifier accepts both v2 signatures. The package ID is `com.tamad.tamad`, version name is `1.2.5`, and minimum Android version is 7.0 (API 24). The universal file has ARM64, ARMv7, and x86-64 binaries with version code 8. The smaller split file has only ARM64 native binaries with version code 2008. The ARM64 file has the same signing certificate and a higher version code than v1.2.3 and v1.2.4 ARM64, so its package metadata supports an in-place update. The icon extracted from the published ARM64 APK visibly matches the supplied blue TAMAD artwork.

The [Android 7/11/13/15 emulator run](https://github.com/teng08/TAMAD/actions/runs/42043876449) passed all four jobs. Each downloaded the **exact published universal APK**, checked the SHA-256, installed it, launched it, and confirmed the app process was alive. The Android 7 job needed one retry after its first attempt had an incomplete Android SDK download; the successful retry reached the app install step. These checks cover installation and startup, not the camera or every document action. The [ARM64 release package check](https://github.com/teng08/TAMAD/actions/runs/42047384618) passed: it downloaded the exact published ARM64 file and verified its checksum, ZIP integrity, Android v2 signature, package identity, version, minimum Android level, and ARM64-only native ABI. This is a package check, not an ARM64 device install test.

## Flutter and iPad checks

- Flutter analysis found no issues. All 15 automated tests passed, including image/PDF import, filters, rotation, manual crop, clearing stale OCR after crop, failure cleanup, and phone/tablet layouts. The small-phone UI test opens the crop screen.
- The [v1.2.5 iOS run](https://github.com/teng08/TAMAD/actions/runs/42043477197) passed analysis and tests, built the iOS target without signing, installed and launched the app in an iPad simulator, and kept its process alive for 60 seconds. Its [home-screen screenshot](ipad-home-v1.2.5.png) visibly shows the supplied logo, Scan a document, Import photos, and Add file. A simulator cannot verify camera scanning on a physical iPad.
- Flutter/Dart handles the interface, local documents, image editing, and PDF generation. [Google ML Kit's native Android scanner](https://pub.dev/packages/google_mlkit_document_scanner) handles Android camera document capture; [Apple VisionKit](https://pub.dev/documentation/apple_vision_document_scanner/latest/) handles native iOS capture. Native ML Kit text recognition is also used. Dependencies are not counted in GitHub's repository language chart.

## What remains unverified

The earlier OPPO A96 Android 13 installation error has not been diagnosed on that physical phone because it was not connected. A locally available copy of the v1.2.0 APK verifies with the same signing certificate as v1.2.5; that does not prove the bytes on the phone were intact or reveal why its installer rejected it. The new released APK's checksum, signature, package ID, version, icon, and architecture are verified; physical installation and scanning remain unverified. The [ARM64 emulator attempt](https://github.com/teng08/TAMAD/actions/runs/42041235557) failed before installation because GitHub's Mac runner reported `HV_UNSUPPORTED` when starting Android, including with the software-emulation option. The duplicate [v1.2.5 emulator run](https://github.com/teng08/TAMAD/actions/runs/42044727053) was cancelled after that same infrastructure failure was established. Neither run exercised the APK installer. Camera capture, native OCR, file-picker behavior, sharing, and large-batch performance were not exercised on real hardware. Automated checks cannot guarantee identical behavior on every device.

The physical iPad mini 6 was not connected. [VisionKit scanning requires a real iOS device](https://pub.dev/documentation/apple_vision_document_scanner/latest/). There is no installable iPhone/iPad download because Apple code signing and a distribution path such as TestFlight or the App Store are not configured. The source ZIP and unsigned simulator app cannot be installed on a physical iPad. [Apple's distribution guidance](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) explains the required setup.

TAMAD is not yet feature-equivalent to CamScanner. Searchable text layers inside PDFs, annotations and signatures, cloud sync, and other advanced features are not implemented. OCR text can be searched in the TAMAD library but is not embedded in exported PDFs.

Back up any saved documents before uninstalling an older TAMAD app because uninstalling may erase its private library. If an ARM64 split APK is installed, update with the ARM64 file; the universal file uses a lower version-code sequence.
