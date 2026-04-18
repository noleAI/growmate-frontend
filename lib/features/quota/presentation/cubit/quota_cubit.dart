import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/quota_status.dart';
import '../../data/repositories/quota_repository.dart';
import 'quota_state.dart';

/// Cubit managing the user's daily LLM chat quota.
class QuotaCubit extends Cubit<QuotaState> {
  QuotaCubit({required QuotaRepository repository})
    : _repository = repository,
      super(const QuotaInitial());

  final QuotaRepository _repository;

  /// Load the current quota from backend. Safe to call multiple times.
  Future<void> loadQuota({bool silent = false}) async {
    final shouldShowLoading = !silent || state is! QuotaLoaded;
    if (shouldShowLoading) {
      emit(const QuotaLoading());
    }

    try {
      final quota = await _repository.fetchQuota();
      emit(QuotaLoaded(quota));
    } catch (e) {
      emit(QuotaError(e.toString()));
    }
  }

  /// Locally decrement remaining after a chat message is sent.
  void useOne() {
    final current = state;
    if (current is QuotaLoaded) {
      final q = current.quota;
      final remaining = (q.remaining - 1).clamp(0, q.limit).toInt();
      emit(
        QuotaLoaded(
          q.copyWith(used: q.limit - remaining, remaining: remaining),
        ),
      );
    }
  }

  /// Sync quota using the latest `remaining_quota` returned by chatbot API.
  void syncFromRemaining(int remaining, {int? limit}) {
    final current = state;

    if (current is QuotaLoaded) {
      final resolvedLimit = limit ?? current.quota.limit;
      final safeRemaining = remaining.clamp(0, resolvedLimit).toInt();
      emit(
        QuotaLoaded(
          current.quota.copyWith(
            limit: resolvedLimit,
            used: resolvedLimit - safeRemaining,
            remaining: safeRemaining,
          ),
        ),
      );
      return;
    }

    final resolvedLimit = limit ?? QuotaStatus.defaultQuota.limit;
    final safeRemaining = remaining.clamp(0, resolvedLimit).toInt();
    emit(
      QuotaLoaded(
        QuotaStatus(
          used: resolvedLimit - safeRemaining,
          limit: resolvedLimit,
          remaining: safeRemaining,
        ),
      ),
    );
  }

  /// Mark quota as exhausted after a backend 429 response.
  void markExceeded({Map<String, dynamic>? details}) {
    final quota = QuotaStatus.fromRateLimitDetails(details);
    emit(QuotaLoaded(quota));
  }

  /// Whether the user can still send chat messages.
  bool get canChat {
    final current = state;
    if (current is QuotaLoaded) {
      return !current.quota.isExceeded;
    }
    return true; // Allow by default if quota hasn't loaded.
  }
}
