import '../models/onboarding_models.dart';

/// Helper to build mock options with synthetic IDs (A, B, C, D).
List<OnboardingOption> _opts(List<String> texts) {
  const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  return [
    for (int i = 0; i < texts.length; i++)
      OnboardingOption(id: letters[i], text: texts[i]),
  ];
}

/// 10 câu hỏi chẩn đoán trình độ toán sơ/trung/cao.
final List<OnboardingQuestion> mockOnboardingQuestions = [
  OnboardingQuestion(
    id: 'q1',
    questionText: 'Đạo hàm của f(x) = x² là gì?',
    options: _opts(['x', '2x', '2x²', 'x³']),
    correctOptionIndex: 1,
    topicTag: 'basic_rules',
  ),
  OnboardingQuestion(
    id: 'q2',
    questionText: 'sin²(x) + cos²(x) = ?',
    options: _opts(['0', '2', '1', 'sin(2x)']),
    correctOptionIndex: 2,
    topicTag: 'basic_trig',
  ),
  OnboardingQuestion(
    id: 'q3',
    questionText: 'Tích phân của 2x là gì?',
    options: _opts(['x² + C', '2 + C', '2x² + C', 'x + C']),
    correctOptionIndex: 0,
    topicTag: 'basic_rules',
  ),
  OnboardingQuestion(
    id: 'q4',
    questionText: 'ln(e) = ?',
    options: _opts(['0', 'e', '1', '2']),
    correctOptionIndex: 2,
    topicTag: 'exp_log',
  ),
  OnboardingQuestion(
    id: 'q5',
    questionText: 'Đạo hàm của f(g(x)) là gì theo quy tắc dây chuyền?',
    options: _opts([
      "f'(x) · g'(x)",
      "f'(g(x)) · g'(x)",
      "f(x) · g'(x)",
      "f'(g(x)) + g'(x)",
    ]),
    correctOptionIndex: 1,
    topicTag: 'chain_rule',
  ),
  OnboardingQuestion(
    id: 'q6',
    questionText: 'cos(0) = ?',
    options: _opts(['0', '1', '-1', 'π']),
    correctOptionIndex: 1,
    topicTag: 'basic_trig',
  ),
  OnboardingQuestion(
    id: 'q7',
    questionText: 'Đạo hàm của e^x là gì?',
    options: _opts(['e^(x-1)', 'x·e^x', 'e^x', 'ln(x)']),
    correctOptionIndex: 2,
    topicTag: 'exp_log',
  ),
  OnboardingQuestion(
    id: 'q8',
    questionText: 'Giới hạn lim(x→0) sin(x)/x = ?',
    options: _opts(['0', '∞', '1', 'không xác định']),
    correctOptionIndex: 2,
    topicTag: 'basic_rules',
  ),
  OnboardingQuestion(
    id: 'q9',
    questionText: 'Đạo hàm của tan(x) là gì?',
    options: _opts(['sec(x)', 'sec²(x)', 'cot(x)', '1/sin(x)']),
    correctOptionIndex: 1,
    topicTag: 'basic_trig',
  ),
  OnboardingQuestion(
    id: 'q10',
    questionText: 'Đạo hàm của ln(x) là gì?',
    options: _opts(['ln(x)/x', '1/x', 'e^x', 'x·ln(x)']),
    correctOptionIndex: 1,
    topicTag: 'exp_log',
  ),
];

/// Các mục tiêu học tập cho onboarding.
const List<StudyGoal> mockStudyGoals = [
  StudyGoal(
    id: 'exam_prep',
    label: 'Chuẩn bị thi THPT',
    emoji: '🎯',
    description: 'Ôn luyện toàn diện để đạt điểm cao trong kỳ thi quốc gia',
  ),
  StudyGoal(
    id: 'improve_grade',
    label: 'Nâng điểm trên lớp',
    emoji: '📈',
    description: 'Cải thiện điểm số trong các bài kiểm tra và bài thi học kỳ',
  ),
  StudyGoal(
    id: 'fill_gaps',
    label: 'Lấp lỗ hổng kiến thức',
    emoji: '🧩',
    description: 'Tìm và sửa những điểm yếu còn tồn tại trong toán học',
  ),
  StudyGoal(
    id: 'curiosity',
    label: 'Học vì đam mê toán',
    emoji: '💡',
    description: 'Khám phá vẻ đẹp của toán học một cách thú vị và nhẹ nhàng',
  ),
];
