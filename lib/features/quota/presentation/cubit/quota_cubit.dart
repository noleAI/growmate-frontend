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
  Future<void> loadQuota() async {
    emit(const QuotaLoading());
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
      emit(QuotaLoaded(QuotaStatus(
        used: q.used + 1,
        limit: q.limit,
        remaining: (q.remaining - 1).clamp(0, q.limit),
      )));
    }
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
