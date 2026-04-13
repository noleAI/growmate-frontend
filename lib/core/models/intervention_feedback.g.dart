// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterventionFeedback _$InterventionFeedbackFromJson(
  Map<String, dynamic> json,
) => InterventionFeedback(
  sessionId: json['session_id'] as String,
  submissionId: json['submission_id'] as String,
  diagnosisId: json['diagnosis_id'] as String,
  selectedOption: SelectedOption.fromJson(
    json['selected_option'] as Map<String, dynamic>,
  ),
  updatedQValues:
      (json['updated_q_values'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
);

Map<String, dynamic> _$InterventionFeedbackToJson(
  InterventionFeedback instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'submission_id': instance.submissionId,
  'diagnosis_id': instance.diagnosisId,
  'selected_option': instance.selectedOption.toJson(),
  'updated_q_values': instance.updatedQValues,
};

SelectedOption _$SelectedOptionFromJson(Map<String, dynamic> json) =>
    SelectedOption(
      id: json['id'] as String,
      label: json['label'] as String,
      mode: json['mode'] as String,
      remainingRestSeconds: (json['remaining_rest_seconds'] as num).toInt(),
      skipped: json['skipped'] as bool? ?? false,
    );

Map<String, dynamic> _$SelectedOptionToJson(SelectedOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'mode': instance.mode,
      'remaining_rest_seconds': instance.remainingRestSeconds,
      'skipped': instance.skipped,
    };
