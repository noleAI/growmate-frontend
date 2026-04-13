import 'package:json_annotation/json_annotation.dart';

part 'diagnosis_result.g.dart';

/// Kết quả chẩn đoán từ backend sau khi user submit answer.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DiagnosisResult {
  const DiagnosisResult({
    required this.id,
    required this.sessionId,
    required this.answerId,
    required this.title,
    required this.gapAnalysis,
    required this.diagnosisReason,
    this.strengths = const <String>[],
    this.needsReview = const <String>[],
    required this.mode,
    this.requiresHITL = false,
    this.recoveryMode = false,
    required this.riskLevel,
    required this.confidence,
    this.uncertaintyScore,
    this.summary,
    this.interventionPlan = const <InterventionPlanItem>[],
    this.hitl,
  });

  final String id;
  final String sessionId;
  final String answerId;
  final String title;
  final String gapAnalysis;
  final String diagnosisReason;
  final List<String> strengths;
  final List<String> needsReview;
  final String mode;
  final bool requiresHITL;
  final bool recoveryMode;
  final String riskLevel;
  final double confidence;
  final double? uncertaintyScore;
  final String? summary;
  final List<InterventionPlanItem> interventionPlan;
  final HITLTicket? hitl;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) =>
      _$DiagnosisResultFromJson(json);

  Map<String, dynamic> toJson() => _$DiagnosisResultToJson(this);

  bool get isHitlPending => mode == 'hitl_pending';
  bool get isRecoveryMode => mode == 'recovery';
  bool get isNormal => mode == 'normal';
}

/// Một mục trong kế hoạch can thiệp
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class InterventionPlanItem {
  const InterventionPlanItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.type,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String type;

  factory InterventionPlanItem.fromJson(Map<String, dynamic> json) =>
      _$InterventionPlanItemFromJson(json);

  Map<String, dynamic> toJson() => _$InterventionPlanItemToJson(this);
}

/// Ticket Human-in-the-Loop
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class HITLTicket {
  const HITLTicket({
    required this.ticketId,
    required this.status,
    required this.reason,
    required this.priority,
  });

  final String ticketId;
  final String status;
  final String reason;
  final String priority;

  factory HITLTicket.fromJson(Map<String, dynamic> json) =>
      _$HITLTicketFromJson(json);

  Map<String, dynamic> toJson() => _$HITLTicketToJson(this);

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
