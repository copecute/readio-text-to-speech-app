# 🎙️ Readio — Text-to-Speech Studio

<p align="center">
  <img src="assets/logo-readio.png" alt="Readio Logo" width="160"/>
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

### 🗣️ Tạo giọng nói (TTS)
- Nhập văn bản tự do, **dán nhanh**, nạp file `.txt` hoặc dùng văn bản mẫu
- Đếm ký tự và ước tính thời lượng trực tiếp ngay trên màn hình
- Lọc và chọn giọng đọc theo ngôn ngữ — hiển thị **cờ quốc gia + tên tiếng người**
- Cấu hình giọng đọc: **giới tính, phong cách, tốc độ, cao độ (pitch)**
- Xem trước ngay (preview 10–30s) trước khi tạo file
- Chia văn bản dài thành chunk 550 ký tự — không bao giờ bị buffer overflow

### 🎵 Nhạc nền (BGM)
- 6 bản nhạc nền có sẵn: Asphyxia, Beat 1, Illlusionary Daytime, Paris, Shiverr, Time Back
- Thêm nhạc từ **file nội bộ** hoặc **tải từ URL** (lưu về máy để không gián đoạn)
- Bật/tắt nhạc nền bằng một nút toggle ngay màn hình chính
- Âm lượng nhạc nền mặc định **30%**, tối đa **80%**
- Chế độ phát: **lặp 1 bài / lặp danh sách / phát hết rồi dừng**
- Bỏ qua bài (hiển thị xám) hoặc xoá bài user thêm

### 📁 Xuất file
- Chọn định dạng **MP3** hoặc **WAV** ngay tại màn hình tạo
- Ghép nhạc nền vào file xuất bằng **FFmpeg** — hỗ trợ mọi định dạng nhạc nền
- Tên file tự sinh từ **30 ký tự đầu** của nội dung văn bản
- Overlay tiến trình toàn màn hình với **progress ring** và **% hoàn thành** rõ ràng
- **Nút Huỷ tạo** — dừng ngay và rollback toàn bộ file tạm
- Lưu tại `/storage/emulated/0/copecute/readio/` (Android)

### 🎚️ Preset
- Lưu cấu hình giọng đọc (tốc độ, cao độ, giọng) thành preset
- Preset mẫu tích hợp sẵn: Bình thường, Sách nói, Podcast
- Áp dụng preset một chạm

### 📚 Lịch sử
- Toàn bộ file đã tạo được lưu vào lịch sử kèm đường dẫn thư mục
- Tìm kiếm theo tên file hoặc nội dung văn bản
- **Phát lại inline** với thanh tiến trình và waveform animation ngay trong danh sách
- Chia sẻ, xoá từ lịch sử
- Hiển thị metadata: giọng đọc, dung lượng, ngày tạo

### ⚙️ Cài đặt
- Chọn **ngôn ngữ giao diện** (8 ngôn ngữ) với giao diện lưới cờ quốc gia
- Chủ đề: **Theo hệ thống / Sáng / Tối**
- Chọn **TTS engine** (hỗ trợ nhiều engine: Google TTS, …) và làm mới danh sách giọng đọc
- Quản lý thư mục lưu âm thanh, sao chép đường dẫn nhanh

### 🌍 Đa ngôn ngữ
Hỗ trợ **8 ngôn ngữ** giao diện:
🇻🇳 Tiếng Việt · 🇺🇸 English · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇨🇳 中文 · 🇫🇷 Français · 🇪🇸 Español · 🇩🇪 Deutsch

### 🎨 UX / UI
- Dark mode mặc định với màu sắc tinh tế (teal accent trên nền xanh đậm)
- Overlay toàn màn hình khi đang tạo file — progress ring animate mượt
- Không cần kết nối mạng (**offline hoàn toàn**)

---

## 📱 Ảnh chụp màn hình

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="Màn hình Tạo giọng nói" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="Tiến trình tạo âm thanh" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="Màn hình Lịch sử" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="Màn hình Cài đặt" width="22%"/>
</p>

<p align="center">
  <em>Tạo giọng nói</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Đang tạo (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Lịch sử lưu</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Cài đặt</em>
</p>

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
