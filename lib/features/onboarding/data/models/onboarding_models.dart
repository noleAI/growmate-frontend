import 'user_level.dart';

/// Trạng thái lưu trữ kết quả onboarding.
class OnboardingResult {
  const OnboardingResult({
    required this.level,
    required this.correctCount,
    required this.totalQuestions,
    required this.elapsedMs,
    required this.selectedGoal,
  });

  final UserLevel level;
  final int correctCount;
  final int totalQuestions;
  final int elapsedMs;
  final String selectedGoal;

  double get accuracy => correctCount / totalQuestions;
}

/// Một lựa chọn trong câu hỏi onboarding, kèm ID từ backend.
class OnboardingOption {
  const OnboardingOption({required this.id, required this.text});

  /// ID lựa chọn (ví dụ "A", "B", "C", "D") — dùng để gửi lên backend.
  final String id;

  /// Nội dung hiển thị cho user.
  final String text;

  @override
  String toString() => text;
}

/// Câu hỏi chẩn đoán trong onboarding.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.topicTag,
  });

  final String id;
  final String questionText;
  final List<OnboardingOption> options;
  final int correctOptionIndex;
  final String? topicTag;
}

/// Mục tiêu học tập.
class StudyGoal {
  const StudyGoal({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
  });

  final String id;
  final String label;
  final String emoji;
  final String description;
}
