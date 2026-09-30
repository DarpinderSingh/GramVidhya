# GramVidya AI

**Offline-first learning for students in low-connectivity rural and tribal regions.**

GramVidya AI is a single Flutter codebase that runs on Android, Windows, macOS and Linux. Once set up, the AI tutor, voice input and content sharing all work without an internet connection.

> **Status: working scaffold, not yet compiled or tested on devices.**
> Read [Project status](#project-status) before planning a pilot.

---

## Why GramVidya?

Many students in rural and tribal areas have unreliable or no internet access, and most AI learning tools assume constant connectivity. GramVidya brings a local AI tutor, study notes, scholarship information and peer-to-peer content sharing to the device itself, so learning does not stop when the network does.

## Features

- **Offline AI tutor**: answers questions using a local model (Ollama on desktop, llama.cpp on Android), with retrieval over bundled study notes
- **Graceful fallback**: if no model is installed, the app answers from the best matching offline note
- **Voice input and output**: speech-to-text (system recogniser or Whisper) and text-to-speech
- **Scholarships**: a browsable scholarship section (sample data for now)
- **Peer-to-peer sharing**: share course packs and model files between nearby devices over a local network, with no internet needed
- **Multilingual UI**: 6 UI languages with a black theme
- **Local progress tracking**: progress events are stored on-device with Hive

## Project status

| Area | State |
| --- | --- |
| UI (Home, Ask, Scholarships, Share), black theme, 6 UI languages | Written |
| Local AI on desktop through Ollama (streaming) | Written, needs a device test |
| Local AI on Android through llama.cpp | **Stub.** Dart side and channel contract are done. `native/android/LlamaPlugin.kt` still needs the llama.cpp JNI binding |
| Fallback when no model exists | Works: answers from the best offline note |
| RAG | Keyword search (BM25) over bundled notes. Not embeddings, so a Hindi question will not find English notes |
| Voice input | Android and macOS use the system recogniser. Windows and Linux record audio and call the `whisper.cpp` CLI |
| Voice output | `flutter_tts`, which needs an offline voice for the language. It does not support Linux |
| Scholarships | **Sample data.** Verify every cap and rule on [scholarships.gov.in](https://scholarships.gov.in) before use |
| Peer-to-peer sharing | Written: UDP discovery and HTTP transfer on a shared network |
| Video modules, career decision tree, mentoring, sync upload | Not built yet. Progress events are queued locally only |
| Gondi and Santali | No UI strings yet. Add reviewed translations in `lib/core/i18n.dart`. Local models are weak in these languages, so test before promising them |

## Tech stack

- **Framework:** Flutter (Dart), one codebase for Android, Windows, macOS and Linux
- **Local LLM:** Ollama (desktop), llama.cpp via a native Android plugin (Kotlin)
- **Retrieval:** BM25 keyword search over bundled content
- **Speech:** system speech recogniser, `whisper.cpp`, `flutter_tts`
- **Storage:** Hive
- **Sharing:** UDP discovery and HTTP file transfer
- **CI/CD:** GitHub Actions

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

## Getting started

### 1. Prerequisites

Install Flutter (stable) and the toolchain for your platform:

- **Android:** Android Studio
- **Windows:** Visual Studio with the C++ desktop workload
- **macOS:** Xcode
- **Linux:** `clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev`

### 2. Set up and run

From the project folder:

```bash
bash scripts/setup.sh      # generates android/windows/macos/linux, adds permissions
flutter run -d windows     # or macos, linux, or an Android device id
```

On Windows, run the setup script in Git Bash.

## Install the AI model

Do this once while online, then the app works offline.

### Desktop (Ollama)

```bash
# install Ollama from ollama.com, then, while online:
ollama pull llama3.2:3b        # about 2 GB. Use llama3.2:1b (about 1 GB) on weak laptops
export GRAMVIDYA_OLLAMA_MODEL=llama3.2:3b   # optional, this is the default
```

Keep Ollama running. Open the app and tap refresh on Home; it should show `Ollama · llama3.2:3b`.

To move a model to an offline machine, copy the Ollama `models` folder (`~/.ollama/models`, or `%USERPROFILE%\.ollama\models` on Windows).

### Voice on Windows and Linux (Whisper)

```bash
git clone https://github.com/ggml-org/whisper.cpp && cd whisper.cpp
cmake -B build && cmake --build build -j --config Release
sh models/download-ggml-model.sh base      # about 150 MB
export GRAMVIDYA_WHISPER_BIN=/path/to/build/bin/whisper-cli
export GRAMVIDYA_WHISPER_MODEL=/path/to/models/ggml-base.bin
```

On Android and macOS, install the offline speech pack for your language in system settings instead.

### Android (llama.cpp)

This part is still a stub. To finish it:

1. Build the JNI library from llama.cpp's `examples/llama.android`.
2. Implement `LlamaJni.load` and `LlamaJni.generate` in `LlamaPlugin.kt`.
3. Copy the file into `android/app/src/main/kotlin/org/gramvidya/gramvidya/`.
4. Call `LlamaPlugin.register(flutterEngine, "<app files dir>/model.gguf")` from `MainActivity.configureFlutterEngine`.

Use a Q4 GGUF of a 1B to 3B model.

## Adding study content

Add entries to `assets/content/chunks.json` and rebuild:

```json
{ "id": "...", "subject": "...", "text": "..." }
```

Alternatively, put a `.json` file in the same format into the app's share folder on another device and send it with the Share tab. Received packs are indexed immediately.

## Sharing content and models between devices

1. Put both devices on the same network: one phone's hotspot, a Wi-Fi Direct group joined in system settings, or a local router with no internet.
2. **Device A:** open the Share tab and tap **Share my files**. It serves the `share` folder shown on screen. Copy course packs or `.gguf` model files there.
3. **Device B:** tap **Find nearby**, choose the device, and download a file.

> **Security note:** anyone on the same network can fetch shared files. Use this only on networks you trust. Android needs the permissions added by `setup.sh`.

## Build and package

```bash
flutter build apk --release --split-per-abi              # build/app/outputs/flutter-apk/*.apk
flutter build windows --release                          # then: iscc packaging\windows\installer.iss -> build\GramVidya-Setup.exe
flutter build macos --release && bash packaging/macos/build_dmg.sh     # build/GramVidya.dmg
flutter build linux --release && bash packaging/linux/build_deb.sh && bash packaging/linux/build_appimage.sh
```

`.github/workflows/build.yml` builds all four platforms on GitHub Actions (use **Run workflow**, or push a `v*` tag).

Notes:

- The Windows installer requires Inno Setup (`choco install innosetup`).
- Release signing is **not configured**. Before public distribution, add an Android keystore in `android/app/build.gradle`, and set up code signing and notarisation for macOS and Windows.

## Roadmap

- [ ] Compile and fix on all four platforms, then test on a low-end Android phone
- [ ] Finish the llama.cpp Android binding
- [ ] Replace BM25 with multilingual embeddings so questions in any language find the notes
- [ ] Add compressed video modules, the career decision tree and mentor booking
- [ ] Add optional low-bandwidth sync for the progress queue

## Contributing

Contributions are welcome, especially:

- Reviewed translations (including Gondi and Santali) in `lib/core/i18n.dart`
- Verified scholarship data
- Study content packs
- Testing on low-end devices

Please open an issue to discuss larger changes before submitting a pull request.

## License

No license has been added yet. Add a `LICENSE` file before accepting outside contributions or distributing builds.
