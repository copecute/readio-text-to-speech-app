# 🎙️ Readio — テキスト読み上げスタジオ

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Readio ロゴ" width="160"/>
</p>

<p align="center">
  <b>プロフェッショナルな音声合成 · BGM · MP3/WAV エクスポート</b>
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

## ✨ 機能

### 🗣️ テキスト読み上げ (TTS)
- テキストを自由に入力、**貼り付け**、`.txt` ファイル読み込み、またはサンプルテキストを使用
- リアルタイム文字数カウントと推定再生時間表示
- 言語別に音声をフィルタリング・選択 — **国旗 + わかりやすい名前**で表示
- 音声設定: **性別、スタイル、速度、ピッチ**
- ファイル生成前にプレビュー再生 (10〜30秒)
- 長いテキストを550文字のチャンクに分割 — バッファオーバーフローなし

### 🎵 BGM（バックグラウンドミュージック）
- 6つの内蔵トラック: Asphyxia、Beat 1、Illusionary Daytime、Paris、Shiverr、Time Back
- **ローカルファイル**または **URL からダウンロード**して音楽を追加
- メイン画面のトグルスイッチで BGM をオン/オフ
- デフォルト BGM 音量 **30%**、最大 **80%**
- 再生モード: **1曲リピート / 全曲リピート / 通し再生**
- トラックをスキップ（グレーアウト）またはユーザー追加トラックを削除

### 📁 エクスポート
- 作成画面で **MP3** または **WAV** 形式を選択
- **FFmpeg** を使って BGM をエクスポートファイルにミックス
- テキストの**最初の30文字**からファイル名を自動生成
- **アニメーション進行リング**と**完了 %** 表示付きフルスクリーンオーバーレイ
- **キャンセルボタン** — 即時停止し、一時ファイルをロールバック
- `/storage/emulated/0/copecute/readio/` に保存 (Android)

### 🎚️ プリセット
- 音声設定（速度、ピッチ、音声）をプリセットとして保存
- 内蔵プリセット: 標準、オーディオブック、ポッドキャスト
- ワンタップでプリセットを適用

### 📚 履歴
- 生成したすべてのファイルをフォルダパス付きで保存
- ファイル名またはテキスト内容で検索
- 進行バーと波形アニメーション付き**インライン再生**
- 履歴から共有・削除
- メタデータ: 音声、ファイルサイズ、作成日

### ⚙️ 設定
- フラググリッドで **UI 言語**（8言語）を選択
- テーマ: **システム / ライト / ダーク**
- **TTS エンジン**（Google TTS など）を選択し音声リストを更新
- 音声出力フォルダの管理、パスのコピー

### 🌍 多言語対応
**8つの UI 言語**に対応:
🇻🇳 ベトナム語 · 🇺🇸 英語 · 🇯🇵 日本語 · 🇰🇷 韓国語 · 🇨🇳 中国語 · 🇫🇷 フランス語 · 🇪🇸 スペイン語 · 🇩🇪 ドイツ語

### 🎨 UX / UI
- ディープネイビーにティールアクセントの洗練されたダークモード
- 生成中のフルスクリーンオーバーレイ — スムーズなアニメーション進行リング
- **完全オフライン** — インターネット接続不要

---

## 📱 スクリーンショット

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="作成画面" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="生成中 (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="履歴画面" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="設定画面" width="22%"/>
</p>

<p align="center">
  <em>音声作成</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>生成中 (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>履歴</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>設定</em>
</p>

---

## 🚀 セットアップ & ビルド

### 必要環境
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### クローン & 実行
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### APK ビルド
```bash
# デバッグ
flutter build apk --debug

# リリース
flutter build apk --release
```

出力 APK: `build/app/outputs/flutter-apk/`

---

## 📦 主な依存関係

| パッケージ | 用途 |
|---|---|
| `flutter_tts` | Android TTS エンジン |
| `ffmpeg_kit_flutter_new` | エクスポートファイルへの BGM ミックス |
| `audioplayers` | BGM 再生 + 音声プレビュー |
| `file_picker` | ローカル音楽ファイルの選択 |
| `share_plus` | ファイル共有 |
| `path_provider` | 一時ファイルパス |
| `shared_preferences` | 設定・履歴・プリセットの保存 |

---

## 📄 ライセンス

MIT © 2026 [copecute](https://github.com/copecute)
