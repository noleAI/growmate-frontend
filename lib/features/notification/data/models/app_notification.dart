class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.targetRoute,
    required this.targetQuery,
    required this.createdAt,
    required this.isRead,
    this.dedupeKey,
  });

  final String id;
  final String category;
  final String title;
  final String message;
  final String targetRoute;
  final Map<String, String> targetQuery;
  final DateTime createdAt;
  final bool isRead;
  final String? dedupeKey;

  AppNotification copyWith({
    String? id,
    String? category,
    String? title,
    String? message,
    String? targetRoute,
    Map<String, String>? targetQuery,
    DateTime? createdAt,
    bool? isRead,
    String? dedupeKey,
  }) {
    return AppNotification(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      targetRoute: targetRoute ?? this.targetRoute,
      targetQuery: targetQuery ?? this.targetQuery,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      dedupeKey: dedupeKey ?? this.dedupeKey,
    );
  }

  String toLocation() {
    if (targetQuery.isEmpty) {
      return targetRoute;
    }

    final encoded = targetQuery.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    if (encoded.isEmpty) {
      return targetRoute;
    }

    return '$targetRoute?$encoded';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'title': title,
      'message': message,
      'targetRoute': targetRoute,
      'targetQuery': targetQuery,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'isRead': isRead,
      'dedupeKey': dedupeKey,
    };
  }

  static AppNotification fromJson(Map<String, dynamic> json) {
    final targetQueryRaw = json['targetQuery'];
    final targetQuery = <String, String>{};

    if (targetQueryRaw is Map) {
      for (final entry in targetQueryRaw.entries) {
        targetQuery[entry.key.toString()] = entry.value.toString();
      }
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      targetRoute: json['targetRoute']?.toString() ?? '/home',
      targetQuery: targetQuery,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isRead: json['isRead'] == true,
      dedupeKey: json['dedupeKey']?.toString(),
    );
  }
}

class StudyReminderSettings {
  const StudyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  StudyReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return StudyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }

  static StudyReminderSettings fromJson(Map<String, dynamic> json) {
    return StudyReminderSettings(
      enabled: json['enabled'] == true,
      hour: _safeInt(json['hour'], fallback: 20),
      minute: _safeInt(json['minute'], fallback: 30),
    );
  }

  static int _safeInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
