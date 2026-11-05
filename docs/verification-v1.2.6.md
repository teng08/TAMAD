# TAMAD v1.2.6 verification

Checked on 6 November 2026. Source: [commit ea243cd](https://github.com/teng08/TAMAD/commit/ea243cd5c5231b16d7f3dd52eb2921b0f5bf62b9) at [tag v1.2.6](https://github.com/teng08/TAMAD/tree/v1.2.6). Downloads: [GitHub release v1.2.6](https://github.com/teng08/TAMAD/releases/tag/v1.2.6).

## Changes

Renaming a scan or imported PDF now renames the actual PDF file inside TAMAD's document library, updates its saved path, and persists the new name across launches. Open PDF and Share use that updated path. A name entered with `.pdf` is normalized to a single `.pdf` extension. The iPad share sheet now anchors to the Share button. The iOS build check verifies the compiled TAMAD display name, bundle identifier, and icon catalog.

## Android downloads

| File | Intended device | Size | SHA-256 |
| --- | --- | ---: | --- |
| [TAMAD-v1.2.6-arm64.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.6/TAMAD-v1.2.6-arm64.apk) | OPPO A96 and other ARM64 phones | 32,879,863 bytes | `7397D3A5A992CC8191F43729318E979EE2669D892E8D5546A5F9002E541B1D1E` |
| [TAMAD-v1.2.6-android.apk](https://github.com/teng08/TAMAD/releases/download/v1.2.6/TAMAD-v1.2.6-android.apk) | Universal Android build | 88,492,474 bytes | `2C4CC907EED5133BE0BC8C25D365041A8A7D3C91EE3250F301F664B2DB59CA99` |

GitHub reports the same sizes and SHA-256 hashes for the exact published files. Android's APK verifier accepts both v2 signatures, with the same signing certificate as v1.2.5. Both have package ID `com.tamad.tamad`, version name `1.2.6`, and minimum Android version 7.0 (API 24). The universal APK has ARM64, ARMv7, and x86-64 native binaries and version code 9. The smaller APK has only ARM64 native binaries and version code 2009. Both are testing builds signed with the Android debug certificate, not Play Store releases.

The [ARM64 published-package check](https://github.com/teng08/TAMAD/actions/runs/42063277304) passed: it downloaded the exact release asset and checked its SHA-256, ZIP integrity, Android signature, package identity, version, minimum Android level, and ARM64 architecture. This is a package check, not an OPPO A96 installation test.

The [universal APK emulator run](https://github.com/teng08/TAMAD/actions/runs/42063271640) passed all four jobs. Each job downloaded the exact published APK, checked its SHA-256, installed it, launched it, and confirmed the app process remained alive on Android 7, 11, 13, or 15. These are install and startup checks, not camera or end-to-end document tests.

## Code and PDF behavior

Flutter analysis found no issues. All 17 automated tests passed. The new rename tests cover a PDF made from two photos and an imported PDF. They check the renamed file exists, the old filename is gone, the document metadata reloads with the new name, the two-page PDF rebuilds under that filename, and imported PDF bytes remain unchanged. The app's Share action supplies that saved file path to the platform share sheet. Share targets on a physical phone or tablet were not exercised.

The [iPad simulator run](https://github.com/teng08/TAMAD/actions/runs/42061776659) passed Flutter analysis and tests, compiled the iOS release target without signing, checked the built app's TAMAD display name, bundle ID, and icon catalog, installed and launched the simulator app, and saved an [in-app home-screen screenshot](ipad-home-v1.2.6.png). It stayed alive for the workflow's 60-second check. This verifies the simulator app, not physical iPad installation or camera capture.

## iOS installation limit

The iOS project targets iPhone and iPad, includes TAMAD app icons, and targets iOS/iPadOS 15.5 or newer. The source ZIP and unsigned simulator build cannot be installed on a physical iPhone or iPad. The user has no Apple Developer Program team, and a physical iPad was not connected; no signed `.ipa`, TestFlight build, or App Store release exists. [Apple's distribution guidance](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) requires program membership for distribution to registered devices, TestFlight, or the App Store. A personal app can be installed through Xcode without membership, but that route requires access to a Mac and the device and does not provide a public GitHub download.

## Device-test limits

The OPPO A96 is not connected, so its earlier installation error and real camera, file-picker, sharing, and OCR behavior remain unverified on that phone. The physical iPad mini 6 is not connected, so native VisionKit scanning and the iPad share sheet cannot be confirmed on it. Emulator startup checks and unit tests do not establish that every feature will run perfectly on every device. Back up saved documents before uninstalling an older TAMAD app. If an ARM64 split APK is already installed, update with the ARM64 file because its version-code sequence differs from the universal APK.
