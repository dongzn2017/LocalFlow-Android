# LocalFlow Android

Private release repository for the Android edition of LocalFlow, an offline
two-person speech translator.

## Current release target

- Android 13 or newer
- ARM64 devices (`arm64-v8a`)
- Signed APK distributed through GitHub Releases
- Lightweight Windows USB installer using Google's Android Platform Tools
- Whisper speech-recognition model bundled with the APK
- Qwen3.5-2B Q4_K_M downloaded from its upstream model repository, verified by
  file size and SHA-256, and transferred to the phone during installation

Translation and speech recognition run locally after installation. The
one-time internet connection is used only to download installation files and
the external translation model.

## Repository status

This repository is currently private and contains no public release. Release
artifacts, checksums, notices, and installation instructions will be added
after the signed build and USB installation flow have been verified.
