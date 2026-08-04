# Third-party notices

LocalFlow Android includes or interoperates with the following third-party
components. This inventory accompanies the private Beta release and is not a
substitute for legal advice.

## Qwen3.5-2B

- Original model: <https://huggingface.co/Qwen/Qwen3.5-2B>
- Tested GGUF quantization: <https://huggingface.co/bartowski/Qwen_Qwen3.5-2B-GGUF>
- Quantized file: `Qwen_Qwen3.5-2B-Q4_K_M.gguf`
- License declared by both model repositories: Apache License 2.0
- The model is downloaded from the quantizer's upstream repository and is not
  stored in this GitHub repository or bundled in the APK.

License text: [`licenses/Qwen3.5-Apache-2.0.txt`](licenses/Qwen3.5-Apache-2.0.txt)

## llama.cpp

- Project: <https://github.com/ggml-org/llama.cpp>
- Source commit:
  [`9b2a088819cda774bdbf713168ee1eee8498cda5`](https://github.com/ggml-org/llama.cpp/commit/9b2a088819cda774bdbf713168ee1eee8498cda5)
- Use: local GGUF inference through the Android ARM64 JNI runtime
- License: MIT
- License text: [`licenses/llama.cpp-MIT.txt`](licenses/llama.cpp-MIT.txt)

## Whisper and whisper.cpp

- Whisper: <https://github.com/openai/whisper>
- whisper.cpp: <https://github.com/ggml-org/whisper.cpp>
- whisper.cpp source: `v1.8.6`, commit
  [`23ee03506a91ac3d3f0071b40e66a430eebdfa1d`](https://github.com/ggml-org/whisper.cpp/commit/23ee03506a91ac3d3f0071b40e66a430eebdfa1d)
- Use: local speech recognition; the tested Whisper Small Q5_1 model is bundled
  in the APK
- License declared by the upstream projects: MIT
- License texts:
  [`licenses/OpenAI-Whisper-MIT.txt`](licenses/OpenAI-Whisper-MIT.txt) and
  [`licenses/whisper.cpp-MIT.txt`](licenses/whisper.cpp-MIT.txt)

## Android SDK Platform Tools

- Official download: <https://developer.android.com/tools/releases/platform-tools>
- Use: the Windows installer downloads Google's pinned Platform Tools archive
  directly from `dl.google.com`; LocalFlow does not bundle or re-host it.
- Use remains subject to Google's Android SDK license terms presented by the
  official distribution.

## Android text-to-speech voices

LocalFlow uses offline voices installed on the phone. Those voices are Android
system or vendor components and are not distributed by LocalFlow.
