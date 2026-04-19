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
    final colors = theme.colorScheme;

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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: IconThemeData(color: colors.primary),
          titleSpacing: 0,
          title: Text(
            context.t(vi: 'Chọn Linh Vật', en: 'Choose Mascot'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.primary,
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
                  color: colors.primary.withValues(alpha: 0.9),
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
              // ── Selected mascot preview ────────────────────────────────
              BlocBuilder<MascotCubit, MascotId?>(
                builder: (context, selected) {
                  final mascot = selected != null
                      ? Mascot.all.firstWhere(
                          (m) => m.id == selected,
                          orElse: () => Mascot.all.first,
                        )
                      : null;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: mascot != null
                        ? _SelectedMascotPreview(
                            key: ValueKey(mascot.id),
                            mascot: mascot,
                            colors: colors,
                            theme: theme,
                          )
                        : _EmptyPreviewCard(colors: colors, theme: theme),
                  );
                },
              ),
              const SizedBox(height: GrowMateLayout.sectionGap),
              // ── Grid ────────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
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
                                              content: Text(
                                                context.t(
                                                  vi: mascot.unlockHint,
                                                  en: mascot.unlockHint,
                                                ),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: enabled
                          ? () async {
                              await _saveMascot(selected);
                              if (context.mounted) {
                                Navigator.of(context).pop(selected);
                              }
                            }
                          : null,
                      child: Text(
                        context.t(vi: 'Xác nhận', en: 'Confirm'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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

// ── Selected Mascot Preview ─────────────────────────────────────────────────

class _SelectedMascotPreview extends StatelessWidget {
  const _SelectedMascotPreview({
    super.key,
    required this.mascot,
    required this.colors,
    required this.theme,
  });

  final Mascot mascot;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.55),
            colors.primaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              mascot.emoji,
              style: const TextStyle(fontSize: 38),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(vi: mascot.viName, en: mascot.enName),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    vi: mascot.viDescription,
                    en: mascot.enDescription,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                // Mood preview
                Row(
                  children: [
                    _MoodChip(label: mascot.moods.happy, colors: colors),
                    const SizedBox(width: 6),
                    _MoodChip(label: mascot.moods.sad, colors: colors),
                    const SizedBox(width: 6),
                    _MoodChip(label: mascot.moods.sleep, colors: colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreviewCard extends StatelessWidget {
  const _EmptyPreviewCard({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 28,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Text(
            context.t(
              vi: 'Chọn một linh vật bên dưới',
              en: 'Pick a mascot below',
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label, required this.colors});

  final String label;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

// ── Mascot Card ─────────────────────────────────────────────────────────────

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primaryContainer,
                    colors.primaryContainer.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: isSelected ? null : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mascot.emoji,
                    style: TextStyle(
                      fontSize: isSelected ? 38 : 34,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t(vi: mascot.viName, en: mascot.enName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.t(
                      vi: mascot.viDescription,
                      en: mascot.enDescription,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colors.onPrimaryContainer.withValues(alpha: 0.7)
                          : colors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Selected check
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            // Lock overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 22,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          mascot.unlockHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
