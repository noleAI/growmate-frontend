import 'package:flutter/material.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/zen_text_field.dart';
import '../../domain/entities/quiz_question_template.dart';

class QuizAnswerWidgetFactory extends StatelessWidget {
  const QuizAnswerWidgetFactory({
    super.key,
    required this.question,
    required this.enabled,
    required this.textController,
    required this.textFocusNode,
    required this.onTextChanged,
    required this.onTextTap,
    required this.selectedOptionId,
    required this.onOptionSelected,
    required this.trueFalseAnswers,
    required this.onTrueFalseChanged,
  });

  final QuizQuestionTemplate question;
  final bool enabled;

  final TextEditingController textController;
  final FocusNode textFocusNode;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onTextTap;

  final String? selectedOptionId;
  final ValueChanged<String> onOptionSelected;

  final Map<String, bool> trueFalseAnswers;
  final void Function(String statementId, bool value) onTrueFalseChanged;

  @override
  Widget build(BuildContext context) {
    switch (question.questionType) {
      case QuizQuestionType.multipleChoice:
        return _buildMultipleChoice(context);
      case QuizQuestionType.trueFalseCluster:
        return _buildTrueFalseCluster(context);
      case QuizQuestionType.shortAnswer:
        return _buildShortAnswer(context);
    }
  }

  Widget _buildMultipleChoice(BuildContext context) {
    final payload = question.payload;
    if (payload is! MultipleChoicePayload) {
      return _FactoryError(
        message: context.t(
          vi: 'Không đọc được dữ liệu lựa chọn của câu hỏi này.',
          en: 'Unable to load options for this question.',
        ),
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: payload.options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: enabled ? () => onOptionSelected(option.id) : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selectedOptionId == option.id
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          )
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedOptionId == option.id
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: selectedOptionId == option.id
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHigh,
                        ),
                        child: Text(
                          option.id,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selectedOptionId == option.id
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTrueFalseCluster(BuildContext context) {
    final payload = question.payload;
    if (payload is! TrueFalseClusterPayload) {
      return _FactoryError(
        message: context.t(
          vi: 'Không đọc được dữ liệu Đúng/Sai của câu hỏi này.',
          en: 'Unable to load true/false cluster data.',
        ),
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        if (payload.generalHint.trim().isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.36,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              payload.generalHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ...payload.subQuestions.map(
          (statement) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${statement.id.toLowerCase()}) ${statement.text}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TrueFalseButton(
                        label: context.t(vi: 'Đúng', en: 'True'),
                        selected: trueFalseAnswers[statement.id] == true,
                        onTap: enabled
                            ? () => onTrueFalseChanged(statement.id, true)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TrueFalseButton(
                        label: context.t(vi: 'Sai', en: 'False'),
                        selected: trueFalseAnswers[statement.id] == false,
                        onTap: enabled
                            ? () => onTrueFalseChanged(statement.id, false)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortAnswer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTextTap();
        if (!textFocusNode.hasFocus) {
          textFocusNode.requestFocus();
        }
      },
      child: ZenTextField(
        controller: textController,
        focusNode: textFocusNode,
        onTap: onTextTap,
        onChanged: onTextChanged,
        textAlign: TextAlign.center,
        enabled: enabled,
        hintText: context.t(
          vi: 'Nhập đáp án ngắn...',
          en: 'Enter short answer...',
        ),
      ),
    );
  }
}

class _TrueFalseButton extends StatelessWidget {
  const _TrueFalseButton({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHigh,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _FactoryError extends StatelessWidget {
  const _FactoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
