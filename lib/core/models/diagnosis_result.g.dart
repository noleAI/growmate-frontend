// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnosis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagnosisResult _$DiagnosisResultFromJson(
  Map<String, dynamic> json,
) => DiagnosisResult(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  answerId: json['answer_id'] as String,
  title: json['title'] as String,
  gapAnalysis: json['gap_analysis'] as String,
  diagnosisReason: json['diagnosis_reason'] as String,
  strengths:
      (json['strengths'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  needsReview:
      (json['needs_review'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  mode: json['mode'] as String,
  requiresHITL: json['requires_h_i_t_l'] as bool? ?? false,
  recoveryMode: json['recovery_mode'] as bool? ?? false,
  riskLevel: json['risk_level'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  uncertaintyScore: (json['uncertainty_score'] as num?)?.toDouble(),
  summary: json['summary'] as String?,
  interventionPlan:
      (json['intervention_plan'] as List<dynamic>?)
          ?.map((e) => InterventionPlanItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InterventionPlanItem>[],
  hitl: json['hitl'] == null
      ? null
      : HITLTicket.fromJson(json['hitl'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DiagnosisResultToJson(DiagnosisResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'answer_id': instance.answerId,
      'title': instance.title,
      'gap_analysis': instance.gapAnalysis,
      'diagnosis_reason': instance.diagnosisReason,
      'strengths': instance.strengths,
      'needs_review': instance.needsReview,
      'mode': instance.mode,
      'requires_h_i_t_l': instance.requiresHITL,
      'recovery_mode': instance.recoveryMode,
      'risk_level': instance.riskLevel,
      'confidence': instance.confidence,
      'uncertainty_score': instance.uncertaintyScore,
      'summary': instance.summary,
      'intervention_plan': instance.interventionPlan
          .map((e) => e.toJson())
          .toList(),
      'hitl': instance.hitl?.toJson(),
    };

InterventionPlanItem _$InterventionPlanItemFromJson(
  Map<String, dynamic> json,
) => InterventionPlanItem(
  id: json['id'] as String,
  title: json['title'] as String,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  type: json['type'] as String,
);

Map<String, dynamic> _$InterventionPlanItemToJson(
  InterventionPlanItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'duration_minutes': instance.durationMinutes,
  'type': instance.type,
};

HITLTicket _$HITLTicketFromJson(Map<String, dynamic> json) => HITLTicket(
  ticketId: json['ticket_id'] as String,
  status: json['status'] as String,
  reason: json['reason'] as String,
  priority: json['priority'] as String,
);

Map<String, dynamic> _$HITLTicketToJson(HITLTicket instance) =>
    <String, dynamic>{
      'ticket_id': instance.ticketId,
      'status': instance.status,
      'reason': instance.reason,
      'priority': instance.priority,
    };
