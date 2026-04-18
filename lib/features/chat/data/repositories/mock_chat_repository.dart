import 'dart:math';
import 'dart:typed_data';

import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  MockChatRepository();

  final _random = Random();
  final List<ChatMessage> _history = [];

  /// Context-aware mock AI responses grouped by topic keywords.
  static const _topicResponses = <String, List<String>>{
    'đạo hàm|derivative|dao ham': [
      'Đạo hàm \$f\'(x)\$ biểu thị tốc độ thay đổi của hàm số tại điểm \$x\$.\n\n'
          'Công thức cơ bản:\n'
          '- \$(x^n)\' = nx^{n-1}\$\n'
          '- \$(\\sin x)\' = \\cos x\$\n'
          '- \$(\\cos x)\' = -\\sin x\$\n'
          '- \$(e^x)\' = e^x\$\n\n'
          'Bạn muốn mình giải thích thêm phần nào?',
      'Để tính đạo hàm hàm hợp, dùng quy tắc chain rule:\n\n'
          '\$[f(g(x))]\' = f\'(g(x)) \\cdot g\'(x)\$\n\n'
          'Ví dụ: \$(\\sin(2x))\' = \\cos(2x) \\cdot 2 = 2\\cos(2x)\$',
    ],
    'tích phân|integral|nguyen ham': [
      'Tích phân là phép ngược của đạo hàm:\n\n'
          '\$\\int f(x)dx = F(x) + C\$ (tích phân bất định)\n\n'
          '\$\\int_a^b f(x)dx = F(b) - F(a)\$ (tích phân xác định)\n\n'
          'Nhớ rằng: \$\\int x^n dx = \\frac{x^{n+1}}{n+1} + C\$ (với \$n \\neq -1\$)',
      'Các phương pháp tính tích phân:\n\n'
          '1. **Đổi biến**: đặt \$t = g(x)\$\n'
          '2. **Từng phần**: \$\\int u \\, dv = uv - \\int v \\, du\$\n'
          '3. **Bảng nguyên hàm**: tra cứu công thức cơ bản\n\n'
          'Bạn đang gặp khó ở phương pháp nào?',
    ],
    'cực trị|cực đại|cực tiểu|extremum|max|min': [
      'Để tìm cực trị của hàm \$y = f(x)\$:\n\n'
          '1. Tính \$f\'(x) = 0\$ → tìm các nghiệm \$x_0\$\n'
          '2. Lập bảng biến thiên (xét dấu \$f\'(x)\$)\n'
          '3. Nếu \$f\'(x)\$ đổi dấu từ \$+\$ sang \$-\$: **cực đại**\n'
          '   Nếu \$f\'(x)\$ đổi dấu từ \$-\$ sang \$+\$: **cực tiểu**\n\n'
          'Hoặc dùng đạo hàm bậc 2: nếu \$f\'\'(x_0) < 0\$ → cực đại, \$f\'\'(x_0) > 0\$ → cực tiểu.',
    ],
    'logarit|log|ln': [
      'Các công thức logarit cơ bản:\n\n'
          '- \$\\log_a(xy) = \\log_a x + \\log_a y\$\n'
          '- \$\\log_a\\frac{x}{y} = \\log_a x - \\log_a y\$\n'
          '- \$\\log_a x^n = n \\cdot \\log_a x\$\n'
          '- Đổi cơ số: \$\\log_a x = \\frac{\\ln x}{\\ln a}\$\n\n'
          '\$\\ln x\$ là logarit tự nhiên (cơ số \$e \\approx 2.718\$).',
    ],
    'giải thích|explain': [
      'Để mình giải thích rõ hơn nhé!\n\n'
          'Bạn muốn mình giải thích phần nào? Ví dụ:\n'
          '- Lý thuyết cơ bản\n'
          '- Cách giải bài tập cụ thể\n'
          '- Mẹo làm bài nhanh\n\n'
          'Cứ hỏi chi tiết, mình sẽ trả lời ngay! 😊',
    ],
    'ví dụ|example|vi du': [
      'Đây là ví dụ minh họa:\n\n'
          '**Bài**: Tìm đạo hàm \$f(x) = x^3 - 3x^2 + 2x\$\n\n'
          '**Giải**:\n'
          '\$f\'(x) = 3x^2 - 6x + 2\$\n\n'
          'Tại \$x = 1\$: \$f\'(1) = 3 - 6 + 2 = -1\$\n'
          '→ Hàm đang giảm tại \$x = 1\$.',
    ],
  };

  static const _fallbackResponses = [
    'Câu hỏi hay đó! 🤔\n\n'
        'Mình cần thêm thông tin để trả lời chính xác. '
        'Bạn có thể chia sẻ thêm:\n'
        '- Đề bài cụ thể\n'
        '- Phần bạn chưa hiểu\n'
        '- Bước nào bạn đang bị stuck?',
    'Chắc chắn rồi! Mình giải thích đơn giản hơn nhé:\n\n'
        'Hàm số bậc 3 \$y = ax^3 + bx^2 + cx + d\$ có dạng chữ S.\n'
        'Nếu \$a > 0\$: đi từ dưới lên trên.\n'
        'Nếu \$a < 0\$: đi từ trên xuống dưới.',
    'Mình hiểu rồi! Với bài dạng này, mẹo là:\n\n'
        '- Đặt \$t = \\sin(x)\$ hoặc \$t = \\cos(x)\$\n'
        '- Giải phương trình bậc 2 theo \$t\$\n'
        '- Kiểm tra điều kiện \$-1 \\leq t \\leq 1\$',
    'Đúng rồi! Bạn đang tiến bộ tốt 💪\n\n'
        'Nhớ rằng: \$\\int_a^b f(x)dx = F(b) - F(a)\$\n\n'
        'Trong đó \$F(x)\$ là nguyên hàm của \$f(x)\$.',
    'Hmm, để mình nghĩ... 🤔\n\n'
        'Với phương trình \$\\log_2(x) + \\log_2(x-1) = 1\$:\n\n'
        '→ \$\\log_2[x(x-1)] = 1\$\n'
        '→ \$x(x-1) = 2\$\n'
        '→ \$x^2 - x - 2 = 0\$\n\n'
        'Giải ra \$x = 2\$ (vì \$x > 1\$).',
  ];

  @override
  Future<ChatMessage> sendMessage(String userMessage) async {
    await Future.delayed(Duration(milliseconds: 600 + _random.nextInt(1000)));

    _history.add(
      ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.user,
        content: userMessage,
        timestamp: DateTime.now(),
      ),
    );

    final lowerMessage = userMessage.toLowerCase();
    String? response;

    for (final entry in _topicResponses.entries) {
      final keywords = entry.key.split('|');
      final matches = keywords.any(
        (kw) => lowerMessage.contains(kw.toLowerCase()),
      );
      if (matches) {
        final responses = entry.value;
        response = responses[_random.nextInt(responses.length)];
        break;
      }
    }

    response ??= _fallbackResponses[_random.nextInt(_fallbackResponses.length)];

    final aiMessage = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    );

    _history.add(aiMessage);
    return aiMessage;
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    await Future.delayed(Duration(milliseconds: 700 + _random.nextInt(900)));

    _history.add(
      ChatMessage(
        id: 'user_img_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatRole.user,
        content: userMessage,
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        imageName: imageName,
      ),
    );

    final aiMessage = ChatMessage(
      id: 'ai_img_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content:
          'Mình đã nhận ảnh rồi nè 📷\n\n'
          'Hiện tại bạn đang ở mock mode nên mình chỉ mô phỏng phản hồi. '
          'Khi dùng backend thật, mình sẽ phân tích trực tiếp nội dung trong ảnh và trả lời chi tiết hơn.',
      timestamp: DateTime.now(),
    );

    _history.add(aiMessage);
    return aiMessage;
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
  Future<List<ChatMessage>> loadHistory() async => [];

  @override
  void clearHistory() {
    _history.clear();
  }
}
