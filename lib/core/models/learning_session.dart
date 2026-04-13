import 'package:json_annotation/json_annotation.dart';

part 'learning_session.g.dart';

/// Thông tin learning session.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LearningSession {
  const LearningSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.totalScore,
    this.questionsAnswered,
  });

  final String id;
  final String startTime;
  final String? endTime;
  final String status;
  final double? totalScore;
  final int? questionsAnswered;

  factory LearningSession.fromJson(Map<String, dynamic> json) =>
      _$LearningSessionFromJson(json);

  Map<String, dynamic> toJson() => _$LearningSessionToJson(this);

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}

/// Response khi start session
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SessionStartResponse {
  const SessionStartResponse({
    required this.sessionId,
    required this.startTime,
    required this.status,
  });

  final String sessionId;
  final String startTime;
  final String status;

  factory SessionStartResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionStartResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStartResponseToJson(this);
}
