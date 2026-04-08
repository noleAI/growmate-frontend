import 'package:equatable/equatable.dart';

sealed class DiagnosisEvent extends Equatable {
  const DiagnosisEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class DiagnosisRequested extends DiagnosisEvent {
  const DiagnosisRequested(this.submissionId);

  final String submissionId;

  @override
  List<Object?> get props => <Object?>[submissionId];
}

final class HITLConfirmed extends DiagnosisEvent {
  const HITLConfirmed({required this.approved, this.reviewerNote});

  final bool approved;
  final String? reviewerNote;

  @override
  List<Object?> get props => <Object?>[approved, reviewerNote];
}
