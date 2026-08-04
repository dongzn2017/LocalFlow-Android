# LocalFlow Android

Private release repository for the Android edition of LocalFlow, an offline
two-person speech translator.

## Requirements

- Android 13 or newer
- ARM64 phone (`arm64-v8a`)
- Windows 10 or 11 computer for the USB installer
- A USB data cable and USB debugging enabled on the phone
- About 3 GB of temporary free phone storage during first-time model import

Android Studio, Java, the Android SDK, and the NDK are not required on the
user's computer.

## USB installation

1. Download `LocalFlow-Android-0.6.5-beta.1-USB-Installer.zip` from the latest
   GitHub Release.
2. Extract the complete ZIP.
3. Enable **Developer options > USB debugging** on the phone.
4. Connect one phone and accept the phone's USB debugging authorization.
5. Double-click `Install-LocalFlow.cmd`.

The installer verifies the signed APK, downloads a pinned copy of Google's
Platform Tools when `adb` is not already available, installs the APK, downloads
and verifies the tested translation model, and transfers it to the app's USB
staging directory. LocalFlow verifies the model again before importing it into
private app storage.

The installer caches the model under `%LOCALAPPDATA%\LocalFlow\InstallerCache`
so later installations do not download 1.3 GB again. Translation and speech
recognition run without Internet access after setup. The Android app itself
does not request Internet permission.

## Release target

- App version: `0.6.5-beta.1` (`versionCode 14`)
- Package: `com.localflow.translator`
- Minimum and target API: 33
- ABI: `arm64-v8a`
- Whisper Small Q5_1 is bundled in the APK
- Qwen3.5-2B Q4_K_M remains outside the APK and comes from its upstream model
  repository

## Signing

Release APKs use a dedicated LocalFlow signing key. The private key and its
password are never stored in this repository. All future updates must use the
same signing key. The release notes publish the certificate fingerprint and
artifact SHA-256 values so installations can be audited.

## Privacy

Audio, recognized text, translations, and model inference remain on the phone.
The installer uses the network only to obtain Google's ADB tools and the
external translation model during setup.

Third-party sources and license notices are recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
