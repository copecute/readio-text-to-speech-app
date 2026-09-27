# 🎙️ Readio — Text-to-Speech Studio

<p align="center">
  <img src="assets/logo-readio.png" alt="Readio Logo" width="120"/>
</p>

<p align="center">
  <b>Chuyển văn bản thành giọng nói chuyên nghiệp · Nhạc nền · Xuất MP3/WAV</b>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart"/>
  <img alt="Android" src="https://img.shields.io/badge/Android-API%2024+-3DDC84?logo=android"/>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue"/>
</p>

---

## ✨ Tính năng

### 🗣️ Đọc văn bản (TTS)
- Đọc văn bản bất kỳ với giọng đọc hệ thống (Android TTS engine)
- Lọc và chọn giọng đọc theo ngôn ngữ — hiển thị **cờ quốc gia + tên tiếng người**
- Điều chỉnh **tốc độ** (0.5× – 1.5×) và **cao độ giọng** (pitch)
- Xem trước ngay (preview) từng giọng đọc trước khi áp dụng
- Chia văn bản dài thành chunk 550 ký tự — không bao giờ bị buffer overflow

### 🎵 Nhạc nền (BGM)
- 6 bản nhạc nền có sẵn: Asphyxia, Beat 1, Illlusionary Daytime, Paris, Shiverr, Time Back
- Thêm nhạc từ **file nội bộ** hoặc **tải từ URL** (lưu về máy để không gián đoạn)
- Âm lượng nhạc nền mặc định **30%**, tối đa **80%**
- Chế độ phát: **lặp 1 bài / lặp danh sách / phát hết rồi dừng**
- Bỏ qua bài (hiển thị xám) hoặc xoá bài user thêm

### 📁 Xuất file
- Xuất định dạng **MP3** hoặc **WAV** (user tự chọn)
- Ghép nhạc nền vào file xuất bằng **FFmpeg** — hỗ trợ mọi định dạng nhạc nền
- Tên file tự sinh từ **30 ký tự đầu** của nội dung văn bản
- Lưu tại `/storage/emulated/0/copecute/readio/` (Android)
- Thông báo hệ thống (notification) hiển thị tiến trình

### 🎚️ Preset
- Lưu cấu hình giọng đọc (tốc độ, cao độ, giọng) thành preset
- Preset mẫu tích hợp sẵn: Bình thường, Sách nói, Podcast
- Áp dụng preset một chạm

### 📚 Lịch sử
- Toàn bộ file đã tạo được lưu vào lịch sử
- Tìm kiếm theo tên file hoặc nội dung văn bản
- Phát lại, chia sẻ, xoá từ lịch sử
- Hiển thị metadata: giọng đọc, thời lượng, dung lượng, ngày tạo

### 🌍 Đa ngôn ngữ
Hỗ trợ **8 ngôn ngữ** giao diện:
🇻🇳 Tiếng Việt · 🇺🇸 English · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇨🇳 中文 · 🇫🇷 Français · 🇪🇸 Español · 🇩🇪 Deutsch

### 🎨 UX / UI
- Dark mode mặc định với màu sắc tinh tế
- Overlay toàn màn hình khi đang tạo file (không bị che bởi dialog)
- Progress ring animate mượt (TweenAnimationBuilder)
- **Nút Huỷ** — dừng và rollback toàn bộ file tạm ngay lập tức
- Không cần kết nối mạng (offline hoàn toàn)

---

## 📱 Ảnh chụp màn hình

> *(Cập nhật sau khi có bản build release)*

---

## 🚀 Cài đặt & Build

### Yêu cầu
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### Clone & chạy
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

File APK xuất ra tại: `build/app/outputs/flutter-apk/`

---

## 🗂️ Cấu trúc dự án

```
lib/
├── core/
│   └── localization/       # app_locale.dart — 8 ngôn ngữ
├── models/                 # BgmTrack, TtsVoiceItem, HistoryAudioItem, ...
├── services/
│   ├── tts_service.dart    # TTS engine, synthesizeToFile, chunk merge
│   ├── bgm_service.dart    # Quản lý nhạc nền
│   ├── audio_mixer.dart    # FFmpeg BGM mixing
│   ├── wav_merger.dart     # Ghép WAV chunk thuần Dart
│   ├── audio_player_service.dart
│   ├── history_service.dart
│   └── preset_service.dart
├── views/
│   ├── create_view.dart    # Màn hình tạo âm thanh (màn hình chính)
│   ├── history_view.dart
│   ├── settings_view.dart
│   ├── home_view.dart
│   └── welcome_view.dart
└── widgets/                # Các widget dùng lại

android/
└── app/src/main/kotlin/.../MainActivity.kt  # Export, scan media, storage permission
assets/
└── audio/                  # Nhạc nền mặc định (MP3)
```

---

## 📦 Dependencies chính

| Package | Mục đích |
|---|---|
| `flutter_tts` | TTS engine Android |
| `ffmpeg_kit_flutter_new` | Ghép nhạc nền vào file xuất |
| `audioplayers` | Phát nhạc nền + preview giọng |
| `file_picker` | Chọn file nhạc nền |
| `share_plus` | Chia sẻ file |
| `path_provider` | Đường dẫn file tạm |
| `shared_preferences` | Lưu cài đặt, lịch sử, preset |

---

## 🛠️ Luồng hoạt động

```
Nhập văn bản
    ↓
Chọn giọng đọc + tốc độ + cao độ
    ↓
(Tuỳ chọn) Chọn nhạc nền + âm lượng + chế độ lặp
    ↓
Bấm "Tạo âm thanh & Lưu tệp"
    ↓
TTS chia văn bản thành chunks 550 ký tự
    ↓
Synthesize từng chunk → WAV
    ↓
Ghép WAV chunks → merged.wav (thuần Dart)
    ↓
FFmpeg: merged.wav + bgm.mp3 → output.mp3 / output.wav
    ↓
Export ra /storage/emulated/0/copecute/readio/
    ↓
Lưu vào lịch sử
```

---

## 📄 License

MIT © 2026 [copecute](https://github.com/copecute)
