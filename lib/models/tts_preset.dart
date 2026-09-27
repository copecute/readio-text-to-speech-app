class TtsPreset {
  final String id;
  final String name;
  final String? voiceKey;
  final String? voiceName;
  final String? locale;
  final double speechRate;
  final double pitch;
  final double volume;
  final bool isBuiltIn;

  const TtsPreset({
    required this.id,
    required this.name,
    this.voiceKey,
    this.voiceName,
    this.locale,
    required this.speechRate,
    required this.pitch,
    this.volume = 1.0,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'voiceKey': voiceKey,
      'voiceName': voiceName,
      'locale': locale,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory TtsPreset.fromJson(Map<String, dynamic> json) {
    return TtsPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      voiceKey: json['voiceKey'] as String?,
      voiceName: json['voiceName'] as String?,
      locale: json['locale'] as String?,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  static List<TtsPreset> get defaultPresets => [
        const TtsPreset(
          id: 'preset_standard',
          name: 'Chuẩn tự nhiên',
          speechRate: 0.50,
          pitch: 1.0,
          volume: 1.0,
          isBuiltIn: true,
        ),
        const TtsPreset(
          id: 'preset_slow_reading',
          name: 'Đọc sách chậm rãi',
          speechRate: 0.42,
          pitch: 0.98,
          volume: 1.0,
          isBuiltIn: true,
        ),
        const TtsPreset(
          id: 'preset_fast_news',
          name: 'Điểm tin nhanh',
          speechRate: 0.56,
          pitch: 1.0,
          volume: 1.0,
          isBuiltIn: true,
        ),
        const TtsPreset(
          id: 'preset_storytelling',
          name: 'Kể chuyện truyền cảm',
          speechRate: 0.45,
          pitch: 0.92,
          volume: 1.0,
          isBuiltIn: true,
        ),
      ];
}
