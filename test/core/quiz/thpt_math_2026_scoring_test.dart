import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/features/quiz/domain/entities/quiz_question_template.dart';
import 'package:growmate_frontend/features/quiz/domain/usecases/thpt_math_2026_scoring.dart';

void main() {
  group('QuizQuestionTemplate parsing', () {
    test('parses MULTIPLE_CHOICE payload', () {
      final template = QuizQuestionTemplate.fromJson(<String, dynamic>{
        'id': 'q_mc_1',
        'subject': 'math',
        'exam_year': 2026,
        'question_type': 'MULTIPLE_CHOICE',
        'part_no': 1,
        'difficulty_level': 2,
        'content': 'Dao ham cua y = x^2 la gi?',
        'payload': <String, dynamic>{
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'A', 'text': '2x'},
            <String, dynamic>{'id': 'B', 'text': 'x'},
          ],
          'correct_option_id': 'A',
          'explanation': 'y\' = 2x',
        },
      });

      expect(template.questionType, QuizQuestionType.multipleChoice);
      expect(template.payload, isA<MultipleChoicePayload>());
      final payload = template.payload as MultipleChoicePayload;
      expect(payload.correctOptionId, 'A');
      expect(payload.options.length, 2);
    });
  });

  group('THPT Math 2026 scoring', () {
    final multipleChoiceQuestion = QuizQuestionTemplate(
      id: 'mc_1',
      subject: 'math',
      topicCode: 'derivative',
      topicName: 'Dao ham',
      examYear: 2026,
      questionType: QuizQuestionType.multipleChoice,
      partNo: 1,
      difficultyLevel: 2,
      content: 'Chon dap an dung',
      payload: const MultipleChoicePayload(
        options: <MultipleChoiceOption>[
          MultipleChoiceOption(id: 'A', text: '2x'),
          MultipleChoiceOption(id: 'B', text: 'x'),
          MultipleChoiceOption(id: 'C', text: '2'),
          MultipleChoiceOption(id: 'D', text: '1'),
        ],
        correctOptionId: 'A',
        explanation: 'y\' = 2x',
      ),
      isActive: true,
    );

    final trueFalseQuestion = QuizQuestionTemplate(
      id: 'tf_1',
      subject: 'math',
      topicCode: 'function_analysis',
      topicName: 'Khao sat ham so',
      examYear: 2026,
      questionType: QuizQuestionType.trueFalseCluster,
      partNo: 2,
      difficultyLevel: 3,
      content: 'Xet tinh dung sai cua cac menh de sau',
      payload: const TrueFalseClusterPayload(
        subQuestions: <TrueFalseStatement>[
          TrueFalseStatement(
            id: 'a',
            text: 'Menh de A',
            isTrue: true,
            explanation: '',
          ),
          TrueFalseStatement(
            id: 'b',
            text: 'Menh de B',
            isTrue: false,
            explanation: '',
          ),
          TrueFalseStatement(
            id: 'c',
            text: 'Menh de C',
            isTrue: true,
            explanation: '',
          ),
          TrueFalseStatement(
            id: 'd',
            text: 'Menh de D',
            isTrue: true,
            explanation: '',
          ),
        ],
        generalHint: 'Ve bang bien thien',
      ),
      isActive: true,
    );

    final shortAnswerQuestion = QuizQuestionTemplate(
      id: 'sa_1',
      subject: 'math',
      topicCode: 'volume',
      topicName: 'Toi uu hoa',
      examYear: 2026,
      questionType: QuizQuestionType.shortAnswer,
      partNo: 3,
      difficultyLevel: 3,
      content: 'Tinh the tich',
      payload: const ShortAnswerPayload(
        exactAnswer: '15.5',
        acceptedAnswers: <String>['15,5', '31/2'],
        unit: 'cm3',
        explanation: 'V = a*b*h',
      ),
      isActive: true,
    );

    test('scores MULTIPLE_CHOICE correctly', () {
      final result = ThptMath2026Scoring.evaluate(
        question: multipleChoiceQuestion,
        answer: const MultipleChoiceUserAnswer(selectedOptionId: 'A'),
      );

      expect(result.isCorrect, isTrue);
      expect(result.score, 0.25);
      expect(result.maxScore, 0.25);
    });

    test('scores TRUE_FALSE_CLUSTER progressively for 1 correct', () {
      final result = ThptMath2026Scoring.evaluate(
        question: trueFalseQuestion,
        answer: const TrueFalseClusterUserAnswer(
          subAnswers: <String, bool>{
            'a': false,
            'b': false,
            'c': false,
            'd': false,
          },
        ),
      );

      expect(result.isCorrect, isFalse);
      expect(result.score, 0.1);
    });

    test('scores TRUE_FALSE_CLUSTER progressively for 2 correct', () {
      final result = ThptMath2026Scoring.evaluate(
        question: trueFalseQuestion,
        answer: const TrueFalseClusterUserAnswer(
          subAnswers: <String, bool>{
            'a': true,
            'b': false,
            'c': false,
            'd': false,
          },
        ),
      );

      expect(result.score, 0.25);
    });

    test('scores TRUE_FALSE_CLUSTER progressively for 3 correct', () {
      final result = ThptMath2026Scoring.evaluate(
        question: trueFalseQuestion,
        answer: const TrueFalseClusterUserAnswer(
          subAnswers: <String, bool>{
            'a': true,
            'b': false,
            'c': true,
            'd': false,
          },
        ),
      );

      expect(result.score, 0.5);
    });

    test('scores TRUE_FALSE_CLUSTER progressively for 4 correct', () {
      final result = ThptMath2026Scoring.evaluate(
        question: trueFalseQuestion,
        answer: const TrueFalseClusterUserAnswer(
          subAnswers: <String, bool>{
            'a': true,
            'b': false,
            'c': true,
            'd': true,
          },
        ),
      );

      expect(result.isCorrect, isTrue);
      expect(result.score, 1.0);
    });

    test('accepts SHORT_ANSWER in comma format', () {
      final result = ThptMath2026Scoring.evaluate(
        question: shortAnswerQuestion,
        answer: const ShortAnswerUserAnswer(answerText: '15,5'),
      );

      expect(result.isCorrect, isTrue);
      expect(result.score, 0.5);
    });

    test('accepts SHORT_ANSWER in fraction format', () {
      final result = ThptMath2026Scoring.evaluate(
        question: shortAnswerQuestion,
        answer: const ShortAnswerUserAnswer(answerText: '31/2'),
      );

      expect(result.isCorrect, isTrue);
      expect(result.score, 0.5);
    });

    test('accepts SHORT_ANSWER by tolerance when configured', () {
      final toleranceQuestion = QuizQuestionTemplate(
        id: 'sa_tol',
        subject: 'math',
        topicCode: 'stats',
        topicName: 'Thong ke',
        examYear: 2026,
        questionType: QuizQuestionType.shortAnswer,
        partNo: 3,
        difficultyLevel: 3,
        content: 'Tinh gia tri trung binh',
        payload: const ShortAnswerPayload(
          exactAnswer: '2.5',
          acceptedAnswers: <String>[],
          explanation: '',
          tolerance: 0.05,
        ),
        isActive: true,
      );

      final result = ThptMath2026Scoring.evaluate(
        question: toleranceQuestion,
        answer: const ShortAnswerUserAnswer(answerText: '2.53 cm3'),
      );

      expect(result.isCorrect, isTrue);
      expect(result.details['matched_by'], 'tolerance');
      expect(result.score, 0.5);
    });

    test('returns zero for wrong SHORT_ANSWER', () {
      final result = ThptMath2026Scoring.evaluate(
        question: shortAnswerQuestion,
        answer: const ShortAnswerUserAnswer(answerText: '12'),
      );

      expect(result.isCorrect, isFalse);
      expect(result.score, 0);
    });
  });
}
