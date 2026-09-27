import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bgm_track.dart';

class BgmService extends ChangeNotifier {
  static const String _storageKey = 'readio_bgm_tracks_v1';
  static const String _enabledKey = 'readio_bgm_enabled_v1';
  static const String _volumeKey = 'readio_bgm_volume_v1';
  static const String _playModeKey = 'readio_bgm_play_mode_v1';
  static const String _currentTrackKey = 'readio_bgm_current_track_v1';

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  double _volume = 0.30; // Default 30% (0.30), maximum 80% (0.80)
  double get volume => _volume;

  BgmPlayMode _playMode = BgmPlayMode.repeatAll;
  BgmPlayMode get playMode => _playMode;

  List<BgmTrack> _tracks = [];
  List<BgmTrack> get tracks => List.unmodifiable(_tracks);

  String? _currentTrackId;
  String? get currentTrackId => _currentTrackId;

  BgmTrack? get currentTrack {
    if (_tracks.isEmpty) return null;
    if (_currentTrackId == null) {
      return _tracks.firstWhere((t) => !t.isSkipped, orElse: () => _tracks.first);
    }
    return _tracks.firstWhere(
      (t) => t.id == _currentTrackId,
      orElse: () => _tracks.firstWhere((t) => !t.isSkipped, orElse: () => _tracks.first),
    );
  }

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _auditioningTrackId;
  String? get auditioningTrackId => _auditioningTrackId;

  int _currentPlaylistIndex = 0;

  static List<BgmTrack> get defaultTracks => [
        const BgmTrack(
          id: 'bgm_beat_1',
          name: 'Beat 1 (Nhẹ nhàng)',
          path: 'assets/audio/Beat 1.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
        const BgmTrack(
          id: 'bgm_illusionary_daytime',
          name: 'Illusionary Daytime (Piano du dương)',
          path: 'assets/audio/IllusionaryDaytime.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
        const BgmTrack(
          id: 'bgm_paris',
          name: 'Paris (Lãng mạn, êm dịu)',
          path: 'assets/audio/Paris.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
        const BgmTrack(
          id: 'bgm_shiverr',
          name: 'Shiverr (Thư giãn, tập trung)',
          path: 'assets/audio/Shiverr.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
        const BgmTrack(
          id: 'bgm_time_back',
          name: 'Time Back (Trầm lắng, sâu sắc)',
          path: 'assets/audio/TimeBack.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
        const BgmTrack(
          id: 'bgm_asphyxia',
          name: 'Asphyxia (Hùng tráng, tiết tấu)',
          path: 'assets/audio/Asphyxia.mp3',
          sourceType: BgmSourceType.asset,
          isBuiltIn: true,
        ),
      ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;
    _volume = (prefs.getDouble(_volumeKey) ?? 0.30).clamp(0.05, 0.80);

    final savedMode = prefs.getString(_playModeKey);
    if (savedMode != null) {
      _playMode = BgmPlayMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => BgmPlayMode.repeatAll,
      );
    }

    _currentTrackId = prefs.getString(_currentTrackKey);

    // Load custom tracks and skipped state for built-in tracks
    final jsonStr = prefs.getString(_storageKey);
    Map<String, bool> skippedMap = {};
    List<BgmTrack> customTracks = [];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in decoded) {
          final track = BgmTrack.fromJson(item as Map<String, dynamic>);
          if (track.isBuiltIn) {
            skippedMap[track.id] = track.isSkipped;
          } else {
            // Verify custom file still exists
            if (File(track.path).existsSync()) {
              customTracks.add(track);
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading saved BGM tracks: $e');
      }
    }

    // Merge default tracks with their saved skipped states
    _tracks = defaultTracks.map((def) {
      if (skippedMap.containsKey(def.id)) {
        return def.copyWith(isSkipped: skippedMap[def.id]!);
      }
      return def;
    }).toList();

    _tracks.addAll(customTracks);

    if (_currentTrackId == null && _tracks.isNotEmpty) {
      _currentTrackId = _tracks.first.id;
    }

    // Setup audio player listener for track completion
    _audioPlayer.onPlayerComplete.listen((_) {
      _handleTrackCompleted();
    });

    notifyListeners();
  }

  Future<void> setEnabled(bool val) async {
    _isEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, val);
    if (!val && _isPlaying) {
      await stopBgm();
    }
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.05, 0.80);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
    if (_isPlaying) {
      await _audioPlayer.setVolume(_volume);
    }
    notifyListeners();
  }

  Future<void> setPlayMode(BgmPlayMode mode) async {
    _playMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playModeKey, mode.name);
    notifyListeners();
  }

  Future<void> selectTrack(String trackId) async {
    _currentTrackId = trackId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentTrackKey, trackId);
    if (_isPlaying) {
      final track = _tracks.firstWhere((t) => t.id == trackId, orElse: () => _tracks.first);
      await _playTrack(track);
    }
    notifyListeners();
  }

