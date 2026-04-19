import 'package:equatable/equatable.dart';

import '../../../quota/data/models/quota_status.dart';

sealed class ChatQuotaState extends Equatable {
  const ChatQuotaState();

  @override
  List<Object?> get props => [];
}

final class ChatQuotaInitial extends ChatQuotaState {
  const ChatQuotaInitial();
}

final class ChatQuotaLoaded extends ChatQuotaState {
  const ChatQuotaLoaded(this.quota);

  final QuotaStatus quota;

  @override
  List<Object?> get props => [
    quota.used,
    quota.limit,
    quota.remaining,
    quota.resetAt,
  ];
}
