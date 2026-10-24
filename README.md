<div align="center">

# ⚡ DevVault

### Your personal vault of developer and media tools.

A Flutter application bringing useful media utilities and developer tools together in one place.

<p>
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Status-In%20Development-orange" alt="In development" />
  <img src="https://img.shields.io/badge/License-Not%20Specified-lightgrey" alt="License not specified" />
</p>

[Explore the Code](https://github.com/gauravbelwal13/devvault) · [Report a Bug](https://github.com/gauravbelwal13/devvault/issues)

</div>

---

## ✨ About

**DevVault** is a Flutter project designed to bring practical tools into one organized application. Its feature-based structure separates the dashboard, vault, collections, settings, and developer utilities into dedicated areas.

The current developer toolkit includes image editing utilities, audio and video trimming, media-to-PDF conversion, and Voice Studio.

The goal is to build a clean, maintainable application that can grow with additional tools and capabilities over time.

## 🚀 Features

### 🛠️ Developer Toolkit

| Tool | Description |
|---|---|
| 🎙️ **Voice Studio** | Record audio, transform it, and apply voice effects locally. |
| 🖼️ **Image Resize** | Resize images while maintaining their aspect ratio. |
| 📦 **Image Compression** | Reduce image file size while retaining good visual quality. |
| 🔄 **Image Converter** | Convert images between JPG, PNG, and WebP formats. |
| ✂️ **Image Cropper** | Crop images using custom dimensions or aspect ratios. |
| 🎬 **Video Trimmer** | Select a start and end position to trim a video. |
| 🎧 **Audio Trimmer** | Extract the audio segment you need. |
| 📄 **Media to PDF** | Convert one or more images into a PDF document. |

### 🧩 Application Modules

- **Dashboard** — a dedicated area for the app's main experience.
- **Vault** — a separate feature module for vault-related functionality.
- **Collections** — a dedicated module for organizing collections.
- **Developer Tools** — a centralized collection of media utilities.
- **Onboarding** — a dedicated onboarding flow.
- **Settings** — a separate area for app preferences.
- **Splash** — the application launch experience.

> Feature modules reflect the current project structure. Individual capabilities may evolve as development continues.

## 🧰 Tech Stack

| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev/) | Cross-platform application framework |
| [Dart](https://dart.dev/) | Application programming language |
| Material Design | UI components and visual styling |
| FFmpeg Kit plugin | Media-processing integration |
| PDFx | PDF-related integration |

## 🏗️ Project Structure

The project follows a feature-oriented organization to keep related code grouped together.

```text
lib/
├── app/
│   ├── theme/
│   └── ...
├── core/
│   └── ...
├── features/
│   ├── collections/
│   ├── dashboard/
│   ├── developer_tools/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── onboarding/
│   ├── settings/
│   ├── splash/
│   └── vault/
└── main.dart
```

*This is a simplified overview; individual folders may contain additional files and layers.*

## ⚙️ Getting Started

### Prerequisites

Install the following tools before running the project:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/downloads)
- Android SDK and an Android emulator or connected device

Verify your Flutter setup:

```bash
flutter doctor
```

### 1. Clone the repository

```bash
git clone https://github.com/gauravbelwal13/devvault.git
cd devvault
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Check the project

```bash
flutter analyze
```

### 4. Run the application

```bash
flutter run
```

### Build a debug APK

```bash
flutter build apk --debug
```

The generated APK is available at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

**Note:** Build requirements can vary by Flutter version, Android SDK, Java version, and plugin compatibility.

## 🗺️ Roadmap

Planned areas for future development:

- [ ] Continue refining the dashboard and core navigation.
- [ ] Improve the vault and collections experience.
- [ ] Polish media-tool workflows and error handling.
- [ ] Add application screenshots and usage examples.
- [ ] Explore local AI model management and additional on-device capabilities.
- [ ] Improve performance, testing, and release readiness.

*Roadmap items are plans, not claims that the functionality is already implemented.*

## 🖼️ Screenshots

Screenshots will be added as the interface is documented and polished.

## 🤝 Contributing

Contributions, bug reports, and practical suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make and test your changes.
4. Open a pull request describing the change.

For larger changes, open an issue first so the proposed work can be discussed.

## 📄 License

No license has been specified yet. Until a license is added to the repository, do not assume that the source code is available for unrestricted reuse.

---

<div align="center">

**DevVault** · Built with Flutter 💙

[Repository](https://github.com/gauravbelwal13/devvault) · [Issues](https://github.com/gauravbelwal13/devvault/issues)

</div>
