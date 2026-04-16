import '../../../../core/network/agentic_api_service.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

/// Chat repository that sends messages through the agentic backend
/// via `POST /sessions/{sessionId}/interact` with `action_type: "chat"`.
class RealChatRepository implements ChatRepository {
  RealChatRepository({
    required AgenticApiService apiService,
    required String sessionId,
  }) : _api = apiService,
       _sessionId = sessionId;

  final AgenticApiService _api;
  final String _sessionId;

  @override
  Future<ChatMessage> sendMessage(String userMessage) async {
    final response = await _api.interact(
      sessionId: _sessionId,
      actionType: 'chat',
      responseData: {'message': userMessage},
    );

    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: response.content,
      timestamp: DateTime.now(),
      planRepaired: response.planRepaired,
      beliefEntropy: response.beliefEntropy,
      nextNodeType: response.nextNodeType,
    );
  }

  @override
  ChatMessage getGreeting() {
    return ChatMessage(
      id: 'greeting_0',
      role: ChatRole.assistant,
      content:
          'Xin chào! Mình là GrowMate AI 🤖\n\n'
          'Mình có thể giúp bạn:\n'
          '• Giải thích bài tập Toán (đạo hàm, tích phân, logarit...)\n'
          '• Ôn tập kiến thức THPT 2026\n'
          '• Gợi ý phương pháp học hiệu quả\n'
          '• Giải đề thi thử\n\n'
          'Hỏi mình bất cứ điều gì nhé! 📚',
      timestamp: DateTime.now(),
    );
  }

  @override
  void clearHistory() {
    // Real chat history is server-side; nothing to clear locally.
  }
}
