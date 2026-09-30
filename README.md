# 🌾 GramVidya AI

### **Learning should not stop when the internet does.**

> **An offline-first AI learning platform designed for students in rural and low-connectivity communities.**

GramVidya AI is a Flutter-based educational platform that brings **AI tutoring, multilingual learning, voice interaction, offline study material, scholarships, progress tracking, and peer-to-peer content sharing** directly to the learner's device.

The core idea is simple:

**Download once. Learn anywhere. Keep learning offline.**

---

## 🎯 The Problem

Millions of students in rural and underserved regions face a fundamental barrier to digital education:

### **Internet connectivity cannot be assumed.**

Most modern EdTech and AI learning platforms depend on:

* Continuous internet connectivity
* Cloud-hosted AI models
* Online educational content
* Expensive or high-bandwidth video
* Centralized servers
* English-first interfaces

For a student with an unreliable connection, limited data, or no connectivity at all, even the best AI tutor becomes useless the moment the network disappears.

### We asked:

> **What if an AI tutor could travel with the student instead of requiring the student to travel to the internet?**

That question led to **GramVidya**.

---

# 💡 Our Solution

GramVidya is designed around an **offline-first architecture**.

Instead of making the internet a requirement, the internet is used primarily for **initial acquisition and synchronization**.

```text
                ONLINE
                   │
        ┌──────────▼──────────┐
        │ Download AI Model   │
        │ Download Courses    │
        │ Download Resources  │
        │ Update Content      │
        └──────────┬──────────┘
                   │
                   ▼
             DEVICE STORAGE
                   │
        ┌──────────▼──────────┐
        │     GramVidya       │
        │                     │
        │  🤖 Local AI Tutor  │
        │  📚 Offline Courses │
        │  🎙️ Voice Learning │
        │  🎓 Scholarships    │
        │  📈 Progress        │
        │  📡 P2P Sharing    │
        └──────────┬──────────┘
                   │
                   ▼
              OFFLINE USE
```

A student can download the required model and educational resources while connected and continue learning when connectivity disappears.

---

# 🚀 Key Features

## 🤖 1. Offline AI Tutor

GramVidya is being built to run a **local language model directly on the device**.

The application supports an architecture based around:

* GGUF models
* `llamadart`
* llama.cpp
* Local inference
* Streaming generation
* Optional Retrieval-Augmented Generation (RAG)

### Designed workflow

```text
Student asks a question
        ↓
Ask Tab
        ↓
Local AI Engine
        ↓
Downloaded GGUF Model
        ↓
Local inference
        ↓
Generated explanation
        ↓
Student
```

No cloud request is required once the required model and content are available locally.

### Model philosophy

The application does **not force every user to install a large AI model inside the initial application package**.

Instead:

```text
Small App
   +
Optional AI Model Download
   =
Offline AI
```

This reduces the initial installation size and allows users to decide whether they want the local AI capability.

---

# 📚 2. Offline Learning Content

Students can access educational material even without an active internet connection.

Content can include:

* Subject notes
* Chapters
* Course material
* Study packs
* Downloaded resources
* Locally stored educational content

The application maintains local content and learning state so that connectivity is not required for basic learning.

---

# 🧠 3. Retrieval-Augmented Learning

GramVidya separates:

### **Knowledge retrieval**

from

### **AI generation**

Educational content can be retrieved from the local knowledge base and supplied as context to the AI tutor.

```text
Student Question
       ↓
Local Retrieval
       ↓
Relevant Educational Content
       ↓
AI Model
       ↓
Context-aware Explanation
```

This architecture is intended to reduce irrelevant answers and make explanations more grounded in educational material.

---

# 🌐 4. Multilingual Learning

Education should not be restricted by language.

GramVidya includes a multilingual interface and is designed to support learning in Indian languages.

The architecture allows:

* Localized UI
* Language switching
* Regional educational content
* AI responses in the learner's preferred language
* Voice interaction

