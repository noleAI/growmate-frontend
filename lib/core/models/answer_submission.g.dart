// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnswerSubmission _$AnswerSubmissionFromJson(Map<String, dynamic> json) =>
    AnswerSubmission(
      answerId: json['answer_id'] as String,
      sessionId: json['session_id'] as String,
      questionId: json['question_id'] as String,
      answerText: json['answer_text'] as String,
      isCorrect: json['is_correct'] as bool?,
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      receivedAt: json['received_at'] as String,
      pipeline: json['pipeline'] == null
          ? null
          : PipelineInfo.fromJson(json['pipeline'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnswerSubmissionToJson(AnswerSubmission instance) =>
    <String, dynamic>{
      'answer_id': instance.answerId,
      'session_id': instance.sessionId,
      'question_id': instance.questionId,
      'answer_text': instance.answerText,
      'is_correct': instance.isCorrect,
      'score': instance.score,
      'max_score': instance.maxScore,
      'received_at': instance.receivedAt,
      'pipeline': instance.pipeline?.toJson(),
    };

PipelineInfo _$PipelineInfoFromJson(Map<String, dynamic> json) => PipelineInfo(
  nextStep: json['next_step'] as String,
  estimatedSeconds: (json['estimated_seconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$PipelineInfoToJson(PipelineInfo instance) =>
    <String, dynamic>{
      'next_step': instance.nextStep,
      'estimated_seconds': instance.estimatedSeconds,
    };
