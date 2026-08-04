# LocalFlow Android 0.6.5 Beta 1

This is the first private USB-installable Android Beta.

## Included

- Signed ARM64 APK for Android 13 and newer
- Whisper Small Q5_1 bundled for local multilingual speech recognition
- Two-person push-to-talk translation and offline TTS playback
- Bluetooth left/right channel routing with speaker fallback
- Text translation screen
- USB installer that requires neither Android Studio nor a preinstalled SDK
- Pinned, SHA-256-verified downloads for Google Platform Tools and the external
  Qwen3.5-2B Q4_K_M translation model
- Automatic import of a USB-staged model into private app storage

## First installation

The computer needs Internet access once to download approximately 1.4 GB of
model data. The phone may temporarily need about 3 GB of free storage while the
model is transferred and copied into private storage. After successful import,
the staging copy is deleted and recognition and translation run offline.

Some target-language TTS voices may need to be installed through the phone's
system speech settings before completely offline playback is available.

## Integrity

- APK SHA-256:
  `35fff6041d6305a202eca3daf357c0e1a4f36fe3b6c2aba2b7ecf8607a596ae3`
- Signing certificate SHA-256:
  `6e7dc7cd0d9230b441120632bdb135f2e44f951a10baf49205f27086d44f923f`
- Qwen GGUF SHA-256:
  `57a1085840f497d764a7fc5d346922dbde961efb54cc792ea81d694fd846a1d8`
