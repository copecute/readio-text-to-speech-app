import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/history_audio_item.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  HistoryAudioItem? _currentItem;
  HistoryAudioItem? get currentItem => _currentItem;

  String? _currentlyPlayingPath;
  String? get currentlyPlayingPath => _currentlyPlayingPath;

  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  final StreamController<HistoryAudioItem?> _itemController =
      StreamController<HistoryAudioItem?>.broadcast();
  Stream<HistoryAudioItem?> get onItemChanged => _itemController.stream;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  AudioPlayerService() {
    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _syncMediaNotification();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
    });

    _player.onPlayerComplete.listen((_) {
      _playerState = PlayerState.completed;
      _position = Duration.zero;
      _dismissMediaNotification();
    });
  }

  void _syncMediaNotification() {
    if (_currentItem == null) return;
    if (_playerState == PlayerState.playing) {
      _showMediaNotification(
        title: _currentItem!.title,
        subtitle: 'Readio • ${_currentItem!.voiceName}',
        isPlaying: true,
      );
    } else if (_playerState == PlayerState.paused) {
      _showMediaNotification(
        title: _currentItem!.title,
        subtitle: 'Tạm dừng • ${_currentItem!.voiceName}',
        isPlaying: false,
      );
    } else {
      _dismissMediaNotification();
    }
  }

  Future<void> _showMediaNotification({
    required String title,
    required String subtitle,
    required bool isPlaying,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      const channel = MethodChannel('com.copecute.readio/storage');
      await channel.invokeMethod('showMediaNotification', {
        'title': title,
        'subtitle': subtitle,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      debugPrint('Error showing media notification: $e');
    }
  }

  Future<void> _dismissMediaNotification() async {
    if (!Platform.isAndroid) return;
    try {
      const channel = MethodChannel('com.copecute.readio/storage');
      await channel.invokeMethod('dismissMediaNotification');
    } catch (e) {
      debugPrint('Error dismissing media notification: $e');
    }
  }

  Future<void> playItem(HistoryAudioItem item) async {
    _currentItem = item;
    _itemController.add(_currentItem);
    await playFile(item.filePath);
  }

  Future<void> playFile(String path) async {
    try {
      if (_currentlyPlayingPath != path) {
        await _player.stop();
        _currentlyPlayingPath = path;
        await _player.play(DeviceFileSource(path));
      } else {
        if (_playerState == PlayerState.paused) {
          await _player.resume();
        } else {
          await _player.play(DeviceFileSource(path));
        }
      }
    } catch (e) {
      debugPrint('Error playing audio file: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _currentlyPlayingPath = null;
      _position = Duration.zero;
      _dismissMediaNotification();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  void clearCurrentItem() {
    _currentItem = null;
    _itemController.add(null);
    _dismissMediaNotification();
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  void dispose() {
    _dismissMediaNotification();
    _itemController.close();
    _player.dispose();
  }
}