The project is designed so that additional reviewed translations and language resources can be added over time.

---

# 🎙️ 5. Voice-Based Learning

For learners who may find typing difficult or prefer conversational learning, GramVidya includes voice capabilities.

### Voice pipeline

```text
Student speaks
      ↓
Speech-to-Text
      ↓
AI / Educational Engine
      ↓
Generated explanation
      ↓
Text-to-Speech
      ↓
Student listens
```

The project uses platform speech capabilities and offline speech tooling such as Whisper-based components where appropriate.

---

# 🎓 6. Scholarship Discovery

GramVidya includes a scholarship section intended to make educational opportunities easier to discover.

The goal is to provide students with:

* Scholarship information
* Eligibility information
* Application-related guidance
* Educational opportunities

> Scholarship eligibility, deadlines and funding information should always be verified against the official source before application.

---

# 📈 7. Personalized Learning & Progress

Learning progress is stored locally.

GramVidya can track:

* Courses
* Chapters
* Recent learning activity
* Progress
* Weak topics
* Learning history

This enables the platform to evolve from a simple chatbot into a **personal learning companion**.

---

# 📡 8. Peer-to-Peer Learning

One of GramVidya's key ideas is that **one connected device can help other nearby devices become connected to knowledge**.

Devices on the same local network can exchange:

* Educational content packs
* Study resources
* AI model files

### Example

```text
             Student A
          ┌─────────────┐
          │ Has internet│
          │ + AI model  │
          └──────┬──────┘
                 │
          Local Wi-Fi / Hotspot
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
 Student B             Student C
 Offline               Offline
```

This creates a foundation for **community-powered offline education**.

---

# 🏗️ System Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    GRAMVIDYA AI                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Flutter Application                                │
│                                                     │
│  ┌─────────┐ ┌────────┐ ┌────────────┐ ┌────────┐ │
│  │  Home   │ │  Ask   │ │  Learning  │ │ Mentor │ │
│  └─────────┘ └───┬────┘ └────────────┘ └────────┘ │
│                  │                                  │
│           ┌──────▼──────┐                           │
│           │ AI Engine   │                           │
│           └──────┬──────┘                           │
│                  │                                  │
│        ┌─────────┴─────────┐                        │
│        ▼                   ▼                        │
│  Local LLM             RAG Engine                   │
│  GGUF / llama.cpp      Local Content                │
│        │                   │                        │
│        └─────────┬─────────┘                        │
│                  ▼                                  │
│          Contextual Answer                         │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Voice │ Content │ Progress │ Scholarships │ P2P    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

# 🧰 Technology Stack

| Layer          | Technology                                    |
| -------------- | --------------------------------------------- |
| Application    | **Flutter / Dart**                            |
| AI Runtime     | **llamadart / llama.cpp**                     |
| Model Format   | **GGUF**                                      |
| Desktop AI     | Local model backend / Ollama integration      |
| Retrieval      | Local keyword/BM25 retrieval                  |
| Storage        | Hive / local device storage                   |
| Speech-to-Text | System speech APIs / Whisper                  |
| Text-to-Speech | `flutter_tts`                                 |
| Networking     | Local network / UDP discovery / HTTP transfer |
| Android Native | Kotlin                                        |
| CI/CD          | GitHub Actions                                |
| Packaging      | Android APK, Windows, macOS, Linux            |

---

# 🗂️ Project Structure

```text
GramVidhya/
│
├── lib/
│   ├── ai/
│   │   ├── inference_controller.dart
│   │   └── rag.dart
│   │
│   ├── core/
│   │   └── i18n.dart
│   │
│   ├── data/
│   │
│   ├── screens/
│   │
│   ├── voice/
│   │   └── voice_service.dart
│   │
│   └── p2p/
│       └── share_service.dart
│
├── assets/
│   └── content/
│       └── chunks.json
│
├── native/
│   └── android/
│       └── LlamaPlugin.kt
│
├── android/
│
├── test/
│
├── packaging/
│
├── scripts/
│
└── .github/
    └── workflows/
```

