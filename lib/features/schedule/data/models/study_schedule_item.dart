class StudyScheduleItem {
  const StudyScheduleItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueAt,
    required this.type,
    required this.priority,
    required this.completed,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime dueAt;
  final String type;
  final int priority;
  final bool completed;

  StudyScheduleItem copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueAt,
    String? type,
    int? priority,
    bool? completed,
  }) {
    return StudyScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueAt: dueAt ?? this.dueAt,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subject': subject,
      'dueAt': dueAt.toUtc().toIso8601String(),
      'type': type,
      'priority': priority,
      'completed': completed,
    };
  }

  static StudyScheduleItem fromJson(Map<String, dynamic> json) {
    return StudyScheduleItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'Tổng hợp',
      dueAt:
          DateTime.tryParse(json['dueAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      type: json['type']?.toString() ?? 'deadline',
      priority: _safeInt(json['priority'], fallback: 2),
      completed: json['completed'] == true,
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
