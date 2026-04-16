import 'package:flutter/foundation.dart';

import '../../../core/network/agentic_api_service.dart';
import 'mock_user_progress_generator.dart';

/// Progress repository backed by inspection belief-state endpoint.
class RealProgressRepository {
  RealProgressRepository({required AgenticApiService apiService})
    : _apiService = apiService;

  final AgenticApiService _apiService;

  /// Whether a fetch is currently in progress.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<TopicMastery>> fetchMasteryMap({
    required String sessionId,
  }) async {
    _isLoading = true;
    try {
      final beliefState = await _apiService.getBeliefState(
        sessionId: sessionId,
      );
      return mapBeliefsToMastery(beliefState.beliefs);
    } catch (e) {
      debugPrint('⚠️ Lỗi khi fetch belief state: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  static List<TopicMastery> mapBeliefsToMastery(Map<String, double> beliefs) {
    if (beliefs.isEmpty) {
      return const <TopicMastery>[];
    }

    final items =
        beliefs.entries
            .map((entry) {
              final score = (entry.value * 4).clamp(0.0, 4.0);
              return TopicMastery(
                topic: entry.key,
                score: score,
                statusLabel: _statusLabel(score),
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));

    return items;
  }

  static String _statusLabel(double score) {
    if (score >= 3.2) return 'Đang vững';
    if (score >= 2.4) return 'Cần ôn nhẹ';
    return 'Đang khởi động';
  }
}
