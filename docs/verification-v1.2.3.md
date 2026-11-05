# TAMAD v1.2.3 verification

Checked on 5 November 2026. App source: [commit bb8640d](https://github.com/teng08/TAMAD/commit/bb8640dfb1dc962f2ec5530ee4d5e906368e36f4). Downloads: [GitHub release v1.2.3](https://github.com/teng08/TAMAD/releases/tag/v1.2.3).

## What changed

Scanned and imported image pages now have an **Edit page** menu with Enhance contrast, Grayscale, Black and white, Original color, and Rotate clockwise. The first filter saves one extra local copy of the original page; selecting another filter uses that copy, so changes do not accumulate and Original color restores it. Rotating a filtered page rotates its saved original too. The PDF is rebuilt after each page edit. Filter processing runs in a Dart isolate to keep the interface responsive. Imported PDF files retain their original pages and do not have image-page editing controls.

## Android downloads

| File | Purpose | Size | SHA-256 |
| --- | --- | ---: | --- |
| [TAMAD-v1.2.3-arm64.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.3/TAMAD-v1.2.3-arm64.apk) | OPPO A96 and other ARM64 phones | 32,879,647 bytes | `912F877DCA4F84890C8B558E662AB5A2C4A402E3BD5F6AABCDA1C4B3540CB7AB` |
| [TAMAD-v1.2.3-android.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.3/TAMAD-v1.2.3-android.apk) | Universal Android build | 88,443,102 bytes | `20F268E8CA6F1AC5B04A70B4CD94F53BCB2F33BC5506CD16E62E242E110897B4` |

GitHub reports the same SHA-256 digests for both uploaded assets. Android's APK verifier accepts both v2 signatures. The package ID is `com.tamad.tamad`, version name is `1.2.3`, and minimum Android version is 7.0 (API 24). The universal build uses version code 6 and includes ARM64, ARMv7, and x86-64 Flutter binaries. The smaller split build uses version code 2006 and contains ARM64 native binaries only. Both use the same testing certificate as the v1.2.2 APKs.

The **exact universal file from the release page** downloaded with its checksum verified, then installed and launched on Android 7, 11, 13, and 15 emulators: [Android verification run](https://github.com/teng08/TAMAD/actions/runs/42033346478). This checks installation and startup, not the camera or every document action.

## Code and iPad checks

- Flutter analysis found no issues. All 13 automated tests passed, including PDF and PNG import, reversible image filters, rotation after filtering, failed-import cleanup, damaged saved metadata, and phone/tablet layouts. A small-phone UI test opened a document and checked the page-edit menu.
- The iOS release target compiled without signing. The iPad simulator build installed and launched; the app process remained alive after 60 seconds. The [home-screen screenshot](ipad-home-v1.2.3.png) visibly shows the logo, scan card, Add file, and navigation: [iOS verification run](https://github.com/teng08/TAMAD/actions/runs/42032807480).
- Flutter/Dart provides the interface, local document handling, filters, and PDF generation. [Google ML Kit's native Android scanner](https://pub.dev/packages/google_mlkit_document_scanner) supplies camera document detection, crop, rotation, and its own cleanup options; [Apple VisionKit](https://pub.dev/documentation/apple_vision_document_scanner/latest/) supplies the native iOS document camera. The app also uses native ML Kit text recognition. These are dependencies, so GitHub's repository language chart does not show all their native code.

## Limits

TAMAD is **not feature-equivalent to CamScanner**. It still lacks, among other things, manual crop for imported photos, searchable text layers inside exported PDFs, annotations/signatures, and cloud sync. These are not claimed as working features.

The earlier OPPO A96 Android 13 installation error was not reproduced or diagnosed on that phone because it was not connected. The ARM64 APK has a valid signature and correct ABI, but its installation and scanning on the OPPO A96 are **not verified**. Camera capture, native OCR, photo/file picker behavior, PDF sharing, and large-batch performance were not exercised on real hardware. Simulator and unit checks cannot guarantee identical behavior on every device.

The physical iPad mini 6th generation was not connected. The simulator proves build and startup, but [VisionKit document scanning requires a real iOS device](https://pub.dev/documentation/apple_vision_document_scanner/latest/). There is **no installable iPhone/iPad download**: the user has an iPad but no Apple Developer Program team, and [Apple's distribution process](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) requires signing and a distribution path such as TestFlight or the App Store.

If an older TAMAD app is installed, back up its saved documents before uninstalling it. Removing the app may erase its private local library.
