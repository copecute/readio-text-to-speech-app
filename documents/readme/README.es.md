# 🎙️ Readio — Estudio de texto a voz

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Logo de Readio" width="160"/>
</p>

<p align="center">
  <b>Texto a voz profesional · Música de fondo · Exportar MP3/WAV</b>
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

## ✨ Características

### 🗣️ Texto a voz (TTS)
- Escribe libremente, **pega texto**, carga un archivo `.txt` o usa un texto de ejemplo
- Conteo de caracteres en tiempo real y visualización de duración estimada
- Filtra y elige voces por idioma — muestra **bandera del país + nombre legible**
- Configura la voz: **género, estilo, velocidad y tono (pitch)**
- Vista previa de audio (10–30s) antes de generar el archivo final
- Los textos largos se dividen en fragmentos de 550 caracteres — sin desbordamiento de búfer

### 🎵 Música de fondo (BGM)
- 6 pistas integradas: Asphyxia, Beat 1, Illusionary Daytime, Paris, Shiverr, Time Back
- Añadir música desde un **archivo local** o **descargar desde URL** (guardado localmente)
- Activar/desactivar BGM con un solo interruptor en la pantalla principal
- Volumen BGM predeterminado **30%**, máximo **80%**
- Modos de reproducción: **repetir una / repetir todo / reproducir y detener**
- Omitir pistas (en gris) o eliminar pistas añadidas por el usuario

### 📁 Exportar
- Elige el formato **MP3** o **WAV** directamente en la pantalla de creación
- Mezcla la música de fondo en el archivo exportado usando **FFmpeg** — compatible con cualquier formato de audio
- Nombre de archivo generado automáticamente a partir de los **primeros 30 caracteres** del texto
- Superposición de pantalla completa con **anillo de progreso animado** y **% completado** visible
- **Botón Cancelar** — detiene de inmediato y revierte todos los archivos temporales
- Guardado en `/storage/emulated/0/copecute/readio/` (Android)

### 🎚️ Preajustes
- Guarda configuraciones de voz (velocidad, tono, voz) como preajustes
- Preajustes integrados: Normal, Audiolibro, Podcast
- Aplica cualquier preajuste con un solo toque

### 📚 Historial
- Todos los archivos generados se guardan con su ruta de carpeta
- Busca por nombre de archivo o contenido de texto
- **Reproducción en línea** con barra de progreso y animación de forma de onda
- Comparte o elimina desde el historial
- Metadatos: voz, tamaño de archivo, fecha de creación

### ⚙️ Ajustes
- Elige el **idioma de la interfaz** (8 idiomas) con una cuadrícula de banderas
- Tema: **Sistema / Claro / Oscuro**
- Selecciona el **motor TTS** (p. ej., Google TTS) y actualiza la lista de voces
- Gestiona la carpeta de salida de audio, copia la ruta rápidamente

### 🌍 Localización
Compatible con **8 idiomas de interfaz**:
🇻🇳 Vietnamita · 🇺🇸 Inglés · 🇯🇵 Japonés · 🇰🇷 Coreano · 🇨🇳 Chino · 🇫🇷 Francés · 🇪🇸 Español · 🇩🇪 Alemán

### 🎨 UX / UI
- Modo oscuro predeterminado con acento turquesa refinado sobre azul marino profundo
- Superposición de pantalla completa durante la generación — anillo de progreso animado y fluido
- **Totalmente sin conexión** — no requiere conexión a internet

---

## 📱 Capturas de pantalla

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="Pantalla de creación" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="Generando (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="Pantalla de historial" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="Pantalla de ajustes" width="22%"/>
</p>

<p align="center">
  <em>Crear voz</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Generando (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Historial</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Ajustes</em>
</p>

---

## 🚀 Instalación & Compilación

### Requisitos
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### Clonar & ejecutar
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### Compilar APK
```bash
# Depuración
flutter build apk --debug

# Lanzamiento
flutter build apk --release
```

APK de salida: `build/app/outputs/flutter-apk/`

---

## 📦 Dependencias principales

| Paquete | Propósito |
|---|---|
| `flutter_tts` | Motor TTS de Android |
| `ffmpeg_kit_flutter_new` | Mezclar BGM en el archivo exportado |
| `audioplayers` | Reproducción de BGM + vista previa de voz |
| `file_picker` | Seleccionar archivos de música locales |
| `share_plus` | Compartir archivos |
| `path_provider` | Rutas de archivos temporales |
| `shared_preferences` | Persistencia de ajustes, historial y preajustes |

---

## 📄 Licencia

MIT © 2026 [copecute](https://github.com/copecute)
