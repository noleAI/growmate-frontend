// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LearningSession _$LearningSessionFromJson(Map<String, dynamic> json) =>
    LearningSession(
      id: json['id'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      status: json['status'] as String,
      totalScore: (json['total_score'] as num?)?.toDouble(),
      questionsAnswered: (json['questions_answered'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LearningSessionToJson(LearningSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'status': instance.status,
      'total_score': instance.totalScore,
      'questions_answered': instance.questionsAnswered,
    };

SessionStartResponse _$SessionStartResponseFromJson(
  Map<String, dynamic> json,
) => SessionStartResponse(
  sessionId: json['session_id'] as String,
  startTime: json['start_time'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$SessionStartResponseToJson(
  SessionStartResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'start_time': instance.startTime,
  'status': instance.status,
};
