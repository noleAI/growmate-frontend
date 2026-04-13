import 'package:json_annotation/json_annotation.dart';

part 'intervention_feedback.g.dart';

/// Phản hồi can thiệp từ user.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class InterventionFeedback {
  const InterventionFeedback({
    required this.sessionId,
    required this.submissionId,
    required this.diagnosisId,
    required this.selectedOption,
    this.updatedQValues = const <String, double>{},
  });

  final String sessionId;
  final String submissionId;
  final String diagnosisId;
  final SelectedOption selectedOption;
  final Map<String, double> updatedQValues;

  factory InterventionFeedback.fromJson(Map<String, dynamic> json) =>
      _$InterventionFeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$InterventionFeedbackToJson(this);
}

/// Option mà user đã chọn
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SelectedOption {
  const SelectedOption({
    required this.id,
    required this.label,
    required this.mode,
    required this.remainingRestSeconds,
    this.skipped = false,
  });

  final String id;
  final String label;
  final String mode;
  final int remainingRestSeconds;
  final bool skipped;

  factory SelectedOption.fromJson(Map<String, dynamic> json) =>
      _$SelectedOptionFromJson(json);

  Map<String, dynamic> toJson() => _$SelectedOptionToJson(this);
}
