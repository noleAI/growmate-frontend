import 'package:equatable/equatable.dart';

import '../../data/models/quota_status.dart';

sealed class QuotaState extends Equatable {
  const QuotaState();

  @override
  List<Object?> get props => [];
}

final class QuotaInitial extends QuotaState {
  const QuotaInitial();
}

final class QuotaLoading extends QuotaState {
  const QuotaLoading();
}

final class QuotaLoaded extends QuotaState {
  const QuotaLoaded(this.quota);

  final QuotaStatus quota;

  @override
  List<Object?> get props => [
    quota.used,
    quota.limit,
    quota.remaining,
    quota.resetAt,
  ];
}

final class QuotaError extends QuotaState {
  const QuotaError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
