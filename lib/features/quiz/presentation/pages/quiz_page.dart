import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../../../../data/models/agentic_models.dart' as agentic_models;
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
  static const String _draftStoragePrefix = 'quiz_draft_bundle_v1';
  static const String _advancedTimelineFlagKey =
      'ff_quiz_advanced_agentic_timeline';
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
  bool _didKickoffInitialLoad = false;
  bool _didResolveResumeRoute = false;
  String? _resumeSessionId;
  int? _resumeStartIndex;
  String? _resumeMode;
  bool? _canPlayOverride;
  int? _nextRegenInSecondsOverride;

  /// True when questions come from backend API (GET /quiz/next) instead of
  /// local Supabase pool. Activated when [quizApiRepository] is non-null.
  bool _isApiDrivenMode = false;
  int _apiQuestionIndex = 0;
  int _apiTotalQuestions = 10;

  Timer? _countdownTimer;
  Timer? _draftPersistDebounce;
  int _previousLength = 0;
  AgenticSessionCubit? _agenticCubit;
  StreamSubscription<AgenticSessionState>? _agenticSub;
  late final QuizSessionGuard _sessionGuard;
  bool _showAfkOverlay = false;
  StudyMode _studyMode = StudyMode.examPrep;
  final SubmitTapLock _submitTapLock = SubmitTapLock();
  bool _draftRestoredFromLocal = false;
  bool _isDraftSyncing = false;
  DateTime? _lastDraftSavedAt;
  bool _isAdvancedAgenticTimelineEnabled = true;
  DateTime? _quizStartedAt;
  DateTime? _firstAnswerAt;
  DateTime? _lastSubmitClickedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_loadClientFlags());

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
              (signal) =>
                  signal.toSupabaseInsert(sessionId: _effectiveSessionId),
            )
            .toList(growable: false),
      );
    });

    // Only start countdown timer in exam-prep mode
    if (_studyMode == StudyMode.examPrep) {
      _startCountdownTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didResolveResumeRoute) {
      _resolveResumeRouteIfNeeded();
    }

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

    if (!_didKickoffInitialLoad) {
      _didKickoffInitialLoad = true;
      unawaited(_loadQuestionsAndInit());
    }
  }

  String get _effectiveSessionId {
    final resumeSessionId = _resumeSessionId?.trim();
    if (resumeSessionId != null && resumeSessionId.isNotEmpty) {
      return resumeSessionId;
    }
    return widget.quizRepository.sessionId;
  }

  String? get _effectiveQuizMode {
    final mode = _resumeMode?.trim();
    if (mode == null || mode.isEmpty) {
      return null;
    }
    return mode;
  }

  bool get _isSubmitBlockedByLives {
    if (_canPlayOverride == false) {
      return true;
    }

    final livesState = _livesCubit?.state;
    if (livesState is LivesLoaded && !livesState.canPlay) {
      return true;
    }

    return false;
  }

  void _resolveResumeRouteIfNeeded() {
    _didResolveResumeRoute = true;

    final uri = GoRouterState.of(context).uri;
    final query = uri.queryParameters;
    if (!_isTruthyFlag(query['resume'])) {
      return;
    }

    final sessionId = query['session_id']?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      _resumeSessionId = sessionId;
    }

    final startIndex = int.tryParse(query['next_index'] ?? '');
    if (startIndex != null && startIndex >= 0) {
      _resumeStartIndex = startIndex;
    }

    final mode = query['mode']?.trim();
    if (mode != null && mode.isNotEmpty) {
      _resumeMode = mode;
    }

    _trackQuizEvent(
      'session_resumed',
      data: <String, Object?>{
        'session_id': _resumeSessionId,
        'next_index': _resumeStartIndex,
        'mode': _resumeMode,
      },
    );
  }

  bool _isTruthyFlag(String? raw) {
    if (raw == null) {
      return false;
    }
    final normalized = raw.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
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
        sessionId: _effectiveSessionId,
      );

      _signalService.startQuestion(questionId: _activeQuestion!.id);
      _sessionGuard.onQuestionShown();
      await _restoreLocalDraftBundle(_effectiveSessionId);
      _quizStartedAt = DateTime.now();
      _firstAnswerAt = null;
      _lastSubmitClickedAt = null;
      _trackQuizEvent(
        'quiz_started',
        data: <String, Object?>{
          'source': 'local_pool',
          'question_count': _questionPool.length,
          'mode': _studyMode.name,
        },
      );

      // Persist pending session for recovery
      unawaited(_persistPendingSession(status: 'in_progress'));

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
      final sessionId = _effectiveSessionId;
      final startIndex = _resumeStartIndex ?? 0;
      final response = await widget.quizApiRepository!.getNextQuestion(
        sessionId: sessionId,
        index: startIndex,
        mode: _effectiveQuizMode,
      );

      if (!mounted) return false;

      if (response.isCompleted || response.nextQuestion == null) {
        return false; // No questions available — fall back to local.
      }

      final apiQ = response.nextQuestion!;
      final question = QuizQuestionTemplate.fromApiResponse(apiQ);

      _isApiDrivenMode = true;
      _apiQuestionIndex = apiQ.index ?? startIndex;
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
      await _restoreLocalDraftBundle(sessionId);
      _quizStartedAt = DateTime.now();
      _firstAnswerAt = null;
      _lastSubmitClickedAt = null;
      _trackQuizEvent(
        'quiz_started',
        data: <String, Object?>{
          'source': 'api',
          'question_index': _apiQuestionIndex,
          'total_questions': _apiTotalQuestions,
          'mode': _studyMode.name,
        },
      );

      unawaited(_persistPendingSession(status: 'in_progress'));

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
      final sessionId = _effectiveSessionId;
      final nextIndex = _apiQuestionIndex + 1;
      final response = await widget.quizApiRepository!.getNextQuestion(
        sessionId: sessionId,
        index: nextIndex,
        totalQuestions: _apiTotalQuestions,
        mode: _effectiveQuizMode,
      );

      if (!mounted) return;

      if (response.isCompleted || response.nextQuestion == null) {
        // Quiz session completed by backend.
        _trackQuizEvent(
          'quiz_completed',
          data: <String, Object?>{
            'total_quiz_duration': _elapsedMsSince(_quizStartedAt),
            'source': 'api_complete',
          },
        );
        unawaited(SessionRecoveryLocal.clear());
        unawaited(_clearLocalDraftBundle());
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
      unawaited(_persistPendingSession(status: 'in_progress'));

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
    _draftPersistDebounce?.cancel();
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
    if (!_hasAnyAnswers) {
      await SessionRecoveryLocal.clear();
      return true;
    }

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
      await SessionRecoveryLocal.clear();
      await _clearLocalDraftBundle();
      unawaited(_agenticCubit?.endSession(status: 'abandoned'));
    }

    return shouldLeave;
  }

  void _onAnswerChanged(String value) {
    _quizCubit?.onAnswerChanged(value);

    if (_firstAnswerAt == null && value.trim().isNotEmpty) {
      _firstAnswerAt = DateTime.now();
      _trackQuizEvent(
        'time_to_first_answer',
        data: <String, Object?>{
          'duration_ms': _elapsedMsSince(_quizStartedAt),
          'question_id': _activeQuestion?.id,
        },
      );
    }

    if (_activeQuestion!.questionType == QuizQuestionType.shortAnswer) {
      _shortAnswerDraftByQuestion[_activeQuestion!.id] = value;
      _scheduleDraftPersist();
    }

    final currentLength = value.length;

    if (currentLength > _previousLength) {
      _signalService.recordTypingDelta(currentLength - _previousLength);
    } else if (currentLength < _previousLength) {
      final correctionCount = _previousLength - currentLength;
      _signalService.recordCorrectionCount(correctionCount);
    }

    _previousLength = currentLength;
    _trackQuizEvent(
      'answer_changed',
      data: <String, Object?>{
        'question_id': _activeQuestion?.id,
        'question_type': _activeQuestion?.questionType.name,
        'answer_length': value.length,
      },
    );
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
    unawaited(_persistPendingSession(status: 'in_progress'));
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
    if (_firstAnswerAt == null) {
      _firstAnswerAt = DateTime.now();
      _trackQuizEvent(
        'time_to_first_answer',
        data: <String, Object?>{
          'duration_ms': _elapsedMsSince(_quizStartedAt),
          'question_id': _activeQuestion?.id,
        },
      );
    }
    _trackQuizEvent(
      'answer_changed',
      data: <String, Object?>{
        'question_id': _activeQuestion?.id,
        'question_type': _activeQuestion?.questionType.name,
        'statement_id': statementId,
        'value': value,
      },
    );
    _scheduleDraftPersist();
  }

  String _draftStorageKey(String sessionId) {
    return '${_draftStoragePrefix}_${sessionId.trim()}';
  }

  bool _tryAcquireSubmitTapLock() {
    if (!_submitTapLock.tryAcquire()) {
      return false;
    }
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        _submitTapLock.release();
      }),
    );
    return true;
  }

  void _scheduleDraftPersist() {
    _draftPersistDebounce?.cancel();
    if (mounted && !_isDraftSyncing) {
      setState(() {
        _isDraftSyncing = true;
      });
    }
    _draftPersistDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_persistPendingSession(status: 'in_progress'));
    });
  }

  Future<void> _loadClientFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_advancedTimelineFlagKey) ?? true;
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdvancedAgenticTimelineEnabled = enabled;
    });
  }

  Future<void> _setAdvancedTimelineEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_advancedTimelineFlagKey, enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdvancedAgenticTimelineEnabled = enabled;
    });
    _trackQuizEvent(
      'feature_flag_changed',
      data: <String, Object?>{
        'flag': _advancedTimelineFlagKey,
        'enabled': enabled,
      },
    );
  }

  void _trackQuizEvent(
    String eventName, {
    Map<String, Object?> data = const {},
  }) {
    final payload = <String, Object?>{
      'event': eventName,
      'session_id': _effectiveSessionId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...data,
    };
    debugPrint('QUIZ_EVENT ${jsonEncode(payload)}');
  }

  int? _elapsedMsSince(DateTime? start) {
    if (start == null) {
      return null;
    }
    return DateTime.now().difference(start).inMilliseconds;
  }

  Future<void> _clearLocalDraftBundle() async {
    final sessionId = _effectiveSessionId.trim();
    if (sessionId.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftStorageKey(sessionId));
  }

  Future<void> _saveLocalDraftBundle({
    required String sessionId,
    required String status,
  }) async {
    final trimmedSessionId = sessionId.trim();
    if (trimmedSessionId.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'sessionId': trimmedSessionId,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'status': status,
      'selectedOptionByQuestion': Map<String, String>.from(
        _selectedOptionByQuestion,
      ),
      'shortAnswerDraftByQuestion': Map<String, String>.from(
        _shortAnswerDraftByQuestion,
      ),
      'trueFalseDraftByQuestion': _trueFalseDraftByQuestion.map(
        (k, v) => MapEntry(k, v.map((sk, sv) => MapEntry(sk, sv))),
      ),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _draftStorageKey(trimmedSessionId),
        jsonEncode(payload),
      );
      if (!mounted) return;
      setState(() {
        _draftRestoredFromLocal = false;
        _isDraftSyncing = false;
        _lastDraftSavedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDraftSyncing = false;
      });
    }
  }

  Future<void> _restoreLocalDraftBundle(String sessionId) async {
    final trimmedSessionId = sessionId.trim();
    if (trimmedSessionId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftStorageKey(trimmedSessionId));
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final selectedRaw = decoded['selectedOptionByQuestion'];
      if (selectedRaw is Map) {
        _selectedOptionByQuestion
          ..clear()
          ..addAll(
            selectedRaw.map<String, String>(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          );
      }

      final shortRaw = decoded['shortAnswerDraftByQuestion'];
      if (shortRaw is Map) {
        _shortAnswerDraftByQuestion
          ..clear()
          ..addAll(
            shortRaw.map<String, String>(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          );
      }

      final trueFalseRaw = decoded['trueFalseDraftByQuestion'];
      if (trueFalseRaw is Map) {
        _trueFalseDraftByQuestion
          ..clear()
          ..addAll(
            trueFalseRaw.map<String, Map<String, bool>>((key, value) {
              if (value is! Map) {
                return MapEntry(key.toString(), <String, bool>{});
              }
              return MapEntry(
                key.toString(),
                value.map<String, bool>(
                  (subKey, subValue) =>
                      MapEntry(subKey.toString(), subValue == true),
                ),
              );
            }),
          );
      }

      _restoreDraftForActiveQuestion();
      if (mounted) {
        setState(() {
          _draftRestoredFromLocal = true;
          _isDraftSyncing = false;
        });
      }
      _trackQuizEvent(
        'answer_restored',
        data: <String, Object?>{
          'multiple_choice_count': _selectedOptionByQuestion.length,
          'short_answer_count': _shortAnswerDraftByQuestion.length,
          'true_false_count': _trueFalseDraftByQuestion.length,
        },
      );
    } catch (_) {
      await prefs.remove(_draftStorageKey(trimmedSessionId));
    }
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
    if (!_tryAcquireSubmitTapLock()) {
      return;
    }

    _lastSubmitClickedAt = DateTime.now();
    _trackQuizEvent(
      'submit_clicked',
      data: <String, Object?>{
        'scope': 'single',
        'question_id': _activeQuestion?.id,
        'answered_count': _answeredCount,
      },
    );

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
    _syncDraftForQuestion(_activeQuestion!.id, userAnswer);
    unawaited(_persistPendingSession(status: 'in_progress'));

    if (_isApiDrivenMode) {
      if (_apiQuestionIndex >= _submissionTargetCount - 1) {
        _showInputWarning(
          context,
          context.t(
            vi: 'Đã lưu câu cuối. Nhấn "Nộp toàn bộ bài" để AI chấm cả bài.',
            en: 'Final answer saved. Tap "Submit all" for AI grading.',
          ),
        );
        return;
      }

      unawaited(_loadNextApiQuestion());
      return;
    }

    final currentIndex = _questionPool.indexWhere(
      (item) => item.id == _activeQuestion!.id,
    );

    if (currentIndex >= 0 && currentIndex < _submissionTargetCount - 1) {
      _moveToAdjacentQuestion(1);
    } else {
      _showInputWarning(
        context,
        context.t(
          vi: 'Đã lưu đủ câu. Nhấn "Nộp toàn bộ bài" để AI chấm.',
          en: 'Required answers saved. Tap "Submit all" for AI grading.',
        ),
      );
    }
  }

  void _syncDraftForQuestion(String questionId, QuizQuestionUserAnswer answer) {
    switch (answer) {
      case MultipleChoiceUserAnswer(:final selectedOptionId):
        _selectedOptionByQuestion[questionId] = selectedOptionId;
      case TrueFalseClusterUserAnswer(:final subAnswers):
        _trueFalseDraftByQuestion[questionId] = Map<String, bool>.from(
          subAnswers,
        );
      case ShortAnswerUserAnswer(:final answerText):
        _shortAnswerDraftByQuestion[questionId] = answerText;
    }
  }

  QuizQuestionUserAnswer? _buildAnswerFromDraft(QuizQuestionTemplate question) {
    switch (question.questionType) {
      case QuizQuestionType.multipleChoice:
        final selected = _selectedOptionByQuestion[question.id]?.trim();
        if (selected == null || selected.isEmpty) {
          return null;
        }
        return MultipleChoiceUserAnswer(selectedOptionId: selected);
      case QuizQuestionType.trueFalseCluster:
        final payload = question.payload;
        if (payload is! TrueFalseClusterPayload) {
          return null;
        }
        final answers = Map<String, bool>.from(
          _trueFalseDraftByQuestion[question.id] ?? const <String, bool>{},
        );
        if (answers.length < payload.subQuestions.length) {
          return null;
        }
        return TrueFalseClusterUserAnswer(subAnswers: answers);
      case QuizQuestionType.shortAnswer:
        final value = _shortAnswerDraftByQuestion[question.id]?.trim() ?? '';
        if (value.isEmpty) {
          return null;
        }
        return ShortAnswerUserAnswer(answerText: value);
    }
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

  /// Number of answers required before triggering AI grading.
  int get _submissionTargetCount {
    if (_isApiDrivenMode) {
      return _apiTotalQuestions;
    }
    return math.min(10, _questionPool.length);
  }

  bool get _hasSavedAnswersForSubmissionTarget {
    final target = _submissionTargetCount;
    if (target <= 0 || _questionPool.length < target) {
      return false;
    }

    final submissionQuestions = _questionPool
        .take(target)
        .toList(growable: false);
    return submissionQuestions.every((question) {
      return _buildAnswerFromDraft(question) != null;
    });
  }

  int get _activeQuestionIndexForPending {
    if (_isApiDrivenMode) {
      return _apiQuestionIndex;
    }
    if (_activeQuestion == null) {
      return 0;
    }
    final index = _questionPool.indexWhere((q) => q.id == _activeQuestion!.id);
    return index < 0 ? 0 : index;
  }

  Future<void> _persistPendingSession({required String status}) async {
    final sessionId = _effectiveSessionId;
    if (sessionId.trim().isEmpty) {
      return;
    }

    final totalQuestions = math.max(
      _isApiDrivenMode ? _apiTotalQuestions : _questionPool.length,
      1,
    );
    final boundedIndex = _activeQuestionIndexForPending
        .clamp(0, totalQuestions - 1)
        .toInt();

    await SessionRecoveryLocal.saveSnapshot(
      sessionId: sessionId,
      lastQuestionIndex: boundedIndex,
      totalQuestions: totalQuestions,
      status: status,
    );

    await _saveLocalDraftBundle(sessionId: sessionId, status: status);
  }

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

    // Auto-submit full batch when timer expires.
    await _submitEntireQuiz();
  }

  Future<void> _submitEntireQuiz() async {
    if (!_tryAcquireSubmitTapLock()) {
      return;
    }

    _lastSubmitClickedAt = DateTime.now();
    _trackQuizEvent(
      'submit_clicked',
      data: <String, Object?>{
        'scope': 'batch',
        'answered_count': _answeredCount,
        'target_count': _submissionTargetCount,
      },
    );

    // Persist current active question draft first
    _persistDraftForActiveQuestion();

    final activeAnswer = _buildUserAnswer(context);
    if (activeAnswer == null) {
      return;
    }
    _syncDraftForQuestion(_activeQuestion!.id, activeAnswer);

    final submissionQuestions = _questionPool
        .take(_submissionTargetCount)
        .toList(growable: false);

    final total = submissionQuestions.length;
    final answered = submissionQuestions.where(_questionHasAnswer).length;

    if (total == 0) {
      _showInputWarning(
        context,
        context.t(
          vi: 'Không có câu hỏi để nộp.',
          en: 'No questions available for submission.',
        ),
      );
      return;
    }

    if (answered < total) {
      final firstMissing = submissionQuestions.firstWhere(
        (q) => !_questionHasAnswer(q),
      );
      _selectQuestion(firstMissing);
      _showInputWarning(
        context,
        context.t(
          vi: 'Bạn cần trả lời đủ $total/$total câu trước khi nộp.',
          en: 'Please answer all $total/$total questions before submitting.',
        ),
      );
      return;
    }

    final answerEntries = <Map<String, dynamic>>[];
    for (final question in submissionQuestions) {
      final answer = _buildAnswerFromDraft(question);
      if (answer == null) {
        _selectQuestion(question);
        _showInputWarning(
          context,
          context.t(
            vi: 'Thiếu dữ liệu câu trả lời ở một số câu. Vui lòng kiểm tra lại.',
            en: 'Some answers are incomplete. Please review and try again.',
          ),
        );
        return;
      }

      answerEntries.add(<String, dynamic>{
        'question_id': question.id,
        'answer': jsonEncode(answer.toJson()),
      });
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
                  vi: 'Nộp bài ($total câu)',
                  en: 'Submit ($total answers)',
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
    setState(() {
      _isNavigatingToDiagnosis = true;
      _submitErrorMessage = null;
    });

    _quizCubit?.submitAllAnswers(answerEntries);
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
                          _trackQuizEvent(
                            'submit_failed',
                            data: <String, Object?>{
                              'scope': _isSubmittingEntireQuiz
                                  ? 'batch'
                                  : 'single',
                              'error': state.message,
                              'submit_latency_client': _elapsedMsSince(
                                _lastSubmitClickedAt,
                              ),
                            },
                          );
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

                        if (state is QuizBatchSubmittingState) {
                          _trackQuizEvent(
                            'submit_in_flight',
                            data: <String, Object?>{'scope': 'batch'},
                          );
                          setState(() {
                            _isNavigatingToDiagnosis = true;
                            _submitErrorMessage = null;
                          });
                        }

                        if (state is QuizSubmitSuccessState) {
                          _trackQuizEvent(
                            'submit_succeeded',
                            data: <String, Object?>{
                              'scope': _isSubmittingEntireQuiz
                                  ? 'batch'
                                  : 'single',
                              'submit_latency_client': _elapsedMsSince(
                                _lastSubmitClickedAt,
                              ),
                              'is_correct': state.isCorrect,
                              'xp_earned': state.xpEarned,
                            },
                          );
                          if (_isSubmittingEntireQuiz) {
                            _trackQuizEvent(
                              'quiz_completed',
                              data: <String, Object?>{
                                'total_quiz_duration': _elapsedMsSince(
                                  _quizStartedAt,
                                ),
                              },
                            );
                          }
                          if (_isNavigatingToDiagnosis) {
                            return;
                          }

                          if (state.canPlay != null ||
                              state.nextRegenInSeconds != null) {
                            setState(() {
                              _canPlayOverride =
                                  state.canPlay ?? _canPlayOverride;
                              _nextRegenInSecondsOverride =
                                  state.nextRegenInSeconds ??
                                  _nextRegenInSecondsOverride;
                            });
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
                          unawaited(_clearLocalDraftBundle());
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

                        if (state is QuizBatchSubmitSuccessState) {
                          _trackQuizEvent(
                            'submit_succeeded',
                            data: <String, Object?>{
                              'scope': 'batch',
                              'submit_latency_client': _elapsedMsSince(
                                _lastSubmitClickedAt,
                              ),
                            },
                          );
                          _trackQuizEvent(
                            'quiz_completed',
                            data: <String, Object?>{
                              'total_quiz_duration': _elapsedMsSince(
                                _quizStartedAt,
                              ),
                            },
                          );
                          _isSubmittingEntireQuiz = false;

                          setState(() {
                            _isNavigatingToDiagnosis = true;
                            _submitErrorMessage = null;
                          });

                          unawaited(SessionRecoveryLocal.clear());
                          unawaited(_clearLocalDraftBundle());
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
                              '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(_effectiveSessionId)}',
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

                        if (state is QuizNoLivesState) {
                          final nextRegenInSeconds =
                              state.nextRegenInSeconds ??
                              _nextRegenInSecondsOverride;
                          final noLivesMessage = _buildNoLivesMessage(
                            context,
                            nextRegenInSeconds,
                          );

                          setState(() {
                            _isNavigatingToDiagnosis = false;
                            _canPlayOverride = false;
                            _nextRegenInSecondsOverride = nextRegenInSeconds;
                            _submitErrorMessage = noLivesMessage;
                          });

                          _countdownTimer?.cancel();
                          unawaited(_livesCubit?.loadLives());

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(noLivesMessage),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                        }
                      },
                      builder: (context, state) {
                        final isLoading =
                            state is QuizSubmittingState ||
                            state is QuizBatchSubmittingState;
                        final showSubmitTransition =
                            state is QuizSubmitSuccessState ||
                            state is QuizBatchSubmitSuccessState ||
                            _isNavigatingToDiagnosis;
                        final isBlockedByLives = _isSubmitBlockedByLives;
                        final livesState = _livesCubit?.state;
                        final fallbackRegenSeconds = livesState is LivesLoaded
                            ? livesState.info.nextRegenIn?.inSeconds
                            : null;
                        final nextRegenInSeconds =
                            _nextRegenInSecondsOverride ?? fallbackRegenSeconds;
                        final noLivesMessage = _buildNoLivesMessage(
                          context,
                          nextRegenInSeconds,
                        );
                        final noLivesCountdown = _buildNoLivesCountdownLabel(
                          context,
                          nextRegenInSeconds,
                        );
                        final noLivesLivesLabel = livesState is LivesLoaded
                            ? context.t(
                                vi: 'Tim hiện tại: ${livesState.info.currentLives}/${livesState.info.maxLives}',
                                en: 'Current lives: ${livesState.info.currentLives}/${livesState.info.maxLives}',
                              )
                            : null;
                        final disableSubmit =
                            isLoading ||
                            _isNavigatingToDiagnosis ||
                            isBlockedByLives;
                        final theme = Theme.of(context);
                        final formulaText = _activeQuestion!.metadata['formula']
                            ?.toString();
                        final currentIndex = _questionPool.indexWhere(
                          (item) => item.id == _activeQuestion!.id,
                        );
                        final currentNumber = currentIndex >= 0
                            ? currentIndex + 1
                            : 1;
                        final questionText = _activeQuestion!.content.trim();
                        final isLongQuestion = questionText.runes.length >= 140;
                        final submissionTargetCount = _submissionTargetCount;
                        final answeredCount = _questionPool
                            .take(submissionTargetCount)
                            .where(_questionHasAnswer)
                            .length;
                        final showSubmitAllButton =
                            answeredCount >= submissionTargetCount &&
                            _hasSavedAnswersForSubmissionTarget;
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
                                if (_displayTotalQuestions > 0)
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
                                            if (_questionPool.length > 1)
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
                                        if (_questionPool.length > 1) ...[
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
                                                          _questionPool.length -
                                                              1
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
                                        ],
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            context.t(
                                              vi: 'Đã trả lời: $answeredCount/$submissionTargetCount',
                                              en: 'Answered: $answeredCount/$submissionTargetCount',
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
                                        if (_draftRestoredFromLocal ||
                                            _isDraftSyncing ||
                                            _lastDraftSavedAt != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _isDraftSyncing
                                                    ? context.t(
                                                        vi: 'Đang đồng bộ bản nháp cục bộ',
                                                        en: 'Syncing local draft',
                                                      )
                                                    : _draftRestoredFromLocal
                                                    ? context.t(
                                                        vi: 'Đã khôi phục bản nháp cục bộ',
                                                        en: 'Local draft restored',
                                                      )
                                                    : context.t(
                                                        vi: 'Đã lưu bản nháp cục bộ',
                                                        en: 'Local draft saved',
                                                      ),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .tertiary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
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
                                  child: RepaintBoundary(
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
                                        if (_firstAnswerAt == null) {
                                          _firstAnswerAt = DateTime.now();
                                          _trackQuizEvent(
                                            'time_to_first_answer',
                                            data: <String, Object?>{
                                              'duration_ms': _elapsedMsSince(
                                                _quizStartedAt,
                                              ),
                                              'question_id':
                                                  _activeQuestion?.id,
                                            },
                                          );
                                        }
                                        _trackQuizEvent(
                                          'answer_changed',
                                          data: <String, Object?>{
                                            'question_id': _activeQuestion?.id,
                                            'question_type': _activeQuestion
                                                ?.questionType
                                                .name,
                                            'selected_option_id': optionId,
                                          },
                                        );
                                        _scheduleDraftPersist();
                                      },
                                      trueFalseAnswers: _trueFalseAnswers,
                                      onTrueFalseChanged: _onTrueFalseChanged,
                                    ),
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
                                          child: QuizMathText(
                                            text: _hintText(context),
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
                                if (_agenticCubit != null) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  RepaintBoundary(
                                    child:
                                        BlocBuilder<
                                          AgenticSessionCubit,
                                          AgenticSessionState
                                        >(
                                          bloc: _agenticCubit,
                                          buildWhen: (previous, current) {
                                            return previous.phase !=
                                                    current.phase ||
                                                previous.stepCount !=
                                                    current.stepCount ||
                                                previous.currentContent !=
                                                    current.currentContent ||
                                                previous.currentAction !=
                                                    current.currentAction ||
                                                previous.reasoningTrace !=
                                                    current.reasoningTrace ||
                                                previous.reasoningConfidence !=
                                                    current
                                                        .reasoningConfidence ||
                                                previous.beliefEntropy !=
                                                    current.beliefEntropy ||
                                                previous.academicState !=
                                                    current.academicState ||
                                                previous.empathyState !=
                                                    current.empathyState ||
                                                previous.strategyState !=
                                                    current.strategyState;
                                          },
                                          builder: (context, agenticState) {
                                            return _isAdvancedAgenticTimelineEnabled
                                                ? _AgenticProcessCard(
                                                    state: agenticState,
                                                    onDisableAdvanced: () {
                                                      unawaited(
                                                        _setAdvancedTimelineEnabled(
                                                          false,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : _AgenticProcessCompactCard(
                                                    state: agenticState,
                                                    onEnableAdvanced: () {
                                                      unawaited(
                                                        _setAdvancedTimelineEnabled(
                                                          true,
                                                        ),
                                                      );
                                                    },
                                                  );
                                          },
                                        ),
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
                                    onRetry:
                                        isLoading || _isNavigatingToDiagnosis
                                        ? null
                                        : isBlockedByLives
                                        ? () => _livesCubit?.loadLives()
                                        : _submitCurrentAnswer,
                                    onDismiss: () {
                                      setState(() {
                                        _submitErrorMessage = null;
                                      });
                                    },
                                  ),
                                ],
                                if (isBlockedByLives) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  _NoLivesActionCard(
                                    message: noLivesMessage,
                                    countdownLabel: noLivesCountdown,
                                    livesLabel: noLivesLivesLabel,
                                    onRefreshLives: () =>
                                        _livesCubit?.loadLives(),
                                    onGoProgress: () =>
                                        context.go(AppRoutes.progress),
                                    onGoReview: () =>
                                        context.go(AppRoutes.spacedReview),
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
                                      : isLoading || _isNavigatingToDiagnosis
                                      ? context.t(
                                          vi: 'Đang gửi...',
                                          en: 'Submitting...',
                                        )
                                      : isBlockedByLives
                                      ? context.t(
                                          vi: 'Hết tim - chờ hồi sinh',
                                          en: 'No lives - waiting to regen',
                                        )
                                      : context.t(
                                          vi:
                                              currentNumber <
                                                  submissionTargetCount
                                              ? 'Lưu & sang câu ${currentNumber + 1}'
                                              : 'Lưu câu $currentNumber',
                                          en:
                                              currentNumber <
                                                  submissionTargetCount
                                              ? 'Save & go to Q${currentNumber + 1}'
                                              : 'Save Q$currentNumber',
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
                                if (showSubmitAllButton) ...[
                                  const SizedBox(
                                    height: GrowMateLayout.space12,
                                  ),
                                  ZenButton(
                                    label: context.t(
                                      vi: 'Nộp toàn bộ bài ($answeredCount/$submissionTargetCount)',
                                      en: 'Submit all ($answeredCount/$submissionTargetCount)',
                                    ),
                                    variant: ZenButtonVariant.secondary,
                                    onPressed: disableSubmit
                                        ? null
                                        : _submitEntireQuiz,
                                  ),
                                ],
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

  String _buildNoLivesMessage(BuildContext context, int? nextRegenInSeconds) {
    if (nextRegenInSeconds == null || nextRegenInSeconds <= 0) {
      return context.t(
        vi: 'Bạn đã hết tim! Hãy chờ hồi sinh hoặc xem lại bài cũ nhé.',
        en: 'You are out of lives. Please wait for regen or review previous lessons.',
      );
    }

    final duration = Duration(seconds: nextRegenInSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final countdown = hours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';

    return context.t(
      vi: 'Bạn đã hết tim. Tim tiếp theo hồi sau $countdown.',
      en: 'You are out of lives. Next life regenerates in $countdown.',
    );
  }

  String? _buildNoLivesCountdownLabel(
    BuildContext context,
    int? nextRegenInSeconds,
  ) {
    if (nextRegenInSeconds == null || nextRegenInSeconds <= 0) {
      return null;
    }

    final duration = Duration(seconds: nextRegenInSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final countdown = hours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
    return context.t(
      vi: 'Hồi tim sau: $countdown',
      en: 'Next regen: $countdown',
    );
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

enum ReasoningStepStatus { running, completed, failed, fallback }

class SubmitTapLock {
  bool _locked = false;

  bool get isLocked => _locked;

  bool tryAcquire() {
    if (_locked) {
      return false;
    }
    _locked = true;
    return true;
  }

  void release() {
    _locked = false;
  }
}

String inferAgentBucketFromReasoningStep(agentic_models.ReasoningStep step) {
  final tool = step.tool.toLowerCase();
  if (tool.contains('academic')) {
    return 'academic';
  }
  if (tool.contains('empathy')) {
    return 'empathy';
  }
  return 'strategy';
}

ReasoningStepStatus inferReasoningStepStatus(
  agentic_models.ReasoningStep step, {
  required bool isLast,
  required bool isLoading,
}) {
  final summary = step.resultSummary.toLowerCase();
  if (summary.contains('error') || summary.contains('fail')) {
    return ReasoningStepStatus.failed;
  }
  if (summary.contains('fallback') || summary.contains('degrade')) {
    return ReasoningStepStatus.fallback;
  }
  if (isLoading && isLast) {
    return ReasoningStepStatus.running;
  }
  return ReasoningStepStatus.completed;
}

class _AgenticProcessCard extends StatefulWidget {
  const _AgenticProcessCard({
    required this.state,
    required this.onDisableAdvanced,
  });

  final AgenticSessionState state;
  final VoidCallback onDisableAdvanced;

  @override
  State<_AgenticProcessCard> createState() => _AgenticProcessCardState();
}

class _AgenticProcessCardState extends State<_AgenticProcessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final Set<String> _enabledAgentFilters = <String>{
    'academic',
    'empathy',
    'strategy',
  };
  final Set<int> _expandedSteps = <int>{};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final state = widget.state;
    final reasoningSteps = state.reasoningTrace
        .take(30)
        .toList(growable: false);
    final filteredReasoningSteps = reasoningSteps
        .where(
          (step) => _enabledAgentFilters.contains(
            inferAgentBucketFromReasoningStep(step),
          ),
        )
        .take(12)
        .toList(growable: false);
    final confidencePercent = state.reasoningConfidence == null
        ? null
        : (state.reasoningConfidence!.clamp(0.0, 1.0) * 100).round();
    final latencyMs = state.lastOrchestratorStep?.latencyMs;

    final academic = state.academicState;
    final empathy = state.empathyState;
    final strategy = state.strategyState;

    return ZenCard(
      radius: 18,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hub_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Timeline Agentic AI (Realtime)',
                    en: 'Agentic AI realtime timeline',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.t(
                  vi: 'Tắt timeline nâng cao',
                  en: 'Disable advanced timeline',
                ),
                onPressed: widget.onDisableAdvanced,
                icon: const Icon(Icons.tune_rounded, size: 18),
              ),
              if (reduceMotion)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isLoading
                        ? theme.colorScheme.primary
                        : theme.colorScheme.tertiary,
                  ),
                )
              else
                FadeTransition(
                  opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isLoading
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AgenticChip(
                label: context.t(
                  vi: 'Pha: ${_phaseLabel(context, state.phase)}',
                  en: 'Phase: ${state.phase.name}',
                ),
              ),
              _AgenticChip(
                label: context.t(
                  vi: 'Mode: ${state.reasoningMode}',
                  en: 'Mode: ${state.reasoningMode}',
                ),
              ),
              _AgenticChip(
                label: context.t(
                  vi: 'Step: ${state.stepCount}',
                  en: 'Step: ${state.stepCount}',
                ),
              ),
              if (state.currentAction != null &&
                  state.currentAction!.trim().isNotEmpty)
                _AgenticChip(
                  label: context.t(
                    vi: 'Action: ${state.currentAction}',
                    en: 'Action: ${state.currentAction}',
                  ),
                ),
              if (confidencePercent != null)
                _AgenticChip(
                  label: context.t(
                    vi: 'Độ tin cậy: $confidencePercent%',
                    en: 'Confidence: $confidencePercent%',
                  ),
                ),
              if (state.beliefEntropy != null)
                _AgenticChip(
                  label: context.t(
                    vi: 'Entropy: ${state.beliefEntropy!.toStringAsFixed(2)}',
                    en: 'Entropy: ${state.beliefEntropy!.toStringAsFixed(2)}',
                  ),
                ),
              if (latencyMs != null)
                _AgenticChip(
                  label: context.t(
                    vi: 'Latency: ${latencyMs}ms',
                    en: 'Latency: ${latencyMs}ms',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AgenticFilterChip(
                label: 'Academic',
                isSelected: _enabledAgentFilters.contains('academic'),
                onTap: () => _toggleAgentFilter('academic'),
              ),
              _AgenticFilterChip(
                label: 'Empathy',
                isSelected: _enabledAgentFilters.contains('empathy'),
                onTap: () => _toggleAgentFilter('empathy'),
              ),
              _AgenticFilterChip(
                label: 'Strategy',
                isSelected: _enabledAgentFilters.contains('strategy'),
                onTap: () => _toggleAgentFilter('strategy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.t(vi: 'Trạng thái từng agent', en: 'Per-agent status'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AgentStatusTile(
                title: 'Academic',
                icon: Icons.school_rounded,
                value: academic == null
                    ? context.t(vi: 'Chưa có dữ liệu', en: 'No data')
                    : '${(academic.confidence * 100).round()}%',
                subtitle:
                    academic?.topHypothesis ??
                    context.t(vi: 'Đang suy luận', en: 'Reasoning'),
              ),
              _AgentStatusTile(
                title: 'Empathy',
                icon: Icons.favorite_rounded,
                value: empathy == null
                    ? context.t(vi: 'Chưa có dữ liệu', en: 'No data')
                    : empathy.dominantState,
                subtitle: empathy == null
                    ? context.t(vi: 'Đang suy luận', en: 'Reasoning')
                    : 'u=${empathy.uncertainty.toStringAsFixed(2)}',
              ),
              _AgentStatusTile(
                title: 'Strategy',
                icon: Icons.psychology_alt_rounded,
                value:
                    strategy?.bestStrategy ??
                    context.t(vi: 'Đang chọn', en: 'Selecting'),
                subtitle: strategy == null
                    ? context.t(vi: 'Đang suy luận', en: 'Reasoning')
                    : 'R=${strategy.avgReward.toStringAsFixed(2)}',
              ),
            ],
          ),
          if (filteredReasoningSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.t(
                      vi: 'Timeline xử lý từng bước',
                      en: 'Step-by-step timeline',
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.t(
                    vi: 'Sao chép tóm tắt timeline',
                    en: 'Copy timeline summary',
                  ),
                  onPressed: () async {
                    final copiedMessage = context.t(
                      vi: 'Đã sao chép timeline',
                      en: 'Timeline copied',
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    final summary = filteredReasoningSteps
                        .map(
                          (s) =>
                              '#${s.step} ${s.toolLabel}: ${s.resultSummary}',
                        )
                        .join('\n');
                    if (summary.trim().isEmpty) {
                      return;
                    }
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (!mounted) return;
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(copiedMessage)));
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Column(
                key: ValueKey<String>(
                  '${state.stepCount}-${filteredReasoningSteps.length}-${_enabledAgentFilters.join(',')}',
                ),
                children: [
                  for (var i = 0; i < filteredReasoningSteps.length; i += 1)
                    _TimelineStepTile(
                      step: filteredReasoningSteps[i],
                      isLast: i == filteredReasoningSteps.length - 1,
                      delayMs: i * 70,
                      isExpanded: _expandedSteps.contains(
                        filteredReasoningSteps[i].step,
                      ),
                      status: _statusForStep(
                        filteredReasoningSteps[i],
                        isLast: i == filteredReasoningSteps.length - 1,
                        isLoading: state.isLoading,
                      ),
                      reduceMotion: reduceMotion,
                      onTap: () {
                        final stepId = filteredReasoningSteps[i].step;
                        setState(() {
                          if (_expandedSteps.contains(stepId)) {
                            _expandedSteps.remove(stepId);
                          } else {
                            _expandedSteps.add(stepId);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
          if (state.currentContent != null &&
              state.currentContent!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Text(
                state.currentContent!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _phaseLabel(BuildContext context, AgenticPhase phase) {
    return switch (phase) {
      AgenticPhase.idle => context.t(vi: 'Nhàn rỗi', en: 'Idle'),
      AgenticPhase.ready => context.t(vi: 'Sẵn sàng', en: 'Ready'),
      AgenticPhase.interacting => context.t(vi: 'Tương tác', en: 'Interacting'),
      AgenticPhase.processing => context.t(vi: 'Đang xử lý', en: 'Processing'),
      AgenticPhase.hitlPending => context.t(vi: 'Chờ HITL', en: 'HITL pending'),
      AgenticPhase.recovery => context.t(vi: 'Phục hồi', en: 'Recovery'),
      AgenticPhase.completed => context.t(vi: 'Hoàn tất', en: 'Completed'),
      AgenticPhase.error => context.t(vi: 'Lỗi', en: 'Error'),
    };
  }

  void _toggleAgentFilter(String key) {
    setState(() {
      if (_enabledAgentFilters.contains(key)) {
        if (_enabledAgentFilters.length > 1) {
          _enabledAgentFilters.remove(key);
        }
      } else {
        _enabledAgentFilters.add(key);
      }
    });
  }

  ReasoningStepStatus _statusForStep(
    agentic_models.ReasoningStep step, {
    required bool isLast,
    required bool isLoading,
  }) {
    return inferReasoningStepStatus(step, isLast: isLast, isLoading: isLoading);
  }
}

class _AgenticProcessCompactCard extends StatelessWidget {
  const _AgenticProcessCompactCard({
    required this.state,
    required this.onEnableAdvanced,
  });

  final AgenticSessionState state;
  final VoidCallback onEnableAdvanced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZenCard(
      radius: 18,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hub_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Agentic timeline đang ở chế độ gọn',
                    en: 'Agentic timeline in compact mode',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEnableAdvanced,
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text(context.t(vi: 'Bật', en: 'Enable')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              vi: 'Pha hiện tại: ${state.phase.name}',
              en: 'Current phase: ${state.phase.name}',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentStatusTile extends StatelessWidget {
  const _AgentStatusTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  const _TimelineStepTile({
    required this.step,
    required this.isLast,
    required this.delayMs,
    required this.isExpanded,
    required this.status,
    required this.reduceMotion,
    required this.onTap,
  });

  final agentic_models.ReasoningStep step;
  final bool isLast;
  final int delayMs;
  final bool isExpanded;
  final ReasoningStepStatus status;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 280 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        if (reduceMotion) {
          return child!;
        }
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${step.step}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: isExpanded ? 54 : 20,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${step.toolIcon} ${step.toolLabel}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _StepStatusBadge(status: status),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            step.resultSummary.trim().isEmpty
                                ? 'No result summary'
                                : step.resultSummary,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgenticFilterChip extends StatelessWidget {
  const _AgenticFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 86),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StepStatusBadge extends StatelessWidget {
  const _StepStatusBadge({required this.status});

  final ReasoningStepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (text, color) = switch (status) {
      ReasoningStepStatus.running => ('RUNNING', theme.colorScheme.primary),
      ReasoningStepStatus.failed => ('FAILED', theme.colorScheme.error),
      ReasoningStepStatus.fallback => ('FALLBACK', theme.colorScheme.tertiary),
      ReasoningStepStatus.completed => ('DONE', theme.colorScheme.secondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _AgenticChip extends StatelessWidget {
  const _AgenticChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoLivesActionCard extends StatelessWidget {
  const _NoLivesActionCard({
    required this.message,
    this.countdownLabel,
    this.livesLabel,
    required this.onRefreshLives,
    required this.onGoProgress,
    required this.onGoReview,
  });

  final String message;
  final String? countdownLabel;
  final String? livesLabel;
  final VoidCallback onRefreshLives;
  final VoidCallback onGoProgress;
  final VoidCallback onGoReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 16,
      color: colors.errorContainer.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: colors.error, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(
                    vi: 'Bạn đang tạm hết tim',
                    en: 'You are temporarily out of lives',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
              height: 1.35,
            ),
          ),
          if (countdownLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              countdownLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (livesLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              livesLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onRefreshLives,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.t(vi: 'Kiểm tra tim', en: 'Refresh lives')),
              ),
              FilledButton.tonalIcon(
                onPressed: onGoProgress,
                icon: const Icon(Icons.insights_rounded, size: 18),
                label: Text(context.t(vi: 'Xem Progress', en: 'Open Progress')),
              ),
              FilledButton.tonalIcon(
                onPressed: onGoReview,
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: Text(context.t(vi: 'Ôn tập', en: 'Review now')),
              ),
            ],
          ),
        ],
      ),
    );
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
