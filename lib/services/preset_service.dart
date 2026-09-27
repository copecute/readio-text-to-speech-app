import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_preset.dart';

class PresetService extends ChangeNotifier {
  static const _storageKey = 'readio_tts_presets';
  static const _activePresetKey = 'readio_active_preset_id';

  List<TtsPreset> _presets = [];
  List<TtsPreset> get presets => List.unmodifiable(_presets);

  TtsPreset? _activePreset;
  TtsPreset? get activePreset => _activePreset;
  String? get activePresetId => _activePreset?.id;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    List<TtsPreset> customPresets = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        customPresets = decoded
            .map((item) => TtsPreset.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing saved presets: $e');
      }
    }

    // Ensure built-in presets are always up to date with the calibrated speeds
    customPresets = customPresets
        .where((p) => !p.isBuiltIn && !TtsPreset.defaultPresets.any((d) => d.id == p.id))
        .map((p) {
          // If custom preset had excessive speed from old scale (>0.8), normalize to standard
          if (p.speechRate > 0.8) {
            return TtsPreset(
              id: p.id,
              name: p.name,
              voiceKey: p.voiceKey,
              voiceName: p.voiceName,
              locale: p.locale,
              speechRate: 0.50,
              pitch: p.pitch,
              volume: p.volume,
              isBuiltIn: false,
            );
          }
          return p;
        })
        .toList();

    _presets = [...TtsPreset.defaultPresets, ...customPresets];

    final savedActiveId = prefs.getString(_activePresetKey) ?? 'preset_standard';
    _activePreset = _presets.firstWhere(
      (p) => p.id == savedActiveId,
      orElse: () => _presets.first,
    );
    notifyListeners();
  }

  Future<void> setActivePreset(TtsPreset? preset) async {
    _activePreset = preset;
    notifyListeners();
    if (preset != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activePresetKey, preset.id);
    }
  }

  Future<void> setActivePresetById(String id) async {
    final found = _presets.firstWhere(
      (p) => p.id == id,
      orElse: () => _presets.first,
    );
    await setActivePreset(found);
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
    final preset = _presets.firstWhere((p) => p.id == id, orElse: () => throw Exception('Not found'));
    if (preset.isBuiltIn) return; // Cannot delete built-in presets

    _presets.removeWhere((p) => p.id == id);
    if (_activePreset?.id == id) {
      _activePreset = _presets.first;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final customOnly = _presets.where((p) => !p.isBuiltIn).map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(customOnly));
    if (_activePreset != null) {
      await prefs.setString(_activePresetKey, _activePreset!.id);
    }
  }
}
