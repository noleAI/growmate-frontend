import '../../../../core/network/api_service.dart';

class QuizRepository {
  QuizRepository({required ApiService apiService, required this.sessionId})
    : _apiService = apiService;

  final ApiService _apiService;
  final String sessionId;

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
  ) {
    return _apiService.submitSignals(sessionId: sessionId, signals: signals);
  }
}
