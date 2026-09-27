import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_voice_item.dart';
import '../models/bgm_track.dart';
import 'wav_merger.dart';
import 'audio_mixer.dart';

/// Simple cancel token for generation tasks.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void reset() => _cancelled = false;
}

/// Thrown when user cancels the generation mid-way.
class GenerationCancelledException implements Exception {
  @override
  String toString() => 'GenerationCancelledException';
}

enum TtsPlaybackState { stopped, playing, paused }

class TtsService with ChangeNotifier {
  static const String _favStorageKey = 'readio_favorite_voice_keys_v1';
  final FlutterTts _tts = FlutterTts();

  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  TtsPlaybackState get playbackState => _playbackState;
  bool get isSpeaking => _playbackState == TtsPlaybackState.playing;
  bool get isPreviewing => isSpeaking && _previewingVoiceKey != null;

  List<TtsVoiceItem> _allVoices = [];
  List<TtsVoiceItem> get allVoices => _allVoices;

  List<String> _languages = [];
  List<String> get languages => _languages;

  List<String> _engines = [];
  List<String> get engines => _engines;

  TtsVoiceItem? _currentVoice;
  TtsVoiceItem? get currentVoice => _currentVoice;

  String? _currentEngine;
  String? get currentEngine => _currentEngine;

  double _speechRate = 0.5; // 0.0 to 1.0 (0.5 is normal for flutter_tts)
  double get speechRate => _speechRate;

  double _pitch = 1.0; // 0.5 to 2.0 (1.0 is normal)
  double get pitch => _pitch;

  double _volume = 1.0; // 0.0 to 1.0
  double get volume => _volume;

  // Favorite voices
  final Set<String> _favoriteVoiceKeys = {};
  Set<String> get favoriteVoiceKeys => Set.unmodifiable(_favoriteVoiceKeys);

  final StreamController<Set<String>> _favoritesController =
      StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get favoritesStream => _favoritesController.stream;

  // Active voice preview tracking
  String? _previewingVoiceKey;
  String? get previewingVoiceKey => _previewingVoiceKey;

  // Stream controllers for state updates
  final StreamController<TtsPlaybackState> _stateController =
      StreamController<TtsPlaybackState>.broadcast();
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  final StreamController<Map<String, dynamic>> _progressController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;

