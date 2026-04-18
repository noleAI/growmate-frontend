import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/agentic_api_service.dart';
import '../../../../data/models/agentic_models.dart';
import '../../../../data/repositories/config_repository.dart';
import '../../../../shared/widgets/ai_knowledge_card_widget.dart';
import '../../../../shared/widgets/ai_reasoning_trace_widget.dart';
import '../../../../shared/widgets/ai_reflection_widget.dart';
import '../cubit/agentic_session_cubit.dart';
import '../cubit/agentic_session_state.dart';

/// Dev dashboard hiển thị reasoning trace và snapshot inspection/config thật.
/// Dùng cho demo stakeholders và debug agentic backend.
class ReasoningDashboardPage extends StatelessWidget {
  const ReasoningDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agentic Reasoning Dashboard')),
      body: BlocBuilder<AgenticSessionCubit, AgenticSessionState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildModeBadge(state, context),
              const SizedBox(height: 16),
              _SessionOverview(state: state),
              if (state.hasReasoningTrace) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Reasoning Trace',
                  child: AiReasoningTraceWidget(
                    steps: state.reasoningTrace,
                    conclusion: state.reasoningContent ?? '',
                    confidence: state.reasoningConfidence ?? 0,
                    isExpanded: true,
                  ),
                ),
              ],
              if (state.hasKnowledge) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Knowledge Retrieved',
                  child: AiKnowledgeCardWidget(chunks: state.knowledgeChunks),
                ),
              ],
              if (state.latestReflection != null) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Latest Reflection',
                  child: AiReflectionWidget(
                    reflection: state.latestReflection!,
                    stepNumber: state.stepCount,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _InspectionSnapshotSection(sessionId: state.sessionId),
              const SizedBox(height: 16),
              const _RemoteConfigSection(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Raw Agentic State',
                child: SelectableText(
                  _prettyJson(<String, dynamic>{
                    'phase': state.phase.name,
                    'mode': state.reasoningMode,
                    'action': state.currentAction,
                    'content': state.currentContent,
                    'confidence': state.reasoningConfidence,
                    'steps': state.stepCount,
                    'entropy': state.beliefEntropy,
                    'session_id': state.sessionId,
                  }),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
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
          Expanded(
            child: Text(
              isAgentic ? 'Agentic AI Mode' : 'Adaptive Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isAgentic ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (state.sessionId != null && state.sessionId!.isNotEmpty)
            Text(
              'Session ${state.sessionId!.substring(0, 8)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }
}

class _SessionOverview extends StatelessWidget {
  const _SessionOverview({required this.state});

  final AgenticSessionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, String)>[
      ('Phase', state.phase.name),
      ('Action', state.currentAction ?? '-'),
      ('Confidence', state.reasoningConfidence == null
          ? '-'
          : '${(state.reasoningConfidence! * 100).round()}%'),
      ('Entropy', state.beliefEntropy?.toStringAsFixed(2) ?? '-'),
      ('Steps', '${state.stepCount}'),
    ];

    return _SectionCard(
      title: 'Session Snapshot',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map(
              (item) => Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _InspectionSnapshotSection extends StatefulWidget {
  const _InspectionSnapshotSection({required this.sessionId});

  final String? sessionId;

  @override
  State<_InspectionSnapshotSection> createState() =>
      _InspectionSnapshotSectionState();
}

class _InspectionSnapshotSectionState extends State<_InspectionSnapshotSection> {
  bool _loading = false;
  String? _errorMessage;
  InspectionBeliefResponse? _beliefResponse;
  InspectionParticleResponse? _particleResponse;
  InspectionQValuesResponse? _qValuesResponse;
  InspectionAuditLogsResponse? _auditLogsResponse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant _InspectionSnapshotSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final sessionId = widget.sessionId;
    final api = context.read<AgenticApiService?>();
    if (!mounted || api == null || sessionId == null || sessionId.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        api.getBeliefState(sessionId: sessionId),
        api.getParticleState(sessionId: sessionId),
        api.getQValues(),
        api.getAuditLogs(sessionId: sessionId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _beliefResponse = results[0] as InspectionBeliefResponse;
        _particleResponse = results[1] as InspectionParticleResponse;
        _qValuesResponse = results[2] as InspectionQValuesResponse;
        _auditLogsResponse = results[3] as InspectionAuditLogsResponse;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionId = widget.sessionId;
    final api = context.read<AgenticApiService?>();

    if (api == null) {
      return const _SectionCard(
        title: 'Inspection APIs',
        child: Text('Agentic API service is not available in this build.'),
      );
    }

    if (sessionId == null || sessionId.isEmpty) {
      return const _SectionCard(
        title: 'Inspection APIs',
        child: Text('Start a session first to fetch belief, particle, q-value, and audit snapshots.'),
      );
    }

    final beliefs =
        _beliefResponse?.beliefs.entries.toList(growable: false) ??
        <MapEntry<String, double>>[];
    beliefs.sort((a, b) => b.value.compareTo(a.value));
    final particleEntries =
        _particleResponse?.stateSummary.entries.toList(growable: false) ??
        <MapEntry<String, dynamic>>[];
    final qEntries =
        _qValuesResponse?.qTable.entries.toList(growable: false) ??
        <MapEntry<String, dynamic>>[];
    qEntries.sort((a, b) => _asDouble(b.value).compareTo(_asDouble(a.value)));
    final auditLogs = _auditLogsResponse?.logs ?? const <Map<String, dynamic>>[];

    return _SectionCard(
      title: 'Inspection APIs',
      trailing: IconButton(
        onPressed: _loading ? null : _refresh,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Endpoints: belief-state, particle-state, q-values, audit-logs',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Belief Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (beliefs.isEmpty)
            const Text('No belief snapshot yet.')
          else
            Column(
              children: beliefs.take(6).map((entry) {
                final ratio = entry.value.clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${(ratio * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: ratio),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 14),
          Text(
            'Particle Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (particleEntries.isEmpty)
            const Text('No particle snapshot yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: particleEntries.take(8).map((entry) {
                return Chip(
                  label: Text('${entry.key}: ${entry.value}'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 14),
          Text(
            'Global Q-values',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (qEntries.isEmpty)
            const Text('No Q-table snapshot yet.')
          else
            Column(
              children: qEntries.take(6).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(_asDouble(entry.value).toStringAsFixed(3)),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 14),
          Text(
            'Audit Logs',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (auditLogs.isEmpty)
            const Text('No audit logs returned for this session yet.')
          else
            Column(
              children: auditLogs.take(5).map((log) {
                final eventType = log['event_type']?.toString() ?? 'event';
                final createdAt = log['created_at']?.toString() ?? '';
                final hitlTriggered = log['hitl_triggered'] == true;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    hitlTriggered
                        ? Icons.notification_important_outlined
                        : Icons.chevron_right_rounded,
                  ),
                  title: Text(eventType),
                  subtitle: Text(createdAt.isEmpty ? 'No timestamp' : createdAt),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RemoteConfigSection extends StatefulWidget {
  const _RemoteConfigSection();

  @override
  State<_RemoteConfigSection> createState() => _RemoteConfigSectionState();
}

class _RemoteConfigSectionState extends State<_RemoteConfigSection> {
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  Map<String, dynamic> _featureFlags = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final repository = context.read<ConfigRepository?>();
    if (repository == null) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final config = await repository.getConfig(
        'feature_flags',
        forceRefresh: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _featureFlags = config;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _publishDemoFlags() async {
    final repository = context.read<ConfigRepository?>();
    if (repository == null) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      ..._featureFlags,
      'dev_reasoning_dashboard': true,
      'quiz_advanced_agentic_timeline': true,
      'inspection_dev_mode': true,
      'updated_from': 'growmate_frontend_reasoning_dashboard',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final saved = await repository.uploadConfig('feature_flags', payload);
      if (!mounted) {
        return;
      }
      setState(() {
        _featureFlags = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Demo feature flags synced to backend.')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<ConfigRepository?>();
    if (repository == null) {
      return const _SectionCard(
        title: 'Remote Config',
        child: Text('ConfigRepository is not available in this build.'),
      );
    }

    return _SectionCard(
      title: 'Remote Config',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          FilledButton.tonal(
            onPressed: _saving ? null : _publishDemoFlags,
            child: Text(_saving ? 'Saving...' : 'Publish demo flags'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category: feature_flags (GET/POST)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SelectableText(
            _prettyJson(_featureFlags),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...?trailing == null ? null : <Widget>[trailing!],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? 0.0;
  }
  return 0.0;
}

String _prettyJson(Map<String, dynamic> value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}