---

# 🔥 What Makes GramVidya Different?

Most EdTech platforms follow:

```text
Student
   ↓
Internet
   ↓
Cloud Server
   ↓
AI Model
   ↓
Answer
```

GramVidya is designed around:

```text
Student
   ↓
Device
   ↓
Local AI + Local Knowledge
   ↓
Answer
```

### The internet becomes an accelerator, not a dependency.

That distinction matters in environments where:

* Connectivity is unreliable
* Mobile data is expensive
* Bandwidth is limited
* Cloud access is unavailable
* Infrastructure is inconsistent

---

# 🧩 Offline-First Design Principles

GramVidya follows five core principles:

### 1. Local First

Prefer local data and computation whenever possible.

### 2. Download Once

Acquire models and content while connected.

### 3. Learn Anywhere

Continue learning without internet connectivity.

### 4. Share Locally

Allow nearby devices to exchange educational resources.

### 5. Sync When Possible

When connectivity returns, the platform can synchronize or refresh resources.

---

# 📱 User Journey

### First-time user

```text
Install GramVidya
       ↓
Choose language
       ↓
Explore courses
       ↓
Download AI model (optional)
       ↓
Download educational content
       ↓
AI becomes available offline
```

### Offline user

```text
Open GramVidya
       ↓
Ask a question
       ↓
Local AI
       ↓
Get explanation
       ↓
Continue learning
```

### Community sharing

```text
Device A
   │
   │ Local network
   ▼
Device B
   │
   ▼
Educational content / AI model
```

---

# 🌾 Real-World Use Case

Imagine a student in a village preparing for an examination.

The student has:

* An Android phone
* Intermittent internet
* Limited mobile data
* No reliable access to a private AI tutor

While connected to the internet, the student downloads:

```text
GramVidya
+
AI model
+
Course content
```

Later, when the internet disappears:

> **Learning continues.**

The student can:

* Ask questions
* Read chapters
* Review previous topics
* Track progress
* Use supported voice features
* Access downloaded resources
* Exchange educational files with nearby users

---

# 🏆 Hackathon Innovation

GramVidya is not simply another educational chatbot.

The project combines:

### 🤖 On-device AI

Local language-model inference.

### 📚 Offline education

Educational material stored locally.

### 🧠 Context-aware tutoring

Retrieval + local generation.

### 🎙️ Voice interaction

Speech-based learning.

### 🌐 Multilingual access

Designed around Indian-language accessibility.

### 📡 Community distribution

Peer-to-peer exchange of models and educational resources.

### 📱 Low-connectivity design

The system is designed around unreliable connectivity rather than treating it as an edge case.

---

# 🔐 Privacy

Local-first AI also provides a privacy advantage.

When inference occurs locally:

```text
Student Question
      ↓
   Device
      ↓
 Local Model
      ↓
   Answer
```

The question does not inherently need to leave the device for AI inference.

This architecture can reduce dependence on centralized processing for supported offline workflows.

---

# 📊 Impact

GramVidya aims to address three connected problems:

| Challenge                     | GramVidya Approach           |
| ----------------------------- | ---------------------------- |
| Poor connectivity             | Offline-first learning       |
| Limited access to AI          | On-device AI                 |
| Language barriers             | Multilingual interface       |
| Limited educational resources | Downloadable content         |
| Expensive cloud inference     | Local inference              |
| Resource distribution         | Peer-to-peer sharing         |
| Lack of personalized help     | AI tutor + progress tracking |

---

# 🛣️ Roadmap

### Phase 1 — Core Platform

* [x] Flutter application architecture
* [x] Offline content system
* [x] Local progress tracking
* [x] Multilingual UI foundation
* [x] AI inference architecture
* [x] Content retrieval
* [x] Peer-to-peer sharing foundation

