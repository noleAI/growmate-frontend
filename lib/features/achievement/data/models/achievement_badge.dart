class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final DateTime unlockedAt;

  AchievementBadge copyWith({
    String? id,
    String? title,
    String? description,
    String? iconKey,
    DateTime? unlockedAt,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'iconKey': iconKey,
      'unlockedAt': unlockedAt.toUtc().toIso8601String(),
    };
  }

  static AchievementBadge fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'badge',
      unlockedAt:
          DateTime.tryParse(json['unlockedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}
