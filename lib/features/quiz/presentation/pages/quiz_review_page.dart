import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/quiz_api_models.dart';
import '../../data/repositories/quiz_api_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/entities/quiz_question_template.dart';
import '../../domain/usecases/thpt_math_2026_scoring.dart';
import '../widgets/quiz_math_text.dart';
import '../widgets/quiz_question_content.dart';

class QuizReviewPageArgs {
  const QuizReviewPageArgs({
    required this.sessionId,
    this.seededSummary,
    this.seededEntries = const <QuizReviewSeedEntry>[],
  });

  final String sessionId;
  final QuizSessionScoreSummary? seededSummary;
  final List<QuizReviewSeedEntry> seededEntries;
}

class QuizReviewSeedEntry {
  const QuizReviewSeedEntry({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.score,
    required this.maxScore,
    this.explanation = '',
  });

  final QuizQuestionTemplate question;
  final QuizQuestionUserAnswer userAnswer;
  final bool isCorrect;
  final double score;
  final double maxScore;
  final String explanation;
}

class QuizReviewPage extends StatefulWidget {
  const QuizReviewPage({
    super.key,
    required this.quizRepository,
    required this.args,
    this.quizApiRepository,
  });

  final QuizRepository quizRepository;
  final QuizApiRepository? quizApiRepository;
  final QuizReviewPageArgs args;

  @override
  State<QuizReviewPage> createState() => _QuizReviewPageState();
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  final Set<String> _revealedAnswers = <String>{};
  final TextEditingController _chatController = TextEditingController();

