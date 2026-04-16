import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../core/models/signal_batch.dart';
import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../core/services/quiz_session_guard.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_error_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/ai_knowledge_card_widget.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_cubit.dart';
import '../../../agentic_session/presentation/cubit/agentic_session_state.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/quiz_api_repository.dart';
import '../../data/repositories/lives_repository.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';
import '../../../recovery/data/repositories/session_recovery_local.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/lives_cubit.dart';
import '../cubit/lives_state.dart';
import '../cubit/study_mode_cubit.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../data/models/study_mode.dart';
import '../widgets/quiz_answer_widget_factory.dart';
import '../widgets/quiz_math_text.dart';
import '../widgets/afk_overlay.dart';
import '../widgets/spam_warning_dialog.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.quizRepository,
    this.quizApiRepository,
  });

  final QuizRepository quizRepository;
  final QuizApiRepository? quizApiRepository;

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
  LivesCubit? _livesCubit;
  QuizQuestionTemplate? _activeQuestion;

  // Start with empty pool â€” will load from Supabase
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
  bool _isQuestionBankEmpty = false;
  bool _isNavigatingToDiagnosis = false;
  bool _isSubmittingEntireQuiz = false;
  bool _isTimerExpired = false;
  String? _fetchError;
  String? _submitErrorMessage;

  /// True when questions come from backend API (GET /quiz/next) instead of
  /// local Supabase pool. Activated when [quizApiRepository] is non-null.
  bool _isApiDrivenMode = false;
  int _apiQuestionIndex = 0;
  int _apiTotalQuestions = 10;

  Timer? _countdownTimer;
  int _previousLength = 0;
  AgenticSessionCubit? _agenticCubit;
  StreamSubscription<AgenticSessionState>? _agenticSub;
  late final QuizSessionGuard _sessionGuard;
  bool _showAfkOverlay = false;
  StudyMode _studyMode = StudyMode.examPrep;

  @override
  void initState() {
    super.initState();

    _answerFocusNode.addListener(_onAnswerFocusChanged);

    // Sync initial study mode from repository
    StudyModeRepository.instance.getMode().then((mode) {
      if (mounted && mode != _studyMode) {
        setState(() => _studyMode = mode);
      }
    });

    _sessionGuard = QuizSessionGuard(
      onSpamDetected: (count) {
        if (mounted) {
          SpamWarningDialog.show(context, consecutiveCount: count);
        }
      },
      onAfkDetected: () {
        if (mounted) {
          _countdownTimer?.cancel();
          setState(() => _showAfkOverlay = true);
        }
      },
      onAfkResume: () {
        if (mounted) {
          _restartCountdownTimer();
          setState(() => _showAfkOverlay = false);
        }
      },
    );

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

    // Only start countdown timer in exam-prep mode
    if (_studyMode == StudyMode.examPrep) {
      _startCountdownTimer();
    }

    // Load questions from Supabase first, then initialize quiz
    unawaited(_loadQuestionsAndInit());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize LivesCubit from RepositoryProvider.
    if (_livesCubit == null) {
      try {
        final livesRepo = context.read<LivesRepository>();
        _livesCubit = LivesCubit(repository: livesRepo)..loadLives();
      } catch (_) {
        // LivesRepository not provided (mock mode) — lives indicator hidden.
      }
    }

    // Safely try to obtain AgenticSessionCubit — only present when useAgenticBackend = true.
    if (_agenticCubit == null) {
      try {
        _agenticCubit = context.read<AgenticSessionCubit>();
        _agenticSub = _agenticCubit!.stream.listen(_onAgenticStateChanged);
      } catch (_) {
        _agenticCubit = null;
      }
    }
    // Sync study mode from cubit
    try {
      final mode = context.read<StudyModeCubit>().state;
      if (mode != _studyMode) {
        _studyMode = mode;
        if (mode == StudyMode.casual) {
          _countdownTimer?.cancel();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadQuestionsAndInit() async {
    setState(() {
      _isLoadingQuestions = true;
      _isQuestionBankEmpty = false;
      _isNavigatingToDiagnosis = false;
      _fetchError = null;
      _submitErrorMessage = null;
    });

    try {
      // Try API-driven mode when quizApiRepository is available.
      if (widget.quizApiRepository != null) {
        final loaded = await _tryLoadFirstApiQuestion();
        if (loaded) return;
        // Fallback to local pool if API fails.
      }

      final remoteQuestions = await widget.quizRepository
          .fetchQuestionTemplates(limit: 80);

      if (!mounted) return;

      if (remoteQuestions.isEmpty) {
        setState(() {
          _isLoadingQuestions = false;
          _isQuestionBankEmpty = true;
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
        quizApiRepository: widget.quizApiRepository,
        sessionId: widget.quizRepository.sessionId,
      );

      _signalService.startQuestion(questionId: _activeQuestion!.id);
      _sessionGuard.onQuestionShown();

      // Persist pending session for recovery
      unawaited(
        SessionRecoveryLocal.save(<String, dynamic>{
          'sessionId': widget.quizRepository.sessionId,
          'questionCount': _questionPool.length,
          'startedAt': DateTime.now().toIso8601String(),
        }),
      );

      setState(() {
        _quizDuration = quizDuration;
        _remainingTime = quizDuration;
        _isLoadingQuestions = false;
        _isQuestionBankEmpty = false;
      });

      // Bridge to agentic backend when enabled (no-op when cubit is absent)
      unawaited(
        _agenticCubit?.startSession(subject: 'math', topic: 'derivative'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuestions = false;
        _isQuestionBankEmpty = false;
        _fetchError =
            'Không kết nối được với server. Kiểm tra mạng và thử lại.';
      });
    }
  }

  /// Attempt to load the first question from the backend API.
  /// Returns true if successful (API-driven mode activated).
  Future<bool> _tryLoadFirstApiQuestion() async {
    try {
      final sessionId = widget.quizRepository.sessionId;
      final response = await widget.quizApiRepository!.getNextQuestion(
        sessionId: sessionId,
        index: 0,
      );

      if (!mounted) return false;

      if (response.isCompleted || response.nextQuestion == null) {
        return false; // No questions available — fall back to local.
      }

      final apiQ = response.nextQuestion!;
      final question = QuizQuestionTemplate.fromApiResponse(apiQ);

      _isApiDrivenMode = true;
      _apiQuestionIndex = apiQ.index ?? 0;
      _apiTotalQuestions = apiQ.totalQuestions ?? 10;
      _questionPool = [question];
      _activeQuestion = question;

      _quizCubit = QuizCubit(
        quizRepository: widget.quizRepository,
        questionId: question.id,
        questionText: question.content,
        quizApiRepository: widget.quizApiRepository,
        sessionId: sessionId,
      );

      _signalService.startQuestion(questionId: question.id);
      _sessionGuard.onQuestionShown();

      unawaited(
        SessionRecoveryLocal.save(<String, dynamic>{
          'sessionId': sessionId,
          'questionCount': _apiTotalQuestions,
          'startedAt': DateTime.now().toIso8601String(),
        }),
      );

      final timerSec = response.timerSec;
      final quizDuration = timerSec != null && timerSec > 0
          ? Duration(seconds: timerSec * _apiTotalQuestions)
          : const Duration(seconds: _initialQuizDurationSeconds);

      setState(() {
        _quizDuration = quizDuration;
        _remainingTime = quizDuration;
        _isLoadingQuestions = false;
        _isQuestionBankEmpty = false;
      });

      unawaited(
        _agenticCubit?.startSession(subject: 'math', topic: 'derivative'),
      );

      return true;
    } catch (e) {
      debugPrint('⚠️ API question loading failed, falling back to local: $e');
      return false;
    }
  }

  /// Load the next question from the backend API (API-driven mode only).
  Future<void> _loadNextApiQuestion() async {
    if (!_isApiDrivenMode || widget.quizApiRepository == null) return;

    setState(() => _isLoadingQuestions = true);

    try {
      final sessionId = widget.quizRepository.sessionId;
      final nextIndex = _apiQuestionIndex + 1;
      final response = await widget.quizApiRepository!.getNextQuestion(
        sessionId: sessionId,
        index: nextIndex,
        totalQuestions: _apiTotalQuestions,
      );

      if (!mounted) return;

      if (response.isCompleted || response.nextQuestion == null) {
        // Quiz session completed by backend.
        unawaited(SessionRecoveryLocal.clear());
        unawaited(_agenticCubit?.endSession(status: 'completed'));
        if (mounted) {
          context.go(
            '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(sessionId)}',
          );
        }
        return;
      }

      final apiQ = response.nextQuestion!;
      final question = QuizQuestionTemplate.fromApiResponse(apiQ);

      _apiQuestionIndex = apiQ.index ?? nextIndex;
      _activeQuestion = question;
      _questionPool.add(question);

      _quizCubit?.close();
      _quizCubit = QuizCubit(
        quizRepository: widget.quizRepository,
        questionId: question.id,
        questionText: question.content,
        quizApiRepository: widget.quizApiRepository,
        sessionId: sessionId,
      );

      _selectedOptionId = null;
      _trueFalseAnswers = {};
      _answerController.clear();
      _signalService.startQuestion(questionId: question.id);
      _sessionGuard.onQuestionShown();

      setState(() => _isLoadingQuestions = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuestions = false;
        _submitErrorMessage =
            'Không tải được câu hỏi tiếp theo. Vui lòng thử lại.';
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
    _sessionGuard.dispose();
    _agenticSub?.cancel();
    _signalService.stop();
    _answerFocusNode
      ..removeListener(_onAnswerFocusChanged)
      ..dispose();
    _answerController.dispose();
    _quizCubit?.close();
    _livesCubit?.close();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingTime.inSeconds <= 0) {
        if (!_isTimerExpired && _remainingTime.inSeconds <= 0) {
          _countdownTimer?.cancel();
          setState(() => _isTimerExpired = true);
          _showTimerExpiredAndAutoSubmit();
        }
        return;
      }
      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    });
  }

  void _restartCountdownTimer() {
    _startCountdownTimer();
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
              vi: 'Tiến trình sẽ mất. Chắc chưa?',
              en: 'Progress will be lost. Are you sure?',
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

    final shouldLeave = result ?? false;

    // PATCH session as "abandoned" when user confirms leaving.
    if (shouldLeave) {
      unawaited(_agenticCubit?.endSession(status: 'abandoned'));
    }

    return shouldLeave;
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
    _sessionGuard.onQuestionShown();

    setState(() {
      _persistDraftForActiveQuestion();
      _activeQuestion = question;
      _restoreDraftForActiveQuestion();
      _showHint = false;
    });

    _signalService.startQuestion(questionId: question.id);
  }

  void _onTrueFalseChanged(String statementId, bool value) {
    HapticFeedback.lightImpact();
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
            context.t(vi: 'Chọn đáp án trước.', en: 'Select an answer first.'),
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
              vi: 'Chọn Đúng/Sai cho tất cả ý.',
              en: 'Complete all True/False items.',
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

  bool _isValidationSubmitMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('vui lòng') ||
        normalized.contains('please') ||
        normalized.contains('hãy chọn') ||
        normalized.contains('hoàn thành');
  }

  String _localizedQuizMessage(BuildContext context, String message) {
    if (!context.isEnglish) {
      return message;
    }

    final trimmed = message.trim();
    switch (trimmed) {
      case 'Vui lòng nhập kết quả trước khi gửi.':
        return 'Please enter your result before submitting.';
      case 'Không thể gửi bài lúc này. Vui lòng thử lại.':
        return 'Unable to submit right now. Please try again.';
      case 'Vui lòng hoàn thành câu trả lời trước khi gửi.':
        return 'Please complete your answer before submitting.';
      case 'Không thể gửi toàn bộ bài. Vui lòng thử lại.':
        return 'Unable to submit the full quiz. Please try again.';
      default:
        if (_containsVietnameseChars(trimmed)) {
          return 'Unable to submit right now. Please try again.';
        }
        return trimmed;
    }
  }

  bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
  }

  Widget _buildSubmitTransitionCard(BuildContext context) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 18,
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: GrowMateLayout.space12),
          Expanded(
            child: Text(
              context.t(
                vi: 'Đã nhận bài - AI đang phân tích...',
                en: 'Submission received - AI is analyzing...',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitCurrentAnswer() {
    _sessionGuard.onAnswerSubmitted();
    final userAnswer = _buildUserAnswer(context);
    if (userAnswer == null) {
      return;
    }

    setState(() {
      _submitErrorMessage = null;
    });

    HapticFeedback.mediumImpact();
    _signalService.markSubmitted();
    _quizCubit?.submitTypedAnswer(
      question: _activeQuestion!,
      userAnswer: userAnswer,
    );

    // Mirror to agentic backend when enabled
    if (_agenticCubit != null) {
      unawaited(
        _agenticCubit!.submitAnswer(
          questionId: _activeQuestion!.id,
          responseData: _buildAgenticResponseData(userAnswer),
        ),
      );
    }
  }

  /// Builds the response data map for the agentic backend from a typed answer.
  Map<String, dynamic> _buildAgenticResponseData(
    QuizQuestionUserAnswer answer,
  ) {
    if (answer is MultipleChoiceUserAnswer) {
      return <String, dynamic>{'selected_option': answer.selectedOptionId};
    } else if (answer is TrueFalseClusterUserAnswer) {
      return <String, dynamic>{'sub_answers': answer.subAnswers};
    } else if (answer is ShortAnswerUserAnswer) {
      return <String, dynamic>{'answer_text': answer.answerText};
    }
    return <String, dynamic>{};
  }

  /// Handles agentic session state changes from the real-time stream.
  void _onAgenticStateChanged(AgenticSessionState state) {
    if (!mounted) return;
    if (state.isRecovery) {
      final reason = Uri.encodeQueryComponent(
        'Hệ thống AI phát hiện bạn cần nghỉ ngơi.',
      );
      context.go('${AppRoutes.recovery}?reason=$reason');
    }
  }

  int get _answeredCount => _questionPool.where(_questionHasAnswer).length;

  /// Total questions to display in UI. In API mode, use the fixed total
  /// from backend instead of the growing pool length.
  int get _displayTotalQuestions =>
      _isApiDrivenMode ? _apiTotalQuestions : _questionPool.length;

  Future<void> _showTimerExpiredAndAutoSubmit() async {
    if (!mounted) return;
    _persistDraftForActiveQuestion();

    final answered = _answeredCount;
    final total = _displayTotalQuestions;

    // Show countdown dialog before auto-submit
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TimerExpiredDialog(
          answered: answered,
          total: total,
          onSubmit: () => Navigator.of(dialogContext).pop(),
        );
      },
    );

    if (!mounted) return;

    // Flag so the listener navigates to diagnosis instead of loading next question
    _isSubmittingEntireQuiz = true;

    // Auto-submit entire quiz
    _submitCurrentAnswer();
  }

  Future<void> _submitEntireQuiz() async {
    // Persist current active question draft first
    _persistDraftForActiveQuestion();

    final answered = _answeredCount;
    final total = _displayTotalQuestions;

    if (answered == 0) {
      _showInputWarning(
        context,
        context.t(
          vi: 'Trả lời ít nhất 1 câu trước khi nộp.',
          en: 'Answer at least 1 question first.',
        ),
      );
      return;
    }

    final shouldSubmit = await showDialog<bool>(
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
              Icon(
                Icons.assignment_turned_in_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(vi: 'Nộp toàn bộ bài?', en: 'Submit entire quiz?'),
                ),
              ),
            ],
          ),
          content: Text(
            context.t(
              vi: 'Đã trả lời $answered/$total. Nộp bài?',
              en: '$answered/$total answered. Submit?',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.t(vi: 'Quay lại', en: 'Go back'),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.t(
                  vi: 'Nộp bài ($answered câu)',
                  en: 'Submit ($answered answers)',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || !mounted) return;

    // Flag so the listener navigates to diagnosis instead of loading next question
    _isSubmittingEntireQuiz = true;

    // Submit the current active question's answer if it has one
    _submitCurrentAnswer();
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
                  sheetContext.t(vi: 'Chạm để chuyển câu.', en: 'Tap to jump.'),
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

    if (_fetchError != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ZenPageContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZenErrorCard(
                message: _fetchError!,
                onRetry: _loadQuestionsAndInit,
                onDismiss: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      );
    }

    if (_isQuestionBankEmpty || _questionPool.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ZenPageContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZenCard(
                radius: 20,
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: GrowMateLayout.space12),
                    Text(
                      context.t(
                        vi: 'Chưa có câu hỏi. Quay lại sau nhé!',
                        en: 'No questions available. Try later!',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: GrowMateLayout.space16),
                    ZenButton(
                      label: context.t(
                        vi: 'Quay về Trang chủ',
                        en: 'Back to Home',
                      ),
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return BlocProvider<QuizCubit>.value(
      value: _quizCubit!,
      child: BlocListener<StudyModeCubit, StudyMode>(
        listener: (context, mode) {
          setState(() {
            _studyMode = mode;
            if (mode == StudyMode.casual) {
              _countdownTimer?.cancel();
              _isTimerExpired = false;
            } else {
              _restartCountdownTimer();
            }
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _signalService.registerInteraction();
            _sessionGuard.onUserActivity();
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              PopScope(
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
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: context.t(
                        vi: 'Quay về Trang chủ',
                        en: 'Back to Home',
                      ),
                      onPressed: () async {
                        final shouldLeave = await _confirmLeaveQuiz();
                        if (!mounted) return;
                        if (shouldLeave) {
                          // Schedule navigation after current frame to avoid context async gap
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) context.go(AppRoutes.home);
                          });
                        }
                      },
                    ),
                    title: Text(
                      context.t(vi: 'Làm bài', en: 'Quiz'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    centerTitle: true,
                    elevation: 0,
                  ),
                  body: SelectionContainer.disabled(
                    child: BlocConsumer<QuizCubit, QuizCubitState>(
                      listener: (context, state) {
                        if (state is QuizSubmitFailureState) {
                          final localizedMessage = _localizedQuizMessage(
                            context,
                            state.message,
                          );

                          if (_isValidationSubmitMessage(localizedMessage)) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text(localizedMessage)),
                              );

                            setState(() {
                              _isNavigatingToDiagnosis = false;
                              _submitErrorMessage = null;
                            });
                          } else {
                            setState(() {
                              _isNavigatingToDiagnosis = false;
                              _submitErrorMessage = localizedMessage;
                            });
                          }
                        }

                        if (state is QuizSubmitSuccessState) {
                          if (_isNavigatingToDiagnosis) {
                            return;
                          }

                          // Award XP for correct answers
                          if (state.isCorrect && state.xpEarned > 0) {
                            context.read<LeaderboardCubit>().addXp(
                              eventType: 'correct_answer',
                            );
                          }

                          // Refresh lives indicator when backend reports lives change.
                          if (state.livesRemaining != null) {
                            _livesCubit?.loadLives();
                          }

                          // API-driven mode: fetch next question from backend,
                          // UNLESS user chose "Nộp toàn bộ bài" or we reached the total.
                          if (_isApiDrivenMode && !_isSubmittingEntireQuiz) {
                            // Auto-finish if we've reached the total questions
                            if (_questionPool.length >= _apiTotalQuestions) {
                              // Fall through to diagnosis navigation below
                            } else {
                              setState(() => _submitErrorMessage = null);
                              unawaited(_loadNextApiQuestion());
                              return;
                            }
                          }

                          // Reset the flag after consuming it
                          _isSubmittingEntireQuiz = false;

                          setState(() {
                            _isNavigatingToDiagnosis = true;
                            _submitErrorMessage = null;
                          });

                          // Clear pending session on successful submission
                          unawaited(SessionRecoveryLocal.clear());
                          unawaited(
                            _agenticCubit?.endSession(status: 'completed'),
                          );

                          final router = GoRouter.of(context);
                          Future<
                            void
                          >.delayed(const Duration(milliseconds: 900), () {
                            if (!mounted) {
                              return;
                            }

                            router.go(
                              '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(state.submissionId)}',
                            );
                          });
                          return;
                        }

                        if (state is QuizRecoveryTriggeredState) {
                          setState(() {
                            _isNavigatingToDiagnosis = false;
                          });

                          context.go(
                            '${AppRoutes.recovery}?reason=${Uri.encodeQueryComponent(state.reason)}',
                          );
                        }

                        if (state is QuizRateLimitedState) {
                          setState(() {
                            _isNavigatingToDiagnosis = false;
                            _submitErrorMessage = null;
                          });
                          _countdownTimer?.cancel();
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          // Navigate back to home after showing rate limit message
                          final nav = GoRouter.of(context);
                          Future<void>.delayed(const Duration(seconds: 2), () {
                            if (mounted) nav.go(AppRoutes.today);
                          });
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is QuizSubmittingState;
                        final showSubmitTransition =
                            state is QuizSubmitSuccessState ||
                            _isNavigatingToDiagnosis;
                        final disableSubmit =
                            isLoading || _isNavigatingToDiagnosis;
                        final theme = Theme.of(context);
                        final formulaText = _activeQuestion!.metadata['formula']
                            ?.toString();
                        final currentIndex = _questionPool.indexWhere(
                          (item) => item.id == _activeQuestion!.id,
                        );
                        final currentNumber = currentIndex >= 0
                            ? currentIndex + 1
                            : 1;
                        final questionNumber = currentNumber.toString();
                        final questionText = _activeQuestion!.content.trim();
                        final isLongQuestion = questionText.runes.length >= 140;
                        final answeredCount = _questionPool
                            .where(_questionHasAnswer)
                            .length;
                        final totalQuizSeconds = _quizDuration.inSeconds > 0
                            ? _quizDuration.inSeconds
                            : _initialQuizDurationSeconds;
                        final progress =
                            (_remainingTime.inSeconds / totalQuizSeconds)
                                .clamp(0.0, 1.0)
                                .toDouble();
                        final screenWidth = MediaQuery.of(context).size.width;
                        final horizontalPadding = screenWidth < 390
                            ? 14.0
                            : 20.0;

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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _activeQuestion?.topicName ??
                                            context.t(
                                              vi: 'Toán học',
                                              en: 'Mathematics',
                                            ),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (_studyMode == StudyMode.examPrep) ...[
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 22,
                                        color: _isTimerExpired
                                            ? theme.colorScheme.error
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDuration(_remainingTime),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: _isTimerExpired
                                                  ? theme.colorScheme.error
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                    if (_livesCubit != null) ...[
                                      const SizedBox(width: 10),
                                      _LivesIndicator(cubit: _livesCubit!),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    height: 6,
                                    width: double.infinity,
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
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
                                                              theme
                                                                  .colorScheme
                                                                  .primary,
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
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHigh,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                context.t(
                                                  vi: 'Câu $currentNumber/$_displayTotalQuestions',
                                                  en: 'Question $currentNumber/$_displayTotalQuestions',
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _openQuestionNavigatorSheet(
                                                    context,
                                                  ),
                                              icon: const Icon(
                                                Icons.grid_view_rounded,
                                                size: 18,
                                              ),
                                              label: Text(
                                                context.t(
                                                  vi: 'Danh sách',
                                                  en: 'All',
                                                ),
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
                                                    ? () =>
                                                          _moveToAdjacentQuestion(
                                                            -1,
                                                          )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_left_rounded,
                                                ),
                                                label: Text(
                                                  context.t(
                                                    vi: 'Trước',
                                                    en: 'Prev',
                                                  ),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                                    ? () =>
                                                          _moveToAdjacentQuestion(
                                                            1,
                                                          )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_right_rounded,
                                                ),
                                                label: Text(
                                                  context.t(
                                                    vi: 'Sau',
                                                    en: 'Next',
                                                  ),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                              vi: 'Đã trả lời: $answeredCount/$_displayTotalQuestions',
                                              en: 'Answered: $answeredCount/$_displayTotalQuestions',
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ZenCard(
                                  radius: 28,
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    16,
                                    18,
                                    16,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.surface,
                                      theme.colorScheme.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                    ],
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 620,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.t(
                                            vi: 'CÂU HỎI SỐ $questionNumber',
                                            en: 'QUESTION $questionNumber',
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
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
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    14,
                                  ),
                                  color:
                                      theme.colorScheme.surfaceContainerLowest,
                                  child: QuizAnswerWidgetFactory(
                                    question: _activeQuestion!,
                                    enabled: !disableSubmit,
                                    showHints: _showHint,
                                    textController: _answerController,
                                    textFocusNode: _answerFocusNode,
                                    onTextChanged: _onAnswerChanged,
                                    onTextTap:
                                        _signalService.registerInteraction,
                                    selectedOptionId: _selectedOptionId,
                                    onOptionSelected: (optionId) {
                                      HapticFeedback.selectionClick();
                                      _signalService.registerInteraction();
                                      setState(() {
                                        _selectedOptionId = optionId;
                                        _selectedOptionByQuestion[_activeQuestion!
                                                .id] =
                                            optionId;
                                      });
                                    },
                                    trueFalseAnswers: _trueFalseAnswers,
                                    onTrueFalseChanged: _onTrueFalseChanged,
                                  ),
                                ),
                                const SizedBox(height: GrowMateLayout.space12),
                                if (_studyMode == StudyMode.casual) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: disableSubmit
                                          ? null
                                          : _toggleHint,
                                      icon: Icon(
                                        _showHint
                                            ? Icons.visibility_off_rounded
                                            : Icons.lightbulb_outline_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _showHint
                                            ? context.t(
                                                vi: 'Ẩn gợi ý',
                                                en: 'Hide hint',
                                              )
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
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                      child: AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOut,
                                        offset: Offset.zero,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .secondaryContainer
                                                .withValues(alpha: 0.42),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: Text(
                                            _hintText(context),
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.42,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ], // end casual mode hint block
                                // Knowledge cards from agentic RAG
                                if (_showHint) ...[
                                  Builder(
                                    builder: (context) {
                                      final agenticState = context
                                          .select<
                                            AgenticSessionCubit,
                                            AgenticSessionState
                                          >((c) => c.state);
                                      if (!agenticState.hasKnowledge) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: GrowMateLayout.space8,
                                        ),
                                        child: AiKnowledgeCardWidget(
                                          chunks: agenticState.knowledgeChunks,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (_isTimerExpired &&
                                    _studyMode == StudyMode.examPrep) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  ZenCard(
                                    radius: 16,
                                    color: theme.colorScheme.errorContainer
                                        .withValues(alpha: 0.3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer_off_rounded,
                                          color: theme.colorScheme.error,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            context.t(
                                              vi: '⏰ Hết giờ! Nộp hoặc làm tiếp.',
                                              en: '⏰ Time\'s up! Submit or continue.',
                                            ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onErrorContainer,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_submitErrorMessage != null) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  ZenErrorCard(
                                    message: _submitErrorMessage!,
                                    onRetry: disableSubmit
                                        ? null
                                        : _submitCurrentAnswer,
                                    onDismiss: () {
                                      setState(() {
                                        _submitErrorMessage = null;
                                      });
                                    },
                                  ),
                                ],
                                if (showSubmitTransition) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  _buildSubmitTransitionCard(context),
                                ],
                                const SizedBox(height: GrowMateLayout.space16),
                                ZenButton(
                                  label: showSubmitTransition
                                      ? context.t(
                                          vi: 'AI đang phân tích...',
                                          en: 'AI is analyzing...',
                                        )
                                      : disableSubmit
                                      ? context.t(
                                          vi: 'Đang gửi...',
                                          en: 'Submitting...',
                                        )
                                      : context.t(
                                          vi: 'Gửi câu $currentNumber',
                                          en: 'Submit Q$currentNumber',
                                        ),
                                  onPressed: disableSubmit
                                      ? null
                                      : _submitCurrentAnswer,
                                  trailing: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: GrowMateLayout.space12),
                                ZenButton(
                                  label: context.t(
                                    vi: 'Nộp toàn bộ bài ($answeredCount/$_displayTotalQuestions)',
                                    en: 'Submit all ($answeredCount/$_displayTotalQuestions)',
                                  ),
                                  variant: ZenButtonVariant.secondary,
                                  onPressed: disableSubmit
                                      ? null
                                      : _submitEntireQuiz,
                                ),
                                const SizedBox(
                                  height: GrowMateLayout.sectionGap,
                                ),
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
              if (_showAfkOverlay)
                Positioned.fill(
                  child: AfkOverlay(
                    onResume: () {
                      _sessionGuard.onUserActivity();
                    },
                  ),
                ),
            ],
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

/// Countdown dialog shown when quiz timer expires.
class _TimerExpiredDialog extends StatefulWidget {
  const _TimerExpiredDialog({
    required this.answered,
    required this.total,
    required this.onSubmit,
  });

  final int answered;
  final int total;
  final VoidCallback onSubmit;

  @override
  State<_TimerExpiredDialog> createState() => _TimerExpiredDialogState();
}

class _TimerExpiredDialogState extends State<_TimerExpiredDialog> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _countdown -= 1;
      });
      if (_countdown <= 0) {
        _timer?.cancel();
        widget.onSubmit();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.errorContainer,
          ),
          child: Icon(Icons.timer_off_rounded, size: 36, color: colors.error),
        ),
      ),
      title: Text(
        context.t(vi: '⏰ Hết giờ!', en: '⏰ Time\'s up!'),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t(
              vi: 'Đã trả lời ${widget.answered}/${widget.total} câu.',
              en: '${widget.answered}/${widget.total} answered.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            context.t(
              vi: 'Tự động nộp sau $_countdown giây...',
              en: 'Auto-submitting in $_countdown seconds...',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.onSubmit,
            child: Text(context.t(vi: 'Nộp bài ngay', en: 'Submit now')),
          ),
        ),
      ],
    );
  }
}

/// Compact hearts indicator for the quiz header.
class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.cubit});

  final LivesCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LivesCubit, LivesState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is! LivesLoaded) return const SizedBox.shrink();

        final info = state.info;
        final colors = Theme.of(context).colorScheme;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < info.maxLives; i++)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i < info.currentLives
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: i < info.currentLives
                      ? colors.error
                      : colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            if (state.countdownDisplay != null) ...[
              const SizedBox(width: 4),
              Text(
                state.countdownDisplay!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
