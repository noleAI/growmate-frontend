import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/models/signal_batch.dart';
import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_text_field.dart';
import '../../data/repositories/quiz_repository.dart';
import '../cubit/quiz_cubit.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quizRepository});

  final QuizRepository quizRepository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const Duration _totalQuizDuration = Duration(minutes: 12, seconds: 45);
  static const String _questionId = 'math_derivative_001';
  static const int _questionNumber = 4;
  static const String _questionText =
      'Tính đạo hàm của hàm số y = 4x³ + 2x² - 5';

  final BehavioralSignalService _signalService =
      BehavioralSignalService.instance;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  late final QuizCubit _quizCubit;

  Duration _remainingTime = _totalQuizDuration;
  bool _showHint = false;

  Timer? _countdownTimer;
  Timer? _hintTimer;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();

    _quizCubit = QuizCubit(
      quizRepository: widget.quizRepository,
      questionId: _questionId,
      questionText: _questionText,
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
    _signalService.startQuestion(questionId: _questionId);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingTime.inSeconds <= 0) {
        return;
      }

      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });
    });

    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showHint = true;
      });
    });
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

  void _submitCurrentAnswer() {
    _signalService.markSubmitted();
    _quizCubit.submitAnswer(_answerController.text);
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
          backgroundColor: GrowMateColors.background,
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
              final progress =
                  (_remainingTime.inSeconds / _totalQuizDuration.inSeconds)
                      .clamp(0.0, 1.0)
                      .toDouble();

              return ZenPageContainer(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Giải tích 12',
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
                            'CÂU HỎI SỐ $_questionNumber',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: GrowMateColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.85,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tính đạo hàm của hàm\nsố',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: GrowMateColors.textPrimary,
                              fontSize: 34,
                              height: 1.18,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'y = 4x³ + 2x² - 5',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: GrowMateColors.primary,
                              fontStyle: FontStyle.italic,
                              fontSize: 32,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ZenCard(
                      radius: 24,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      color: Colors.white.withValues(alpha: 0.78),
                      child: GestureDetector(
                        onTap: () {
                          _signalService.registerInteraction();
                          if (!_answerFocusNode.hasFocus) {
                            _answerFocusNode.requestFocus();
                          }
                        },
                        child: ZenTextField(
                          controller: _answerController,
                          focusNode: _answerFocusNode,
                          onTap: _signalService.registerInteraction,
                          onChanged: _onAnswerChanged,
                          textAlign: TextAlign.center,
                          enabled: !isLoading,
                          hintText: 'Nhập kết quả của bạn…',
                        ),
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
                        offset: _showHint ? Offset.zero : const Offset(0, 0.08),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: GrowMateColors.secondaryContainer.withValues(
                              alpha: 0.42,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: GrowMateColors.primary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                          child: Text(
                            'Gợi ý nhỏ: Đạo hàm của x^n là n.x^(n-1)',
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
                    const Spacer(),
                    ZenButton(
                      label: isLoading ? 'Đang gửi...' : 'Gửi bài',
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
                        'CẦN TRỢ GIÚP TỪ AI TUTOR?',
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
}
