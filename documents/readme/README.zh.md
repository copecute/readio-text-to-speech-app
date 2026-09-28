# 🎙️ Readio — 文字转语音工作室

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Readio 标志" width="160"/>
</p>

<p align="center">
  <b>专业文字转语音 · 背景音乐 · 导出 MP3/WAV</b>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart"/>
  <img alt="Android" src="https://img.shields.io/badge/Android-API%2024+-3DDC84?logo=android"/>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue"/>
</p>

<p align="center">
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> ·
  <a href="../../README.md">🇺🇸 English</a> ·
  <a href="README.ja.md">🇯🇵 日本語</a> ·
  <a href="README.ko.md">🇰🇷 한국어</a> ·
  <a href="README.zh.md">🇨🇳 中文</a> ·
  <a href="README.fr.md">🇫🇷 Français</a> ·
  <a href="README.es.md">🇪🇸 Español</a> ·
  <a href="README.de.md">🇩🇪 Deutsch</a>
</p>

---

## ✨ 功能特性

### 🗣️ 文字转语音 (TTS)
- 自由输入文本、**粘贴内容**、加载 `.txt` 文件或使用示例文本
- 实时字符计数及预估播放时长显示
- 按语言筛选并选择语音 — 显示**国旗 + 易读名称**
- 语音配置：**性别、风格、语速、音调（Pitch）**
- 生成文件前可试听预览（10~30秒）
- 长文本自动分割为550字符块 — 彻底避免缓冲区溢出

### 🎵 背景音乐 (BGM)
- 6首内置曲目：Asphyxia、Beat 1、Illusionary Daytime、Paris、Shiverr、Time Back
- 从**本地文件**添加或**从 URL 下载**音乐（本地保存，不间断播放）
- 在主界面通过一个开关按钮开启/关闭背景音乐
- 默认 BGM 音量 **30%**，最大 **80%**
- 播放模式：**单曲循环 / 列表循环 / 顺序播放后停止**
- 跳过曲目（灰色显示）或删除用户添加的曲目

### 📁 导出
- 直接在创建界面选择 **MP3** 或 **WAV** 格式
- 使用 **FFmpeg** 将背景音乐混入导出文件 — 支持任意音频格式
- 文件名自动从文本的**前30个字符**生成
- 全屏进度遮罩层，带**动态进度环**及清晰的**完成百分比**显示
- **取消按钮** — 立即停止并回滚所有临时文件
- 保存至 `/storage/emulated/0/copecute/readio/`（Android）

### 🎚️ 预设
- 将语音配置（语速、音调、声音）保存为预设
- 内置预设：普通、有声书、播客
- 单击即可应用任意预设

### 📚 历史记录
- 所有生成的文件连同文件夹路径一起保存
- 按文件名或文本内容搜索
- 带进度条和波形动画的**内嵌播放**
- 从历史记录中分享或删除
- 元数据：声音、文件大小、创建日期

### ⚙️ 设置
- 通过国旗网格界面选择 **UI 语言**（8种语言）
- 主题：**跟随系统 / 浅色 / 深色**
- 选择 **TTS 引擎**（如 Google TTS）并刷新语音列表
- 管理音频输出文件夹，快速复制路径

### 🌍 多语言支持
支持 **8种 UI 语言**：
🇻🇳 越南语 · 🇺🇸 英语 · 🇯🇵 日语 · 🇰🇷 韩语 · 🇨🇳 中文 · 🇫🇷 法语 · 🇪🇸 西班牙语 · 🇩🇪 德语

### 🎨 UX / UI
- 深海军蓝配精致青色强调色的深色模式
- 生成期间的全屏遮罩 — 流畅的动态进度环
- **完全离线** — 无需网络连接

---

## 📱 截图

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="创建界面" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="生成中 (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="历史记录界面" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="设置界面" width="22%"/>
</p>

<p align="center">
  <em>创建语音</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>生成中 (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>历史记录</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>设置</em>
</p>

---

## 🚀 安装 & 构建

### 环境要求
- Flutter SDK ≥ 3.13
- Android SDK API 24+（Android 7.0 Nougat）
- Java 17+

### 克隆 & 运行
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### 构建 APK
```bash
# 调试版
flutter build apk --debug

# 发布版
flutter build apk --release
```

输出 APK 路径：`build/app/outputs/flutter-apk/`

---

## 📦 主要依赖

| 包名 | 用途 |
|---|---|
| `flutter_tts` | Android TTS 引擎 |
| `ffmpeg_kit_flutter_new` | 将 BGM 混入导出文件 |
| `audioplayers` | BGM 播放 + 语音预览 |
| `file_picker` | 选择本地音乐文件 |
| `share_plus` | 文件分享 |
| `path_provider` | 临时文件路径 |
| `shared_preferences` | 持久化设置、历史记录、预设 |

---

## 📄 许可证

MIT © 2026 [copecute](https://github.com/copecute)
