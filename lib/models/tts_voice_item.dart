/// Represents a TTS voice returned by the device TTS engine.
class TtsVoiceItem {
  final String name;
  final String locale;
  final String? engine;
  final String? gender;

  const TtsVoiceItem({
    required this.name,
    required this.locale,
    this.engine,
    this.gender,
  });

  factory TtsVoiceItem.fromMap(Map<dynamic, dynamic> map) {
    return TtsVoiceItem(
      name: map['name']?.toString() ?? 'Default Voice',
      locale: map['locale']?.toString() ?? 'en-US',
      engine: map['engine']?.toString(),
      gender: map['gender']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locale': locale,
      if (engine != null) 'engine': engine,
      if (gender != null) 'gender': gender,
    };
  }

  /// Unique key for favorites and persistence
  String get uniqueKey => '$locale:$name';

  /// Whether this voice is an offline/local model
  bool get isLocal => name.toLowerCase().contains('local');

  /// Whether this voice requires network connectivity
  bool get isNetwork => name.toLowerCase().contains('network');

  /// Extracts the country code (e.g., "US", "VN", "GB")
  String get countryCode {
    final parts = locale.split(RegExp(r'[-_]'));
    if (parts.length > 1) {
      return parts.last.toUpperCase();
    }
    return '';
  }

  /// Extracts the language code (e.g., "en", "vi", "fr")
  String get languageCode {
    final parts = locale.split(RegExp(r'[-_]'));
    return parts.first.toLowerCase();
  }

  /// Returns flag emoji corresponding to the country code
  String get flagEmoji {
    final code = countryCode;
    if (code.length != 2) return '🌐';
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  /// Returns a clean display name.
  /// If the engine provides a real human-readable name (like "Microsoft An", "Microsoft Mai"), uses it.
  /// Otherwise, falls back to "Giọng nói 1", "Giọng nói 2", "Giọng nói 3"... as requested.
  String getFriendlyName({int? fallbackIndex}) {
    final lowerName = name.toLowerCase();

    // 1. If name already has a human-readable format without technical prefixes/dashes
    if (!lowerName.contains('-x-') &&
        !lowerName.contains('_') &&
        lowerName.split(' ').length > 1 &&
        !lowerName.startsWith('com.')) {
      return name;
    }

    // 2. Fallback cleanly to: Giọng nói 1, Giọng nói 2, ...
    final idx = fallbackIndex != null ? ' $fallbackIndex' : '';
    final g = genderLabel;
    if (g != null) {
      return 'Giọng nói$idx ($g)';
    }
    return 'Giọng nói$idx';
  }

  /// Returns gender label ONLY if explicitly provided by the OS engine
  String? get genderLabel {
    final g = (gender ?? '').toLowerCase().trim();
    if (g == 'female') return 'Nữ';
    if (g == 'male') return 'Nam';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsVoiceItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          locale == other.locale;

  @override
  int get hashCode => name.hashCode ^ locale.hashCode;
}
