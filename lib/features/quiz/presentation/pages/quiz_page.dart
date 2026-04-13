import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
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
import '../widgets/quiz_math_text.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quizRepository});

  final QuizRepository quizRepository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const int _secondsPerMultipleChoice = 35;
  static const int _secondsPerTrueFalseCluster = 60;
  static const int _secondsPerShortAnswer = 70;
  static const int _mvpDemoTotalQuestions = 20;
  static const int _multipleChoiceQuestionCount = 12;
  static const int _trueFalseClusterQuestionCount = 3;
  static const int _shortAnswerQuestionCount = 5;
  static const int _extraQuestionCount = 0;
  static const int _initialQuizDurationSeconds =
      (_multipleChoiceQuestionCount * _secondsPerMultipleChoice) +
      (_trueFalseClusterQuestionCount * _secondsPerTrueFalseCluster) +
      (_shortAnswerQuestionCount * _secondsPerShortAnswer);

  final BehavioralSignalService _signalService =
      BehavioralSignalService.instance;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  QuizCubit? _quizCubit;
  QuizQuestionTemplate? _activeQuestion;

  // Start with empty pool — will load from Supabase
  List<QuizQuestionTemplate> _questionPool = <QuizQuestionTemplate>[];
  String? _selectedOptionId;
  Map<String, bool> _trueFalseAnswers = <String, bool>{};
  final Map<String, String> _shortAnswerDraftByQuestion = <String, String>{};
  final Map<String, String> _selectedOptionByQuestion = <String, String>{};
  final Map<String, Map<String, bool>> _trueFalseDraftByQuestion =
      <String, Map<String, bool>>{};

  Duration _remainingTime = const Duration(
    seconds: _initialQuizDurationSeconds,
  );
  Duration _quizDuration = const Duration(seconds: _initialQuizDurationSeconds);
  bool _showHint = false;
  bool _isLoadingQuestions = true;
  String? _fetchError;

  Timer? _countdownTimer;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();

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

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingTime.inSeconds <= 0) {
        return;
      }

      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    });

    // Load questions from Supabase first, then initialize quiz
    unawaited(_loadQuestionsAndInit());
  }

  Future<void> _loadQuestionsAndInit() async {
    setState(() {
      _isLoadingQuestions = true;
      _fetchError = null;
    });

    try {
      final remoteQuestions = await widget.quizRepository
          .fetchQuestionTemplates(limit: 80);

      if (!mounted) return;

      if (remoteQuestions.isEmpty) {
        setState(() {
          _isLoadingQuestions = false;
          _fetchError = 'Không có câu hỏi nào. Vui lòng liên hệ quản trị viên.';
        });
        return;
      }

      // Build a stable MVP demo pool with target distribution:
      // Multiple choice 12, true/false cluster 3, short answer 5 (total 20).
      final mvpDemoPool = _buildMvpDemoQuestionPool(remoteQuestions);
      final quizDuration = _buildQuizDuration(mvpDemoPool);

      // Success: initialize quiz with real data
      _questionPool = mvpDemoPool;
      _activeQuestion = mvpDemoPool.first;

      _quizCubit = QuizCubit(
        quizRepository: widget.quizRepository,
        questionId: _activeQuestion!.id,
        questionText: _activeQuestion!.content,
      );

      _signalService.startQuestion(questionId: _activeQuestion!.id);

      setState(() {
        _quizDuration = quizDuration;
        _remainingTime = quizDuration;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuestions = false;
        _fetchError =
            'Không kết nối được với server. Kiểm tra mạng và thử lại.';
      });
    }
  }

  List<QuizQuestionTemplate> _buildMvpDemoQuestionPool(
    List<QuizQuestionTemplate> source,
  ) {
    final selectedById = <String>{};
    final selected = <QuizQuestionTemplate>[];

    void pickFrom(List<QuizQuestionTemplate> candidates, int count) {
      var picked = 0;
      for (final question in candidates) {
        if (selected.length >= _mvpDemoTotalQuestions || picked >= count) {
          break;
        }
        if (selectedById.contains(question.id)) {
          continue;
        }
        selected.add(question);
        selectedById.add(question.id);
        picked += 1;
      }
    }

    final sorted = List<QuizQuestionTemplate>.from(source)
      ..sort((a, b) {
        final partCompare = a.partNo.compareTo(b.partNo);
        if (partCompare != 0) return partCompare;

        final difficultyCompare = a.difficultyLevel.compareTo(
          b.difficultyLevel,
        );
        if (difficultyCompare != 0) return difficultyCompare;

        return a.id.compareTo(b.id);
      });

    final multipleChoice = sorted
        .where((q) => q.questionType == QuizQuestionType.multipleChoice)
        .toList(growable: false);
    final trueFalseCluster = sorted
        .where((q) => q.questionType == QuizQuestionType.trueFalseCluster)
        .toList(growable: false);
    final shortAnswer = sorted
        .where((q) => q.questionType == QuizQuestionType.shortAnswer)
        .toList(growable: false);

    final multipleChoiceTarget = math.min(
      _multipleChoiceQuestionCount,
      multipleChoice.length,
    );
    final trueFalseTarget = math.min(
      _trueFalseClusterQuestionCount,
      trueFalseCluster.length,
    );
    final shortAnswerTarget = math.min(
      _shortAnswerQuestionCount,
      shortAnswer.length,
    );

    final allocatedCore =
        multipleChoiceTarget + trueFalseTarget + shortAnswerTarget;
    final extraTarget = math.max(
      _extraQuestionCount,
      _mvpDemoTotalQuestions - allocatedCore,
    );

    // Bucket 1: Multiple-choice questions (prefer low/medium difficulty).
    final multipleChoiceCandidates = multipleChoice
        .where((q) => q.difficultyLevel <= 2)
        .toList(growable: false);
    pickFrom(multipleChoiceCandidates, multipleChoiceTarget);

    // Bucket 2: True/false cluster questions.
    pickFrom(trueFalseCluster, trueFalseTarget);

    // Bucket 3: Short-answer questions.
    pickFrom(shortAnswer, shortAnswerTarget);

    // Bucket 4: Fill remaining slots from harder/remaining questions.
    final remainingHard =
        sorted
            .where(
              (q) =>
                  !selectedById.contains(q.id) &&
                  (q.difficultyLevel >= 2 ||
                      q.questionType == QuizQuestionType.shortAnswer),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final difficultyCompare = b.difficultyLevel.compareTo(
              a.difficultyLevel,
            );
            if (difficultyCompare != 0) return difficultyCompare;
            return a.id.compareTo(b.id);
          });
    pickFrom(remainingHard, extraTarget);

    // Fallback: fill any missing slots from the remaining ordered pool.
    if (selected.length < _mvpDemoTotalQuestions) {
      for (final question in sorted) {
        if (selected.length >= _mvpDemoTotalQuestions) break;
        if (selectedById.contains(question.id)) continue;
        selected.add(question);
        selectedById.add(question.id);
      }
    }

    return selected;
  }

  Duration _buildQuizDuration(List<QuizQuestionTemplate> questions) {
    var totalSeconds = 0;
    for (final question in questions) {
      switch (question.questionType) {
        case QuizQuestionType.multipleChoice:
          totalSeconds += _secondsPerMultipleChoice;
          break;
        case QuizQuestionType.trueFalseCluster:
          totalSeconds += _secondsPerTrueFalseCluster;
          break;
        case QuizQuestionType.shortAnswer:
          totalSeconds += _secondsPerShortAnswer;
          break;
      }
    }

    return Duration(seconds: totalSeconds);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _signalService.stop();
    _answerFocusNode
      ..removeListener(_onAnswerFocusChanged)
      ..dispose();
    _answerController.dispose();
    _quizCubit?.close();
    super.dispose();
  }

  void _onAnswerFocusChanged() {
    _signalService.recordFocusChanged(hasFocus: _answerFocusNode.hasFocus);
  }

  bool get _hasAnyAnswers {
    final hasMultipleChoiceAnswers = _selectedOptionByQuestion.values.any(
      (v) => v.isNotEmpty,
    );
    final hasTrueFalseAnswers = _trueFalseAnswers.isNotEmpty;
    final hasShortAnswerDrafts = _shortAnswerDraftByQuestion.values.any(
      (v) => v.trim().isNotEmpty,
    );
    return hasMultipleChoiceAnswers ||
        hasTrueFalseAnswers ||
        hasShortAnswerDrafts;
  }

  Future<bool> _confirmLeaveQuiz() async {
    if (!_hasAnyAnswers) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.t(vi: 'Rời bài quiz?', en: 'Leave quiz?')),
              ),
            ],
          ),
          content: Text(
            context.t(
              vi: 'Bạn đã trả lời một số câu hỏi. Tiến trình sẽ bị mất nếu rời đi bây giờ.',
              en: 'You have answered some questions. Your progress will be lost if you leave now.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.t(vi: 'Ở lại', en: 'Stay'),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(context.t(vi: 'Rời đi', en: 'Leave')),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _onAnswerChanged(String value) {
    _quizCubit?.onAnswerChanged(value);

    if (_activeQuestion!.questionType == QuizQuestionType.shortAnswer) {
      _shortAnswerDraftByQuestion[_activeQuestion!.id] = value;
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

  void _selectQuestion(QuizQuestionTemplate question) {
    if (_activeQuestion?.id == question.id) {
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
  }

  void _onTrueFalseChanged(String statementId, bool value) {
    _signalService.registerInteraction();
    setState(() {
      _trueFalseAnswers = <String, bool>{
        ..._trueFalseAnswers,
        statementId: value,
      };

      _trueFalseDraftByQuestion[_activeQuestion!.id] = Map<String, bool>.from(
        _trueFalseAnswers,
      );
    });
  }

  void _persistDraftForActiveQuestion() {
    switch (_activeQuestion!.questionType) {
      case QuizQuestionType.multipleChoice:
        final selected = _selectedOptionId;
        if (selected == null || selected.isEmpty) {
          _selectedOptionByQuestion.remove(_activeQuestion!.id);
        } else {
          _selectedOptionByQuestion[_activeQuestion!.id] = selected;
        }
        break;
      case QuizQuestionType.trueFalseCluster:
        if (_trueFalseAnswers.isEmpty) {
          _trueFalseDraftByQuestion.remove(_activeQuestion!.id);
        } else {
          _trueFalseDraftByQuestion[_activeQuestion!.id] =
              Map<String, bool>.from(_trueFalseAnswers);
        }
        break;
      case QuizQuestionType.shortAnswer:
        final answer = _answerController.text;
        if (answer.trim().isEmpty) {
          _shortAnswerDraftByQuestion.remove(_activeQuestion!.id);
        } else {
          _shortAnswerDraftByQuestion[_activeQuestion!.id] = answer;
        }
        break;
    }
  }

  void _restoreDraftForActiveQuestion() {
    _selectedOptionId = _selectedOptionByQuestion[_activeQuestion!.id];
    _trueFalseAnswers = Map<String, bool>.from(
      _trueFalseDraftByQuestion[_activeQuestion!.id] ?? <String, bool>{},
    );

    final shortAnswer = _shortAnswerDraftByQuestion[_activeQuestion!.id] ?? '';
    _answerController
      ..text = shortAnswer
      ..selection = TextSelection.collapsed(offset: shortAnswer.length);

    _previousLength = shortAnswer.length;
  }

  void _toggleHint() {
    _signalService.registerInteraction();
    setState(() {
      _showHint = !_showHint;
    });
  }

  bool _hasInlineGeneralHint() {
    if (_activeQuestion?.questionType != QuizQuestionType.trueFalseCluster) {
      return false;
    }

    final payload = _activeQuestion?.payload;
    return payload is TrueFalseClusterPayload &&
        payload.generalHint.trim().isNotEmpty;
  }

  QuizQuestionUserAnswer? _buildUserAnswer(BuildContext context) {
    switch (_activeQuestion!.questionType) {
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
        final payload = _activeQuestion!.payload;
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
    _quizCubit?.submitTypedAnswer(
      question: _activeQuestion!,
      userAnswer: userAnswer,
    );
  }

  TextStyle _questionContentStyle(ThemeData theme, String content) {
    final length = content.runes.length;
    final fontSize = switch (length) {
      >= 220 => 18.0,
      >= 140 => 20.0,
      _ => 24.0,
    };

    return theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: fontSize,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: fontSize,
          height: 1.3,
          fontWeight: FontWeight.w700,
        );
  }

  bool _questionHasAnswer(QuizQuestionTemplate question) {
    return switch (question.questionType) {
      QuizQuestionType.multipleChoice =>
        (_selectedOptionByQuestion[question.id]?.isNotEmpty ?? false) ||
            (question.id == _activeQuestion?.id &&
                (_selectedOptionId?.isNotEmpty ?? false)),
      QuizQuestionType.trueFalseCluster =>
        (_trueFalseDraftByQuestion[question.id]?.isNotEmpty ?? false) ||
            (question.id == _activeQuestion?.id &&
                _trueFalseAnswers.isNotEmpty),
      QuizQuestionType.shortAnswer =>
        (_shortAnswerDraftByQuestion[question.id]?.trim().isNotEmpty ??
                false) ||
            (question.id == _activeQuestion?.id &&
                _answerController.text.trim().isNotEmpty),
    };
  }

  void _moveToAdjacentQuestion(int offset) {
    if (_questionPool.length <= 1 || _activeQuestion == null) {
      return;
    }

    final currentIndex = _questionPool.indexWhere(
      (item) => item.id == _activeQuestion!.id,
    );
    if (currentIndex < 0) {
      return;
    }

    final nextIndex = (currentIndex + offset).clamp(
      0,
      _questionPool.length - 1,
    );
    if (nextIndex == currentIndex) {
      return;
    }

    _selectQuestion(_questionPool[nextIndex]);
  }

  Future<void> _openQuestionNavigatorSheet(BuildContext context) async {
    if (_questionPool.length <= 1) {
      return;
    }

    _persistDraftForActiveQuestion();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final mediaQuery = MediaQuery.of(sheetContext);
        final sheetHeight = math.min(mediaQuery.size.height * 0.75, 460.0);
        final crossAxisCount = mediaQuery.size.width < 360 ? 4 : 5;

        return SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.t(vi: 'Danh sách câu hỏi', en: 'Question list'),
                  style: sheetTheme.textTheme.titleMedium?.copyWith(
                    color: sheetTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sheetContext.t(
                    vi: 'Chạm vào câu để chuyển nhanh.',
                    en: 'Tap a question to jump quickly.',
                  ),
                  style: sheetTheme.textTheme.bodySmall?.copyWith(
                    color: sheetTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    itemCount: _questionPool.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (itemContext, index) {
                      final question = _questionPool[index];
                      final isSelected = question.id == _activeQuestion!.id;
                      final isAnswered = _questionHasAnswer(question);

                      final backgroundColor = isSelected
                          ? sheetTheme.colorScheme.tertiaryContainer
                          : isAnswered
                          ? sheetTheme.colorScheme.primaryContainer.withValues(
                              alpha: 0.44,
                            )
                          : sheetTheme.colorScheme.surfaceContainerLow;
                      final foregroundColor = isSelected
                          ? sheetTheme.colorScheme.onTertiaryContainer
                          : sheetTheme.colorScheme.onSurfaceVariant;

                      return InkWell(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _selectQuestion(question);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? sheetTheme.colorScheme.primary
                                  : sheetTheme.colorScheme.surfaceContainerHigh,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isAnswered) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: foregroundColor,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  sheetContext.t(
                                    vi: 'Câu ${index + 1}',
                                    en: 'Q${index + 1}',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: sheetTheme.textTheme.labelLarge
                                      ?.copyWith(
                                        color: foregroundColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while fetching questions from Supabase
    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.t(
                  vi: 'Đang tải câu hỏi...',
                  en: 'Loading questions...',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state if fetch failed
    if (_fetchError != null || _questionPool.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _fetchError ?? 'Không có câu hỏi nào.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadQuestionsAndInit,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.t(vi: 'Thử lại', en: 'Retry')),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_outlined),
                label: Text(context.t(vi: 'Về trang chủ', en: 'Go Home')),
              ),
            ],
          ),
        ),
      );
    }

    return BlocProvider<QuizCubit>.value(
      value: _quizCubit!,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _signalService.registerInteraction();
          FocusScope.of(context).unfocus();
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final navigator = Navigator.of(context);
            final canPopRoute = context.canPop();
            final shouldLeave = await _confirmLeaveQuiz();
            if (shouldLeave && mounted && canPopRoute) {
              navigator.pop();
            }
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
                final formulaText = _activeQuestion!.metadata['formula']
                    ?.toString();
                final currentIndex = _questionPool.indexWhere(
                  (item) => item.id == _activeQuestion!.id,
                );
                final currentNumber = currentIndex >= 0 ? currentIndex + 1 : 1;
                final questionNumber = currentNumber.toString();
                final questionText = _activeQuestion!.content.trim();
                final isLongQuestion = questionText.runes.length >= 140;
                final answeredCount = _questionPool
                    .where(_questionHasAnswer)
                    .length;
                final totalQuizSeconds = _quizDuration.inSeconds > 0
                    ? _quizDuration.inSeconds
                    : _initialQuizDurationSeconds;
                final progress = (_remainingTime.inSeconds / totalQuizSeconds)
                    .clamp(0.0, 1.0)
                    .toDouble();
                final screenWidth = MediaQuery.of(context).size.width;
                final horizontalPadding = screenWidth < 390 ? 14.0 : 20.0;

                return ZenPageContainer(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    18,
                  ),
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final router = GoRouter.of(context);
                                final canPopRoute = context.canPop();
                                final shouldLeave = await _confirmLeaveQuiz();
                                if (!mounted) return;

                                if (shouldLeave) {
                                  if (canPopRoute) {
                                    navigator.pop();
                                    return;
                                  }
                                  router.go(AppRoutes.home);
                                }
                              },
                              tooltip: context.t(vi: 'Quay lại', en: 'Back'),
                              padding: EdgeInsets.all(12),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.t(
                                  vi: 'Giải tích 12',
                                  en: 'Calculus 12',
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.timer_outlined, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              _formatDuration(_remainingTime),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      HSLColor.fromColor(
                                            theme.colorScheme.primary,
                                          )
                                          .withLightness(
                                            (HSLColor.fromColor(
                                                      theme.colorScheme.primary,
                                                    ).lightness -
                                                    0.06)
                                                .clamp(0.0, 1.0)
                                                .toDouble(),
                                          )
                                          .toColor(),
                                      theme.colorScheme.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_questionPool.length > 1)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.colorScheme.surfaceContainerHigh,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.t(
                                          vi: 'Câu $currentNumber/${_questionPool.length}',
                                          en: 'Question $currentNumber/${_questionPool.length}',
                                        ),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openQuestionNavigatorSheet(context),
                                      icon: const Icon(
                                        Icons.grid_view_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        context.t(vi: 'Danh sách', en: 'All'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        onPressed: currentIndex > 0
                                            ? () => _moveToAdjacentQuestion(-1)
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                        label: Text(
                                          context.t(vi: 'Trước', en: 'Prev'),
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        onPressed:
                                            currentIndex <
                                                _questionPool.length - 1
                                            ? () => _moveToAdjacentQuestion(1)
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
                                        label: Text(
                                          context.t(vi: 'Sau', en: 'Next'),
                                        ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.t(
                                      vi: 'Đã trả lời: $answeredCount/${_questionPool.length}',
                                      en: 'Answered: $answeredCount/${_questionPool.length}',
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ZenCard(
                          radius: 28,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.surface,
                              theme.colorScheme.surfaceContainerHigh.withValues(
                                alpha: 0.5,
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t(
                                    vi: 'CÂU HỎI SỐ $questionNumber',
                                    en: 'QUESTION $questionNumber',
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.85,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                QuizMathText(
                                  text: _activeQuestion!.content,
                                  textAlign: isLongQuestion
                                      ? TextAlign.left
                                      : TextAlign.center,
                                  style: _questionContentStyle(
                                    theme,
                                    questionText,
                                  ),
                                ),
                                if (formulaText != null &&
                                    formulaText.isNotEmpty) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: QuizMathText(
                                      text: formulaText,
                                      renderAsLatex: true,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: GrowMateLayout.space12),
                        ZenCard(
                          radius: 24,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          color: theme.colorScheme.surfaceContainerLowest,
                          child: QuizAnswerWidgetFactory(
                            question: _activeQuestion!,
                            enabled: !isLoading,
                            showHints: _showHint,
                            textController: _answerController,
                            textFocusNode: _answerFocusNode,
                            onTextChanged: _onAnswerChanged,
                            onTextTap: _signalService.registerInteraction,
                            selectedOptionId: _selectedOptionId,
                            onOptionSelected: (optionId) {
                              _signalService.registerInteraction();
                              setState(() {
                                _selectedOptionId = optionId;
                                _selectedOptionByQuestion[_activeQuestion!.id] =
                                    optionId;
                              });
                            },
                            trueFalseAnswers: _trueFalseAnswers,
                            onTrueFalseChanged: _onTrueFalseChanged,
                          ),
                        ),
                        const SizedBox(height: GrowMateLayout.space12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _toggleHint,
                            icon: Icon(
                              _showHint
                                  ? Icons.visibility_off_rounded
                                  : Icons.lightbulb_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _showHint
                                  ? context.t(vi: 'Ẩn gợi ý', en: 'Hide hint')
                                  : context.t(
                                      vi: 'Hiện gợi ý',
                                      en: 'Show hint',
                                    ),
                            ),
                          ),
                        ),
                        if (_showHint && !_hasInlineGeneralHint())
                          AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              offset: Offset.zero,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer
                                      .withValues(alpha: 0.42),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _hintText(context),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.42,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: GrowMateLayout.space16),
                        ZenButton(
                          label: isLoading
                              ? context.t(
                                  vi: 'Đang gửi...',
                                  en: 'Submitting...',
                                )
                              : context.t(vi: 'Gửi bài', en: 'Submit'),
                          onPressed: isLoading ? null : _submitCurrentAnswer,
                          trailing: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: GrowMateLayout.sectionGap),
                        Center(
                          child: Text(
                            context.t(
                              vi: 'CẦN TRỢ GIÚP TỪ AI TUTOR?',
                              en: 'NEED HELP FROM AI TUTOR?',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _hintText(BuildContext context) {
    final payload = _activeQuestion!.payload;

    return switch (_activeQuestion!.questionType) {
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
