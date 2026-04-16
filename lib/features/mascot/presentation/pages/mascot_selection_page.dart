import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';

// ── Mascot Model ────────────────────────────────────────────────────────────

enum MascotId { cat, fox, turtle, owl, dog, rabbit, panda, dragon, penguin }

class Mascot {
  const Mascot({
    required this.id,
    required this.emoji,
    required this.viName,
    required this.enName,
    required this.viDescription,
    required this.enDescription,
    required this.moods,
    required this.unlockHint,
  });

  final MascotId id;
  final String emoji;
  final String viName;
  final String enName;
  final String viDescription;
  final String enDescription;
  final MascotMoods moods;
  final String unlockHint;

  static const all = [
    Mascot(
      id: MascotId.cat,
      emoji: '🐱',
      viName: 'Mèo Toán',
      enName: 'Math Cat',
      viDescription: 'Dễ thương, kiên nhẫn',
      enDescription: 'Cute and patient',
      moods: MascotMoods(happy: '😺', sad: '😿', sleep: '😴'),
      unlockHint: 'Mặc định cho người mới',
    ),
    Mascot(
      id: MascotId.fox,
      emoji: '🦊',
      viName: 'Cáo Thông Minh',
      enName: 'Smart Fox',
      viDescription: 'Nhanh nhẹn, thử thách',
      enDescription: 'Agile, challenging',
      moods: MascotMoods(happy: '🦊✨', sad: '🦊🥲', sleep: '🦊💤'),
      unlockHint: 'Mở khi đạt 500 XP',
    ),
    Mascot(
      id: MascotId.turtle,
      emoji: '🐢',
      viName: 'Rùa Kiên Trì',
      enName: 'Steady Turtle',
      viDescription: 'Chậm mà chắc',
      enDescription: 'Slow but steady',
      moods: MascotMoods(happy: '🐢😊', sad: '🐢😢', sleep: '🐢💤'),
      unlockHint: 'Mở khi bỏ dở 3 lần',
    ),
    Mascot(
      id: MascotId.owl,
      emoji: '🦉',
      viName: 'Cú Đêm',
      enName: 'Night Owl',
      viDescription: 'Học khuya hiệu quả',
      enDescription: 'Efficient late-night learner',
      moods: MascotMoods(happy: '🦉😃', sad: '🦉😔', sleep: '🦉💤'),
      unlockHint: 'Mở khi học sau 21:00',
    ),
    Mascot(
      id: MascotId.dog,
      emoji: '🐶',
      viName: 'Chó Đồng Hành',
      enName: 'Buddy Dog',
      viDescription: 'Trung thành, khích lệ',
      enDescription: 'Loyal cheerleader',
      moods: MascotMoods(happy: '🐶😊', sad: '🐶😢', sleep: '🐶💤'),
      unlockHint: 'Mở khi đạt 200 XP',
    ),
    Mascot(
      id: MascotId.rabbit,
      emoji: '🐰',
      viName: 'Thỏ Nhanh Nhẹn',
      enName: 'Swift Rabbit',
      viDescription: 'Nhanh, tinh tế',
      enDescription: 'Fast and nimble',
      moods: MascotMoods(happy: '🐰✨', sad: '🐰🥲', sleep: '🐰💤'),
      unlockHint: 'Mở khi hoàn thành 10 bài',
    ),
    Mascot(
      id: MascotId.panda,
      emoji: '🐼',
      viName: 'Gấu Trúc Bình Tĩnh',
      enName: 'Calm Panda',
      viDescription: 'Bình tĩnh, tập trung',
      enDescription: 'Calm and focused',
      moods: MascotMoods(happy: '🐼🙂', sad: '🐼😔', sleep: '🐼💤'),
      unlockHint: 'Mở khi đạt chuỗi 5 ngày',
    ),
    Mascot(
      id: MascotId.dragon,
      emoji: '🐲',
      viName: 'Rồng Tri Thức',
      enName: 'Scholar Dragon',
      viDescription: 'Uy nghi, trí tuệ',
      enDescription: 'Wise and majestic',
      moods: MascotMoods(happy: '🐲😄', sad: '🐲😟', sleep: '🐲💤'),
      unlockHint: 'Mở khi đạt 2000 XP',
    ),
    Mascot(
      id: MascotId.penguin,
      emoji: '🐧',
      viName: 'Chim Cánh Cụt Học',
      enName: 'Study Penguin',
      viDescription: 'Chăm chỉ, đồng đội',
      enDescription: 'Diligent team player',
      moods: MascotMoods(happy: '🐧😊', sad: '🐧😢', sleep: '🐧💤'),
      unlockHint: 'Mở khi hoàn thành 50 bài',
    ),
  ];
}

