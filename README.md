# GramVidya AI

Offline-first learning for students in low-connectivity rural and tribal regions. One Flutter codebase for Android, Windows, macOS and Linux. The AI tutor, voice input and content sharing all work without internet once set up.

> **Status: working scaffold, not yet compiled or tested on devices.** Read "What is real and what is a stub" before you plan a pilot.

## What is real and what is a stub

| Area | State |
|---|---|
| UI (Home, Ask, Scholarships, Share), black theme, 6 UI languages | Written |
| Local AI on desktop through Ollama (streaming) | Written, needs a device test |
| Local AI on Android through llama.cpp | **Stub.** Dart side and channel contract are done. `native/android/LlamaPlugin.kt` still needs the llama.cpp JNI binding |
| Fallback when no model exists | Works: answers from the best offline note |
| RAG | Keyword search (BM25) over bundled notes. Not embeddings, so a Hindi question will not find English notes |
| Voice input | Android and macOS use the system recogniser. Windows and Linux record audio and call the `whisper.cpp` CLI |
| Voice output | `flutter_tts`, which needs an offline voice for the language. It does not support Linux |
| Scholarships | **Sample data.** Verify every cap and rule on scholarships.gov.in before use |
| Peer-to-peer sharing | Written: UDP discovery and HTTP transfer on a shared network |
| Video modules, career decision tree, mentoring, sync upload | Not built yet. Progress events are queued locally only |
| Gondi and Santali | No UI strings yet. Add reviewed translations in `lib/core/i18n.dart`. Local models are weak in these languages, so test before promising them |

## Project layout

```
lib/main.dart                     app shell and black theme
lib/core/i18n.dart                language list and UI strings
lib/ai/inference_controller.dart  backends: Ollama, native llama.cpp, fallback
lib/ai/rag.dart                   offline BM25 retrieval, content pack import
lib/voice/voice_service.dart      speech-to-text (system or Whisper) and text-to-speech
lib/p2p/share_service.dart        discovery and file transfer
lib/data/                         Hive progress store and scholarship data
lib/screens/                      home, chat, scholarships, share
assets/content/chunks.json        bundled study notes
native/android/LlamaPlugin.kt     Android llama.cpp bridge skeleton
packaging/                        .exe, .dmg, .deb, .AppImage scripts
scripts/setup.sh                  creates platform folders and adds permissions
.github/workflows/build.yml       builds all four platforms
```

## Setup

1. Install Flutter (stable) and the toolchain for your platform: Android Studio, Visual Studio with the C++ desktop workload, Xcode, or `clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev` on Linux.
2. From this folder run:
   ```bash
   bash scripts/setup.sh      # generates android/windows/macos/linux, adds permissions
   flutter run -d windows     # or macos, linux, or an Android device id
   ```
   On Windows run the script in Git Bash.

## Install the AI model (do this once, then go offline)

**Desktop (Ollama)**
```bash
# install Ollama from ollama.com, then, while online:
ollama pull llama3.2:3b        # about 2 GB. Use llama3.2:1b (about 1 GB) on weak laptops
export GRAMVIDYA_OLLAMA_MODEL=llama3.2:3b   # optional, this is the default
```
Keep Ollama running. Open the app and tap refresh on Home; it should show `Ollama · llama3.2:3b`. To move a model to an offline machine, copy the Ollama `models` folder (`~/.ollama/models`, or `%USERPROFILE%\.ollama\models` on Windows).

**Voice on Windows and Linux (Whisper)**
```bash
git clone https://github.com/ggml-org/whisper.cpp && cd whisper.cpp
cmake -B build && cmake --build build -j --config Release
sh models/download-ggml-model.sh base      # about 150 MB
export GRAMVIDYA_WHISPER_BIN=/path/to/build/bin/whisper-cli
export GRAMVIDYA_WHISPER_MODEL=/path/to/models/ggml-base.bin
```
On Android and macOS install the offline speech pack for your language in system settings instead.

**Android (llama.cpp)**: build the JNI library from llama.cpp's `examples/llama.android`, implement `LlamaJni.load` and `LlamaJni.generate` in `LlamaPlugin.kt`, copy the file into `android/app/src/main/kotlin/org/gramvidya/gramvidya/`, and call `LlamaPlugin.register(flutterEngine, "<app files dir>/model.gguf")` from `MainActivity.configureFlutterEngine`. Use a Q4 GGUF of a 1B to 3B model.

## Add study content

Add entries to `assets/content/chunks.json` (`id`, `subject`, `text`) and rebuild, or put a `.json` file in the same format into the app's share folder on another device and send it with the Share tab. Received packs are indexed immediately.

## Share content and models between devices

1. Put both devices on the same network: one phone's hotspot, a Wi-Fi Direct group joined in system settings, or a local router with no internet.
2. Device A: Share tab, **Share my files**. It serves the `share` folder shown on screen. Copy course packs or `.gguf` model files there.
3. Device B: **Find nearby**, tap the device, download a file.

Anyone on the same network can fetch these files, so use this only on networks you trust. Android needs the permissions added by `setup.sh`.

## Build and package

```bash
flutter build apk --release --split-per-abi              # build/app/outputs/flutter-apk/*.apk
flutter build windows --release                          # then: iscc packaging\windows\installer.iss -> build\GramVidya-Setup.exe
flutter build macos --release && bash packaging/macos/build_dmg.sh     # build/GramVidya.dmg
flutter build linux --release && bash packaging/linux/build_deb.sh && bash packaging/linux/build_appimage.sh
```
`.github/workflows/build.yml` runs all four on GitHub Actions (Run workflow, or push a `v*` tag). Installing Inno Setup (`choco install innosetup`) is needed for the Windows installer. Release signing is not configured: add an Android keystore in `android/app/build.gradle`, and code signing and notarisation for macOS and Windows before public distribution.

## Roadmap

1. Compile and fix on all four platforms, then test on a low-end Android phone.
2. Finish the llama.cpp Android binding.
3. Replace BM25 with multilingual embeddings so questions in any language find the notes.
4. Add compressed video modules, the career decision tree and mentor booking.
5. Add optional low-bandwidth sync for the progress queue.
