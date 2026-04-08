import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/behavioral_signal_collector.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_text_field.dart';
import '../../data/repositories/quiz_repository.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quizRepository});

  final QuizRepository quizRepository;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const String _questionId = 'math_derivative_001';
  static const int _questionNumber = 4;
  static const String _questionText = 'Tính đạo hàm của hàm số y = 4x³ + 2x² - 5';

  final BehavioralSignalCollector _signalCollector =
      BehavioralSignalCollector.instance;
  final TextEditingController _answerController = TextEditingController();
  late final QuizBloc _quizBloc;

  Duration _remainingTime = const Duration(minutes: 12, seconds: 45);
  bool _showHint = false;

  Timer? _countdownTimer;
  Timer? _hintTimer;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();

    _quizBloc = QuizBloc(
      quizRepository: widget.quizRepository,
      questionId: _questionId,
      questionText: _questionText,
    )..add(const QuizStarted());

    _signalCollector.attachBatchSubmitter((batch) async {
      await widget.quizRepository.submitSignals(batch);
    });
    _signalCollector.startQuestionTimer();

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
    _signalCollector.dispose();
    _answerController.dispose();
    _quizBloc.close();
    super.dispose();
  }

  void _onAnswerChanged(String value) {
    _quizBloc.add(AnswerChanged(value));

    final currentLength = value.length;

    if (currentLength > _previousLength) {
      _signalCollector.recordKeystroke(
        characterCount: currentLength - _previousLength,
      );
    } else if (currentLength < _previousLength) {
      final correctionCount = _previousLength - currentLength;
      for (var i = 0; i < correctionCount; i++) {
        _signalCollector.recordCorrection();
      }
    }

    _previousLength = currentLength;
    _signalCollector.resetIdleTimer();
  }

  void _submitCurrentAnswer() {
    _signalCollector.recordSubmit();
    _quizBloc.add(QuizSubmitted(answer: _answerController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>.value(
      value: _quizBloc,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _signalCollector.resetIdleTimer();
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: GrowMateColors.background,
          body: BlocConsumer<QuizBloc, QuizState>(
            listener: (context, state) {
              if (state is QuizFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }

              if (state is QuizSuccess) {
                context.push(
                  '${AppRoutes.diagnosis}?submissionId=${Uri.encodeQueryComponent(state.submissionId)}',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is QuizLoading;

              return ZenPageContainer(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: GrowMateColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Giải tích 12',
                            style: TextStyle(
                              color: GrowMateColors.primary,
                              fontSize: 20,
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
                          style: const TextStyle(
                            color: GrowMateColors.textSecondary,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: double.infinity,
                      color: GrowMateColors.tertiaryContainer,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 190,
                          color: GrowMateColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 52),
                    Center(
                      child: Text(
                        'CÂU HỎI SỐ $_questionNumber',
                        style: const TextStyle(
                          color: Color(0xFFA2AACF),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Tính đạo hàm của hàm\nsố',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GrowMateColors.textPrimary,
                          fontSize: 36,
                          height: 1.22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'y = 4x³ + 2x² - 5',
                        style: TextStyle(
                          color: GrowMateColors.primary,
                          fontStyle: FontStyle.italic,
                          fontSize: 37,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    GestureDetector(
                      onTap: _signalCollector.resetIdleTimer,
                      child: ZenTextField(
                        controller: _answerController,
                        onTap: _signalCollector.resetIdleTimer,
                        onChanged: _onAnswerChanged,
                        textAlign: TextAlign.center,
                        enabled: !isLoading,
                        hintText: 'Nhập kết quả của bạn…',
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedOpacity(
                      opacity: _showHint ? 1 : 0,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOut,
                        offset: _showHint ? Offset.zero : const Offset(0, 0.08),
                        child: const Text(
                          'Gợi ý nhỏ: Đạo hàm của x^n là n.x^(n-1)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GrowMateColors.textSecondary,
                            fontSize: 20,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
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
                    const Center(
                      child: Text(
                        'CẦN TRỢ GIÚP TỪ AI TUTOR?',
                        style: TextStyle(
                          color: Color(0xFFB1B1B1),
                          fontSize: 18,
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
