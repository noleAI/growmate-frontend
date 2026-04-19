import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';

class AgenticGlossaryPage extends StatelessWidget {
  const AgenticGlossaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terms = <_GlossaryTerm>[
      _GlossaryTerm(
        titleVi: 'HTN Planner',
        titleEn: 'HTN Planner',
        summaryVi:
            'Bộ lập kế hoạch chia mục tiêu lớn thành các bước nhỏ để AI biết nên làm gì trước, làm gì sau.',
        summaryEn:
            'The planner breaks a larger goal into smaller actions so the AI knows what to do next.',
      ),
      _GlossaryTerm(
        titleVi: 'Reasoning Trace',
        titleEn: 'Reasoning Trace',
        summaryVi:
            'Dòng suy luận tóm tắt các bước AI đã cân nhắc trước khi ra quyết định.',
        summaryEn:
            'A compact trace of the reasoning steps the AI considered before choosing an action.',
      ),
      _GlossaryTerm(
        titleVi: 'Belief State',
        titleEn: 'Belief State',
        summaryVi:
            'Ước lượng hiện tại của hệ thống về mức hiểu bài của học sinh ở từng nhóm kiến thức.',
        summaryEn:
            'The system’s current estimate of the learner’s mastery across knowledge areas.',
      ),
      _GlossaryTerm(
        titleVi: 'Particle Filter',
        titleEn: 'Particle Filter',
        summaryVi:
            'Mô hình theo dõi trạng thái tập trung, bối rối hay mệt mỏi từ tín hiệu hành vi trong phiên học.',
        summaryEn:
            'A model that tracks focus, confusion, or fatigue from behavioral signals during the session.',
      ),
      _GlossaryTerm(
        titleVi: 'Q-Values',
        titleEn: 'Q-Values',
        summaryVi:
            'Điểm số nội bộ giúp AI chọn hành động nào có khả năng hiệu quả nhất ở trạng thái hiện tại.',
        summaryEn:
            'Internal scores that help the AI choose the action most likely to work in the current state.',
      ),
      _GlossaryTerm(
        titleVi: 'Intervention Plan',
        titleEn: 'Intervention Plan',
        summaryVi:
            'Kế hoạch hỗ trợ tiếp theo, ví dụ ôn lại quy tắc, luyện nhẹ, nghỉ ngắn hoặc mời người hướng dẫn.',
        summaryEn:
            'The next support plan, such as review, lighter practice, a short break, or human help.',
      ),
      _GlossaryTerm(
        titleVi: 'HITL',
        titleEn: 'HITL',
        summaryVi:
            'Human-in-the-loop: khi AI chưa đủ chắc chắn, hệ thống xin thêm xác nhận từ con người.',
        summaryEn:
            'Human-in-the-loop: when the AI is uncertain, the system asks for human confirmation.',
      ),
      _GlossaryTerm(
        titleVi: 'Fallback',
        titleEn: 'Fallback',
        summaryVi:
            'Phương án an toàn dùng khi backend hoặc kế hoạch chính chưa sẵn sàng, để trải nghiệm không bị đứt.',
        summaryEn:
            'A safe backup path used when the main backend plan is unavailable so the experience keeps moving.',
      ),
      _GlossaryTerm(
        titleVi: 'Session Reflection',
        titleEn: 'Session Reflection',
        summaryVi:
            'Phần tự đánh giá sau mỗi lượt, cho biết AI có nên đổi chiến lược hay không.',
        summaryEn:
            'A short reflection after each step that signals whether the AI should change strategy.',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.t(vi: 'Quay lại', en: 'Back'),
        ),
        title: Text(
          context.t(vi: 'Thuật ngữ Agentic AI', en: 'Agentic AI glossary'),
        ),
      ),
      body: ZenPageContainer(
        child: ListView(
          children: [
            Text(
              context.t(
                vi: 'Trang này giải thích ngắn gọn các thuật ngữ backend đang xuất hiện trong app.',
                en: 'This page explains the backend terms that appear across the app.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ...terms.map(
              (term) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ZenCard(
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(vi: term.titleVi, en: term.titleEn),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t(vi: term.summaryVi, en: term.summaryEn),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryTerm {
  const _GlossaryTerm({
    required this.titleVi,
    required this.titleEn,
    required this.summaryVi,
    required this.summaryEn,
  });

  final String titleVi;
  final String titleEn;
  final String summaryVi;
  final String summaryEn;
}
