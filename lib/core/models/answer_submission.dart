import 'package:json_annotation/json_annotation.dart';

part 'answer_submission.g.dart';

/// Kết quả submit answer từ backend.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AnswerSubmission {
  const AnswerSubmission({
    required this.answerId,
    required this.sessionId,
    required this.questionId,
    required this.answerText,
    this.isCorrect,
    this.score,
    this.maxScore,
    required this.receivedAt,
    this.pipeline,
  });

  final String answerId;
  final String sessionId;
  final String questionId;
  final String answerText;
  final bool? isCorrect;
  final double? score;
  final double? maxScore;
  final String receivedAt;
  final PipelineInfo? pipeline;

  factory AnswerSubmission.fromJson(Map<String, dynamic> json) =>
      _$AnswerSubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$AnswerSubmissionToJson(this);
}

/// Thông tin pipeline xử lý tiếp theo
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PipelineInfo {
  const PipelineInfo({required this.nextStep, this.estimatedSeconds});

  final String nextStep;
  final int? estimatedSeconds;

  factory PipelineInfo.fromJson(Map<String, dynamic> json) =>
      _$PipelineInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PipelineInfoToJson(this);
}