  Future<void> toggleSkipTrack(String trackId) async {
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx >= 0) {
      final current = _tracks[idx];
      _tracks[idx] = current.copyWith(isSkipped: !current.isSkipped);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteTrack(String trackId) async {
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx >= 0) {
      final track = _tracks[idx];
      if (track.isBuiltIn) return; // Cannot delete built-in tracks
      try {
        final f = File(track.path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        debugPrint('Error deleting track file: $e');
      }
      _tracks.removeAt(idx);
      if (_currentTrackId == trackId) {
        _currentTrackId = _tracks.isNotEmpty ? _tracks.first.id : null;
      }
      if (_auditioningTrackId == trackId) {
        await stopBgm();
      }
      await _persist();
      notifyListeners();
    }
  }

  Future<BgmTrack?> addTrackFromFile() async {
    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (result.isEmpty || result.first.path == null) {
        return null;
      }
      final picked = result.first;
      final file = File(picked.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final bgmDir = Directory('${appDir.path}/bgm');
      if (!await bgmDir.exists()) {
        await bgmDir.create(recursive: true);
      }
      final cleanOriginalName = picked.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final destFile = File('${bgmDir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await file.copy(destFile.path);

      final newTrack = BgmTrack(
        id: 'bgm_custom_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanOriginalName,
        path: destFile.path,
        sourceType: BgmSourceType.file,
        isBuiltIn: false,
      );
      _tracks.add(newTrack);
      await _persist();
      notifyListeners();
      return newTrack;
    } catch (e) {
      debugPrint('Error adding track from file: $e');
      rethrow;
    }
  }

  Future<BgmTrack> downloadTrackFromUrl({
    required String url,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Tải thất bại (Mã lỗi ${response.statusCode})');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final bgmDir = Directory('${appDir.path}/bgm');
    if (!await bgmDir.exists()) {
      await bgmDir.create(recursive: true);
    }
    final uriPath = Uri.parse(url).path;
    String ext = uriPath.contains('.') ? uriPath.split('.').last : 'mp3';
    if (!['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext.toLowerCase())) {
      ext = 'mp3';
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_download.$ext';
    final destFile = File('${bgmDir.path}/$fileName');
    final sink = destFile.openWrite();

    final totalBytes = response.contentLength;
    int receivedBytes = 0;

    await for (final chunk in response) {
      receivedBytes += chunk.length;
      sink.add(chunk);
      if (totalBytes > 0 && onProgress != null) {
        onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
      }
    }
    await sink.flush();
    await sink.close();

    final newTrack = BgmTrack(
      id: 'bgm_url_${DateTime.now().millisecondsSinceEpoch}',
      name: title.trim().isNotEmpty ? title.trim() : 'Nhạc tải về',
      path: destFile.path,
      sourceType: BgmSourceType.file,
      isBuiltIn: false,
    );
    _tracks.add(newTrack);
    await _persist();
    notifyListeners();
    return newTrack;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tracks.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Playback control
  Future<void> startBgm({String? trackId}) async {
    if (!_isEnabled) return;
    final activeTracks = _tracks.where((t) => !t.isSkipped).toList();
    if (activeTracks.isEmpty) return;

    BgmTrack? target;
    if (trackId != null) {
      target = _tracks.firstWhere((t) => t.id == trackId, orElse: () => activeTracks.first);
    } else if (_currentTrackId != null) {
      target = _tracks.firstWhere(
        (t) => t.id == _currentTrackId && !t.isSkipped,
        orElse: () => activeTracks.first,
      );
    } else {
      target = activeTracks.first;
    }

    _currentPlaylistIndex = activeTracks.indexWhere((t) => t.id == target?.id);
    if (_currentPlaylistIndex < 0) _currentPlaylistIndex = 0;

    await _playTrack(target);
  }

  Future<void> _playTrack(BgmTrack track) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);

      if (track.sourceType == BgmSourceType.asset) {
        // In audioplayers, asset source path is relative to assets/
        final assetRel = track.path.startsWith('assets/')
            ? track.path.substring(7)
            : track.path;
        await _audioPlayer.play(AssetSource(assetRel));
      } else {
        await _audioPlayer.play(DeviceFileSource(track.path));
      }

      _isPlaying = true;
      _currentTrackId = track.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing BGM track: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> toggleAudition(BgmTrack track) async {
    if (_isPlaying && _auditioningTrackId == track.id) {
      await stopBgm();
      _auditioningTrackId = null;
    } else {
      _auditioningTrackId = track.id;
      await _playTrack(track);
    }
    notifyListeners();
  }

  Future<void> pauseBgm() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> resumeBgm() async {
    if (_isEnabled && !_isPlaying) {
      await _audioPlayer.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> stopBgm() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _auditioningTrackId = null;
    notifyListeners();
  }

  void _handleTrackCompleted() {
    final activeTracks = _tracks.where((t) => !t.isSkipped).toList();
    if (activeTracks.isEmpty) {
      stopBgm();
      return;
    }

    switch (_playMode) {
      case BgmPlayMode.repeatOne:
        // Replay same track
        final track = currentTrack ?? activeTracks.first;
        _playTrack(track);
        break;

      case BgmPlayMode.playOneOnce:
        // Play once then stop BGM (TTS continues normally)
        stopBgm();
        break;

      case BgmPlayMode.repeatAll:
        // Next track in playlist, loops indefinitely
        _currentPlaylistIndex = (_currentPlaylistIndex + 1) % activeTracks.length;
        _playTrack(activeTracks[_currentPlaylistIndex]);
        break;

      case BgmPlayMode.playAllOnce:
        // Play next track or stop if reached end of playlist
        if (_currentPlaylistIndex + 1 < activeTracks.length) {
          _currentPlaylistIndex++;
          _playTrack(activeTracks[_currentPlaylistIndex]);
        } else {
          // Reached end of playlist, stop BGM (TTS continues normally)
          stopBgm();
        }
        break;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
