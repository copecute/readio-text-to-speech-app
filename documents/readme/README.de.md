# 🎙️ Readio — Text-to-Speech Studio

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Readio Logo" width="160"/>
</p>

<p align="center">
  <b>Professionelle Sprachsynthese · Hintergrundmusik · MP3/WAV-Export</b>
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

## ✨ Funktionen

### 🗣️ Text-to-Speech (TTS)
- Text frei eingeben, **einfügen**, eine `.txt`-Datei laden oder einen Beispieltext verwenden
- Echtzeit-Zeichenzähler und Anzeige der geschätzten Wiedergabedauer
- Stimmen nach Sprache filtern und auswählen — zeigt **Landesflagge + lesbaren Namen**
- Stimme konfigurieren: **Geschlecht, Stil, Geschwindigkeit und Tonhöhe (Pitch)**
- Audiovorschau (10–30 Sek.) vor der Dateigenerierung
- Lange Texte werden in 550-Zeichen-Blöcke aufgeteilt — kein Pufferüberlauf

### 🎵 Hintergrundmusik (BGM)
- 6 integrierte Titel: Asphyxia, Beat 1, Illusionary Daytime, Paris, Shiverr, Time Back
- Musik aus einer **lokalen Datei** hinzufügen oder **per URL herunterladen** (lokal gespeichert)
- BGM mit einem einzigen Schalter auf dem Hauptbildschirm ein-/ausschalten
- Standard-BGM-Lautstärke **30 %**, maximal **80 %**
- Wiedergabemodi: **Einen Titel wiederholen / Alle wiederholen / Durchspielen und stoppen**
- Titel überspringen (ausgegraut) oder vom Nutzer hinzugefügte Titel löschen

### 📁 Export
- **MP3** oder **WAV** direkt auf dem Erstellungsbildschirm wählen
- Hintergrundmusik mit **FFmpeg** in die Exportdatei mischen — alle Audioformate unterstützt
- Dateiname automatisch aus den **ersten 30 Zeichen** des Textes generiert
- Vollbild-Overlay mit **animiertem Fortschrittsring** und klar sichtbarem **% Fortschritt**
- **Abbrechen-Schaltfläche** — stoppt sofort und stellt alle temporären Dateien wieder her
- Gespeichert unter `/storage/emulated/0/copecute/readio/` (Android)

### 🎚️ Voreinstellungen
- Stimmkonfigurationen (Geschwindigkeit, Tonhöhe, Stimme) als Voreinstellungen speichern
- Integrierte Voreinstellungen: Normal, Hörbuch, Podcast
- Jede Voreinstellung mit einem einzigen Tippen anwenden

### 📚 Verlauf
- Alle generierten Dateien mit ihrem Ordnerpfad gespeichert
- Suche nach Dateiname oder Textinhalt
- **Inline-Wiedergabe** mit Fortschrittsbalken und Wellenformanimation
- Aus dem Verlauf teilen oder löschen
- Metadaten: Stimme, Dateigröße, Erstellungsdatum

### ⚙️ Einstellungen
- **UI-Sprache** (8 Sprachen) über ein Flaggen-Raster auswählen
- Design: **System / Hell / Dunkel**
- **TTS-Engine** auswählen (z. B. Google TTS) und Stimmliste aktualisieren
- Ausgabeordner verwalten, Pfad schnell kopieren

### 🌍 Lokalisierung
Unterstützt **8 UI-Sprachen**:
🇻🇳 Vietnamesisch · 🇺🇸 Englisch · 🇯🇵 Japanisch · 🇰🇷 Koreanisch · 🇨🇳 Chinesisch · 🇫🇷 Französisch · 🇪🇸 Spanisch · 🇩🇪 Deutsch

### 🎨 UX / UI
- Standardmäßiger Dunkelmodus mit raffiniertem Teal-Akzent auf tiefem Marineblau
- Vollbild-Overlay während der Generierung — flüssiger animierter Fortschrittsring
- **Vollständig offline** — keine Internetverbindung erforderlich

---

## 📱 Screenshots

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="Erstellungsbildschirm" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="Generierung (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="Verlaufsbildschirm" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="Einstellungsbildschirm" width="22%"/>
</p>

<p align="center">
  <em>Stimme erstellen</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Generierung (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Verlauf</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Einstellungen</em>
</p>

---

## 🚀 Installation & Build

### Voraussetzungen
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### Klonen & ausführen
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### APK erstellen
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

Ausgabe-APK: `build/app/outputs/flutter-apk/`

---

## 📦 Wichtige Abhängigkeiten

| Paket | Zweck |
|---|---|
| `flutter_tts` | Android TTS-Engine |
| `ffmpeg_kit_flutter_new` | BGM in Exportdatei mischen |
| `audioplayers` | BGM-Wiedergabe + Stimmenvorschau |
| `file_picker` | Lokale Musikdateien auswählen |
| `share_plus` | Dateien teilen |
| `path_provider` | Temporäre Dateipfade |
| `shared_preferences` | Einstellungen, Verlauf und Voreinstellungen speichern |

---

## 📄 Lizenz

MIT © 2026 [copecute](https://github.com/copecute)
