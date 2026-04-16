import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/i18n/build_context_i18n.dart';
import '../../../../../core/constants/layout.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class BattleRoom {
  const BattleRoom({
    required this.code,
    required this.players,
    this.maxPlayers = 4,
    this.isStarted = false,
  });

  final String code;
  final List<BattlePlayer> players;
  final int maxPlayers;
  final bool isStarted;
}

class BattlePlayer {
  const BattlePlayer({
    required this.id,
    required this.name,
    this.score = 0,
    this.isReady = false,
  });

  final String id;
  final String name;
  final int score;
  final bool isReady;
}

// ── State ───────────────────────────────────────────────────────────────────

sealed class MultiplayerState {
  const MultiplayerState();
}

class MultiplayerIdle extends MultiplayerState {
  const MultiplayerIdle();
}

class MultiplayerWaiting extends MultiplayerState {
  const MultiplayerWaiting(this.room);
  final BattleRoom room;
}

class MultiplayerBattle extends MultiplayerState {
  const MultiplayerBattle({required this.room, required this.currentQuestion});
  final BattleRoom room;
  final int currentQuestion;
}

class MultiplayerResults extends MultiplayerState {
  const MultiplayerResults(this.room);
  final BattleRoom room;
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class MultiplayerCubit extends Cubit<MultiplayerState> {
  MultiplayerCubit() : super(const MultiplayerIdle());

  void createRoom() {
    // Mock room creation
    final room = BattleRoom(
      code: 'GM${DateTime.now().millisecondsSinceEpoch % 10000}',
      players: [const BattlePlayer(id: 'me', name: 'Bạn', isReady: true)],
    );
    emit(MultiplayerWaiting(room));
  }

  void joinRoom(String code) {
    // TODO: WebSocket join room
    final room = BattleRoom(
      code: code,
      players: [
        const BattlePlayer(id: 'me', name: 'Bạn'),
        const BattlePlayer(id: 'p2', name: 'Đối thủ'),
      ],
    );
    emit(MultiplayerWaiting(room));
  }
}

// ── Page ────────────────────────────────────────────────────────────────────

class CreateRoomPage extends StatelessWidget {
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleSpacing: 0,
        title: Text(
          context.t(vi: 'Đấu Quiz', en: 'Quiz Battle'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(GrowMateLayout.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create room
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.t(
                        vi: 'Tính năng đang phát triển',
                        en: 'Feature in development',
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(context.t(vi: 'Tạo phòng', en: 'Create room')),
            ),
            const SizedBox(height: GrowMateLayout.space16),

            // Join room
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.t(
                        vi: 'Tính năng đang phát triển',
                        en: 'Feature in development',
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: Text(context.t(vi: 'Tham gia phòng', en: 'Join room')),
            ),

            const Spacer(),

            // Info
            Center(
              child: Text(
                context.t(
                  vi: '🏗️ Cần backend WebSocket để hoạt động',
                  en: '🏗️ Requires WebSocket backend',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
