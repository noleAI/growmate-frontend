import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/agentic_session_cubit.dart';
import '../cubit/agentic_session_state.dart';
import '../../../../shared/widgets/ai_reasoning_trace_widget.dart';
import '../../../../shared/widgets/ai_knowledge_card_widget.dart';
import '../../../../shared/widgets/ai_reflection_widget.dart';

/// Dev dashboard hiển thị reasoning trace real-time.
/// Chỉ dùng khi build debug / demo cho stakeholders.
class ReasoningDashboardPage extends StatelessWidget {
  const ReasoningDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Reasoning Dashboard')),
      body: BlocBuilder<AgenticSessionCubit, AgenticSessionState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Mode badge
              _buildModeBadge(state, context),
              const SizedBox(height: 16),

              // Current reasoning trace
              if (state.hasReasoningTrace) ...[
                Text(
                  'Reasoning Trace (Step ${state.stepCount})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AiReasoningTraceWidget(
                  steps: state.reasoningTrace,
                  conclusion: state.reasoningContent ?? '',
                  confidence: state.reasoningConfidence ?? 0,
                  isExpanded: true,
                ),
              ],

              // Knowledge chunks
              if (state.hasKnowledge) ...[
                const SizedBox(height: 16),
                Text(
                  'Knowledge Retrieved',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AiKnowledgeCardWidget(chunks: state.knowledgeChunks),
              ],

              // Latest reflection
              if (state.latestReflection != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Latest Reflection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AiReflectionWidget(
                  reflection: state.latestReflection!,
                  stepNumber: state.stepCount,
                ),
              ],

              // Raw state (debug)
              const SizedBox(height: 24),
              ExpansionTile(
                title: const Text('Raw Agentic State'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      'Phase: ${state.phase}\n'
                      'Mode: ${state.reasoningMode}\n'
                      'Action: ${state.currentAction}\n'
                      'Content: ${state.currentContent}\n'
                      'Confidence: ${state.reasoningConfidence}\n'
                      'Steps: ${state.stepCount}\n'
                      'Entropy: ${state.beliefEntropy}\n',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeBadge(AgenticSessionState state, BuildContext context) {
    final isAgentic = state.isAgenticMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isAgentic ? Colors.green : Colors.orange).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isAgentic ? Colors.green : Colors.orange).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAgentic ? Icons.smart_toy : Icons.settings,
            color: isAgentic ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            isAgentic ? 'Agentic AI Mode' : 'Adaptive Mode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isAgentic ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
