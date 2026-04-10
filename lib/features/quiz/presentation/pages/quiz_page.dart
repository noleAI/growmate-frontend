import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/models/signal_batch.dart';
import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';
import '../cubit/quiz_cubit.dart';
import '../widgets/quiz_answer_widget_factory.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quizRepository});

  final QuizRepository quizRepository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const Duration _totalQuizDuration = Duration(minutes: 12, seconds: 45);

  final BehavioralSignalService _signalService =
      BehavioralSignalService.instance;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  late final QuizCubit _quizCubit;
  late QuizQuestionTemplate _activeQuestion;

  List<QuizQuestionTemplate> _questionPool = List<QuizQuestionTemplate>.from(
    _fallbackUiQuestions,
  );
  String? _selectedOptionId;
  Map<String, bool> _trueFalseAnswers = <String, bool>{};
  final Map<String, String> _shortAnswerDraftByQuestion = <String, String>{};
  final Map<String, String> _selectedOptionByQuestion = <String, String>{};
  final Map<String, Map<String, bool>> _trueFalseDraftByQuestion =
      <String, Map<String, bool>>{};

  Duration _remainingTime = _totalQuizDuration;
  bool _showHint = false;

  Timer? _countdownTimer;
  Timer? _hintTimer;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();

    _activeQuestion = _questionPool.first;

    _quizCubit = QuizCubit(
      quizRepository: widget.quizRepository,
      questionId: _activeQuestion.id,
      questionText: _activeQuestion.content,
    );

    _answerFocusNode.addListener(_onAnswerFocusChanged);

    _signalService.attachBatchSubmitter((List<SignalBatch> batch) async {
      await widget.quizRepository.submitSignals(
        batch
            .map(
              (signal) => signal.toSupabaseInsert(
                sessionId: widget.quizRepository.sessionId,
              ),
            )
            .toList(growable: false),
      );
    });
    _signalService.startQuestion(questionId: _activeQuestion.id);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingTime.inSeconds <= 0) {
        return;
      }

      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    });

    _restartHintTimer();
    unawaited(_loadRemoteQuestions());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hintTimer?.cancel();
    _signalService.stop();
    _answerFocusNode
      ..removeListener(_onAnswerFocusChanged)
      ..dispose();
    _answerController.dispose();
    _quizCubit.close();
    super.dispose();
  }

  void _onAnswerFocusChanged() {
    _signalService.recordFocusChanged(hasFocus: _answerFocusNode.hasFocus);
  }

  void _onAnswerChanged(String value) {
    _quizCubit.onAnswerChanged(value);

    if (_activeQuestion.questionType == QuizQuestionType.shortAnswer) {
      _shortAnswerDraftByQuestion[_activeQuestion.id] = value;
    }

    final currentLength = value.length;

    if (currentLength > _previousLength) {
      _signalService.recordTypingDelta(currentLength - _previousLength);
    } else if (currentLength < _previousLength) {
      final correctionCount = _previousLength - currentLength;
      _signalService.recordCorrectionCount(correctionCount);
    }

    _previousLength = currentLength;
    _signalService.registerInteraction();
  }

  Future<void> _loadRemoteQuestions() async {
    final remoteQuestions = await widget.quizRepository.fetchQuestionTemplates(
      limit: 9,
    );

    if (!mounted || remoteQuestions.isEmpty) {
      return;
    }

    setState(() {
      _shortAnswerDraftByQuestion.clear();
      _selectedOptionByQuestion.clear();
      _trueFalseDraftByQuestion.clear();
      _questionPool = remoteQuestions;
      _activeQuestion = remoteQuestions.first;
      _restoreDraftForActiveQuestion();
      _showHint = false;
    });

    _signalService.startQuestion(questionId: _activeQuestion.id);
    _restartHintTimer();
  }

  void _selectQuestion(QuizQuestionTemplate question) {
    if (_activeQuestion.id == question.id) {
      return;
    }

    _signalService.registerInteraction();

    setState(() {
      _persistDraftForActiveQuestion();
      _activeQuestion = question;
      _restoreDraftForActiveQuestion();
      _showHint = false;
    });

    _signalService.startQuestion(questionId: question.id);
    _restartHintTimer();
  }

  void _onTrueFalseChanged(String statementId, bool value) {
    _signalService.registerInteraction();
    setState(() {
      _trueFalseAnswers = <String, bool>{
        ..._trueFalseAnswers,
        statementId: value,
      };

      _trueFalseDraftByQuestion[_activeQuestion.id] = Map<String, bool>.from(
        _trueFalseAnswers,
      );
    });
  }

  void _persistDraftForActiveQuestion() {
    switch (_activeQuestion.questionType) {
      case QuizQuestionType.multipleChoice:
        final selected = _selectedOptionId;
        if (selected == null || selected.isEmpty) {
          _selectedOptionByQuestion.remove(_activeQuestion.id);
        } else {
          _selectedOptionByQuestion[_activeQuestion.id] = selected;
        }
        break;
      case QuizQuestionType.trueFalseCluster:
        if (_trueFalseAnswers.isEmpty) {
          _trueFalseDraftByQuestion.remove(_activeQuestion.id);
        } else {
          _trueFalseDraftByQuestion[_activeQuestion.id] =
              Map<String, bool>.from(_trueFalseAnswers);
        }
        break;
      case QuizQuestionType.shortAnswer:
        final answer = _answerController.text;
        if (answer.trim().isEmpty) {
          _shortAnswerDraftByQuestion.remove(_activeQuestion.id);
        } else {
          _shortAnswerDraftByQuestion[_activeQuestion.id] = answer;
        }
        break;
    }
  }

  void _restoreDraftForActiveQuestion() {
    _selectedOptionId = _selectedOptionByQuestion[_activeQuestion.id];
    _trueFalseAnswers = Map<String, bool>.from(
      _trueFalseDraftByQuestion[_activeQuestion.id] ?? <String, bool>{},
    );

    final shortAnswer = _shortAnswerDraftByQuestion[_activeQuestion.id] ?? '';
    _answerController
      ..text = shortAnswer
      ..selection = TextSelection.collapsed(offset: shortAnswer.length);

    _previousLength = shortAnswer.length;
  }

  void _restartHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showHint = true;
      });
    });
  }

  QuizQuestionUserAnswer? _buildUserAnswer(BuildContext context) {
    switch (_activeQuestion.questionType) {
      case QuizQuestionType.multipleChoice:
        final selected = _selectedOptionId;
        if (selected == null || selected.trim().isEmpty) {
          _showInputWarning(
            context,
            context.t(
              vi: 'Hãy chọn một đáp án trước khi gửi.',
              en: 'Please choose an option before submitting.',
            ),
          );
          return null;
        }
        return MultipleChoiceUserAnswer(selectedOptionId: selected);
      case QuizQuestionType.trueFalseCluster:
        final payload = _activeQuestion.payload;
        if (payload is! TrueFalseClusterPayload) {
          _showInputWarning(
            context,
            context.t(
              vi: 'Không đọc được dữ liệu câu Đúng/Sai.',
              en: 'Unable to read true/false question data.',
            ),
          );
          return null;
        }

        final expected = payload.subQuestions.length;
        if (_trueFalseAnswers.length < expected) {
          _showInputWarning(
            context,
            context.t(
              vi: 'Bạn cần chọn Đúng/Sai cho tất cả ý nhỏ.',
              en: 'Please answer true/false for all sub-statements.',
            ),
          );
          return null;
        }

        return TrueFalseClusterUserAnswer(
          subAnswers: Map<String, bool>.from(_trueFalseAnswers),
        );
      case QuizQuestionType.shortAnswer:
        final raw = _answerController.text.trim();
        if (raw.isEmpty) {
          _showInputWarning(
            context,
            context.t(
              vi: 'Vui lòng nhập đáp án trước khi gửi.',
              en: 'Please enter an answer before submitting.',
            ),
          );
          return null;
        }
        return ShortAnswerUserAnswer(answerText: raw);
    }
  }

  void _showInputWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submitCurrentAnswer() {
    final userAnswer = _buildUserAnswer(context);
    if (userAnswer == null) {
      return;
    }

    _signalService.markSubmitted();
    _quizCubit.submitTypedAnswer(
      question: _activeQuestion,
      userAnswer: userAnswer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizCubit>.value(
      value: _quizCubit,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _signalService.registerInteraction();
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: BlocConsumer<QuizCubit, QuizCubitState>(
            listener: (context, state) {
              if (state is QuizSubmitFailureState) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }

              if (state is QuizSubmitSuccessState) {
                context.go(
                  '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(state.submissionId)}',
                );
              }

              if (state is QuizRecoveryTriggeredState) {
                context.go(
                  '${AppRoutes.recovery}?reason=${Uri.encodeQueryComponent(state.reason)}',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is QuizSubmittingState;
              final theme = Theme.of(context);
              final formulaText = _activeQuestion.metadata['formula']
                  ?.toString();
              final currentIndex = _questionPool.indexWhere(
                (item) => item.id == _activeQuestion.id,
              );
              final questionNumber = (currentIndex >= 0 ? currentIndex + 1 : 1)
                  .toString();
              final progress =
                  (_remainingTime.inSeconds / _totalQuizDuration.inSeconds)
                      .clamp(0.0, 1.0)
                      .toDouble();

              return ZenPageContainer(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    scrollbars: false,
                  ),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                                return;
                              }

                              context.go(AppRoutes.home);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: GrowMateColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.t(vi: 'Giải tích 12', en: 'Calculus 12'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: GrowMateColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.timer_outlined,
                            color: GrowMateColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(_remainingTime),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: GrowMateColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          color: GrowMateColors.surfaceContainerHigh,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    GrowMateColors.success,
                                    GrowMateColors.primary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_questionPool.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _questionPool
                                .asMap()
                                .entries
                                .map(
                                  (entry) => ChoiceChip(
                                    label: Text(
                                      context.t(
                                        vi: 'Câu ${entry.key + 1}',
                                        en: 'Q${entry.key + 1}',
                                      ),
                                    ),
                                    selected:
                                        entry.value.id == _activeQuestion.id,
                                    onSelected: (_) =>
                                        _selectQuestion(entry.value),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ZenCard(
                        radius: 30,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF6FAF8), Color(0xFFF1F3EA)],
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.t(
                                vi: 'CÂU HỎI SỐ $questionNumber',
                                en: 'QUESTION $questionNumber',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.85,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _activeQuestion.content,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: GrowMateColors.textPrimary,
                                fontSize: 30,
                                height: 1.18,
                              ),
                            ),
                            if (formulaText != null &&
                                formulaText.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                formulaText,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: GrowMateColors.primary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 32,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ZenCard(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        color: Colors.white.withValues(alpha: 0.78),
                        child: QuizAnswerWidgetFactory(
                          question: _activeQuestion,
                          enabled: !isLoading,
                          textController: _answerController,
                          textFocusNode: _answerFocusNode,
                          onTextChanged: _onAnswerChanged,
                          onTextTap: _signalService.registerInteraction,
                          selectedOptionId: _selectedOptionId,
                          onOptionSelected: (optionId) {
                            _signalService.registerInteraction();
                            setState(() {
                              _selectedOptionId = optionId;
                              _selectedOptionByQuestion[_activeQuestion.id] =
                                  optionId;
                            });
                          },
                          trueFalseAnswers: _trueFalseAnswers,
                          onTrueFalseChanged: _onTrueFalseChanged,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedOpacity(
                        opacity: _showHint ? 1 : 0,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOut,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOut,
                          offset: _showHint
                              ? Offset.zero
                              : const Offset(0, 0.08),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: GrowMateColors.secondaryContainer
                                  .withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: GrowMateColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: Text(
                              _hintText(context),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GrowMateColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.42,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ZenButton(
                        label: isLoading
                            ? context.t(vi: 'Đang gửi...', en: 'Submitting...')
                            : context.t(vi: 'Gửi bài', en: 'Submit'),
                        onPressed: isLoading ? null : _submitCurrentAnswer,
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          context.t(
                            vi: 'CẦN TRỢ GIÚP TỪ AI TUTOR?',
                            en: 'NEED HELP FROM AI TUTOR?',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: GrowMateColors.textSecondary,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _hintText(BuildContext context) {
    final payload = _activeQuestion.payload;

    return switch (_activeQuestion.questionType) {
      QuizQuestionType.multipleChoice => context.t(
        vi: 'Đọc kỹ đáp án nhiễu trước khi chọn, tránh chọn theo cảm giác.',
        en: 'Check distractors carefully before selecting.',
      ),
      QuizQuestionType.trueFalseCluster =>
        (payload is TrueFalseClusterPayload &&
                payload.generalHint.trim().isNotEmpty)
            ? payload.generalHint
            : context.t(
                vi: 'Gợi ý: đánh dấu từng ý đúng/sai sau khi lập bảng biến thiên.',
                en: 'Hint: verify each statement after analyzing the function.',
              ),
      QuizQuestionType.shortAnswer => context.t(
        vi: 'Gợi ý nhỏ: Đạo hàm của x^n là n.x^(n-1)',
        en: 'Hint: Derivative of x^n is n.x^(n-1)',
      ),
    };
  }
}

const _fallbackUiQuestions = <QuizQuestionTemplate>[
  QuizQuestionTemplate(
    id: '11111111-1111-4111-8111-111111111111',
    subject: 'math',
    topicCode: 'derivative',
    topicName: 'Đạo hàm',
    examYear: 2026,
    questionType: QuizQuestionType.shortAnswer,
    partNo: 3,
    difficultyLevel: 2,
    content: 'Tính đạo hàm của hàm số',
    payload: ShortAnswerPayload(
      exactAnswer: '12x^2 + 4x',
      acceptedAnswers: <String>['12x^2+4x', '4x+12x^2', '12x²+4x'],
      explanation: 'y\' = 12x^2 + 4x',
    ),
    metadata: <String, dynamic>{'formula': 'y = 4x³ + 2x² - 5'},
    isActive: true,
  ),
  QuizQuestionTemplate(
    id: '22222222-2222-4222-8222-222222222222',
    subject: 'math',
    topicCode: 'logarithm',
    topicName: 'Logarit',
    examYear: 2026,
    questionType: QuizQuestionType.multipleChoice,
    partNo: 1,
    difficultyLevel: 1,
    content: 'Hàm số nào đồng biến trên R?',
    payload: MultipleChoicePayload(
      options: <MultipleChoiceOption>[
        MultipleChoiceOption(id: 'A', text: 'y = 2^x'),
        MultipleChoiceOption(id: 'B', text: 'y = (1/2)^x'),
        MultipleChoiceOption(id: 'C', text: 'y = -x^2'),
        MultipleChoiceOption(id: 'D', text: 'y = -|x|'),
      ],
      correctOptionId: 'A',
      explanation: 'Cơ số 2 > 1 nên 2^x đồng biến trên R.',
    ),
    isActive: true,
  ),
  QuizQuestionTemplate(
    id: '33333333-3333-4333-8333-333333333333',
    subject: 'math',
    topicCode: 'function_analysis',
    topicName: 'Khảo sát hàm số',
    examYear: 2026,
    questionType: QuizQuestionType.trueFalseCluster,
    partNo: 2,
    difficultyLevel: 3,
    content: 'Xét tính đúng sai của các mệnh đề về hàm số đã cho.',
    payload: TrueFalseClusterPayload(
      subQuestions: <TrueFalseStatement>[
        TrueFalseStatement(
          id: 'a',
          text: 'Hàm số đạt cực đại tại x = 1.',
          isTrue: true,
          explanation: 'Đạo hàm đổi dấu từ + sang - tại x = 1.',
        ),
        TrueFalseStatement(
          id: 'b',
          text: 'Giá trị nhỏ nhất trên [-1;2] bằng -3.',
          isTrue: false,
          explanation: 'Tính tại các mốc cho min = -5.',
        ),
        TrueFalseStatement(
          id: 'c',
          text: 'Đồ thị có đúng 2 đường tiệm cận.',
          isTrue: true,
          explanation: 'Có 1 đứng và 1 ngang.',
        ),
        TrueFalseStatement(
          id: 'd',
          text: 'y\' < 0 với mọi x trong (1;3).',
          isTrue: true,
          explanation: 'Bảng biến thiên cho thấy hàm giảm trên khoảng này.',
        ),
      ],
      generalHint: 'Chú ý lập bảng biến thiên trước khi kết luận từng mệnh đề.',
    ),
    isActive: true,
  ),
];
