import '../../../../core/network/api_service.dart';
import '../../../offline/data/repositories/offline_mode_repository.dart';

class QuizRepository {
  QuizRepository({
    required ApiService apiService,
    required this.sessionId,
    OfflineModeRepository? offlineModeRepository,
  }) : _apiService = apiService,
       _offlineModeRepository =
           offlineModeRepository ?? OfflineModeRepository.instance;

  final ApiService _apiService;
  final String sessionId;
  final OfflineModeRepository _offlineModeRepository;

  Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required String answer,
    Map<String, dynamic>? context,
  }) {
    return _apiService.submitAnswer(
      sessionId: sessionId,
      questionId: questionId,
      answer: answer,
      context: context,
    );
  }

  Future<Map<String, dynamic>> submitSignals(
    List<Map<String, dynamic>> signals,
  ) async {
    final offlineEnabled = await _offlineModeRepository.isOfflineModeEnabled();

    if (offlineEnabled) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Offline mode is enabled, signals are queued locally.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }

    await _offlineModeRepository.flushQueuedSignals(
      submitter: (queuedSignals) {
        return _apiService.submitSignals(
          sessionId: sessionId,
          signals: queuedSignals,
        );
      },
    );

    try {
      return await _apiService.submitSignals(
        sessionId: sessionId,
        signals: signals,
      );
    } catch (_) {
      await _offlineModeRepository.enqueueSignals(signals);
      return <String, dynamic>{
        'status': 'queued',
        'message': 'Network unstable, signals are queued for next sync.',
        'data': <String, dynamic>{
          'queuedCount': signals.length,
          'sessionId': sessionId,
        },
      };
    }
  }
}
