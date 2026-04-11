import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../services/mindful_sound_service.dart';

class MindfulBreakPage extends StatefulWidget {
  const MindfulBreakPage({super.key});

  @override
  State<MindfulBreakPage> createState() => _MindfulBreakPageState();
}

class _MindfulBreakPageState extends State<MindfulBreakPage> {
  static const int _totalSeconds = 90;
  static const int _cycleSeconds = 8;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;
  final MindfulSoundService _soundService = MindfulSoundService();
  MindfulSoundPreset _selectedSoundPreset = MindfulSoundPreset.rain;
  bool _soundEnabled = false;
  double _soundVolume = 0.42;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) {
        _timer?.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _soundEnabled = false;
        });
        unawaited(_soundService.stop());
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_soundService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
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
                const SizedBox(width: 4),
                Text(
                  context.t(vi: 'Nghỉ thở 90 giây', en: 'Mindful Break'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
            Text(
              context.t(
                vi: 'Dành 90 giây để hít thở nhẹ, giúp hệ thần kinh ổn định trước khi quay lại học.',
                en: 'Take 90 seconds of gentle breathing to calm your nervous system before returning to study.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: GrowMateLayout.contentGap),
            ZenCard(
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        color: GrowMateColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t(
                            vi: 'Âm thanh thư giãn',
                            en: 'Relaxing sounds',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _soundEnabled,
                        onChanged: (value) {
                          unawaited(_toggleSound(value));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t(
                      vi: 'Bật nhạc nền dịu nhẹ để dễ thả lỏng hơn trong lúc hít thở.',
                      en: 'Enable gentle ambient audio to relax more easily while breathing.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (_soundEnabled) ...[
                    const SizedBox(height: GrowMateLayout.space12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MindfulSoundPreset.values
                          .map((preset) {
                            final isSelected = _selectedSoundPreset == preset;

                            return ChoiceChip(
                              label: Text(
                                _soundPresetLabel(context, preset),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? GrowMateColors.textPrimary
                                      : GrowMateColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              selected: isSelected,
                              checkmarkColor: GrowMateColors.textPrimary,
                              backgroundColor: GrowMateColors.surface,
                              selectedColor: GrowMateColors.tertiaryContainer,
                              side: BorderSide.none,
                              onSelected: (selected) {
                                if (!selected) {
                                  return;
                                }
                                unawaited(_selectSoundPreset(preset));
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: GrowMateColors.textSecondary,
                        ),
                        Expanded(
                          child: Slider(
                            value: _soundVolume,
                            min: 0.1,
                            max: 0.8,
                            divisions: 7,
                            label: _soundVolume.toStringAsFixed(2),
                            onChanged: (value) {
                              setState(() {
                                _soundVolume = value;
                              });
                              if (_soundEnabled) {
                                unawaited(_soundService.setVolume(value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          GrowMateColors.primary,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeInOut,
                      width: _phaseScale(),
                      height: _phaseScale(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GrowMateColors.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phaseLabel(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: GrowMateColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatSeconds(_remainingSeconds),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: GrowMateColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            ZenCard(
              radius: 20,
              child: Text(
                _remainingSeconds == 0
                    ? context.t(
                        vi: 'Tuyệt vời. Bạn vừa điều hòa nhịp thở thành công, giờ có thể quay lại phiên học nhé.',
                        en: 'Great job. You have reset your breathing rhythm and can return to studying now.',
                      )
                    : context.t(
                        vi: 'Gợi ý: hít sâu bằng mũi 4 giây, thở ra chậm 4 giây. Không cần cố gắng quá, chỉ cần đều nhịp.',
                        en: 'Tip: breathe in through your nose for 4 seconds, then exhale slowly for 4 seconds. Keep it gentle and steady.',
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGap),
            ZenButton(
              label: _remainingSeconds == 0
                  ? context.t(
                      vi: 'Quay lại lộ trình học',
                      en: 'Return to study plan',
                    )
                  : context.t(
                      vi: 'Kết thúc break nhẹ nhàng',
                      en: 'End break gently',
                    ),
              onPressed: () {
                context.go(AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(BuildContext context) {
    if (_remainingSeconds == 0) {
      return context.t(vi: 'Hoàn thành', en: 'Complete');
    }

    final elapsed = _totalSeconds - _remainingSeconds;
    final inCycle = elapsed % _cycleSeconds;
    return inCycle < 4
        ? context.t(vi: 'Hít vào', en: 'Breathe in')
        : context.t(vi: 'Thở ra', en: 'Breathe out');
  }

  String _soundPresetLabel(BuildContext context, MindfulSoundPreset preset) {
    switch (preset) {
      case MindfulSoundPreset.rain:
        return context.t(vi: 'Mưa nhẹ', en: 'Light rain');
      case MindfulSoundPreset.ocean:
        return context.t(vi: 'Sóng biển', en: 'Ocean waves');
      case MindfulSoundPreset.chimes:
        return context.t(vi: 'Chuông gió', en: 'Wind chimes');
    }
  }

  Future<void> _toggleSound(bool enabled) async {
    if (!enabled) {
      await _soundService.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _soundEnabled = false;
      });
      return;
    }

    try {
      await _soundService.play(
        preset: _selectedSoundPreset,
        volume: _soundVolume,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _soundEnabled = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Mình chưa bật được âm thanh lúc này, bạn thử lại giúp mình nhé.',
                en: 'Unable to enable sound right now. Please try again.',
              ),
            ),
          ),
        );
    }
  }

  Future<void> _selectSoundPreset(MindfulSoundPreset preset) async {
    setState(() {
      _selectedSoundPreset = preset;
    });

    if (!_soundEnabled) {
      return;
    }

    try {
      await _soundService.play(preset: preset, volume: _soundVolume);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Không đổi được âm thanh lúc này, bạn thử lại nhé.',
                en: 'Unable to switch sound right now. Please try again.',
              ),
            ),
          ),
        );
    }
  }

  double _phaseScale() {
    if (_remainingSeconds == 0) {
      return 120;
    }

    final elapsed = _totalSeconds - _remainingSeconds;
    final inCycle = elapsed % _cycleSeconds;
    return inCycle < 4 ? 126 : 104;
  }

  static String _formatSeconds(int value) {
    final minutes = (value ~/ 60).toString().padLeft(2, '0');
    final seconds = (value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
