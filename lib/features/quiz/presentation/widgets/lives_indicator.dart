import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/lives_cubit.dart';
import '../cubit/lives_state.dart';

/// Widget hiển thị 3 trái tim ngang hàng với animation mất tim.
class LivesIndicator extends StatefulWidget {
  const LivesIndicator({super.key});

  @override
  State<LivesIndicator> createState() => _LivesIndicatorState();
}

class _LivesIndicatorState extends State<LivesIndicator>
    with TickerProviderStateMixin {
  int _previousLives = 3;
  late final List<AnimationController> _shakeControllers;
  late final List<Animation<double>> _shakeAnimations;

  @override
  void initState() {
    super.initState();
    _shakeControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _shakeAnimations = _shakeControllers
        .map(
          (ctrl) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: ctrl, curve: Curves.elasticOut)),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final ctrl in _shakeControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onStateChanged(LivesState state) {
    if (state is LivesLoaded) {
      final current = state.info.currentLives;
      if (current < _previousLives) {
        final lostIndex = current; // index of heart just lost
        if (lostIndex >= 0 && lostIndex < _shakeControllers.length) {
          _shakeControllers[lostIndex].forward(from: 0);
        }
      }
      _previousLives = current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LivesCubit, LivesState>(
      listener: (context, state) => _onStateChanged(state),
      builder: (context, state) {
        final currentLives = state is LivesLoaded ? state.info.currentLives : 3;
        final maxLives = state is LivesLoaded ? state.info.maxLives : 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxLives, (index) {
            final isFilled = index < currentLives;
            return AnimatedBuilder(
              animation:
                  _shakeAnimations[index < _shakeControllers.length
                      ? index
                      : 0],
              builder: (context, child) {
                return Transform.scale(
                  scale: isFilled
                      ? 1.0
                      : (1.0 -
                            _shakeAnimations[index < _shakeControllers.length
                                        ? index
                                        : 0]
                                    .value *
                                0.3),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isFilled ? '❤️' : '🤍',
                    key: ValueKey('heart_${index}_$isFilled'),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