### Phase 2 — On-Device Intelligence

* [x] GGUF model support architecture
* [x] `llamadart` integration
* [ ] Complete production Android inference path
* [ ] Robust model lifecycle management
* [ ] Streaming local inference
* [ ] Multilingual retrieval

### Phase 3 — Personalized Education

* [ ] Adaptive learning paths
* [ ] Weak-topic detection
* [ ] AI-generated practice questions
* [ ] Personalized revision plans
* [ ] Improved digital mentoring

### Phase 4 — Community Learning

* [ ] Low-bandwidth synchronization
* [ ] Community course packs
* [ ] Distributed content sharing
* [ ] Regional-language educational datasets
* [ ] Support for more underserved languages

---

# 🧪 Current Development Status

GramVidya is an active hackathon prototype.

The major application architecture, Flutter UI, offline content infrastructure, local storage, multilingual foundation, sharing infrastructure and AI integration are under active development.

### Current focus

> **Making the downloaded local GGUF model reliably load and generate responses inside the Ask experience.**

The project uses `llamadart 0.9.0` and a native local-inference architecture. Runtime initialization has been validated during development; full end-to-end model inference and device validation remain part of the current integration work.

This distinction is intentional: **we would rather document what is actually verified than claim a feature that has not been tested.**

---

# 🚀 Getting Started

## Requirements

* Flutter stable
* Dart
* Android Studio for Android development
* Visual Studio with C++ workload for Windows
* Xcode for macOS
* Linux desktop dependencies where applicable

## Clone

```bash
git clone https://github.com/DarpinderSingh/GramVidhya.git
cd GramVidhya
```

## Install dependencies

```bash
flutter pub get
```

## Run

```bash
flutter run
```

For Windows:

```bash
flutter run -d windows
```

For Android:

```bash
flutter devices
flutter run -d <device-id>
```

---

# 📦 Build Android APK

```bash
flutter build apk --release
```

For split APKs:

```bash
flutter build apk --release --split-per-abi
```

Output:

```text
build/app/outputs/flutter-apk/
```

---

# 🧪 Testing

Run the complete test suite:

```bash
flutter test
```

Run a specific test:

```bash
flutter test test/llamadart_inspect_test.dart
```

Analyze the project:

```bash
flutter analyze
```

---

# 🖥️ Platform Support

| Platform | Goal                  |
| -------- | --------------------- |
| Android  | ⭐ Primary target      |
| Windows  | Development / desktop |
| Linux    | Development / desktop |
| macOS    | Development / desktop |

The architecture intentionally uses Flutter so that the same core educational experience can be extended across platforms.

---

# 🌍 Vision

GramVidya is built around one principle:

> ### **A student's access to education should not depend on the availability of a signal tower.**

AI has made personalized education technically possible.

The challenge is making that intelligence **accessible where connectivity is not guaranteed**.

GramVidya attempts to move AI tutoring from:

**the cloud → to the community → to the device.**

---

# 👥 Team

**GramVidya AI**

Built as a student-led innovation project focused on:

* Artificial Intelligence
* On-device Machine Learning
* Flutter
* Educational Technology
* Offline-first systems
* Rural accessibility

---

# 🔗 Project

**GitHub:**
https://github.com/DarpinderSingh/GramVidhya

---

# ⭐ Support the Project

If you find the idea useful:

* ⭐ Star the repository
* 🐛 Report issues
* 💡 Suggest features
* 📚 Contribute educational content
* 🌐 Contribute reviewed translations
* 📱 Test on low-end Android devices

---

## 📜 License

See the repository for the current licensing status.

---

<div align="center">

### 🌾 GramVidya AI

**Learn anywhere. Learn offline. Learn without limits.**

**Built for learners where connectivity cannot be taken for granted.**

</div>
