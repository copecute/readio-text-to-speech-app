enum BgmSourceType {
  asset,
  file,
}

enum BgmPlayMode {
  repeatOne,   // Lặp 1 bài
  repeatAll,   // Lặp danh sách
  playOneOnce, // Phát hết bài (dừng)
  playAllOnce, // Phát hết danh sách (dừng)
}

class BgmTrack {
  final String id;
  final String name;
  final String path;
  final BgmSourceType sourceType;
  final bool isBuiltIn;
  final bool isSkipped;

  const BgmTrack({
    required this.id,
    required this.name,
    required this.path,
    required this.sourceType,
    this.isBuiltIn = false,
    this.isSkipped = false,
  });

  BgmTrack copyWith({
    String? id,
    String? name,
    String? path,
    BgmSourceType? sourceType,
    bool? isBuiltIn,
    bool? isSkipped,
  }) {
    return BgmTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sourceType: sourceType ?? this.sourceType,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'sourceType': sourceType.name,
      'isBuiltIn': isBuiltIn,
      'isSkipped': isSkipped,
    };
  }

  factory BgmTrack.fromJson(Map<String, dynamic> json) {
    return BgmTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      sourceType: BgmSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => BgmSourceType.file,
      ),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }
}
