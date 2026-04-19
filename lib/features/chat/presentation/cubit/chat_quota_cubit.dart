import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quota/data/models/quota_status.dart';
import 'chat_quota_state.dart';

class ChatQuotaCubit extends Cubit<ChatQuotaState> {
  ChatQuotaCubit() : super(const ChatQuotaInitial());

  void setQuota(QuotaStatus quota) {
    emit(ChatQuotaLoaded(quota));
  }

  void useOne() {
    final current = state;
    if (current is! ChatQuotaLoaded) {
      return;
    }

    final quota = current.quota;
    final remaining = (quota.remaining - 1).clamp(0, quota.limit).toInt();
    emit(
      ChatQuotaLoaded(
        quota.copyWith(used: quota.limit - remaining, remaining: remaining),
      ),
    );
  }

  void syncFromRemaining(int remaining, {int? limit}) {
    final current = state;
    final resolvedLimit =
        limit ??
        (current is ChatQuotaLoaded
            ? current.quota.limit
            : QuotaStatus.defaultQuota.limit);
    final safeRemaining = remaining.clamp(0, resolvedLimit).toInt();

    emit(
      ChatQuotaLoaded(
        QuotaStatus(
          used: resolvedLimit - safeRemaining,
          limit: resolvedLimit,
          remaining: safeRemaining,
        ),
      ),
    );
  }

  void markExceeded({Map<String, dynamic>? details}) {
    emit(ChatQuotaLoaded(QuotaStatus.fromRateLimitDetails(details)));
  }

  bool get canChat {
    final current = state;
    if (current is ChatQuotaLoaded) {
      return !current.quota.isExceeded;
    }
    return true;
  }
}
