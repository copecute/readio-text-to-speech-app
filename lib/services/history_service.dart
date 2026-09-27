import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_audio_item.dart';

class HistoryService {
  static const String _storageKey = 'readio_audio_history_v1';
  final List<HistoryAudioItem> _items = [];
  List<HistoryAudioItem> get items => List.unmodifiable(_items);

  Future<void> loadHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      _items.clear();
      for (final String jsonStr in rawList) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          _items.add(HistoryAudioItem.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing history item: $e');
        }
      }
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> addItem(HistoryAudioItem item) async {
    _items.removeWhere((existing) => existing.id == item.id);
    _items.insert(0, item);
    await _saveToStorage();
  }

  Future<void> deleteItem(String id, {bool deleteFileFromDisk = true}) async {
    final int index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _items[index];
      if (deleteFileFromDisk) {
        try {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Could not delete audio file from disk: $e');
        }
      }
      _items.removeAt(index);
      await _saveToStorage();
    }
  }

  Future<void> clearAll({bool deleteFilesFromDisk = true}) async {
    if (deleteFilesFromDisk) {
      for (final item in _items) {
        try {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
    }
    _items.clear();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> rawList =
          _items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (e) {
      debugPrint('Error saving history to storage: $e');
    }
  }

  /// Opens the audio file directly using the system's preferred app / app chooser.
  static Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('File does not exist: $filePath');
        return;
      }

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      } else if (Platform.isAndroid) {
        const channel = MethodChannel('com.copecute.readio/storage');
        try {
          await channel.invokeMethod('openFile', {'path': filePath});
        } on MissingPluginException {
          await shareFile(filePath);
        }
      }
    } catch (e) {
      debugPrint('Failed to open file: $e');
    }
  }

  /// Opens the folder containing the audio file in the system File Explorer.
  /// On Windows, it highlights the file in File Explorer.
  /// On Android, it opens the directory directly in the native File Manager.
  static Future<void> openFileFolder(String filePath) async {
    try {
      final file = File(filePath);
      final parentDir = file.parent.path;

      if (Platform.isWindows) {
        if (file.existsSync()) {
          await Process.run('explorer.exe', ['/select,', filePath]);
        } else {
          await Process.run('explorer.exe', [parentDir]);
        }
      } else if (Platform.isMacOS) {
        if (file.existsSync()) {
          await Process.run('open', ['-R', filePath]);
        } else {
          await Process.run('open', [parentDir]);
        }
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [parentDir]);
      } else if (Platform.isAndroid) {
        const channel = MethodChannel('com.copecute.readio/storage');
        try {
          await channel.invokeMethod('openFolder', {'path': parentDir});
        } on MissingPluginException {
          // If openFolder is missing (hot reload without full rebuild), fallback to openFile
          await openFile(filePath);
        }
      }
    } catch (e) {
      debugPrint('Failed to open folder: $e');
    }
  }

  /// Opens the directory directly in the system File Explorer (not a share popup).
  static Future<void> openFolder(String folderPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      } else if (Platform.isAndroid) {
        const channel = MethodChannel('com.copecute.readio/storage');
        try {
          await channel.invokeMethod('openFolder', {'path': folderPath});
        } on MissingPluginException {
          debugPrint('MissingPluginException on openFolder. Rebuild required.');
        }
      }
    } catch (e) {
      debugPrint('Failed to open folder: $e');
    }
  }

  /// Shares the audio file with other apps.
  static Future<void> shareFile(String filePath, {String? text}) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: 'Readio Audio File',
            text: text ?? 'Generated by Readio TTS',
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to share file: $e');
    }
  }
}
