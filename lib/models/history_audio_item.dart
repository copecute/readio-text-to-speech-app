import 'dart:io';

/// Represents an audio file generated and saved in history.
class HistoryAudioItem {
  final String id;
  final String title;
  final String text;
  final String filePath;
  final DateTime createdAt;
  final int? durationMs;
  final int fileSizeBytes;
  final String voiceName;
  final String locale;
  final double pitch;
  final double rate;

  const HistoryAudioItem({
    required this.id,
    required this.title,
    required this.text,
    required this.filePath,
    required this.createdAt,
    this.durationMs,
    this.fileSizeBytes = 0,
    required this.voiceName,
    required this.locale,
    this.pitch = 1.0,
    this.rate = 0.5,
  });

  bool get fileExists => File(filePath).existsSync();

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'durationMs': durationMs,
      'fileSizeBytes': fileSizeBytes,
      'voiceName': voiceName,
      'locale': locale,
      'pitch': pitch,
      'rate': rate,
    };
  }

  factory HistoryAudioItem.fromJson(Map<String, dynamic> json) {
    return HistoryAudioItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Audio.wav',
      text: json['text'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationMs: json['durationMs'] as int?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      voiceName: json['voiceName'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
