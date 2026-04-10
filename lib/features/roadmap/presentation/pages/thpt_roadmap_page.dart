import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../shared/widgets/nav_tab_routing.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class ThptRoadmapPage extends StatelessWidget {
  const ThptRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: ListView(
            children: [
              Text(
                context.t(vi: 'Roadmap THPT', en: 'THPT Roadmap'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GrowMateLayout.space8),
              Text(
                context.t(
                  vi: 'Tổng hợp cơ cấu môn thi, dạng đề, dạng bài và lộ trình học theo từng môn cho kỳ thi THPT.',
                  en: 'Overview of exam structure, formats, question types, and subject-by-subject study roadmap for the THPT exam.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  context.t(
                    vi: 'Cập nhật 04/2026: Nội dung bám theo quy chế thi tốt nghiệp THPT hiện hành (ổn định từ kỳ thi 2025) và thông tin tổ chức kỳ thi THPT 2026 của Bộ GDĐT.',
                    en: 'Updated 04/2026: Content aligns with the current graduation-exam regulation (stable since 2025) and MoET updates for the 2026 THPT exam.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: GrowMateLayout.sectionGap),
              _OverviewPanel(),
              const SizedBox(height: GrowMateLayout.sectionGap),
              _SectionTitle(
                title: context.t(
                  vi: '1) Cơ cấu môn thi THPT (cập nhật 2026)',
                  en: '1) THPT exam structure (2026 update)',
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              ..._clusterData.map(
                (cluster) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ClusterCard(data: cluster),
                ),
              ),
              const SizedBox(height: GrowMateLayout.sectionGap),
              _SectionTitle(
                title: context.t(
                  vi: '2) Dạng đề và dạng bài trọng tâm',
                  en: '2) Core exam formats and question types',
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              ..._examPatternData.map(
                (pattern) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExamPatternCard(data: pattern),
                ),
              ),
              const SizedBox(height: GrowMateLayout.sectionGap),
              _SectionTitle(
                title: context.t(
                  vi: '3) Roadmap học theo từng môn',
                  en: '3) Subject-by-subject study roadmap',
                ),
              ),
              const SizedBox(height: GrowMateLayout.space12),
              ..._subjectRoadmapData.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectRoadmapCard(data: subject),
                ),
              ),
              const SizedBox(height: GrowMateLayout.space24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GrowMateBottomNavBar(
        currentTab: GrowMateTab.roadmap,
        onTabSelected: (tab) => handleTabNavigation(context, tab),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t(vi: 'Cách dùng nhanh', en: 'Quick usage'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _HintLine(
            text: context.t(
              vi: 'Chốt 2 môn bắt buộc và 2 môn tự chọn trước, rồi bám roadmap từng môn.',
              en: 'Lock your 2 compulsory and 2 elective subjects first, then follow each subject roadmap.',
            ),
          ),
          _HintLine(
            text: context.t(
              vi: 'Mỗi tuần nên có 1 vòng học chuyên đề + 1 vòng luyện đề có bấm giờ.',
              en: 'Each week should include one topic-focused cycle and one timed mock cycle.',
            ),
          ),
          _HintLine(
            text: context.t(
              vi: 'Giữ nhật ký lỗi sai theo môn để tối ưu giai đoạn nước rút.',
              en: 'Keep a per-subject error log to optimize your final sprint phase.',
            ),
          ),
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  const _ClusterCard({required this.data});

  final _ClusterData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title.of(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.note.of(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.subjects
                .map(
                  (subject) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      subject.of(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ExamPatternCard extends StatelessWidget {
  const _ExamPatternCard({required this.data});

  final _ExamPatternData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.subject.of(context),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _MiniTitle(
            title: context.t(vi: 'Dạng đề', en: 'Exam formats'),
          ),
          const SizedBox(height: 6),
          ...data.formats.map((item) => _DotLine(text: item.of(context))),
          const SizedBox(height: 8),
          _MiniTitle(
            title: context.t(
              vi: 'Dạng bài thường gặp',
              en: 'Frequent question types',
            ),
          ),
          const SizedBox(height: 6),
          ...data.questionTypes.map((item) => _DotLine(text: item.of(context))),
        ],
      ),
    );
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DotLine extends StatelessWidget {
  const _DotLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SubjectRoadmapCard extends StatelessWidget {
  const _SubjectRoadmapCard({required this.data});

  final _SubjectRoadmapData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
        iconColor: colors.primary,
        collapsedIconColor: colors.onSurfaceVariant,
        title: Text(
          data.subject.of(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          data.group.of(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.target.of(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniTitle(
            title: context.t(vi: 'Chuyên đề lõi', en: 'Core topics'),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.coreTopics
                .map(
                  (topic) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      topic.of(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _MiniTitle(
            title: context.t(
              vi: 'Dạng bài ưu tiên luyện',
              en: 'Priority question types',
            ),
          ),
          const SizedBox(height: 6),
          ...data.priorityTypes.map((item) => _DotLine(text: item.of(context))),
          const SizedBox(height: 10),
          _MiniTitle(
            title: context.t(vi: 'Lộ trình 4 chặng', en: '4-stage roadmap'),
          ),
          const SizedBox(height: 8),
          _RoadmapStepLine(
            index: 1,
            phase: context.t(vi: 'Nền tảng', en: 'Foundation'),
            duration: context.t(vi: '1-2 tuần', en: '1-2 weeks'),
            focus: data.foundationFocus.of(context),
          ),
          _RoadmapStepLine(
            index: 2,
            phase: context.t(
              vi: 'Tăng tốc chuyên đề',
              en: 'Topic acceleration',
            ),
            duration: context.t(vi: '2-3 tuần', en: '2-3 weeks'),
            focus: data.accelerationFocus.of(context),
          ),
          _RoadmapStepLine(
            index: 3,
            phase: context.t(vi: 'Luyện đề có giờ', en: 'Timed mocks'),
            duration: context.t(vi: '2 tuần', en: '2 weeks'),
            focus: data.mockFocus.of(context),
          ),
          _RoadmapStepLine(
            index: 4,
            phase: context.t(vi: 'Nước rút', en: 'Final sprint'),
            duration: context.t(vi: '7-10 ngày', en: '7-10 days'),
            focus: data.finalFocus.of(context),
          ),
        ],
      ),
    );
  }
}

class _RoadmapStepLine extends StatelessWidget {
  const _RoadmapStepLine({
    required this.index,
    required this.phase,
    required this.duration,
    required this.focus,
  });

  final int index;
  final String phase;
  final String duration;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$phase ($duration): ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: focus),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalizedText {
  const _LocalizedText({required this.vi, required this.en});

  final String vi;
  final String en;

  String of(BuildContext context) {
    return context.t(vi: vi, en: en);
  }
}

class _ClusterData {
  const _ClusterData({
    required this.icon,
    required this.title,
    required this.note,
    required this.subjects,
  });

  final IconData icon;
  final _LocalizedText title;
  final _LocalizedText note;
  final List<_LocalizedText> subjects;
}

class _ExamPatternData {
  const _ExamPatternData({
    required this.subject,
    required this.formats,
    required this.questionTypes,
  });

  final _LocalizedText subject;
  final List<_LocalizedText> formats;
  final List<_LocalizedText> questionTypes;
}

class _SubjectRoadmapData {
  const _SubjectRoadmapData({
    required this.subject,
    required this.group,
    required this.target,
    required this.coreTopics,
    required this.priorityTypes,
    required this.foundationFocus,
    required this.accelerationFocus,
    required this.mockFocus,
    required this.finalFocus,
  });

  final _LocalizedText subject;
  final _LocalizedText group;
  final _LocalizedText target;
  final List<_LocalizedText> coreTopics;
  final List<_LocalizedText> priorityTypes;
  final _LocalizedText foundationFocus;
  final _LocalizedText accelerationFocus;
  final _LocalizedText mockFocus;
  final _LocalizedText finalFocus;
}

const _clusterData = <_ClusterData>[
  _ClusterData(
    icon: Icons.menu_book_rounded,
    title: _LocalizedText(
      vi: 'Môn bắt buộc (2 môn)',
      en: 'Compulsory subjects (2)',
    ),
    note: _LocalizedText(
      vi: 'Thí sinh thi bắt buộc Toán và Ngữ văn.',
      en: 'Candidates must take Mathematics and Literature.',
    ),
    subjects: [
      _LocalizedText(vi: 'Toán', en: 'Mathematics'),
      _LocalizedText(vi: 'Ngữ văn', en: 'Literature'),
    ],
  ),
  _ClusterData(
    icon: Icons.fact_check_rounded,
    title: _LocalizedText(
      vi: 'Môn tự chọn (chọn 2/9 môn)',
      en: 'Elective subjects (choose 2/9)',
    ),
    note: _LocalizedText(
      vi: 'Theo quy chế hiện hành, thí sinh chọn 2 môn trong danh sách môn học ở lớp 12.',
      en: 'Under current regulation, candidates choose 2 subjects from the eligible Grade-12 list.',
    ),
    subjects: [
      _LocalizedText(vi: 'Ngoại ngữ', en: 'Foreign language'),
      _LocalizedText(vi: 'Lịch sử', en: 'History'),
      _LocalizedText(vi: 'Vật lý', en: 'Physics'),
      _LocalizedText(vi: 'Hóa học', en: 'Chemistry'),
      _LocalizedText(vi: 'Sinh học', en: 'Biology'),
      _LocalizedText(vi: 'Địa lý', en: 'Geography'),
      _LocalizedText(
        vi: 'GD Kinh tế & Pháp luật',
        en: 'Economic and Legal Education',
      ),
      _LocalizedText(vi: 'Tin học', en: 'Informatics'),
      _LocalizedText(vi: 'Công nghệ', en: 'Technology'),
    ],
  ),
  _ClusterData(
    icon: Icons.account_tree_rounded,
    title: _LocalizedText(
      vi: 'Nhóm định hướng tham khảo',
      en: 'Reference orientation groups',
    ),
    note: _LocalizedText(
      vi: 'Dùng để định hướng ngành học. Đây không phải cấu trúc bài thi tổ hợp bắt buộc.',
      en: 'Useful for major planning. These are not mandatory combined exam papers.',
    ),
    subjects: [
      _LocalizedText(
        vi: 'KHTN: Lý - Hóa - Sinh',
        en: 'Natural: Physics - Chemistry - Biology',
      ),
      _LocalizedText(
        vi: 'KHXH: Sử - Địa - GDKT&PL',
        en: 'Social: History - Geography - Economic & Legal Education',
      ),
    ],
  ),
];

const _examPatternData = <_ExamPatternData>[
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Toán', en: 'Mathematics'),
    formats: [
      _LocalizedText(vi: 'Đề theo chuyên đề', en: 'Topic-based sets'),
      _LocalizedText(vi: 'Đề tổng hợp 90 phút', en: 'Full 90-minute mocks'),
      _LocalizedText(
        vi: 'Đề trọng tâm vận dụng',
        en: 'Application-focused mocks',
      ),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Hàm số - mũ log',
        en: 'Functions and exponential-log topics',
      ),
      _LocalizedText(
        vi: 'Nguyên hàm - tích phân',
        en: 'Antiderivatives and integrals',
      ),
      _LocalizedText(vi: 'Hình học tọa độ Oxyz', en: '3D coordinate geometry'),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Ngữ văn', en: 'Literature'),
    formats: [
      _LocalizedText(
        vi: 'Đề đọc hiểu theo ngữ liệu',
        en: 'Reading-comprehension based tests',
      ),
      _LocalizedText(
        vi: 'Đề viết nghị luận trọn bộ',
        en: 'Full essay-writing sets',
      ),
    ],
    questionTypes: [
      _LocalizedText(vi: 'Đọc hiểu văn bản', en: 'Text comprehension'),
      _LocalizedText(vi: 'Nghị luận xã hội', en: 'Social-issue essay'),
      _LocalizedText(vi: 'Nghị luận văn học', en: 'Literary analysis essay'),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Tiếng Anh', en: 'English'),
    formats: [
      _LocalizedText(vi: 'Đề theo kỹ năng', en: 'Skill-based sets'),
      _LocalizedText(
        vi: 'Đề tổng hợp có bấm giờ',
        en: 'Timed mixed-skill mocks',
      ),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Ngữ âm - từ vựng - ngữ pháp',
        en: 'Pronunciation, vocabulary, grammar',
      ),
      _LocalizedText(
        vi: 'Đọc hiểu và điền khuyết',
        en: 'Reading and cloze tests',
      ),
      _LocalizedText(
        vi: 'Viết lại câu / tìm lỗi sai',
        en: 'Sentence transformation / error detection',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Vật lý', en: 'Physics'),
    formats: [
      _LocalizedText(vi: 'Đề chuyên đề chương', en: 'Chapter-topic sets'),
      _LocalizedText(vi: 'Đề tốc độ cao', en: 'High-speed practice tests'),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Dao động - sóng - điện xoay chiều',
        en: 'Oscillation, waves, AC circuits',
      ),
      _LocalizedText(
        vi: 'Bài toán đồ thị và thí nghiệm',
        en: 'Graph and experiment items',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Hóa học', en: 'Chemistry'),
    formats: [
      _LocalizedText(vi: 'Đề theo chủ đề phản ứng', en: 'Reaction-theme sets'),
      _LocalizedText(
        vi: 'Đề tổng hợp lý thuyết + tính toán',
        en: 'Mixed theory-calculation mocks',
      ),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Hữu cơ - vô cơ trọng tâm',
        en: 'Core organic and inorganic chemistry',
      ),
      _LocalizedText(
        vi: 'Bảo toàn, biện luận, nhận biết',
        en: 'Conservation, inference, identification',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Sinh học', en: 'Biology'),
    formats: [
      _LocalizedText(
        vi: 'Đề theo mạch kiến thức',
        en: 'Knowledge-stream tests',
      ),
      _LocalizedText(
        vi: 'Đề tổng hợp di truyền - tiến hóa',
        en: 'Genetics-evolution mixed mocks',
      ),
    ],
    questionTypes: [
      _LocalizedText(vi: 'Di truyền học', en: 'Genetics'),
      _LocalizedText(vi: 'Sinh thái và tiến hóa', en: 'Ecology and evolution'),
      _LocalizedText(vi: 'Sinh học cơ thể', en: 'Organism biology'),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Lịch sử', en: 'History'),
    formats: [
      _LocalizedText(
        vi: 'Đề theo giai đoạn lịch sử',
        en: 'Period-based history sets',
      ),
      _LocalizedText(vi: 'Đề mốc sự kiện', en: 'Milestone-event tests'),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Nhận biết mốc thời gian',
        en: 'Timeline and chronology items',
      ),
      _LocalizedText(
        vi: 'So sánh sự kiện - nguyên nhân',
        en: 'Event comparison and causality',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Địa lý', en: 'Geography'),
    formats: [
      _LocalizedText(vi: 'Đề phân tích Atlat', en: 'Atlas-focused tests'),
      _LocalizedText(
        vi: 'Đề kỹ năng bảng số liệu',
        en: 'Data-table skill tests',
      ),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Nhận xét biểu đồ - bảng số liệu',
        en: 'Chart and data-table interpretation',
      ),
      _LocalizedText(
        vi: 'Địa lý tự nhiên - kinh tế Việt Nam',
        en: 'Vietnam physical and economic geography',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(
      vi: 'GD Kinh tế và Pháp luật',
      en: 'Economic and Legal Education',
    ),
    formats: [
      _LocalizedText(
        vi: 'Đề tình huống thực tiễn',
        en: 'Real-world case-based tests',
      ),
      _LocalizedText(vi: 'Đề phân tích lựa chọn', en: 'Decision-analysis sets'),
    ],
    questionTypes: [
      _LocalizedText(vi: 'Tư duy pháp lý cơ bản', en: 'Basic legal reasoning'),
      _LocalizedText(
        vi: 'Kinh tế thị trường và công dân',
        en: 'Market economics and citizenship',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Tin học', en: 'Informatics'),
    formats: [
      _LocalizedText(
        vi: 'Đề theo chủ đề thuật toán',
        en: 'Algorithm-theme sets',
      ),
      _LocalizedText(vi: 'Đề ứng dụng CNTT', en: 'IT application sets'),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Tư duy thuật toán và dữ liệu',
        en: 'Algorithmic and data thinking',
      ),
      _LocalizedText(
        vi: 'Mạng, an toàn thông tin, ứng dụng số',
        en: 'Networks, cybersecurity, digital tools',
      ),
    ],
  ),
  _ExamPatternData(
    subject: _LocalizedText(vi: 'Công nghệ', en: 'Technology'),
    formats: [
      _LocalizedText(
        vi: 'Đề quy trình kỹ thuật',
        en: 'Technical-process tests',
      ),
      _LocalizedText(
        vi: 'Đề bối cảnh sản xuất',
        en: 'Production-context tests',
      ),
    ],
    questionTypes: [
      _LocalizedText(
        vi: 'Thiết kế và vận hành hệ thống',
        en: 'System design and operation',
      ),
      _LocalizedText(
        vi: 'Ứng dụng công nghệ theo ngành',
        en: 'Industry-specific technology applications',
      ),
    ],
  ),
];

const _subjectRoadmapData = <_SubjectRoadmapData>[
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Toán', en: 'Mathematics'),
    group: _LocalizedText(vi: 'Bắt buộc', en: 'Compulsory'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.5 - 9.0+',
      en: 'Suggested target: 7.5 - 9.0+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Hàm số', en: 'Functions'),
      _LocalizedText(vi: 'Mũ - log', en: 'Exponential - logarithm'),
      _LocalizedText(
        vi: 'Nguyên hàm - tích phân',
        en: 'Antiderivatives - integrals',
      ),
      _LocalizedText(vi: 'Oxyz', en: '3D coordinates'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Bài vận dụng thực tế',
        en: 'Applied real-world items',
      ),
      _LocalizedText(
        vi: 'Bài đồ thị và tối ưu',
        en: 'Graph and optimization items',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Chốt công thức, nhận diện nhanh dạng bài trong từng chuyên đề.',
      en: 'Lock core formulas and quickly identify question families by topic.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện chuỗi 20-30 câu theo chuyên đề yếu nhất.',
      en: 'Run 20-30 question streaks on your weakest topics.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm 2-3 đề/tuần có bấm giờ, kiểm soát tốc độ và độ chính xác.',
      en: 'Take 2-3 timed mocks per week and optimize speed-accuracy balance.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn nhật ký lỗi sai và bộ câu hay nhầm trước ngày thi.',
      en: 'Review error logs and high-mistake items before exam day.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Ngữ văn', en: 'Literature'),
    group: _LocalizedText(vi: 'Bắt buộc', en: 'Compulsory'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.5+',
      en: 'Suggested target: 7.0 - 8.5+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Đọc hiểu', en: 'Reading comprehension'),
      _LocalizedText(vi: 'Nghị luận xã hội', en: 'Social essay'),
      _LocalizedText(vi: 'Nghị luận văn học', en: 'Literary essay'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Phân tích đoạn thơ/đoạn văn',
        en: 'Poetry/prose analysis',
      ),
      _LocalizedText(
        vi: 'Liên hệ mở rộng và lập luận',
        en: 'Extended linkage and argumentation',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Xây dàn ý mẫu, học cách triển khai luận điểm rõ ràng.',
      en: 'Build essay templates and clear argument structures.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Viết đoạn theo đề mở, luyện kỹ năng dẫn chứng đúng trọng tâm.',
      en: 'Practice open prompts and sharpen evidence relevance.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề trọn bộ theo thời gian thực, tự chấm theo rubric.',
      en: 'Complete full timed sets and self-grade with rubric criteria.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn các mở bài/kết bài linh hoạt và danh sách lỗi diễn đạt.',
      en: 'Review flexible openings/closings and expression error list.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Tiếng Anh', en: 'English'),
    group: _LocalizedText(vi: 'Tự chọn', en: 'Elective'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.5 - 9.0+',
      en: 'Suggested target: 7.5 - 9.0+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Ngữ pháp trọng tâm', en: 'Core grammar'),
      _LocalizedText(vi: 'Từ vựng theo chủ đề', en: 'Thematic vocabulary'),
      _LocalizedText(vi: 'Đọc hiểu', en: 'Reading comprehension'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Điền khuyết và paraphrase',
        en: 'Cloze tests and paraphrase',
      ),
      _LocalizedText(vi: 'Tìm lỗi sai', en: 'Error identification'),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Chuẩn hóa ngữ pháp cốt lõi và bộ từ vựng tần suất cao.',
      en: 'Standardize core grammar and high-frequency vocabulary bank.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện theo kỹ năng riêng: grammar, reading, lexical choice.',
      en: 'Train by sub-skill: grammar, reading, lexical choice.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tổng hợp và theo dõi thời gian từng phần.',
      en: 'Take mixed mocks and track timing for each section.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn bộ bẫy ngữ pháp và cụm từ dễ nhiễu.',
      en: 'Review tricky grammar traps and confusing collocations.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Vật lý', en: 'Physics'),
    group: _LocalizedText(vi: 'Khoa học tự nhiên', en: 'Natural sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.8+',
      en: 'Suggested target: 7.0 - 8.8+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Dao động - sóng', en: 'Oscillation - waves'),
      _LocalizedText(vi: 'Điện xoay chiều', en: 'Alternating current'),
      _LocalizedText(vi: 'Lượng tử ánh sáng', en: 'Quantum/light topics'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Bài đồ thị, phân tích hiện tượng',
        en: 'Graph and phenomenon analysis',
      ),
      _LocalizedText(
        vi: 'Bài tổng hợp nhiều công thức',
        en: 'Multi-formula synthesis problems',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Học chắc mô hình vật lý và công thức nền theo từng chương.',
      en: 'Secure physical models and base formulas chapter by chapter.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện bài phân loại nhanh theo dấu hiệu đề.',
      en: 'Practice fast pattern classification by clue signals.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tốc độ, đặt mốc thời gian cho mỗi 10 câu.',
      en: 'Train with speed mocks and strict time checkpoints.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn lỗi suy luận đơn vị, dấu và quy ước đại lượng.',
      en: 'Review unit, sign, and quantity-convention reasoning errors.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Hóa học', en: 'Chemistry'),
    group: _LocalizedText(vi: 'Khoa học tự nhiên', en: 'Natural sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.8+',
      en: 'Suggested target: 7.0 - 8.8+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Hữu cơ', en: 'Organic chemistry'),
      _LocalizedText(vi: 'Vô cơ', en: 'Inorganic chemistry'),
      _LocalizedText(vi: 'Hóa lý - điện hóa', en: 'Physical/electro chemistry'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Bảo toàn khối lượng, e, nguyên tố',
        en: 'Mass/electron/element conservation',
      ),
      _LocalizedText(
        vi: 'Nhận biết và biện luận phản ứng',
        en: 'Reaction identification and inference',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Hệ thống hóa chuỗi phản ứng và điều kiện phản ứng trọng tâm.',
      en: 'Systematize reaction chains and key reaction conditions.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện cụm bài tính nhanh theo phương pháp bảo toàn.',
      en: 'Drill fast-solving clusters using conservation methods.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề trộn lý thuyết - tính toán để giữ nhịp ổn định.',
      en: 'Run mixed theory-calculation mocks for stable pacing.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn bộ phương trình và các ngoại lệ dễ nhầm.',
      en: 'Review equation packs and frequently confused exceptions.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Sinh học', en: 'Biology'),
    group: _LocalizedText(vi: 'Khoa học tự nhiên', en: 'Natural sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.5+',
      en: 'Suggested target: 7.0 - 8.5+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Di truyền', en: 'Genetics'),
      _LocalizedText(vi: 'Sinh thái', en: 'Ecology'),
      _LocalizedText(vi: 'Tiến hóa', en: 'Evolution'),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Bài phân tích sơ đồ phả hệ',
        en: 'Pedigree-analysis items',
      ),
      _LocalizedText(
        vi: 'Bài đọc dữ liệu sinh học',
        en: 'Biological data interpretation',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Nắm bản chất cơ chế sinh học trước khi làm bài công thức.',
      en: 'Master biological mechanisms before formula-style questions.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện câu vận dụng di truyền và xác suất tổ hợp.',
      en: 'Practice genetics application and combinational probability.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tổng hợp theo mạch kiến thức để tăng tốc phản xạ.',
      en: 'Take integrated topic-stream mocks to improve response speed.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn bảng lỗi nhầm thuật ngữ và điều kiện bài toán.',
      en: 'Review term-confusion and condition-interpretation errors.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Lịch sử', en: 'History'),
    group: _LocalizedText(vi: 'Khoa học xã hội', en: 'Social sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 9.0+',
      en: 'Suggested target: 7.0 - 9.0+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Lịch sử Việt Nam', en: 'Vietnam history'),
      _LocalizedText(vi: 'Lịch sử thế giới', en: 'World history'),
      _LocalizedText(
        vi: 'Giai đoạn cận - hiện đại',
        en: 'Modern and contemporary periods',
      ),
    ],
    priorityTypes: [
      _LocalizedText(vi: 'Nhận diện mốc thời gian', en: 'Timeline recognition'),
      _LocalizedText(
        vi: 'So sánh, liên hệ sự kiện',
        en: 'Event comparison and linkage',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Lập trục thời gian tổng quát cho từng giai đoạn lớn.',
      en: 'Build macro timelines for each major historical period.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện cụm câu nguyên nhân - kết quả - ý nghĩa.',
      en: 'Drill cause-effect-significance clusters.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề theo giai đoạn và đề trộn để tránh học tủ.',
      en: 'Alternate period-based and mixed mocks to avoid narrow prep.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Rà lại các mốc dễ đảo thứ tự và bộ câu sai nhiều lần.',
      en: 'Recheck confusing chronology points and repeated wrong items.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Địa lý', en: 'Geography'),
    group: _LocalizedText(vi: 'Khoa học xã hội', en: 'Social sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.8+',
      en: 'Suggested target: 7.0 - 8.8+',
    ),
    coreTopics: [
      _LocalizedText(
        vi: 'Địa lý tự nhiên Việt Nam',
        en: 'Vietnam physical geography',
      ),
      _LocalizedText(
        vi: 'Địa lý kinh tế - xã hội',
        en: 'Socio-economic geography',
      ),
      _LocalizedText(
        vi: 'Kỹ năng Atlat, biểu đồ',
        en: 'Atlas and chart skills',
      ),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Nhận xét bảng số liệu - biểu đồ',
        en: 'Data-table and chart interpretation',
      ),
      _LocalizedText(
        vi: 'Xử lý câu hỏi Atlat',
        en: 'Atlas-based reasoning items',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Ôn khung kiến thức vùng lãnh thổ và chỉ số kinh tế chính.',
      en: 'Review region frameworks and key economic indicators.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện nhanh dạng câu Atlat và dữ liệu bảng.',
      en: 'Speed-train Atlas and table-based question families.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tổng hợp có ghi chú quy tắc nhận xét biểu đồ.',
      en: 'Run mixed mocks with chart-interpretation rule notes.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn checklist lỗi về đơn vị, chiều tăng giảm và xu hướng.',
      en: 'Review checklists for units, trend direction, and variation.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(
      vi: 'GD Kinh tế và Pháp luật',
      en: 'Economic and Legal Education',
    ),
    group: _LocalizedText(vi: 'Khoa học xã hội', en: 'Social sciences'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.8+',
      en: 'Suggested target: 7.0 - 8.8+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Pháp luật cơ bản', en: 'Basic law concepts'),
      _LocalizedText(vi: 'Kinh tế thị trường', en: 'Market economy'),
      _LocalizedText(
        vi: 'Quyền và nghĩa vụ công dân',
        en: 'Citizenship rights and duties',
      ),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Tình huống pháp lý thực tiễn',
        en: 'Practical legal situations',
      ),
      _LocalizedText(
        vi: 'Phân tích lựa chọn kinh tế',
        en: 'Economic decision analysis',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Nắm chắc khái niệm và hệ quy chiếu pháp lý cốt lõi.',
      en: 'Secure core concepts and legal reference framework.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện bộ câu tình huống theo từng nhóm quyền/nghĩa vụ.',
      en: 'Practice scenario banks by rights/duties categories.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tình huống tổng hợp để tăng kỹ năng suy luận nhanh.',
      en: 'Run integrated scenario mocks for fast reasoning.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn lỗi sai khái niệm và các cặp khái niệm dễ nhầm.',
      en: 'Review concept confusion errors and look-alike term pairs.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Tin học', en: 'Informatics'),
    group: _LocalizedText(vi: 'Môn tự chọn mở rộng', en: 'Extended elective'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.5+',
      en: 'Suggested target: 7.0 - 8.5+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Thuật toán cơ bản', en: 'Basic algorithms'),
      _LocalizedText(vi: 'Dữ liệu và biểu diễn', en: 'Data representation'),
      _LocalizedText(
        vi: 'Mạng và an toàn số',
        en: 'Networks and digital safety',
      ),
    ],
    priorityTypes: [
      _LocalizedText(vi: 'Câu logic thuật toán', en: 'Algorithmic logic items'),
      _LocalizedText(vi: 'Câu ứng dụng CNTT', en: 'IT application items'),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Củng cố tư duy thuật toán và các khái niệm dữ liệu nền.',
      en: 'Strengthen algorithmic thinking and foundational data concepts.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện nhóm câu logic và xử lý tình huống số.',
      en: 'Practice logic clusters and digital-scenario handling.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề tổng hợp kết hợp kỹ năng mạng và thuật toán.',
      en: 'Take integrated mocks combining network and algorithm skills.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn checklist khái niệm nền và lỗi đọc đề nhanh.',
      en: 'Review core concept checklist and fast-reading mistakes.',
    ),
  ),
  _SubjectRoadmapData(
    subject: _LocalizedText(vi: 'Công nghệ', en: 'Technology'),
    group: _LocalizedText(vi: 'Môn tự chọn mở rộng', en: 'Extended elective'),
    target: _LocalizedText(
      vi: 'Mục tiêu gợi ý: 7.0 - 8.5+',
      en: 'Suggested target: 7.0 - 8.5+',
    ),
    coreTopics: [
      _LocalizedText(vi: 'Thiết kế kỹ thuật', en: 'Technical design'),
      _LocalizedText(vi: 'Quy trình sản xuất', en: 'Production processes'),
      _LocalizedText(
        vi: 'Ứng dụng công nghệ theo ngành',
        en: 'Sector-based technology applications',
      ),
    ],
    priorityTypes: [
      _LocalizedText(
        vi: 'Câu quy trình và lựa chọn vật liệu',
        en: 'Process and material-selection items',
      ),
      _LocalizedText(
        vi: 'Câu ứng dụng bối cảnh thực tế',
        en: 'Contextual application items',
      ),
    ],
    foundationFocus: _LocalizedText(
      vi: 'Ôn chuẩn thuật ngữ kỹ thuật và sơ đồ quy trình cốt lõi.',
      en: 'Review standard technical terms and core process diagrams.',
    ),
    accelerationFocus: _LocalizedText(
      vi: 'Luyện câu tình huống sản xuất, vận hành và tối ưu.',
      en: 'Practice production-operation-optimization scenarios.',
    ),
    mockFocus: _LocalizedText(
      vi: 'Làm đề theo bối cảnh tổng hợp để tăng năng lực suy luận.',
      en: 'Run integrated-context mocks to improve practical reasoning.',
    ),
    finalFocus: _LocalizedText(
      vi: 'Ôn nhanh bảng lỗi khái niệm và bộ câu dễ nhiễu.',
      en: 'Quick-review concept confusion tables and tricky items.',
    ),
  ),
];
