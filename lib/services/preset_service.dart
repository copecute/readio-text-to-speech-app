import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_preset.dart';

class PresetService extends ChangeNotifier {
  static const _storageKey = 'readio_tts_presets';
  static const _activePresetKey = 'readio_active_preset_id';

  /// Legacy built-in IDs — ignored / cleared on load.
  static const _legacyBuiltInIds = {
    'preset_standard',
    'preset_slow_reading',
    'preset_fast_news',
    'preset_storytelling',
  };

  List<TtsPreset> _presets = [];
  List<TtsPreset> get presets => List.unmodifiable(_presets);

  TtsPreset? _activePreset;
  TtsPreset? get activePreset => _activePreset;
  String? get activePresetId => _activePreset?.id;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    List<TtsPreset> loaded = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        loaded = decoded
            .map((item) => TtsPreset.fromJson(item as Map<String, dynamic>))
            .where((p) => !_legacyBuiltInIds.contains(p.id))
            .map((p) {
              // Normalize old excessive speech-rate scale
              if (p.speechRate > 0.8) {
                return p.copyWith(speechRate: 0.50);
              }
              return p;
            })
            .toList();
      } catch (e) {
        debugPrint('Error parsing saved presets: $e');
      }
    }

    _presets = loaded;

    final savedActiveId = prefs.getString(_activePresetKey);
    if (savedActiveId != null &&
        savedActiveId.isNotEmpty &&
        !_legacyBuiltInIds.contains(savedActiveId)) {
      _activePreset = _presets.cast<TtsPreset?>().firstWhere(
            (p) => p?.id == savedActiveId,
            orElse: () => null,
          );
    } else {
      _activePreset = _presets.isNotEmpty ? _presets.first : null;
    }

    // Persist cleaned list (drops any leftover built-ins from old installs)
    await _persist();
    notifyListeners();
  }

  Future<void> setActivePreset(TtsPreset? preset) async {
    _activePreset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (preset != null) {
      await prefs.setString(_activePresetKey, preset.id);
    } else {
      await prefs.remove(_activePresetKey);
    }
  }

  Future<void> setActivePresetById(String id) async {
    final found = _presets.cast<TtsPreset?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    await setActivePreset(found);
  }

  /// Sync the active (or named) user preset with latest live TTS values.
  Future<void> updatePresetSettings({
    required String id,
    String? voiceKey,
    String? voiceName,
    String? locale,
    required double speechRate,
    required double pitch,
    required double volume,
  }) async {
    final idx = _presets.indexWhere((p) => p.id == id);
    if (idx < 0) return;

    final updated = _presets[idx].copyWith(
      voiceKey: voiceKey,
      voiceName: voiceName,
      locale: locale,
      speechRate: speechRate,
      pitch: pitch,
      volume: volume,
    );
    _presets[idx] = updated;
    if (_activePreset?.id == id) {
      _activePreset = updated;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> savePreset(TtsPreset newPreset) async {
    final existingIdx = _presets.indexWhere((p) => p.id == newPreset.id);
    if (existingIdx >= 0) {
      _presets[existingIdx] = newPreset;
    } else {
      _presets.add(newPreset);
    }
    _activePreset = newPreset;
    await _persist();
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    if (!_presets.any((p) => p.id == id)) return;

    _presets.removeWhere((p) => p.id == id);
    if (_activePreset?.id == id) {
      _activePreset = _presets.isNotEmpty ? _presets.first : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_presets.map((p) => p.toJson()).toList()),
    );
    if (_activePreset != null) {
      await prefs.setString(_activePresetKey, _activePreset!.id);
    } else {
      await prefs.remove(_activePresetKey);
    }
  }
}
