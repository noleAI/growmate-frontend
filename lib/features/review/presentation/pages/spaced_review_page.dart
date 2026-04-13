import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/models/spaced_review_item.dart';
import '../../data/repositories/spaced_repetition_repository.dart';

class SpacedReviewPage extends StatefulWidget {
  const SpacedReviewPage({super.key});

  @override
  State<SpacedReviewPage> createState() => _SpacedReviewPageState();
}

class _SpacedReviewPageState extends State<SpacedReviewPage> {
  final _repository = SpacedRepetitionRepository.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: ZenPageContainer(
        includeBottomSafeArea: true,
        child: Column(
          children: [
            const SizedBox(height: GrowMateLayout.sectionGap),
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: context.t(vi: 'Quay lại', en: 'Back'),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    context.t(vi: 'Ôn tập ngắt quãng', en: 'Spaced Repetition'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GrowMateLayout.space8),
            Text(
              context.t(
                vi: 'Ôn tập đúng nhịp theo đường cong quên lãng',
                en: 'Review at the right pace based on the forgetting curve',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GrowMateLayout.sectionGapLg),
            Expanded(
              child: StreamBuilder<List<SpacedReviewItem>>(
                stream: _repository.watchItems(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: GrowMateLayout.space12),
                          Text(
                            context.t(
                              vi: 'Không tải được danh sách ôn tập',
                              en: 'Unable to load review list',
                            ),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: GrowMateLayout.space12),
                          FilledButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(context.t(vi: 'Thử lại', en: 'Retry')),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allItems = snapshot.data ?? const <SpacedReviewItem>[];
                  final dueItems =
                      allItems
                          .where((item) => !item.dueAt.isAfter(now))
                          .toList(growable: false)
                        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
                  final upcomingItems =
                      allItems
                          .where((item) => item.dueAt.isAfter(now))
                          .toList(growable: false)
                        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

                  if (allItems.isEmpty) {
                    return const _EmptyReviewState();
                  }

                  return ListView(
                    padding: const EdgeInsets.only(
                      bottom: GrowMateLayout.sectionGap,
                    ),
                    children: [
                      if (dueItems.isNotEmpty) ...[
                        _ReviewSection(
                          title: context.t(
                            vi: 'Cần ôn ngay (${dueItems.length})',
                            en: 'Due now (${dueItems.length})',
                          ),
                          icon: Icons.refresh_rounded,
                          iconColor: theme.colorScheme.error,
                          items: dueItems,
                          onReview: _startReviewSession,
                        ),
                        const SizedBox(height: GrowMateLayout.sectionGapLg),
                      ],
                      _ReviewSection(
                        title: context.t(
                          vi: 'Sắp đến lịch (${upcomingItems.length})',
                          en: 'Upcoming (${upcomingItems.length})',
                        ),
                        icon: Icons.schedule_rounded,
                        iconColor: theme.colorScheme.primary,
                        items: upcomingItems,
                        onReview: null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ), // ZenPageContainer
    ); // Material
  }

  Future<void> _startReviewSession(List<SpacedReviewItem> dueItems) async {
    if (dueItems.isEmpty) return;

    // Navigate to quiz with review context
    // For MVP: mark all reviewed and update intervals
    final scaffold = ScaffoldMessenger.of(context);

    for (final item in dueItems) {
      await _repository.registerStudySession(
        topic: item.topic,
        focusScore: 0.8,
        sourceKey: 'spaced_review',
      );
    }

    if (mounted) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              vi: 'Đã hoàn thành ${dueItems.length} chủ đề ôn tập! 🎉',
              en: 'Completed ${dueItems.length} review topics! 🎉',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_alt_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: GrowMateLayout.space12),
          Text(
            context.t(
              vi: 'Chưa có chủ đề nào cần ôn tập',
              en: 'No topics to review yet',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: GrowMateLayout.space8),
          Text(
            context.t(
              vi: 'Hoàn thành vài phiên học để kích hoạt ôn tập ngắt quãng nhé',
              en: 'Complete some study sessions to activate spaced repetition',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    this.onReview,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<SpacedReviewItem> items;
  final Future<void> Function(List<SpacedReviewItem>)? onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: GrowMateLayout.itemGapSm),
        if (items.isEmpty)
          Text(
            context.t(vi: 'Không có mục nào', en: 'No items'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _topicLabel(context, item.topic),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t(
                              vi: 'Chu kỳ ${item.intervalDays} ngày • Đã ôn ${item.repetitions} lần',
                              en: 'Cycle ${item.intervalDays} days • Reviewed ${item.repetitions} times',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onReview != null)
                      FilledButton.tonalIcon(
                        onPressed: () => onReview!([item]),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          context.t(vi: 'Đã ôn', en: 'Done'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (onReview != null && items.length > 1) ...[
          const SizedBox(height: GrowMateLayout.itemGapSm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onReview!(items),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                context.t(
                  vi: 'Ôn tất cả (${items.length})',
                  en: 'Review all (${items.length})',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _topicLabel(BuildContext context, String topic) {
    final labels = <String, String>{
      'derivative': context.t(vi: 'Đạo hàm', en: 'Derivatives'),
      'integral': context.t(vi: 'Nguyên hàm', en: 'Integrals'),
      'logarithm': context.t(vi: 'Logarit', en: 'Logarithms'),
      'function_analysis': context.t(
        vi: 'Khảo sát hàm số',
        en: 'Function Analysis',
      ),
    };
    return labels[topic.toLowerCase()] ?? topic;
  }
}