  _QuizReviewScreenData? _screenData;
  String? _loadError;
  String? _loadWarning;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final seeded = _buildSeededScreenData(widget.args);
    if (seeded != null) {
      _screenData = seeded;
      _isLoading = widget.quizApiRepository != null;
    }
    unawaited(_loadReviewData());
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewData() async {
    final sessionId = widget.args.sessionId.trim();
    final apiRepository = widget.quizApiRepository;

    if (sessionId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError ??= 'Thiếu mã phiên quiz để tải phần review.';
      });
      return;
    }

    if (apiRepository == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        if (_screenData == null) {
          _loadError = 'Chưa có Quiz API để tải kết quả từ backend.';
        }
      });
      return;
    }

    if (mounted && _screenData == null) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _loadWarning = null;
      });
    }

    try {
      final result = await _fetchSessionResultWithRetry(
        apiRepository,
        sessionId,
      );
      final unresolvedTemplateIds = result.attempts
          .where(
            (attempt) =>
                (attempt.questionContent?.trim().isEmpty ?? true) ||
                (attempt.answerKey == null || attempt.answerKey!.isEmpty),
          )
          .map((attempt) => attempt.questionTemplateId?.trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final templateById = <String, QuizQuestionTemplate>{};
      if (unresolvedTemplateIds.isNotEmpty) {
        try {
          final templates = await widget.quizRepository
              .fetchQuestionTemplatesByTemplateIds(unresolvedTemplateIds);
          templateById.addEntries(
            templates.map((template) => MapEntry(template.id, template)),
          );
        } catch (_) {
          // The backend result already contains enough review data for most flows.
        }
      }

      final entries = result.attempts
          .map((attempt) {
            final templateId = attempt.questionTemplateId?.trim() ?? '';
            return _QuizReviewEntry.fromAttempt(
              attempt,
              templateById[templateId],
            );
          })
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      final hasUnresolvedReviewData = entries.any(
        (entry) =>
            entry.question == null &&
            entry.questionContent.isEmpty &&
            (entry.answerKey == null || entry.answerKey!.isEmpty),
      );

      setState(() {
        _screenData = _QuizReviewScreenData(
          sessionId: result.sessionId.isNotEmpty ? result.sessionId : sessionId,
          sessionStatus: result.sessionStatus,
          summary: result.summary,
          entries: entries,
          usesSeedDataOnly: false,
        );
        _isLoading = false;
        _loadError = null;
        _loadWarning = hasUnresolvedReviewData
            ? 'Một vài câu chưa tải đủ dữ liệu review từ backend.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        if (_screenData != null) {
          _loadWarning =
              'Đang hiển thị bản review cục bộ tạm thời vì chưa tải được kết quả từ backend.';
        } else {
          _loadError =
              'Không tải được review của bài quiz này. Vui lòng thử lại.';
        }
      });
    }
  }

  Future<QuizSessionResultResponse> _fetchSessionResultWithRetry(
    QuizApiRepository apiRepository,
    String sessionId,
  ) async {
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 450),
      Duration(milliseconds: 900),
    ];

    Object? lastError;
    for (final delay in retryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        return await apiRepository.getSessionResult(sessionId: sessionId);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Unable to load quiz review result.');
  }

  _QuizReviewScreenData? _buildSeededScreenData(QuizReviewPageArgs args) {
    if (args.seededEntries.isEmpty && args.seededSummary == null) {
      return null;
    }

    final entries = args.seededEntries
        .map(_QuizReviewEntry.fromSeed)
        .toList(growable: false);

    return _QuizReviewScreenData(
      sessionId: args.sessionId,
      sessionStatus: 'completed',
      summary:
          args.seededSummary ??
          _deriveSummaryFromSeedEntries(args.seededEntries),
      entries: entries,
      usesSeedDataOnly: true,
    );
  }

  QuizSessionScoreSummary _deriveSummaryFromSeedEntries(
    List<QuizReviewSeedEntry> entries,
  ) {
    final answeredCount = entries.length;
    final correctCount = entries.where((entry) => entry.isCorrect).length;
    final totalScore = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.score,
    );
    final maxScore = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.maxScore,
    );
    final double accuracyPercent = answeredCount == 0
        ? 0.0
        : (correctCount / answeredCount) * 100.0;

    return QuizSessionScoreSummary(
      answeredCount: answeredCount,
      correctCount: correctCount,
      totalScore: totalScore,
      maxScore: maxScore,
      accuracyPercent: accuracyPercent,
    );
  }

  void _toggleReveal(String questionKey) {
    setState(() {
      if (_revealedAnswers.contains(questionKey)) {
        _revealedAnswers.remove(questionKey);
      } else {
        _revealedAnswers.add(questionKey);
      }
    });
  }

  void _showChatPlaceholderSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            vi: 'Khung ChatBot riêng cho đề này đã sẵn. Phần xử lý chat bạn có thể nối sau.',
            en: 'The quiz-scoped chatbot shell is ready. You can wire the chat flow later.',
          ),
        ),
      ),
    );
  }

  void _openDiagnosis() {
    final sessionId = (_screenData?.sessionId ?? widget.args.sessionId).trim();
    if (sessionId.isEmpty) {
      return;
    }
    context.push(
      '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(sessionId)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenData = _screenData;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFEAF2FF), Color(0xFFF4F7FB)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadReviewData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ZenPageContainer(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: screenData == null
                  ? _buildFallbackBody(theme)
                  : _buildLoadedBody(context, theme, screenData),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBody(ThemeData theme) {
    if (_isLoading) {
      return SizedBox(
        height: 520,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                context.t(
                  vi: 'Đang tải phần review bài làm...',
                  en: 'Loading quiz review...',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(theme),
        const SizedBox(height: 16),
        ZenCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                  vi: 'Chưa hiển thị được review của bài quiz.',
                  en: 'Unable to display the quiz review.',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _loadError ??
                    context.t(
                      vi: 'Vui lòng thử tải lại sau một chút.',
                      en: 'Please try loading again in a moment.',
                    ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      unawaited(_loadReviewData());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.t(vi: 'Tải lại', en: 'Retry')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(context.t(vi: 'Về trang chủ', en: 'Go home')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedBody(
    BuildContext context,
    ThemeData theme,
    _QuizReviewScreenData screenData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(theme),
        const SizedBox(height: 16),
        _buildHeroCard(context, theme, screenData),
        if (_loadWarning != null) ...[
          const SizedBox(height: 14),
          _buildWarningCard(theme, _loadWarning!),
        ],
        const SizedBox(height: 16),
        _buildChatbotScopeCard(context, theme, screenData),
        const SizedBox(height: 20),
        Text(
          context.t(vi: 'Xem lại từng câu', en: 'Review each question'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.t(
            vi: 'Mỗi câu có thể bật/tắt phần đáp án và lời giải ngay trên card.',
            en: 'Each card lets you reveal or hide the correct answer and explanation.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        if (screenData.entries.isEmpty)
          ZenCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              context.t(
                vi: 'Phiên này chưa có câu trả lời nào để review.',
                en: 'This session does not have any answers to review yet.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...List<Widget>.generate(
            screenData.entries.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == screenData.entries.length - 1 ? 0 : 14,
              ),
              child: _buildAttemptCard(
                context,
                theme,
                screenData.entries[index],
                index,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _openDiagnosis,
              icon: const Icon(Icons.insights_rounded),
              label: Text(
                context.t(vi: 'Xem chẩn đoán AI', en: 'Open AI diagnosis'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_rounded),
              label: Text(context.t(vi: 'Về trang chủ', en: 'Go home')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.assignment_turned_in_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(vi: 'Quiz Review', en: 'Quiz Review'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.t(
                  vi: 'Màn xem lại bài làm sau khi nộp quiz.',
                  en: 'Post-submit review for the completed quiz.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ThemeData theme,
    _QuizReviewScreenData screenData,
  ) {
    final summary = screenData.summary;
    final accuracy = summary.accuracyPercent.round();

    return ZenCard(
      padding: const EdgeInsets.all(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF4A86FF), Color(0xFF7BB6FF)],
      ),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(vi: 'Bài quiz đã nộp', en: 'Submitted quiz'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t(
                        vi: 'Xem đáp án từng câu và đặt khung ChatBot riêng cho đề này.',
                        en: 'Review each answer and stage a dedicated chatbot shell for this quiz.',
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildSummaryBadge(
                theme,
                label: context.t(vi: 'Độ chính xác', en: 'Accuracy'),
                value: '$accuracy%',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricPill(
                theme,
                label: context.t(vi: 'Câu đúng', en: 'Correct'),
                value: '${summary.correctCount}/${summary.answeredCount}',
              ),
              _buildMetricPill(
                theme,
                label: context.t(vi: 'Tổng điểm', en: 'Score'),
                value:
                    '${_formatScoreValue(summary.totalScore)}/${_formatScoreValue(summary.maxScore)}',
              ),
              _buildMetricPill(
                theme,
                label: context.t(vi: 'Trạng thái', en: 'Status'),
                value: _sessionStatusLabel(context, screenData.sessionStatus),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSessionChip(
                theme,
                'Session ${_shortSessionId(screenData.sessionId)}',
              ),
              _buildSessionChip(
                theme,
                '${screenData.entries.length} ${context.t(vi: 'câu', en: 'questions')}',
              ),
              if (screenData.usesSeedDataOnly)
                _buildSessionChip(
                  theme,
                  context.t(vi: 'Bản review cục bộ', en: 'Local review copy'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(ThemeData theme, String message) {
    return ZenCard(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFFF7E8),
      border: Border.all(color: const Color(0xFFFFD78C)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB7791F)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A5A12),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotScopeCard(
    BuildContext context,
    ThemeData theme,
    _QuizReviewScreenData screenData,
  ) {
    return ZenCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF7FBFF), Color(0xFFEAF3FF)],
      ),
      border: Border.all(color: const Color(0xFFD5E6FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEECFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF2E6EEB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(
                        vi: 'ChatBot riêng cho đề quiz này',
                        en: 'Dedicated chatbot for this quiz',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.t(
                        vi: 'Khung chat này chỉ nên trao đổi trong phạm vi bài quiz vừa nộp.',
                        en: 'This chat shell is scoped to the quiz that was just submitted.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.t(vi: 'Placeholder', en: 'Placeholder'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF2E6EEB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildScopeChip(
                theme,
                context.t(vi: 'Scope: đề vừa làm', en: 'Scope: current quiz'),
              ),
              _buildScopeChip(
                theme,
                '${screenData.entries.length} ${context.t(vi: 'câu hỏi', en: 'questions')}',
              ),
              _buildScopeChip(
                theme,
                'Session ${_shortSessionId(screenData.sessionId)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _chatController,
            readOnly: true,
            onTap: _showChatPlaceholderSnackBar,
            decoration: InputDecoration(
              hintText: context.t(
                vi: 'Ví dụ: Tại sao câu 4 sai hoặc gợi ý cách sửa?',
                en: 'Example: Why was question 4 wrong or how should it be fixed?',
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded),
              suffixIcon: IconButton(
                onPressed: _showChatPlaceholderSnackBar,
                icon: const Icon(Icons.send_rounded),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.94),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.t(
              vi: 'Phần UI và scope đã sẵn. Phần xử lý hỏi đáp, memory, và context của đề có thể nối sau.',
              en: 'The UI shell and scope are ready. Chat handling, memory, and quiz-scoped context can be wired later.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptCard(
    BuildContext context,
    ThemeData theme,
    _QuizReviewEntry entry,
    int index,
  ) {
    final isExpanded = _revealedAnswers.contains(entry.stableId);
    final question = entry.question;
    final questionType = _tryResolveEntryQuestionType(entry);

    return ZenCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildResultBadge(theme, entry.isCorrect),
              const SizedBox(width: 10),
              if (questionType != null)
                _buildTypeBadge(
                  theme,
                  _questionTypeLabel(context, questionType),
                ),
              const Spacer(),
              Text(
                '${_formatScoreValue(entry.score)} / ${_formatScoreValue(entry.maxScore)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.t(vi: 'Đề bài', en: 'Question'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (question != null)
            QuizQuestionContent(
              content: question.content,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            )
          else if (entry.questionContent.isNotEmpty)
            QuizQuestionContent(
              content: entry.questionContent,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            )
          else
            Text(
              context.t(
                vi: 'Không tìm thấy nội dung câu hỏi trong bank hiện tại.',
                en: 'The question content could not be resolved from the current bank.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          _buildSectionLabel(
            context,
            theme,
            context.t(vi: 'Bạn đã trả lời', en: 'Your answer'),
          ),
          const SizedBox(height: 8),
          _buildUserAnswerBody(theme, entry),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _toggleReveal(entry.stableId),
            icon: Icon(
              isExpanded
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            label: Text(
              isExpanded
                  ? context.t(vi: 'Ẩn đáp án', en: 'Hide answer')
                  : context.t(vi: 'Hiện đáp án', en: 'Show answer'),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildRevealPanel(context, theme, entry),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealPanel(
    BuildContext context,
    ThemeData theme,
    _QuizReviewEntry entry,
  ) {
    final question = entry.question;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(
            context,
            theme,
            context.t(vi: 'Đáp án đúng', en: 'Correct answer'),
          ),
          const SizedBox(height: 8),
          question != null
              ? _buildCorrectAnswerBody(theme, question)
              : entry.answerKey != null && entry.answerKey!.isNotEmpty
              ? _buildCorrectAnswerFromAnswerKey(theme, entry)
              : Text(
                  context.t(
                    vi: 'Chưa resolve được đáp án đúng từ bank câu hỏi.',
                    en: 'The correct answer has not been resolved from the question bank yet.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          const SizedBox(height: 14),
          _buildSectionLabel(
            context,
            theme,
            context.t(vi: 'Lời giải / giải thích', en: 'Explanation'),
          ),
          const SizedBox(height: 8),
          QuizMathText(
            text: entry.explanation.trim().isNotEmpty
                ? entry.explanation
                : context.t(
                    vi: 'Chưa có giải thích chi tiết cho câu này.',
                    en: 'No detailed explanation is available for this question yet.',
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnswerBody(ThemeData theme, _QuizReviewEntry entry) {
    final question = entry.question;
    final questionType = _tryResolveEntryQuestionType(entry);

    if (question != null) {
      switch (question.questionType) {
        case QuizQuestionType.multipleChoice:
          return _buildMultipleChoiceAnswer(
            theme,
            question,
            _resolveSelectedOptionId(entry.userAnswer),
            accentColor: entry.isCorrect
                ? const Color(0xFF1E8E5A)
                : const Color(0xFFD93025),
            emptyLabel: context.t(
              vi: 'Bạn chưa có lựa chọn đã lưu.',
              en: 'No saved choice was found for your answer.',
            ),
          );
        case QuizQuestionType.trueFalseCluster:
          return _buildClusterAnswerComparison(
            theme,
            question,
            _resolveClusterAnswers(entry.userAnswer),
            showCorrectReference: false,
          );
        case QuizQuestionType.shortAnswer:
          return _buildShortAnswerValue(
            theme,
            _resolveShortAnswer(entry.userAnswer),
            emptyLabel: context.t(
              vi: 'Bạn chưa có đáp án đã lưu.',
              en: 'No saved short answer was found.',
            ),
          );
      }
    }

    switch (questionType) {
      case QuizQuestionType.multipleChoice:
        return _buildMultipleChoiceAnswerFromAnswerKey(
          theme,
          entry.answerKey,
          _resolveSelectedOptionId(entry.userAnswer),
          accentColor: entry.isCorrect
              ? const Color(0xFF1E8E5A)
              : const Color(0xFFD93025),
          emptyLabel: context.t(
            vi: 'Bạn chưa có lựa chọn đã lưu.',
            en: 'No saved choice was found for your answer.',
          ),
        );
      case QuizQuestionType.trueFalseCluster:
        return _buildClusterAnswerComparisonFromAnswerKey(
          theme,
          entry.answerKey,
          _resolveClusterAnswers(entry.userAnswer),
          showCorrectReference: false,
        );
      case QuizQuestionType.shortAnswer:
        return _buildShortAnswerValue(
          theme,
          _resolveShortAnswer(entry.userAnswer),
          emptyLabel: context.t(
            vi: 'Bạn chưa có đáp án đã lưu.',
            en: 'No saved short answer was found.',
          ),
        );
      case null:
        return _buildUnknownAnswer(theme, entry.userAnswer);
    }
  }

  Widget _buildCorrectAnswerBody(
    ThemeData theme,
    QuizQuestionTemplate question,
  ) {
    switch (question.questionType) {
      case QuizQuestionType.multipleChoice:
        final payload = question.payload;
        if (payload is! MultipleChoicePayload) {
          return Text(
            context.t(
              vi: 'Không đọc được đáp án trắc nghiệm.',
              en: 'Unable to read the multiple-choice answer.',
            ),
          );
        }
        return _buildMultipleChoiceAnswer(
          theme,
          question,
          payload.correctOptionId,
          accentColor: const Color(0xFF2E6EEB),
          emptyLabel: context.t(
            vi: 'Chưa có đáp án đúng trong payload.',
            en: 'The correct option is missing in the payload.',
          ),
        );
      case QuizQuestionType.trueFalseCluster:
        return _buildClusterAnswerComparison(
          theme,
          question,
          const <String, bool>{},
          showCorrectReference: true,
        );
      case QuizQuestionType.shortAnswer:
        final payload = question.payload;
        if (payload is! ShortAnswerPayload) {
          return Text(
            context.t(
              vi: 'Không đọc được đáp án từ payload.',
              en: 'Unable to read the short answer payload.',
            ),
          );
        }
        final candidates = <String>[];
        if (payload.exactAnswer.trim().isNotEmpty) {
          candidates.add(payload.exactAnswer.trim());
        }
        for (final item in payload.acceptedAnswers) {
          final value = item.trim();
          if (value.isNotEmpty && !candidates.contains(value)) {
            candidates.add(value);
          }
        }
        if (candidates.isEmpty) {
          return Text(
            context.t(
              vi: 'Chưa có đáp án mẫu cho câu trả lời ngắn.',
              en: 'No reference answer is available for this short-answer question.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortAnswerValue(theme, candidates.first, emptyLabel: ''),
            if (candidates.length > 1) ...[
              const SizedBox(height: 10),
              Text(
                context.t(
                  vi: 'Các dạng chấp nhận thêm',
                  en: 'Other accepted forms',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates
                    .skip(1)
                    .map((value) => _buildAnswerToken(theme, value))
                    .toList(growable: false),
              ),
            ],
          ],
        );
    }
  }

  Widget _buildCorrectAnswerFromAnswerKey(
    ThemeData theme,
    _QuizReviewEntry entry,
  ) {
    final questionType = _tryResolveEntryQuestionType(entry);
    switch (questionType) {
      case QuizQuestionType.multipleChoice:
        return _buildMultipleChoiceAnswerFromAnswerKey(
          theme,
          entry.answerKey,
          _resolveCorrectOptionId(entry.answerKey),
          accentColor: const Color(0xFF2E6EEB),
          emptyLabel: context.t(
            vi: 'Chưa có đáp án đúng trong payload.',
            en: 'The correct option is missing in the payload.',
          ),
        );
      case QuizQuestionType.trueFalseCluster:
        return _buildClusterAnswerComparisonFromAnswerKey(
          theme,
          entry.answerKey,
          const <String, bool>{},
          showCorrectReference: true,
        );
      case QuizQuestionType.shortAnswer:
        final candidates = _resolveShortAnswerCandidates(entry.answerKey);
        if (candidates.isEmpty) {
          return Text(
            context.t(
              vi: 'Chưa có đáp án mẫu cho câu trả lời ngắn.',
              en: 'No reference answer is available for this short-answer question.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortAnswerValue(theme, candidates.first, emptyLabel: ''),
            if (candidates.length > 1) ...[
              const SizedBox(height: 10),
              Text(
                context.t(
                  vi: 'Các dạng chấp nhận thêm',
                  en: 'Other accepted forms',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates
                    .skip(1)
                    .map((value) => _buildAnswerToken(theme, value))
                    .toList(growable: false),
              ),
            ],
          ],
        );
      case null:
        return Text(
          context.t(
            vi: 'Chưa đọc được đáp án từ payload review.',
            en: 'Unable to read the review answer payload.',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildMultipleChoiceAnswerFromAnswerKey(
    ThemeData theme,
    Map<String, dynamic>? answerKey,
    String selectedId, {
    required Color accentColor,
    required String emptyLabel,
  }) {
    final normalizedSelectedId = selectedId.trim().toUpperCase();
    if (normalizedSelectedId.isEmpty) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final option = _resolveAnswerKeyOptions(
      answerKey,
    ).where((item) => item.id == normalizedSelectedId).firstOrNull;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              normalizedSelectedId,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: QuizMathText(
              text: option?.text ?? normalizedSelectedId,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterAnswerComparisonFromAnswerKey(
    ThemeData theme,
    Map<String, dynamic>? answerKey,
    Map<String, bool> answers, {
    required bool showCorrectReference,
  }) {
    final subQuestions = _resolveAnswerKeyClusterStatements(answerKey);
    if (subQuestions.isEmpty) {
      return Text(
        context.t(
          vi: 'Không đọc được cụm Đúng/Sai của câu này.',
          en: 'Unable to read the true/false cluster for this question.',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: subQuestions
          .map((statement) {
            final answered = answers[statement.id];
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${statement.id.toLowerCase()}) ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: QuizMathText(
                          text: statement.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
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
                      if (!showCorrectReference)
                        _buildSmallAnswerPill(
                          theme,
                          label: context.t(vi: 'Bạn', en: 'You'),
                          value: answered == null
                              ? context.t(vi: 'Chưa lưu', en: 'Not saved')
                              : _boolAnswerLabel(context, answered),
                          background: answered == null
                              ? const Color(0xFFF1F5F9)
                              : answered == statement.isTrue
                              ? const Color(0xFFE8F6EE)
                              : const Color(0xFFFFECE8),
                          foreground: answered == null
                              ? const Color(0xFF64748B)
                              : answered == statement.isTrue
                              ? const Color(0xFF166534)
                              : const Color(0xFFB42318),
                        ),
                      _buildSmallAnswerPill(
                        theme,
                        label: context.t(vi: 'Đáp án', en: 'Correct'),
                        value: _boolAnswerLabel(context, statement.isTrue),
                        background: const Color(0xFFEAF3FF),
                        foreground: const Color(0xFF1D4ED8),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildMultipleChoiceAnswer(
    ThemeData theme,
    QuizQuestionTemplate question,
    String selectedId, {
    required Color accentColor,
    required String emptyLabel,
  }) {
    final payload = question.payload;
    if (payload is! MultipleChoicePayload) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final normalizedSelectedId = selectedId.trim().toUpperCase();
    if (normalizedSelectedId.isEmpty) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final option = payload.options
        .where((item) => item.id.trim().toUpperCase() == normalizedSelectedId)
        .firstOrNull;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              normalizedSelectedId,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: QuizMathText(
              text: option?.text ?? normalizedSelectedId,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterAnswerComparison(
    ThemeData theme,
    QuizQuestionTemplate question,
    Map<String, bool> answers, {
    required bool showCorrectReference,
  }) {
    final payload = question.payload;
    if (payload is! TrueFalseClusterPayload) {
      return Text(
        context.t(
          vi: 'Không đọc được cụm Đúng/Sai của câu này.',
          en: 'Unable to read the true/false cluster for this question.',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: payload.subQuestions
          .map((statement) {
            final answered = answers[statement.id];
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${statement.id.toLowerCase()}) ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: QuizMathText(
                          text: statement.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
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
                      if (!showCorrectReference)
                        _buildSmallAnswerPill(
                          theme,
                          label: context.t(vi: 'Bạn', en: 'You'),
                          value: answered == null
                              ? context.t(vi: 'Chưa lưu', en: 'Not saved')
                              : _boolAnswerLabel(context, answered),
                          background: answered == null
                              ? const Color(0xFFF1F5F9)
                              : answered == statement.isTrue
                              ? const Color(0xFFE8F6EE)
                              : const Color(0xFFFFECE8),
                          foreground: answered == null
                              ? const Color(0xFF64748B)
                              : answered == statement.isTrue
                              ? const Color(0xFF166534)
                              : const Color(0xFFB42318),
                        ),
                      _buildSmallAnswerPill(
                        theme,
                        label: context.t(vi: 'Đáp án', en: 'Correct'),
                        value: _boolAnswerLabel(context, statement.isTrue),
                        background: const Color(0xFFEAF3FF),
                        foreground: const Color(0xFF1D4ED8),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildShortAnswerValue(
    ThemeData theme,
    String value, {
    required String emptyLabel,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return _buildAnswerToken(theme, normalized);
  }

  Widget _buildUnknownAnswer(ThemeData theme, Map<String, dynamic> answer) {
    if (answer.isEmpty) {
      return Text(
        context.t(
          vi: 'Không đọc được dữ liệu câu trả lời đã lưu.',
          en: 'Unable to read the saved answer payload.',
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: answer.entries
          .map(
            (entry) => _buildAnswerToken(theme, '${entry.key}: ${entry.value}'),
          )
          .toList(growable: false),
    );
  }

  Widget _buildAnswerToken(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: QuizMathText(
        text: text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    ThemeData theme,
    String label,
  ) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSummaryBadge(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildScopeChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2458C7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildResultBadge(ThemeData theme, bool isCorrect) {
    final background = isCorrect
        ? const Color(0xFFE8F6EE)
        : const Color(0xFFFFECE8);
    final foreground = isCorrect
        ? const Color(0xFF166534)
        : const Color(0xFFB42318);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCorrect
            ? context.t(vi: 'Đúng', en: 'Correct')
            : context.t(vi: 'Sai', en: 'Incorrect'),
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSmallAnswerPill(
    ThemeData theme, {
    required String label,
    required String value,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuizReviewScreenData {
  const _QuizReviewScreenData({
    required this.sessionId,
    required this.sessionStatus,
    required this.summary,
    required this.entries,
    required this.usesSeedDataOnly,
  });

  final String sessionId;
  final String sessionStatus;
  final QuizSessionScoreSummary summary;
  final List<_QuizReviewEntry> entries;
  final bool usesSeedDataOnly;
}

class _QuizReviewEntry {
  const _QuizReviewEntry({
    required this.stableId,
    required this.questionId,
    required this.questionTemplateId,
    required this.question,
    required this.questionType,
    required this.questionContent,
    required this.answerKey,
    required this.isCorrect,
    required this.score,
    required this.maxScore,
    required this.explanation,
    required this.userAnswer,
  });

  final String stableId;
  final String questionId;
  final String questionTemplateId;
  final QuizQuestionTemplate? question;
  final String questionType;
  final String questionContent;
  final Map<String, dynamic>? answerKey;
  final bool isCorrect;
  final double score;
  final double maxScore;
  final String explanation;
  final Map<String, dynamic> userAnswer;

  factory _QuizReviewEntry.fromAttempt(
    QuizAttemptRecord attempt,
    QuizQuestionTemplate? question,
  ) {
    final questionTemplateId = attempt.questionTemplateId?.trim() ?? '';
    return _QuizReviewEntry(
      stableId: questionTemplateId.isNotEmpty
          ? questionTemplateId
          : attempt.questionId,
      questionId: attempt.questionId,
      questionTemplateId: questionTemplateId,
      question: question,
      questionType: attempt.questionType?.trim() ?? '',
      questionContent: attempt.questionContent?.trim() ?? '',
      answerKey: attempt.answerKey,
      isCorrect: attempt.isCorrect,
      score: attempt.score,
      maxScore: attempt.maxScore,
      explanation: attempt.explanation?.trim() ?? '',
      userAnswer: attempt.userAnswer ?? const <String, dynamic>{},
    );
  }

  factory _QuizReviewEntry.fromSeed(QuizReviewSeedEntry entry) {
    return _QuizReviewEntry(
      stableId: entry.question.id,
      questionId:
          entry.question.metadata['source_question_id']?.toString() ??
          entry.question.id,
      questionTemplateId: entry.question.id,
      question: entry.question,
      questionType: entry.question.questionType.storageValue,
      questionContent: entry.question.content,
      answerKey: _buildAnswerKeyFromQuestion(entry.question),
      isCorrect: entry.isCorrect,
      score: entry.score,
      maxScore: entry.maxScore,
      explanation: entry.explanation.trim().isNotEmpty
          ? entry.explanation.trim()
          : _resolveQuestionExplanation(entry.question),
      userAnswer: _seedAnswerToMap(entry.userAnswer),
    );
  }
}

class _ResolvedAnswerKeyOption {
  const _ResolvedAnswerKeyOption({required this.id, required this.text});

  final String id;
  final String text;
}

class _ResolvedClusterStatement {
  const _ResolvedClusterStatement({
    required this.id,
    required this.text,
    required this.isTrue,
  });

  final String id;
  final String text;
  final bool isTrue;
}

QuizQuestionType? _tryResolveEntryQuestionType(_QuizReviewEntry entry) {
  if (entry.question != null) {
    return entry.question!.questionType;
  }

  return _tryParseQuestionType(entry.questionType) ??
      _tryResolveQuestionTypeFromAnswerKey(entry.answerKey);
}

QuizQuestionType? _tryParseQuestionType(String? raw) {
  final normalized = raw?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  try {
    return QuizQuestionType.fromStorageValue(normalized);
  } catch (_) {
    return null;
  }
}

QuizQuestionType? _tryResolveQuestionTypeFromAnswerKey(
  Map<String, dynamic>? answerKey,
) {
  final kind = (answerKey?['kind'] ?? '').toString().trim().toLowerCase();
  return switch (kind) {
    'multiple_choice' => QuizQuestionType.multipleChoice,
    'short_answer' => QuizQuestionType.shortAnswer,
    'true_false_cluster' => QuizQuestionType.trueFalseCluster,
    _ => null,
  };
}

String _resolveCorrectOptionId(Map<String, dynamic>? answerKey) {
  return (answerKey?['correct_option_id'] ?? '')
      .toString()
      .trim()
      .toUpperCase();
}

List<String> _resolveShortAnswerCandidates(Map<String, dynamic>? answerKey) {
  final candidates = <String>[];
  final exactAnswer = (answerKey?['exact_answer'] ?? '').toString().trim();
  if (exactAnswer.isNotEmpty) {
    candidates.add(exactAnswer);
  }

  final rawAcceptedAnswers = answerKey?['accepted_answers'];
  if (rawAcceptedAnswers is List) {
    for (final item in rawAcceptedAnswers) {
      final value = item.toString().trim();
      if (value.isNotEmpty && !candidates.contains(value)) {
        candidates.add(value);
      }
    }
  }

  return candidates;
}

List<_ResolvedAnswerKeyOption> _resolveAnswerKeyOptions(
  Map<String, dynamic>? answerKey,
) {
  final rawOptions = answerKey?['options'];
  if (rawOptions is! List) {
    return const <_ResolvedAnswerKeyOption>[];
  }

  return rawOptions
      .whereType<Map>()
      .map(
        (item) => _ResolvedAnswerKeyOption(
          id: (item['id'] ?? '').toString().trim().toUpperCase(),
          text: (item['text'] ?? '').toString(),
        ),
      )
      .where((item) => item.id.isNotEmpty)
      .toList(growable: false);
}

List<_ResolvedClusterStatement> _resolveAnswerKeyClusterStatements(
  Map<String, dynamic>? answerKey,
) {
  final rawSubQuestions = answerKey?['sub_questions'];
  if (rawSubQuestions is! List) {
    return const <_ResolvedClusterStatement>[];
  }

  return rawSubQuestions
      .whereType<Map>()
      .map(
        (item) => _ResolvedClusterStatement(
          id: (item['id'] ?? '').toString().trim(),
          text: (item['text'] ?? '').toString(),
          isTrue: item['is_true'] == true,
        ),
      )
      .where((item) => item.id.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _buildAnswerKeyFromQuestion(
  QuizQuestionTemplate question,
) {
  final payload = question.payload;
  return switch (payload) {
    MultipleChoicePayload(:final correctOptionId, :final options) =>
      <String, dynamic>{
        'kind': 'multiple_choice',
        'correct_option_id': correctOptionId,
        'options': options
            .map(
              (option) => <String, dynamic>{
                'id': option.id,
                'text': option.text,
              },
            )
            .toList(growable: false),
      },
    TrueFalseClusterPayload(:final subQuestions, :final generalHint) =>
      <String, dynamic>{
        'kind': 'true_false_cluster',
        'general_hint': generalHint,
        'sub_questions': subQuestions
            .map(
              (statement) => <String, dynamic>{
                'id': statement.id,
                'text': statement.text,
                'is_true': statement.isTrue,
                'explanation': statement.explanation,
              },
            )
            .toList(growable: false),
      },
    ShortAnswerPayload(
      :final exactAnswer,
      :final acceptedAnswers,
      :final unit,
      :final tolerance,
    ) =>
      <String, dynamic>{
        'kind': 'short_answer',
        'exact_answer': exactAnswer,
        'accepted_answers': [exactAnswer, ...acceptedAnswers]
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false),
        'unit': unit,
        'tolerance': tolerance,
      },
  };
}

Map<String, dynamic> _seedAnswerToMap(QuizQuestionUserAnswer answer) {
  return switch (answer) {
    MultipleChoiceUserAnswer(:final selectedOptionId) => <String, dynamic>{
      'selected_option': selectedOptionId,
    },
    TrueFalseClusterUserAnswer(:final subAnswers) => <String, dynamic>{
      'cluster_answers': subAnswers,
    },
    ShortAnswerUserAnswer(:final answerText) => <String, dynamic>{
      'short_answer': answerText,
    },
  };
}

String _resolveQuestionExplanation(QuizQuestionTemplate question) {
  final payload = question.payload;
  return switch (payload) {
    MultipleChoicePayload(:final explanation) => explanation,
    TrueFalseClusterPayload(:final subQuestions) =>
      subQuestions
          .map((item) => item.explanation.trim())
          .where((value) => value.isNotEmpty)
          .join('\n'),
    ShortAnswerPayload(:final explanation) => explanation,
  };
}

String _formatScoreValue(double value) {
  final fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('00')) {
    return value.toStringAsFixed(0);
  }
  if (fixed.endsWith('0')) {
    return value.toStringAsFixed(1);
  }
  return fixed;
}

String _shortSessionId(String sessionId) {
  final normalized = sessionId.trim();
  if (normalized.length <= 8) {
    return normalized;
  }
  return normalized.substring(0, 8);
}

String _resolveSelectedOptionId(Map<String, dynamic> answer) {
  return (answer['selected_option'] ?? answer['selected_option_id'] ?? '')
      .toString()
      .trim()
      .toUpperCase();
}

String _resolveShortAnswer(Map<String, dynamic> answer) {
  return (answer['short_answer'] ?? answer['answer_text'] ?? '')
      .toString()
      .trim();
}

Map<String, bool> _resolveClusterAnswers(Map<String, dynamic> answer) {
  final raw = answer['cluster_answers'] ?? answer['sub_answers'];
  if (raw is! Map) {
    return const <String, bool>{};
  }
  return raw.map<String, bool>((key, value) {
    final normalizedKey = key.toString();
    final normalizedValue = switch (value) {
      bool boolValue => boolValue,
      num numberValue => numberValue != 0,
      String stringValue =>
        stringValue.trim().toLowerCase() == 'true' || stringValue.trim() == '1',
      _ => false,
    };
    return MapEntry<String, bool>(normalizedKey, normalizedValue);
  });
}

String _sessionStatusLabel(BuildContext context, String status) {
  switch (status.trim().toLowerCase()) {
    case 'completed':
      return context.t(vi: 'Hoàn tất', en: 'Completed');
    case 'active':
      return context.t(vi: 'Đang mở', en: 'Active');
    case 'abandoned':
      return context.t(vi: 'Đã dừng giữa chừng', en: 'Abandoned');
    default:
      return status.trim().isEmpty ? '--' : status.trim();
  }
}

String _boolAnswerLabel(BuildContext context, bool value) {
  return value
      ? context.t(vi: 'Đúng', en: 'True')
      : context.t(vi: 'Sai', en: 'False');
}

String _questionTypeLabel(BuildContext context, QuizQuestionType type) {
  return switch (type) {
    QuizQuestionType.multipleChoice => context.t(
      vi: 'Trắc nghiệm',
      en: 'Multiple choice',
    ),
    QuizQuestionType.trueFalseCluster => context.t(
      vi: 'Đúng / Sai',
      en: 'True / False',
    ),
    QuizQuestionType.shortAnswer => context.t(
      vi: 'Trả lời ngắn',
      en: 'Short answer',
    ),
  };
}

extension IterableFirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
