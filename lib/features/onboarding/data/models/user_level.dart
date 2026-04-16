/// Cấp độ người dùng được xác định qua quiz chẩn đoán.
enum UserLevel {
  beginner,
  intermediate,
  advanced;

  String get viLabel => switch (this) {
    beginner => 'Mới bắt đầu',
    intermediate => 'Trung cấp',
    advanced => 'Nâng cao',
  };

  String get description => switch (this) {
    beginner => 'Bạn sẽ học từ những khái niệm cơ bản nhất. Không cần lo lắng!',
    intermediate => 'Bạn đã có nền tảng tốt. Chúng ta sẽ nâng cao dần!',
    advanced => 'Bạn rất giỏi rồi! Hãy thử thách bản thân với bài khó hơn!',
  };

  String get emoji => switch (this) {
    beginner => '🌱',
    intermediate => '📚',
    advanced => '🚀',
  };
}