  Future<void> initialize() async {
    await _loadFavorites();

    _tts.setStartHandler(() {
      _playbackState = TtsPlaybackState.playing;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _playbackState = TtsPlaybackState.stopped;
      _previewingVoiceKey = null;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _playbackState = TtsPlaybackState.stopped;
      _previewingVoiceKey = null;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      _playbackState = TtsPlaybackState.paused;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setContinueHandler(() {
      _playbackState = TtsPlaybackState.playing;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setErrorHandler((dynamic message) {
      debugPrint('TTS Error: $message');
      _playbackState = TtsPlaybackState.stopped;
      _previewingVoiceKey = null;
      _stateController.add(_playbackState);
      notifyListeners();
    });

    _tts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      _progressController.add({
        'text': text,
        'start': startOffset,
        'end': endOffset,
        'word': word,
      });
    });

    // Query engines (Android)
    try {
      final dynamic rawEngines = await _tts.getEngines;
      if (rawEngines is List) {
        _engines = rawEngines.map((e) => e.toString()).toList();
        final dynamic defaultEngine = await _tts.getDefaultEngine;
        _currentEngine = defaultEngine?.toString();
      }
    } catch (e) {
      debugPrint('Engines not supported on this platform: $e');
    }

    await loadVoices();
    await applySettings();
  }

  Future<void> loadVoices() async {
    try {
      final dynamic rawVoices = await _tts.getVoices;
      if (rawVoices is List) {
        _allVoices = rawVoices
            .whereType<Map>()
            .map((v) => TtsVoiceItem.fromMap(v))
            .toList();
      }

      final dynamic rawLanguages = await _tts.getLanguages;
      if (rawLanguages is List) {
        _languages = rawLanguages.map((e) => e.toString()).toSet().toList()
          ..sort();
      }

      // If voices list is empty but languages are available, construct fallback voices
      if (_allVoices.isEmpty && _languages.isNotEmpty) {
        _allVoices = _languages.map((l) {
          return TtsVoiceItem(
            name: 'Voice ($l)',
            locale: l,
          );
        }).toList();
      }

      // Default selection (prefer Vietnamese or English or first available)
      if (_allVoices.isNotEmpty) {
        final viVoice = _allVoices.cast<TtsVoiceItem?>().firstWhere(
              (v) => v?.locale.toLowerCase().startsWith('vi') == true,
              orElse: () => null,
            );
        final enVoice = _allVoices.cast<TtsVoiceItem?>().firstWhere(
              (v) => v?.locale.toLowerCase().startsWith('en') == true,
              orElse: () => null,
            );
        _currentVoice = viVoice ?? enVoice ?? _allVoices.first;
        await setVoice(_currentVoice!);
      }
    } catch (e) {
      debugPrint('Error loading TTS voices: $e');
    }
  }

  Future<void> applySettings() async {
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      if (_currentVoice != null) {
        await _tts.setLanguage(_currentVoice!.locale);
        await _tts.setVoice({
          'name': _currentVoice!.name,
          'locale': _currentVoice!.locale,
        });
      }
    } catch (e) {
      debugPrint('Error applying TTS settings: $e');
    }
  }

  Future<void> setVoice(TtsVoiceItem voice) async {
    _currentVoice = voice;
    try {
      await _tts.setLanguage(voice.locale);
      await _tts.setVoice({
        'name': voice.name,
        'locale': voice.locale,
      });
    } catch (e) {
      debugPrint('Failed to set voice: $e');
    }
    notifyListeners();
  }

  Future<void> setEngine(String engine) async {
    _currentEngine = engine;
    try {
      await _tts.setEngine(engine);
      await loadVoices();
    } catch (e) {
      debugPrint('Failed to set engine: $e');
    }
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await applySettings();
    _playbackState = TtsPlaybackState.playing;
    _stateController.add(_playbackState);
    await _tts.speak(text);
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
      _playbackState = TtsPlaybackState.paused;
      _stateController.add(_playbackState);
    } catch (e) {
      debugPrint('Pause not supported on this platform: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Stop error: $e');
    } finally {
      _playbackState = TtsPlaybackState.stopped;
      _stateController.add(_playbackState);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favStorageKey) ?? [];
      _favoriteVoiceKeys.clear();
      _favoriteVoiceKeys.addAll(list);
    } catch (e) {
      debugPrint('Error loading favorite voices: $e');
    }
  }

  Future<void> toggleFavorite(TtsVoiceItem voice) async {
    final key = voice.uniqueKey;
    if (_favoriteVoiceKeys.contains(key)) {
      _favoriteVoiceKeys.remove(key);
    } else {
      _favoriteVoiceKeys.add(key);
    }
    _favoritesController.add(Set.unmodifiable(_favoriteVoiceKeys));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favStorageKey, _favoriteVoiceKeys.toList());
    } catch (e) {
      debugPrint('Error saving favorite voices: $e');
    }
  }

  bool isFavorite(TtsVoiceItem voice) {
    return _favoriteVoiceKeys.contains(voice.uniqueKey);
  }

  /// Plays a quick audition/preview of the specified voice with a localized sentence.
  Future<void> previewVoice(TtsVoiceItem voice, {String? customText}) async {
    if (isSpeaking) {
      final wasSame = _previewingVoiceKey == voice.uniqueKey;
      await stop();
      if (wasSame) {
        _previewingVoiceKey = null;
        return;
      }
    }

    _previewingVoiceKey = voice.uniqueKey;
    try {
      await applySettings();
      await _tts.setLanguage(voice.locale);
      await _tts.setVoice({
        'name': voice.name,
        'locale': voice.locale,
      });
      final sample = customText ?? getSampleTextForLocale(voice.locale);
      _playbackState = TtsPlaybackState.playing;
      _stateController.add(_playbackState);
      await _tts.speak(sample);
    } catch (e) {
      debugPrint('Preview error: $e');
      _previewingVoiceKey = null;
      _playbackState = TtsPlaybackState.stopped;
      _stateController.add(_playbackState);
    }
  }

  Future<void> stopPreview() async {
    _previewingVoiceKey = null;
    await stop();
    notifyListeners();
  }

  Future<void> updateProgressNotification({
    required String title,
    required int progress,
    bool isFinished = false,
  }) async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.copecute.readio/storage');
        await channel.invokeMethod('showProgressNotification', {
          'title': title,
          'progress': progress,
          'isFinished': isFinished,
        });
      } catch (e) {
        debugPrint('Error updating progress notification: $e');
      }
    }
  }

  Future<void> dismissProgressNotification() async {
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.copecute.readio/storage');
        await channel.invokeMethod('dismissProgressNotification');
      } catch (e) {
        debugPrint('Error dismissing progress notification: $e');
      }
    }
  }

  static String getSampleTextForLocale(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('vi')) {
      return 'Xin chào! Đây là bản nghe thử giọng đọc của ứng dữ dụng Readio.';
    } else if (lower.startsWith('en')) {
      return 'Hello! This is a preview of this voice in Readio.';
    } else if (lower.startsWith('ja')) {
      return 'こんにちは！これはReadioの音声プレビューです。';
    } else if (lower.startsWith('ko')) {
      return '안녕하세요! Readio의 음성 미리듣기입니다.';
    } else if (lower.startsWith('zh')) {
      return '你好！这是Readio的语音试听。';
    } else if (lower.startsWith('fr')) {
      return 'Bonjour! Ceci est un aperçu de la voix dans Readio.';
    } else if (lower.startsWith('es')) {
      return '¡Hola! Esta es una vista previa de la voz en Readio.';
    } else if (lower.startsWith('de')) {
      return 'Hallo! Dies ist eine Vorschau dieser Stimme in Readio.';
    }
    return 'Hello, this is a sample preview of this voice.';
  }

  /// Resolves the target storage directory:
  /// Android target: STRICTLY /storage/emulated/0/copecute/readio (bộ nhớ trong)
  /// Windows target: %USERPROFILE%/copecute/readio
  static Future<Directory> getAudioStorageDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/copecute/readio');
      try {
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      } catch (e) {
        debugPrint('Directory create notice /storage/emulated/0/copecute/readio: $e');
      }
      return dir;
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final winDir = Directory('$userProfile${Platform.pathSeparator}copecute${Platform.pathSeparator}readio');
      if (!winDir.existsSync()) {
        winDir.createSync(recursive: true);
      }
      return winDir;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${docsDir.path}${Platform.pathSeparator}copecute${Platform.pathSeparator}readio');
    if (!fallbackDir.existsSync()) {
      fallbackDir.createSync(recursive: true);
    }
    return fallbackDir;
  }

  /// Splits text into natural sentence or paragraph chunks, avoiding TTS buffer limits.
  static List<String> splitTextIntoChunks(String text, {int maxChunkLength = 550}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];
    if (trimmed.length <= maxChunkLength) return [trimmed];

    final List<String> chunks = [];
    final paragraphs = trimmed.split(RegExp(r'\r?\n+'));

    String currentChunk = '';

    for (final para in paragraphs) {
      final p = para.trim();
      if (p.isEmpty) continue;

      if ((currentChunk.length + p.length + 1) <= maxChunkLength) {
        currentChunk = currentChunk.isEmpty ? p : '$currentChunk\n$p';
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
          currentChunk = '';
        }

        if (p.length > maxChunkLength) {
          final sentences = p.split(RegExp(r'(?<=[.!?…;:])\s+'));
          for (final sentence in sentences) {
            final s = sentence.trim();
            if (s.isEmpty) continue;

            if ((currentChunk.length + s.length + 1) <= maxChunkLength) {
              currentChunk = currentChunk.isEmpty ? s : '$currentChunk $s';
            } else {
              if (currentChunk.isNotEmpty) {
                chunks.add(currentChunk);
                currentChunk = '';
              }
              if (s.length > maxChunkLength) {
                final words = s.split(' ');
                for (final w in words) {
                  if ((currentChunk.length + w.length + 1) <= maxChunkLength) {
                    currentChunk = currentChunk.isEmpty ? w : '$currentChunk $w';
                  } else {
                    if (currentChunk.isNotEmpty) {
                      chunks.add(currentChunk);
                      currentChunk = '';
                    }
                    currentChunk = w;
                  }
                }
              } else {
                currentChunk = s;
              }
            }
          }
        } else {
          currentChunk = p;
        }
      }
    }

    if (currentChunk.trim().isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  /// Synthesizes text to an audio file (.mp3) saved at:
  /// bộ nhớ trong/copecute/readio/*.mp3 (Android) or %USERPROFILE%/copecute/readio/*.mp3 (Windows)
  /// Automatically splits long text into chunks, synthesizes each segment,
  /// and seamlessly merges them together to prevent timeouts and -8 buffer overflow errors.
  Future<String> synthesizeToFile(
    String text, {
    String? customFileName,
    String? targetTitle,
    BgmTrack? bgmTrack,
    double? bgmVolume,
    BgmPlayMode? bgmPlayMode,
    void Function(double progress, String status)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await applySettings();
    await _tts.awaitSynthCompletion(false);

    // Determine target .mp3 file name
    String baseName = customFileName?.trim() ?? '';
    if (baseName.isEmpty) {
      if (targetTitle != null && targetTitle.trim().isNotEmpty) {
        baseName = targetTitle
            .trim()
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');
        if (!baseName.toLowerCase().endsWith('.mp3')) {
          baseName = '$baseName.mp3';
        }
      } else {
        baseName = 'readio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      }
    } else {
      if (!baseName.toLowerCase().endsWith('.mp3')) {
        baseName = '$baseName.mp3';
      }
    }

    final chunks = splitTextIntoChunks(text, maxChunkLength: 550);
    if (chunks.isEmpty) {
      throw Exception('Văn bản trống, không thể tạo âm thanh.');
    }

    final Directory tempDir = await getTemporaryDirectory();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final List<File> chunkFiles = [];
    File? mergedTempFileRef;

    Future<void> rollback() async {
      for (final f in chunkFiles) {
        try { f.deleteSync(); } catch (_) {}
      }
      try { mergedTempFileRef?.deleteSync(); } catch (_) {}
    }

    onProgress?.call(0.15, '');

    for (int i = 0; i < chunks.length; i++) {
      // Check cancel before each chunk
      if (cancelToken?.isCancelled == true) {
        await rollback();
        throw GenerationCancelledException();
      }

      final chunkText = chunks[i];
      final chunkPath =
          '${tempDir.path}${Platform.pathSeparator}chunk_${timestamp}_$i.wav';
      final chunkFile = File(chunkPath);

      final double progressRatio = 0.15 + ((i + 1) / chunks.length) * 0.65;
      onProgress?.call(progressRatio, '');

      try {
        await _tts.synthesizeToFile(chunkText, chunkPath, true).timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('Chunk $i synth dispatch notice: $e');
      }

      // Wait until chunk file exists and has completed writing
      int elapsedMs = 0;
      int lastSize = -1;
      int stableCount = 0;
      while (elapsedMs < 12000) {
        if (cancelToken?.isCancelled == true) {
          await rollback();
          throw GenerationCancelledException();
        }
        await Future.delayed(const Duration(milliseconds: 150));
        elapsedMs += 150;
        if (chunkFile.existsSync() && chunkFile.lengthSync() > 44) {
          final currentSize = chunkFile.lengthSync();
          if (currentSize == lastSize) {
            stableCount++;
            if (stableCount >= 2) break;
          } else {
            stableCount = 0;
            lastSize = currentSize;
          }
        }
      }

      if (chunkFile.existsSync() && chunkFile.lengthSync() > 44) {
        chunkFiles.add(chunkFile);
        debugPrint('Chunk $i finished: ${chunkFile.lengthSync()} bytes');
      } else {
        debugPrint('Chunk $i timed out or was empty');
      }
    }

    if (chunkFiles.isEmpty) {
      throw Exception('Không thể tạo tệp âm thanh từ hệ thống (kết xuất 0 bytes).');
    }

    onProgress?.call(0.85, '');

    // Merge all chunk WAV files
    final String mergedTempPath =
        '${tempDir.path}${Platform.pathSeparator}merged_$timestamp.wav';
    final File mergedTempFile = File(mergedTempPath);
    mergedTempFileRef = mergedTempFile;
    await WavMerger.mergeWavFiles(chunkFiles, mergedTempFile);

    // Delete chunk files
    for (final f in chunkFiles) {
      try { f.deleteSync(); } catch (_) {}
    }

    // Check cancel after merge
    if (cancelToken?.isCancelled == true) {
      try { mergedTempFile.deleteSync(); } catch (_) {}
      throw GenerationCancelledException();
    }

    File fileToExport = mergedTempFile;

    // Mix Background Music (BGM) if selected
    if (bgmTrack != null) {
      onProgress?.call(0.90, '');
      final String mixedTempPath =
          '${tempDir.path}${Platform.pathSeparator}mixed_$timestamp.wav';
      final File mixedTempFile = File(mixedTempPath);

      fileToExport = await AudioMixer.mixBgmIntoSpeech(
        speechFile: mergedTempFile,
        bgmTrack: bgmTrack,
        bgmVolume: bgmVolume ?? 0.3,
        playMode: bgmPlayMode ?? BgmPlayMode.repeatAll,
        outputFile: mixedTempFile,
      );
    }

    onProgress?.call(0.95, '');

    // Export file to destination (/storage/emulated/0/copecute/readio on Android)
    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.copecute.readio/storage');
        final dynamic res = await channel.invokeMethod('exportAudioFile', {
          'sourcePath': fileToExport.path,
          'fileName': baseName,
        });
        if (res is Map && res['path'] != null) {
          final String finalPath = res['path'].toString();
          debugPrint('Native export audio succeeded: $finalPath');
          onProgress?.call(1.0, 'Hoàn thành!');
          return finalPath;
        }
      } on PlatformException catch (pe) {
        if (pe.code == 'PERMISSION_DENIED') {
          throw Exception(pe.message ?? 'Cần cấp quyền quản lý bộ nhớ để lưu tệp.');
        }
        debugPrint('Native export PlatformException: ${pe.message}, trying fallback...');
      } catch (e) {
        debugPrint('Native export failed: $e, trying fallback...');
      }
    }

    // Fallback for Windows or if native export channel fallback needed
    final Directory targetDir = await getAudioStorageDirectory();
    if (!targetDir.existsSync()) {
      try {
        targetDir.createSync(recursive: true);
      } catch (e) {
        debugPrint('Failed to create targetDir: $e');
      }
    }

    final String targetFullPath = '${targetDir.path}${Platform.pathSeparator}$baseName';
    final File targetFile = File(targetFullPath);

    final bytes = await fileToExport.readAsBytes();
    await targetFile.writeAsBytes(bytes, flush: true);
    try {
      if (fileToExport.existsSync()) {
        fileToExport.deleteSync();
      }
      if (mergedTempFile.existsSync()) {
        mergedTempFile.deleteSync();
      }
    } catch (_) {}

    if (!targetFile.existsSync() || targetFile.lengthSync() == 0) {
      throw Exception('Không thể ghi tệp vào $targetFullPath (vui lòng kiểm tra quyền lưu trữ)');
    }

    if (Platform.isAndroid) {
      try {
        const channel = MethodChannel('com.copecute.readio/storage');
        await channel.invokeMethod('scanFile', {'path': targetFullPath});
      } catch (e) {
        debugPrint('Error invoking scanFile: $e');
      }
    }

    onProgress?.call(1.0, 'Hoàn thành!');
    debugPrint('Created audio successfully: $targetFullPath (${targetFile.lengthSync()} bytes)');
    return targetFullPath;
  }

  /// Returns a map of voice.uniqueKey -> friendly display name.
  /// Sequential numbering fallback (Giọng nói 1, 2, 3...) per locale.
  static Map<String, String> getVoiceDisplayNames(List<TtsVoiceItem> voices) {
    final Map<String, String> result = {};
    final Map<String, List<TtsVoiceItem>> grouped = {};
    for (final v in voices) {
      grouped.putIfAbsent(v.locale, () => []).add(v);
    }

    for (final entry in grouped.entries) {
      final list = entry.value;
      for (int i = 0; i < list.length; i++) {
        final voice = list[i];
        result[voice.uniqueKey] = voice.getFriendlyName(fallbackIndex: i + 1);
      }
    }
    return result;
  }

  @override
  void dispose() {
    _favoritesController.close();
    _stateController.close();
    _progressController.close();
    _tts.stop();
    super.dispose();
  }

  /// Helper to convert locale code into friendly Country Name with Flag
  static String countryNameFromLocale(String locale) {
    final parts = locale.split(RegExp(r'[-_]'));
    final code = parts.length > 1 ? parts.last.toUpperCase() : parts.first.toUpperCase();
    const map = {
      'VN': 'Việt Nam',
      'US': 'Hoa Kỳ',
      'GB': 'Vương quốc Anh',
      'AU': 'Úc',
      'CA': 'Canada',
      'JP': 'Nhật Bản',
      'KR': 'Hàn Quốc',
      'CN': 'Trung Quốc',
      'TW': 'Đài Loan',
      'FR': 'Pháp',
      'DE': 'Đức',
      'ES': 'Tây Ban Nha',
      'IT': 'Ý',
      'RU': 'Nga',
      'IN': 'Ấn Độ',
      'BR': 'Brazil',
      'TH': 'Thái Lan',
      'ID': 'Indonesia',
      'SG': 'Singapore',
      'MX': 'Mexico',
      'PH': 'Philippines',
      'MY': 'Malaysia',
      'NL': 'Hà Lan',
      'PL': 'Ba Lan',
      'TR': 'Thổ Nhĩ Kỳ',
      'SA': 'Ả Rập Xê Út',
    };
    return map[code] ?? locale;
  }

  /// Get flag emoji for a locale
  static String countryFlagFromLocale(String locale) {
    final parts = locale.split(RegExp(r'[-_]'));
    final code = parts.length > 1 ? parts.last.toUpperCase() : parts.first.toUpperCase();
    const flagMap = {
      'VN': '🇻🇳',
      'US': '🇺🇸',
      'GB': '🇬🇧',
      'AU': '🇦🇺',
      'CA': '🇨🇦',
      'JP': '🇯🇵',
      'KR': '🇰🇷',
      'CN': '🇨🇳',
      'TW': '🇹🇼',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
      'ES': '🇪🇸',
      'IT': '🇮🇹',
      'RU': '🇷🇺',
      'IN': '🇮🇳',
      'BR': '🇧🇷',
      'TH': '🇹🇭',
      'ID': '🇮🇩',
      'SG': '🇸🇬',
      'MX': '🇲🇽',
      'PH': '🇵🇭',
      'MY': '🇲🇾',
      'NL': '🇳🇱',
      'PL': '🇵🇱',
      'TR': '🇹🇷',
      'SA': '🇸🇦',
    };
    if (flagMap.containsKey(code)) return flagMap[code]!;
    if (code.length == 2) {
      final first = code.codeUnitAt(0);
      final second = code.codeUnitAt(1);
      if (first >= 65 && first <= 90 && second >= 65 && second <= 90) {
        return String.fromCharCodes([0x1F1E6 + (first - 65), 0x1F1E6 + (second - 65)]);
      }
    }
    return '🌐';
  }

  /// Returns flag emoji + Country name, e.g. "🇻🇳 Việt Nam (vi-VN)"
  static String countryDisplayWithFlag(String locale) {
    final flag = countryFlagFromLocale(locale);
    final name = countryNameFromLocale(locale);
    return '$flag $name ($locale)';
  }
}
