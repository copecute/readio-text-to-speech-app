# 🎙️ Readio — Studio de synthèse vocale

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Logo Readio" width="160"/>
</p>

<p align="center">
  <b>Synthèse vocale professionnelle · Musique de fond · Export MP3/WAV</b>
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

## ✨ Fonctionnalités

### 🗣️ Synthèse vocale (TTS)
- Saisie libre, **coller du texte**, charger un fichier `.txt` ou utiliser un texte d'exemple
- Comptage de caractères en temps réel et affichage de la durée estimée
- Filtrer et choisir les voix par langue — affiche **le drapeau national + un nom lisible**
- Configurer la voix : **genre, style, vitesse et hauteur (pitch)**
- Aperçu audio (10–30s) avant de générer le fichier final
- Les textes longs sont découpés en blocs de 550 caractères — aucun débordement de tampon

### 🎵 Musique de fond (BGM)
- 6 pistes intégrées : Asphyxia, Beat 1, Illusionary Daytime, Paris, Shiverr, Time Back
- Ajouter de la musique depuis un **fichier local** ou **télécharger via URL** (sauvegardé localement)
- Activer/désactiver la BGM avec un simple interrupteur sur l'écran principal
- Volume BGM par défaut **30 %**, maximum **80 %**
- Modes de lecture : **boucle une piste / boucle tout / lecture puis arrêt**
- Ignorer des pistes (grisées) ou supprimer les pistes ajoutées par l'utilisateur

### 📁 Export
- Choisir le format **MP3** ou **WAV** directement sur l'écran de création
- Mélanger la musique de fond dans l'export avec **FFmpeg** — compatible tous formats audio
- Nom de fichier généré automatiquement depuis les **30 premiers caractères** du texte
- Overlay plein écran avec **anneau de progression animé** et **% d'avancement** visible
- **Bouton Annuler** — arrêt immédiat et restauration de tous les fichiers temporaires
- Enregistré dans `/storage/emulated/0/copecute/readio/` (Android)

### 🎚️ Préréglages
- Sauvegarder les configurations vocales (vitesse, pitch, voix) comme préréglages
- Préréglages intégrés : Normal, Livre audio, Podcast
- Appliquer un préréglage en un seul tap

### 📚 Historique
- Tous les fichiers générés sont sauvegardés avec leur chemin de dossier
- Recherche par nom de fichier ou contenu textuel
- **Lecture inline** avec barre de progression et animation de forme d'onde
- Partager ou supprimer depuis l'historique
- Métadonnées : voix, taille du fichier, date de création

### ⚙️ Paramètres
- Choisir la **langue de l'interface** (8 langues) via une grille de drapeaux
- Thème : **Système / Clair / Sombre**
- Sélectionner le **moteur TTS** (ex. Google TTS) et actualiser la liste de voix
- Gérer le dossier de sortie audio, copier le chemin rapidement

### 🌍 Localisation
Prend en charge **8 langues d'interface** :
🇻🇳 Vietnamien · 🇺🇸 Anglais · 🇯🇵 Japonais · 🇰🇷 Coréen · 🇨🇳 Chinois · 🇫🇷 Français · 🇪🇸 Espagnol · 🇩🇪 Allemand

### 🎨 UX / UI
- Mode sombre par défaut avec un accent sarcelle raffiné sur bleu marine profond
- Overlay plein écran pendant la génération — anneau de progression animé et fluide
- **Entièrement hors ligne** — aucune connexion internet requise

---

## 📱 Captures d'écran

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="Écran de création" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="Génération (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="Écran Historique" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="Écran Paramètres" width="22%"/>
</p>

<p align="center">
  <em>Créer une voix</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Génération (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Historique</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Paramètres</em>
</p>

---

## 🚀 Installation & Build

### Prérequis
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### Cloner & lancer
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### Construire l'APK
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

APK de sortie : `build/app/outputs/flutter-apk/`

---

## 📦 Dépendances principales

| Package | Rôle |
|---|---|
| `flutter_tts` | Moteur TTS Android |
| `ffmpeg_kit_flutter_new` | Mixage BGM dans le fichier exporté |
| `audioplayers` | Lecture BGM + aperçu vocal |
| `file_picker` | Sélection de fichiers musicaux locaux |
| `share_plus` | Partage de fichiers |
| `path_provider` | Chemins de fichiers temporaires |
| `shared_preferences` | Persistance des paramètres, historique, préréglages |

---

## 📄 Licence

MIT © 2026 [copecute](https://github.com/copecute)
