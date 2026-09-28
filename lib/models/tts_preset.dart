class TtsPreset {
  final String id;
  final String name;
  final String? voiceKey;
  final String? voiceName;
  final String? locale;
  final double speechRate;
  final double pitch;
  final double volume;

  const TtsPreset({
    required this.id,
    required this.name,
    this.voiceKey,
    this.voiceName,
    this.locale,
    required this.speechRate,
    required this.pitch,
    this.volume = 1.0,
  });

  TtsPreset copyWith({
    String? id,
    String? name,
    String? voiceKey,
    String? voiceName,
    String? locale,
    double? speechRate,
    double? pitch,
    double? volume,
    bool clearVoice = false,
  }) {
    return TtsPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      voiceKey: clearVoice ? null : (voiceKey ?? this.voiceKey),
      voiceName: clearVoice ? null : (voiceName ?? this.voiceName),
      locale: clearVoice ? null : (locale ?? this.locale),
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }

  /// True when current live TTS params still match this preset (within tolerance).
  bool matchesSettings({
    required double speechRate,
    required double pitch,
    required double volume,
    String? voiceKey,
  }) {
    final rateOk = (this.speechRate - speechRate).abs() < 0.02;
    final pitchOk = (this.pitch - pitch).abs() < 0.05;
    final volumeOk = (this.volume - volume).abs() < 0.05;
    final voiceOk = this.voiceKey == null ||
        this.voiceKey!.isEmpty ||
        this.voiceKey == voiceKey;
    return rateOk && pitchOk && volumeOk && voiceOk;
  }

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
    };
  }

  factory TtsPreset.fromJson(Map<String, dynamic> json) {
    return TtsPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      voiceKey: json['voiceKey'] as String?,
      voiceName: json['voiceName'] as String?,
      locale: json['locale'] as String?,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
