# 🎙️ Readio — Text-to-Speech Studio

<p align="center">
  <img src="assets/logo-readio.png" alt="Readio Logo" width="160"/>
</p>

<p align="center">
  <b>Professional text-to-speech · Background music · Export MP3/WAV</b>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart"/>
  <img alt="Android" src="https://img.shields.io/badge/Android-API%2024+-3DDC84?logo=android"/>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue"/>
</p>

<p align="center">
  <a href="documents/readme/README.vi.md">🇻🇳 Tiếng Việt</a> ·
  <a href="README.md">🇺🇸 English</a> ·
  <a href="documents/readme/README.ja.md">🇯🇵 日本語</a> ·
  <a href="documents/readme/README.ko.md">🇰🇷 한국어</a> ·
  <a href="documents/readme/README.zh.md">🇨🇳 中文</a> ·
  <a href="documents/readme/README.fr.md">🇫🇷 Français</a> ·
  <a href="documents/readme/README.es.md">🇪🇸 Español</a> ·
  <a href="documents/readme/README.de.md">🇩🇪 Deutsch</a>
</p>

---

## ✨ Features

### 🗣️ Text-to-Speech (TTS)
- Type freely, **paste text**, load a `.txt` file, or use a sample text
- Live character count and estimated duration display
- Filter and choose voices by language — shows **country flag + human-readable name**
- Configure voice: **gender, style, speed, and pitch**
- Preview audio (10–30s) before generating the final file
- Long texts split into 550-character chunks — no buffer overflow ever

### 🎵 Background Music (BGM)
- 6 built-in tracks: Asphyxia, Beat 1, Illusionary Daytime, Paris, Shiverr, Time Back
- Add music from a **local file** or **download from URL** (saved locally for uninterrupted playback)
- Toggle BGM on/off with a single switch on the main screen
- Default BGM volume **30%**, max **80%**
- Playback modes: **loop one / loop all / play through and stop**
- Skip tracks (grayed out) or delete user-added tracks

### 📁 Export
- Choose **MP3** or **WAV** format directly on the create screen
- Mix background music into the export using **FFmpeg** — supports any audio format
- Filename auto-generated from the **first 30 characters** of the text
- Full-screen progress overlay with **animated progress ring** and clear **% complete**
- **Cancel button** — stops immediately and rolls back all temporary files
- Saved to `/storage/emulated/0/copecute/readio/` (Android)

### 🎚️ Presets
- Save voice configs (speed, pitch, voice) as presets
- Built-in presets: Normal, Audiobook, Podcast
- Apply any preset with a single tap

### 📚 History
- All generated files saved with their folder path
- Search by filename or text content
- **Inline playback** with progress bar and waveform animation
- Share or delete from history
- Metadata: voice, file size, date created

### ⚙️ Settings
- Choose **UI language** (8 languages) via a flag-grid interface
- Theme: **System / Light / Dark**
- Select **TTS engine** (e.g., Google TTS) and refresh the voice list
- Manage audio output folder, copy path quickly

### 🌍 Localization
Supports **8 UI languages**:
🇻🇳 Vietnamese · 🇺🇸 English · 🇯🇵 Japanese · 🇰🇷 Korean · 🇨🇳 Chinese · 🇫🇷 French · 🇪🇸 Spanish · 🇩🇪 German

### 🎨 UX / UI
- Default dark mode with a refined teal accent on deep navy
- Full-screen overlay during generation — smooth animated progress ring
- **Fully offline** — no internet connection required

---

## 📱 Screenshots

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="Create Screen" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="Generating (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="History Screen" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="Settings Screen" width="22%"/>
</p>

<p align="center">
  <em>Create voice</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Generating (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>History</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Settings</em>
</p>

---

## 🚀 Setup & Build

### Requirements
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### Clone & run
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### Build APK
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

Output APK: `build/app/outputs/flutter-apk/`

---

## 🗂️ Project Structure

```
lib/
├── core/
│   └── localization/       # app_locale.dart — 8 languages
├── models/                 # BgmTrack, TtsVoiceItem, HistoryAudioItem, ...
├── services/
│   ├── tts_service.dart    # TTS engine, synthesizeToFile, chunk merge
│   ├── bgm_service.dart    # Background music management
│   ├── audio_mixer.dart    # FFmpeg BGM mixing
│   ├── wav_merger.dart     # Pure-Dart WAV chunk merging
│   ├── audio_player_service.dart
│   ├── history_service.dart
│   └── preset_service.dart
├── views/
│   ├── create_view.dart    # Main create screen
│   ├── history_view.dart
│   ├── settings_view.dart
│   ├── home_view.dart
│   └── welcome_view.dart
└── widgets/                # Reusable widgets

android/
└── app/src/main/kotlin/.../MainActivity.kt  # Export, media scan, storage permission
assets/
└── audio/                  # Default BGM tracks (MP3)
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_tts` | Android TTS engine |
| `ffmpeg_kit_flutter_new` | Mix BGM into exported file |
| `audioplayers` | BGM playback + voice preview |
| `file_picker` | Pick local music files |
| `share_plus` | Share files |
| `path_provider` | Temp file paths |
| `shared_preferences` | Persist settings, history, presets |

---

## 🛠️ How It Works

```
Enter text
    ↓
Select voice + speed + pitch
    ↓
(Optional) Select BGM + volume + loop mode
    ↓
Tap "Create Audio"
    ↓
TTS splits text into 550-char chunks
    ↓
Synthesize each chunk → WAV
    ↓
Merge WAV chunks → merged.wav (pure Dart)
    ↓
FFmpeg: merged.wav + bgm.mp3 → output.mp3 / output.wav
    ↓
Export to /storage/emulated/0/copecute/readio/
    ↓
Save to history
```

---

## 📄 License

MIT © 2026 [copecute](https://github.com/copecute)

