import 'package:flutter/material.dart';

import '../../../quiz/presentation/widgets/quiz_math_text.dart';
import '../../domain/entities/chat_message.dart';

import '../../../mascot/presentation/pages/mascot_selection_page.dart';

enum _AssistantTone { standard, fallback, quota }

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.botMascot,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final MascotId? botMascot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUser = message.role == ChatRole.user;
    final assistantTone = _assistantTone;
    final bubbleWidth =
        MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.82);
    final bubbleGradient = _bubbleGradient(theme, assistantTone, isUser);
    final borderColor = _bubbleBorderColor(theme, assistantTone, isUser);
    final accentColor = _accentColor(theme, assistantTone, isUser);
    final footerColor = isUser
        ? colors.onPrimary.withValues(alpha: 0.80)
        : colors.onSurfaceVariant.withValues(alpha: 0.80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAssistantAvatar(theme, assistantTone),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: bubbleWidth),
            child: GestureDetector(
              onLongPress: onCopy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  gradient: bubbleGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 8),
                    bottomRight: Radius.circular(isUser ? 8 : 22),
                  ),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: isUser ? 0.10 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      _buildAssistantHeader(theme, assistantTone),
                      const SizedBox(height: 12),
                    ],
                    _buildContent(theme, isUser, accentColor),
                    if (!isUser && _hasProcessingDetails) ...[
                      const SizedBox(height: 12),
                      _buildProcessingPanel(theme, assistantTone),
                    ],
                    const SizedBox(height: 10),
                    _buildFooter(theme, isUser, footerColor),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar(ThemeData theme, _AssistantTone tone) {
    final accent = _accentColor(theme, tone, false);

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
      ),
      alignment: Alignment.center,
      child: botMascot != null
          ? Text(
              Mascot.all.firstWhere((m) => m.id == botMascot!).emoji,
              style: const TextStyle(fontSize: 17),
            )
          : Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
    );
  }

  Widget _buildContent(ThemeData theme, bool isUser, Color accentColor) {
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final hasImage =
        (message.imageBytes != null && message.imageBytes!.isNotEmpty) ||
        (message.imageUrl != null && message.imageUrl!.trim().isNotEmpty);
    final hasText = message.content.trim().isNotEmpty;

    if (hasImage) {
      const imageWidth = 220.0;
      const imageHeight = 160.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildImagePreview(width: imageWidth, height: imageHeight),
          ),
          if (hasText) ...[
            const SizedBox(height: 10),
            _buildTextContent(theme, textColor, accentColor, isUser),
          ],
        ],
      );
    }

    return _buildTextContent(theme, textColor, accentColor, isUser);
  }

  Widget _buildAssistantHeader(ThemeData theme, _AssistantTone tone) {
    final colors = theme.colorScheme;
    final accent = _accentColor(theme, tone, false);
    final badgeLabel = switch (tone) {
      _AssistantTone.quota => 'Giới hạn hôm nay',
      _AssistantTone.fallback => 'Chế độ dự phòng',
      _AssistantTone.standard => 'Gia sư AI',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    badgeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_nodeLabel != null)
                    _buildMetaPill(
                      theme,
                      label: _nodeLabel!,
                      icon: Icons.account_tree_outlined,
                    ),
                  if (message.planRepaired)
                    _buildMetaPill(
                      theme,
                      label: 'Đã tự sửa kế hoạch',
                      icon: Icons.build_circle_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerLowest,
              foregroundColor: colors.onSurfaceVariant,
            ),
            icon: const Icon(Icons.content_copy_rounded, size: 16),
            tooltip: 'Sao chép',
          ),
      ],
    );
  }

  Widget _buildMetaPill(
    ThemeData theme, {
    required String label,
    required IconData icon,
  }) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({required double width, required double height}) {
    if (message.imageBytes != null && message.imageBytes!.isNotEmpty) {
      return Image.memory(
        message.imageBytes!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        cacheWidth: 660,
        filterQuality: FilterQuality.low,
      );
    }

    final imageUrl = message.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  Widget _buildTextContent(
    ThemeData theme,
    Color textColor,
    Color accentColor,
    bool isUser,
  ) {
    return _ChatFormattedText(
      text: message.content,
      textColor: textColor,
      accentColor: accentColor,
      theme: theme,
      emphasizeLead: !isUser && _assistantTone == _AssistantTone.standard,
    );
  }

  Widget _buildProcessingPanel(ThemeData theme, _AssistantTone tone) {
    final colors = theme.colorScheme;
    final accent = _accentColor(theme, tone, false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'AI vừa xử lý',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ((message.processingSummary ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message.processingSummary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (message.processingTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.processingTags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isUser, Color footerColor) {
    final colors = theme.colorScheme;

    return Row(
      children: [
        if (!isUser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _assistantTone == _AssistantTone.standard
                  ? 'Phản hồi AI'
                  : _assistantTone == _AssistantTone.quota
                  ? 'Nhắc giới hạn'
                  : 'Tin nhắn hệ thống',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (!isUser) const SizedBox(width: 8),
        if (message.beliefEntropy != null && !isUser) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Entropy ${message.beliefEntropy!.toStringAsFixed(2)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Icon(
          isUser ? Icons.arrow_upward_rounded : Icons.schedule_rounded,
          size: 12,
          color: footerColor,
        ),
        const SizedBox(width: 4),
        Text(
          _formatTime(message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: footerColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Gradient _bubbleGradient(ThemeData theme, _AssistantTone tone, bool isUser) {
    final colors = theme.colorScheme;
    if (isUser) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.primary, colors.primary.withValues(alpha: 0.92)],
      );
    }

    return switch (tone) {
      _AssistantTone.standard => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFAFBFD)],
      ),
      _AssistantTone.fallback => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFCF6), Color(0xFFFFF7EA)],
      ),
      _AssistantTone.quota => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8FBFD), Color(0xFFF0F7FA)],
      ),
    };
  }

  Color _bubbleBorderColor(ThemeData theme, _AssistantTone tone, bool isUser) {
    final colors = theme.colorScheme;
    if (isUser) {
      return colors.primary.withValues(alpha: 0.18);
    }

    return _accentColor(theme, tone, false).withValues(alpha: 0.18);
  }

  Color _accentColor(ThemeData theme, _AssistantTone tone, bool isUser) {
    final colors = theme.colorScheme;
    if (isUser) {
      return colors.primary;
    }

    return switch (tone) {
      _AssistantTone.standard => const Color(0xFF2E6EEB),
      _AssistantTone.fallback => const Color(0xFFB7791F),
      _AssistantTone.quota => const Color(0xFF2C7A7B),
    };
  }

  _AssistantTone get _assistantTone {
    if (message.role == ChatRole.user) {
      return _AssistantTone.standard;
    }

    final normalized = message.content.toLowerCase();
    if (normalized.contains('hết lượt chat') ||
        normalized.contains('ngày mai') ||
        normalized.contains('giới hạn')) {
      return _AssistantTone.quota;
    }
    if (normalized.startsWith('xin lỗi') || normalized.contains('thử lại')) {
      return _AssistantTone.fallback;
    }
    return _AssistantTone.standard;
  }

  String? get _nodeLabel {
    return switch (message.nextNodeType?.trim()) {
      'hint' => 'Đang gợi ý',
      'show_hint' => 'Gợi ý học tập',
      'de_stress' => 'Hỗ trợ giảm áp lực',
      'recovery' => 'Nhắc phục hồi tiến độ',
      'hitl_pending' => 'Cần xác nhận thêm',
      'backtrack_repair' => 'Đã dò lại hướng xử lý',
      final raw? when raw.isNotEmpty => raw.replaceAll('_', ' '),
      _ => null,
    };
  }

  bool get _hasProcessingDetails {
    return (message.processingSummary ?? '').trim().isNotEmpty ||
        message.processingTags.isNotEmpty;
  }

  static String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatFormattedText extends StatelessWidget {
  const _ChatFormattedText({
    required this.text,
    required this.textColor,
    required this.accentColor,
    required this.theme,
    required this.emphasizeLead,
  });

  final String text;
  final Color textColor;
  final Color accentColor;
  final ThemeData theme;
  final bool emphasizeLead;

  @override
  Widget build(BuildContext context) {
    final sections = _splitSections(text);
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _buildSection(
            context,
            sections[index],
            highlightLead:
                emphasizeLead && index == 0 && _isLeadSection(sections[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String rawSection, {
    required bool highlightLead,
  }) {
    final lines = rawSection
        .split('\n')
        .map((line) => _sanitizeText(line.trim()))
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isBulletSection(lines)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in lines) ...[
            _FormattedBulletRow(
              text: _stripBulletPrefix(item),
              theme: theme,
              textColor: textColor,
              accentColor: accentColor,
            ),
            if (item != lines.last) const SizedBox(height: 8),
          ],
        ],
      );
    }

    if (_isNumberedSection(lines)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in lines) ...[
            _FormattedNumberRow(
              numberedText: item,
              theme: theme,
              textColor: textColor,
              accentColor: accentColor,
            ),
            if (item != lines.last) const SizedBox(height: 10),
          ],
        ],
      );
    }

    final paragraph = lines.join('\n');
    if (_isStandaloneHeading(paragraph)) {
      return Text(
        paragraph.replaceAll(':', ''),
        style: theme.textTheme.labelLarge?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      );
    }

    final content = QuizMathText(
      text: paragraph,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.62,
        fontWeight: FontWeight.w500,
      ),
    );

    if (!highlightLead) {
      return content;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: content,
    );
  }

  List<String> _splitSections(String source) {
    return source
        .replaceAll('\r\n', '\n')
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList(growable: false);
  }

  bool _isLeadSection(String section) {
    final normalized = _sanitizeText(section.replaceAll('\n', ' '));
    if (normalized.isEmpty) {
      return false;
    }
    if (_isStandaloneHeading(normalized)) {
      return false;
    }
    return normalized.length <= 180 &&
        !normalized.startsWith('-') &&
        !normalized.startsWith('•') &&
        !RegExp(r'^\d+[.)]\s+').hasMatch(normalized);
  }

  bool _isBulletSection(List<String> lines) {
    return lines.isNotEmpty &&
        lines.every((line) => RegExp(r'^[-•*]\s+').hasMatch(line));
  }

  bool _isNumberedSection(List<String> lines) {
    return lines.isNotEmpty &&
        lines.every((line) => RegExp(r'^\d+[.)]\s+').hasMatch(line));
  }

  bool _isStandaloneHeading(String line) {
    final normalized = _sanitizeText(line).trim();
    if (normalized.isEmpty || normalized.length > 36) {
      return false;
    }
    final compact = normalized.replaceAll(':', '');
    return !compact.contains('.') &&
        !compact.contains('?') &&
        !compact.contains('!') &&
        RegExp(
          r'^(Bài|Giải|Mẹo|Ghi nhớ|Kết luận|Lưu ý|Ví dụ|Tóm tắt)(:)?$',
          caseSensitive: false,
        ).hasMatch(normalized);
  }

  String _stripBulletPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[-•*]\s+'), '');
  }

  String _sanitizeText(String value) {
    return value.replaceAll('**', '').trim();
  }
}

class _FormattedBulletRow extends StatelessWidget {
  const _FormattedBulletRow({
    required this.text,
    required this.theme,
    required this.textColor,
    required this.accentColor,
  });

  final String text;
  final ThemeData theme;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: QuizMathText(
            text: text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.58,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormattedNumberRow extends StatelessWidget {
  const _FormattedNumberRow({
    required this.numberedText,
    required this.theme,
    required this.textColor,
    required this.accentColor,
  });

  final String numberedText;
  final ThemeData theme;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(\d+[.)])\s+(.*)$').firstMatch(numberedText);
    final index = match?.group(1) ?? '1.';
    final content = match?.group(2) ?? numberedText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: QuizMathText(
            text: content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.58,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