class MascotMoods {
  final String happy;
  final String sad;
  final String sleep;
  const MascotMoods({
    required this.happy,
    required this.sad,
    required this.sleep,
  });
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class MascotCubit extends Cubit<MascotId?> {
  MascotCubit() : super(null);

  void selectMascot(MascotId id) => emit(id);
}

// ── Selection Page ──────────────────────────────────────────────────────────

class MascotSelectionPage extends StatefulWidget {
  const MascotSelectionPage({super.key});

  @override
  State<MascotSelectionPage> createState() => _MascotSelectionPageState();
}

class _MascotSelectionPageState extends State<MascotSelectionPage> {
  late final MascotCubit _cubit;
  Set<MascotId> _unlocked = {MascotId.cat};
  MascotId? _initialSelected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cubit = MascotCubit();
    _loadPrefs();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedName = prefs.getString('selected_mascot');
    final unlocked = <MascotId>{MascotId.cat};
    for (final id in MascotId.values) {
      final key = 'mascot_unlocked_${id.name}';
      if (prefs.getBool(key) ?? false) unlocked.add(id);
    }

    // Auto-unlock Night Owl if current time is between 21:00 and 23:59:59
    final now = DateTime.now();
    if (now.hour >= 21 && now.hour <= 23) {
      unlocked.add(MascotId.owl);
    }

    setState(() {
      _unlocked = unlocked;
      if (selectedName != null) {
        try {
          final found = MascotId.values.firstWhere(
            (e) => e.name == selectedName,
          );
          _initialSelected = unlocked.contains(found) ? found : null;
        } catch (_) {
          _initialSelected = null;
        }
      }
      _loading = false;
    });

    if (_initialSelected != null) {
      _cubit.selectMascot(_initialSelected!);
    }
  }

  Future<void> _saveMascot(MascotId id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mascot', id.name);
    // ensure it's marked unlocked so it stays available
    await prefs.setBool('mascot_unlocked_${id.name}', true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ordered = List<Mascot>.from(Mascot.all);
    ordered.sort((a, b) {
      final aLocked = !_unlocked.contains(a.id);
      final bLocked = !_unlocked.contains(b.id);
      if (aLocked != bLocked) return aLocked ? 1 : -1;
      return Mascot.all.indexOf(a) - Mascot.all.indexOf(b);
    });

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
          titleSpacing: 0,
          title: Text(
            context.t(vi: 'Chọn Linh Vật', en: 'Choose Mascot'),
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
            children: [
              Text(
                context.t(
                  vi: 'Linh vật sẽ đồng hành cùng bạn!',
                  en: 'Your mascot will be your study buddy!',
                ),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GrowMateLayout.sectionGapLg),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: ordered.map((mascot) {
                          return BlocBuilder<MascotCubit, MascotId?>(
                            builder: (context, selected) {
                              final isSelected = selected == mascot.id;
                              final isLocked = !_unlocked.contains(mascot.id);
                              return _MascotCard(
                                mascot: mascot,
                                isSelected: isSelected,
                                isLocked: isLocked,
                                onTap: isLocked
                                    ? () {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(mascot.unlockHint),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                      }
                                    : () => _cubit.selectMascot(mascot.id),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),
              BlocBuilder<MascotCubit, MascotId?>(
                builder: (context, selected) {
                  final enabled =
                      selected != null && _unlocked.contains(selected);
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: enabled
                          ? () async {
                              await _saveMascot(selected);
                              if (context.mounted) {
                                Navigator.of(context).pop(selected);
                              }
                            }
                          : null,
                      child: Text(context.t(vi: 'Xác nhận', en: 'Confirm')),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascotCard extends StatelessWidget {
  const _MascotCard({
    required this.mascot,
    required this.isSelected,
    required this.onTap,
    required this.isLocked,
  });

  final Mascot mascot;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primaryContainer
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colors.primary : colors.outlineVariant,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mascot.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 4),
                Text(
                  mascot.unlockHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.t(vi: mascot.viName, en: mascot.enName),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.onPrimaryContainer : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(vi: mascot.viDescription, en: mascot.enDescription),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                        : colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outlineVariant,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
