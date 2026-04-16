# GrowMate Frontend — Kế hoạch nâng cấp Agentic AI

> **Phiên bản:** 1.1  
> **Ngày tạo:** 16/04/2026  
> **Cập nhật lần cuối:** 17/04/2026  
> **Phạm vi:** Toàn bộ `e:\growmate_frontend\lib\`  
> **Mục tiêu:** Hiển thị Agentic reasoning, RAG knowledge, self-reflection trên UI  
> **Trạng thái:** ✅ Phase 1–3 code đã implement xong. Chờ backend deploy + viết tests.

---

## Mục lục

1. [Tổng quan thay đổi Frontend](#1-tổng-quan-thay-đổi-frontend)
2. [Phase 1: Parse Reasoning Trace + Feature Flag](#2-phase-1-parse-reasoning-trace--feature-flag)
3. [Phase 2: AI Companion hiển thị Reasoning](#3-phase-2-ai-companion-hiển-thị-reasoning)
4. [Phase 3: Knowledge Cards (RAG)](#4-phase-3-knowledge-cards-rag)
5. [Phase 4: Reflection Summary UI](#5-phase-4-reflection-summary-ui)
6. [Phase 5: Dev Dashboard nâng cao](#6-phase-5-dev-dashboard-nâng-cao)
7. [Testing Plan](#7-testing-plan)
8. [Rollout Strategy](#8-rollout-strategy)

---

## 1. Tổng quan thay đổi Frontend

### Nguyên tắc

- **Backend-driven**: Frontend KHÔNG quyết định — chỉ hiển thị kết quả từ backend
- **Backward compatible**: Nếu backend trả response cũ (không có reasoning_trace) → UI hoạt động bình thường
- **Progressive enhancement**: Reasoning trace là optional, knowledge cards là optional
- **Không viết lại**: Sửa/mở rộng code hiện có, không refactor toàn bộ

### Luồng dữ liệu mới

```
Backend Response (enriched)
    ↓
┌─────────────────────────────────────────────┐
│ OrchestratorStepResponse                    │
│ ├─ action: "show_hint"        ← giữ nguyên │
│ ├─ payload: ActionPayload     ← giữ nguyên │
│ ├─ dashboardUpdate            ← giữ nguyên │
│ ├─ latencyMs                  ← giữ nguyên │
│ │                                           │
│ ├─ reasoningMode: "agentic"   ← MỚI        │
│ ├─ reasoningTrace: [...]      ← MỚI        │
│ ├─ reasoningContent: "..."    ← MỚI        │
│ ├─ reasoningConfidence: 0.82  ← MỚI        │
│ └─ knowledgeChunks: [...]     ← MỚI (P2)   │
└─────────────────────────────────────────────┘
    ↓
AgenticSessionCubit (state update)
    ↓
SessionToCompanionBridge (mapping)
    ↓
AiCompanionCubit (push blocks)
    ↓
┌────────────────────────────────┐
│ AI Companion Sheet (UI)        │
│ ├─ ReasoningTraceBlock   ← P1 │
│ ├─ KnowledgeCardBlock    ← P2 │
│ ├─ ReflectionBlock       ← P3 │
│ ├─ DecisionBlock   ← đã có    │
│ └─ EmotionCheckBlock ← đã có  │
└────────────────────────────────┘
```

---

## 2. Phase 1: Parse Reasoning Trace + Feature Flag

### 2.1 Sửa file: `lib/data/models/agentic_models.dart`

**Thay đổi:** Thêm fields mới vào `OrchestratorStepResponse` và model `ReasoningStep`.

```dart
// THÊM model mới:

/// Một bước trong chuỗi reasoning của LLM.
class ReasoningStep {
  const ReasoningStep({
    required this.step,
    required this.tool,
    this.args = const {},
    this.resultSummary = '',
  });

  final int step;
  final String tool;               // 'get_academic_beliefs', 'search_knowledge', ...
  final Map<String, dynamic> args;
  final String resultSummary;      // Mô tả kết quả (tiếng Việt)

  factory ReasoningStep.fromJson(Map<String, dynamic> json) {
    return ReasoningStep(
      step: json['step'] as int? ?? 0,
      tool: json['tool'] as String? ?? '',
      args: json['args'] as Map<String, dynamic>? ?? {},
      resultSummary: json['result_summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'tool': tool,
    'args': args,
    'result_summary': resultSummary,
  };

  /// Icon cho từng loại tool.
  String get toolIcon {
    return switch (tool) {
      'get_academic_beliefs' => '🧠',
      'get_empathy_state' => '💛',
      'get_strategy_suggestion' => '🎯',
      'search_knowledge' => '📚',
      'get_student_history' => '📊',
      'get_formula_bank' => '📐',
      'get_orchestrator_score' => '⚙️',
      _ => '🔧',
    };
  }

  /// Label tiếng Việt cho tool.
  String get toolLabel {
    return switch (tool) {
      'get_academic_beliefs' => 'Phân tích kiến thức',
      'get_empathy_state' => 'Đánh giá cảm xúc',
      'get_strategy_suggestion' => 'Gợi ý chiến lược',
      'search_knowledge' => 'Tra cứu kiến thức',
      'get_student_history' => 'Xem lịch sử',
      'get_formula_bank' => 'Tìm công thức',
      'get_orchestrator_score' => 'Tính điểm utility',
      _ => tool,
    };
  }
}


/// Chunk kiến thức từ RAG pipeline.
class KnowledgeChunk {
  const KnowledgeChunk({
    required this.content,
    required this.source,
    this.chapter = '',
    this.similarity = 0.0,
  });

  final String content;
  final String source;       // 'sgk_toan_12', 'cong_thuc', 'bai_giai_mau'
  final String chapter;
  final double similarity;

  factory KnowledgeChunk.fromJson(Map<String, dynamic> json) {
    return KnowledgeChunk(
      content: json['content'] as String? ?? '',
      source: json['source'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Label tiếng Việt cho source.
  String get sourceLabel {
    return switch (source) {
      'sgk_toan_12' => 'SGK Toán 12',
      'cong_thuc' => 'Công thức',
      'bai_giai_mau' => 'Bài giải mẫu',
      'loi_thuong_gap' => 'Lỗi thường gặp',
      _ => source,
    };
  }
}


/// Kết quả self-reflection của AI.
class ReflectionResult {
  const ReflectionResult({
    required this.effectiveness,
    required this.shouldChangeStrategy,
    this.entropyTrend = 'stable',
    this.accuracyTrend = 'stable',
    this.emotionTrend = 'stable',
    this.recommendation = '',
    this.reasoning = '',
  });

  final String effectiveness;        // 'effective', 'neutral', 'ineffective'
  final bool shouldChangeStrategy;
  final String entropyTrend;
  final String accuracyTrend;
  final String emotionTrend;
  final String recommendation;
  final String reasoning;

  factory ReflectionResult.fromJson(Map<String, dynamic> json) {
    return ReflectionResult(
      effectiveness: json['effectiveness'] as String? ?? 'neutral',
      shouldChangeStrategy: json['should_change_strategy'] as bool? ?? false,
      entropyTrend: json['entropy_trend'] as String? ?? 'stable',
      accuracyTrend: json['accuracy_trend'] as String? ?? 'stable',
      emotionTrend: json['emotion_trend'] as String? ?? 'stable',
      recommendation: json['recommendation'] as String? ?? '',
      reasoning: json['reasoning'] as String? ?? '',
    );
  }
}
```

**Sửa `OrchestratorStepResponse`** — thêm fields mới:

```dart
// THÊM fields vào class OrchestratorStepResponse:

class OrchestratorStepResponse {
  // ... fields hiện có giữ nguyên ...

  // === FIELDS MỚI ===
  final String reasoningMode;              // 'agentic' | 'adaptive'
  final List<ReasoningStep> reasoningTrace;
  final String? reasoningContent;          // LLM reasoning text
  final double? reasoningConfidence;       // LLM confidence [0, 1]
  final List<KnowledgeChunk> knowledgeChunks;  // RAG results
  final ReflectionResult? reflection;      // Self-reflection (every N steps)

  // === Derived getters MỚI ===
  bool get isAgenticMode => reasoningMode == 'agentic';
  bool get hasReasoningTrace => reasoningTrace.isNotEmpty;
  bool get hasKnowledge => knowledgeChunks.isNotEmpty;
  bool get hasReflection => reflection != null;

  // SỬA factory fromJson:
  factory OrchestratorStepResponse.fromJson(Map<String, dynamic> json) {
    return OrchestratorStepResponse(
      // ... fields hiện có ...

      // Parse fields mới (với fallback cho backward compat):
      reasoningMode: json['reasoning_mode'] as String? ?? 'adaptive',
      reasoningTrace: (json['reasoning_trace'] as List<dynamic>?)
          ?.map((e) => ReasoningStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      reasoningContent: json['reasoning_content'] as String?,
      reasoningConfidence: (json['reasoning_confidence'] as num?)?.toDouble(),
      knowledgeChunks: (json['knowledge_chunks'] as List<dynamic>?)
          ?.map((e) => KnowledgeChunk.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      reflection: json['reflection'] != null
          ? ReflectionResult.fromJson(json['reflection'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

### 2.2 Sửa file: `lib/features/agentic_session/presentation/cubit/agentic_session_state.dart`

**Thay đổi:** Thêm fields để lưu reasoning data trong state.

```dart
// THÊM fields vào class AgenticSessionState:

class AgenticSessionState extends Equatable {
  // ... fields hiện có ...

  // === FIELDS MỚI ===
  final String reasoningMode;                      // 'agentic' | 'adaptive'
  final List<ReasoningStep> reasoningTrace;        // Current step trace
  final String? reasoningContent;                  // LLM reasoning text
  final double? reasoningConfidence;               // LLM confidence
  final List<KnowledgeChunk> knowledgeChunks;      // RAG knowledge
  final ReflectionResult? latestReflection;        // Latest reflection

  // === Derived getters MỚI ===
  bool get isAgenticMode => reasoningMode == 'agentic';
  bool get hasReasoningTrace => reasoningTrace.isNotEmpty;
  bool get hasKnowledge => knowledgeChunks.isNotEmpty;

  // SỬA factory initial():
  factory AgenticSessionState.initial() => const AgenticSessionState(
    phase: AgenticPhase.idle,
    reasoningMode: 'adaptive',
    reasoningTrace: [],
    knowledgeChunks: [],
  );

  // SỬA copyWith:
  AgenticSessionState copyWith({
    // ... params hiện có ...
    String? reasoningMode,
    List<ReasoningStep>? reasoningTrace,
    String? reasoningContent,
    double? reasoningConfidence,
    List<KnowledgeChunk>? knowledgeChunks,
    ReflectionResult? latestReflection,
  }) => AgenticSessionState(
    // ... assignments hiện có ...
    reasoningMode: reasoningMode ?? this.reasoningMode,
    reasoningTrace: reasoningTrace ?? this.reasoningTrace,
    reasoningContent: reasoningContent ?? this.reasoningContent,
    reasoningConfidence: reasoningConfidence ?? this.reasoningConfidence,
    knowledgeChunks: knowledgeChunks ?? this.knowledgeChunks,
    latestReflection: latestReflection ?? this.latestReflection,
  );

  // SỬA props (Equatable):
  @override
  List<Object?> get props => [
    // ... props hiện có ...
    reasoningMode,
    reasoningTrace,
    reasoningContent,
    reasoningConfidence,
    knowledgeChunks,
    latestReflection,
  ];
}
```

### 2.3 Sửa file: `lib/features/agentic_session/presentation/cubit/agentic_session_cubit.dart`

**Thay đổi:** Parse reasoning data từ response vào state.

```dart
// SỬA method runFullStep():

Future<void> runFullStep({
  String? questionId,
  Map<String, dynamic>? response,
  Map<String, dynamic>? behaviorSignals,
}) async {
  emit(state.copyWith(phase: AgenticPhase.processing));
  try {
    final result = await _repo.runOrchestratorStep(
      questionId: questionId,
      response: response,
      behaviorSignals: behaviorSignals,
    );

    final nextPhase = _phaseFromAction(result.action);

    emit(state.copyWith(
      phase: nextPhase,
      lastOrchestratorStep: result,
      currentAction: result.action,
      currentContent: result.payload.text,
      latestDashboard: result.dashboardUpdate,
      stepCount: state.stepCount + 1,
      // === THÊM reasoning data ===
      reasoningMode: result.reasoningMode,
      reasoningTrace: result.reasoningTrace,
      reasoningContent: result.reasoningContent,
      reasoningConfidence: result.reasoningConfidence,
      knowledgeChunks: result.knowledgeChunks,
      latestReflection: result.reflection ?? state.latestReflection,
    ));
  } catch (e) {
    emit(state.copyWith(
      phase: AgenticPhase.error,
      errorMessage: e.toString(),
    ));
  }
}
```

---

## 3. Phase 2: AI Companion hiển thị Reasoning

### 3.1 Thêm AiBlock types mới

Sửa file nơi `AiBlock` được định nghĩa (trong `ai_companion_state.dart` hoặc file riêng):

```dart
// THÊM block types mới:

/// Block hiển thị chuỗi reasoning của AI.
class ReasoningTraceBlock extends AiBlock {
  const ReasoningTraceBlock({
    required super.id,
    required this.steps,
    required this.conclusion,
    required this.confidence,
    required this.mode,
    super.timestamp,
  }) : super(type: AiBlockType.reasoningTrace);

  final List<ReasoningStep> steps;
  final String conclusion;        // reasoningContent từ backend
  final double confidence;
  final String mode;              // 'agentic' | 'adaptive'
}

/// Block hiển thị kiến thức từ RAG.
class KnowledgeCardBlock extends AiBlock {
  const KnowledgeCardBlock({
    required super.id,
    required this.chunks,
    required this.query,
    super.timestamp,
  }) : super(type: AiBlockType.knowledgeCard);

  final List<KnowledgeChunk> chunks;
  final String query;             // Query đã tìm
}

/// Block hiển thị self-reflection summary.
class ReflectionBlock extends AiBlock {
  const ReflectionBlock({
    required super.id,
    required this.reflection,
    required this.stepNumber,
    super.timestamp,
  }) : super(type: AiBlockType.reflection);

  final ReflectionResult reflection;
  final int stepNumber;
}

// CẬP NHẬT enum AiBlockType:
enum AiBlockType {
  // ... types hiện có ...
  insight,
  decision,
  emotionCheck,

  // === TYPES MỚI ===
  reasoningTrace,    // Phase 1
  knowledgeCard,     // Phase 2
  reflection,        // Phase 3
}
```

### 3.2 Sửa file: `lib/features/ai_companion/presentation/session_companion_bridge.dart`

**Thay đổi:** Map reasoning data → AI blocks.

```dart
// THÊM vào listener, sau phần DASHBOARD UPDATES:

// === REASONING TRACE (Phase 1) ===
if (state.hasReasoningTrace && state.isAgenticMode) {
  _pushReasoningTrace(companion, state);
}

// === KNOWLEDGE CARDS (Phase 2) ===
if (state.hasKnowledge) {
  _pushKnowledgeCards(companion, state);
}

// === REFLECTION (Phase 3) ===
if (state.latestReflection != null &&
    state.stepCount % 5 == 0 &&
    state.stepCount > 0) {
  _pushReflection(companion, state);
}


// THÊM helper methods:

void _pushReasoningTrace(AiCompanionCubit companion, AgenticSessionState state) {
  final blockId = 'reasoning_step_${state.stepCount}';

  // Guard: không push duplicate
  if (companion.state.blocks.any((b) => b.id == blockId)) return;

  companion.pushBlock(ReasoningTraceBlock(
    id: blockId,
    steps: state.reasoningTrace,
    conclusion: state.reasoningContent ?? 'AI đã phân tích và quyết định.',
    confidence: state.reasoningConfidence ?? 0.5,
    mode: state.reasoningMode,
    timestamp: DateTime.now(),
  ));
}

void _pushKnowledgeCards(AiCompanionCubit companion, AgenticSessionState state) {
  final blockId = 'knowledge_step_${state.stepCount}';

  if (companion.state.blocks.any((b) => b.id == blockId)) return;

  // Chỉ push nếu có chunks có nội dung
  final relevantChunks = state.knowledgeChunks
      .where((c) => c.content.isNotEmpty)
      .toList();
  if (relevantChunks.isEmpty) return;

  companion.pushBlock(KnowledgeCardBlock(
    id: blockId,
    chunks: relevantChunks,
    query: state.lastOrchestratorStep?.reasoningTrace
        .where((s) => s.tool == 'search_knowledge')
        .map((s) => s.args['query'] as String? ?? '')
        .firstOrNull ?? '',
    timestamp: DateTime.now(),
  ));
}

void _pushReflection(AiCompanionCubit companion, AgenticSessionState state) {
  final blockId = 'reflection_step_${state.stepCount}';

  if (companion.state.blocks.any((b) => b.id == blockId)) return;

  companion.pushBlock(ReflectionBlock(
    id: blockId,
    reflection: state.latestReflection!,
    stepNumber: state.stepCount,
    timestamp: DateTime.now(),
  ));
}
```

### 3.3 Tạo file mới: `lib/shared/widgets/ai_reasoning_trace_widget.dart`

**Mục đích:** Widget hiển thị chuỗi reasoning steps dưới dạng timeline.

```dart
// lib/shared/widgets/ai_reasoning_trace_widget.dart

import 'package:flutter/material.dart';
import 'package:growmate_frontend/data/models/agentic_models.dart';

/// Timeline widget hiển thị các bước reasoning của AI.
///
/// Mỗi step hiển thị:
/// - Icon của tool (🧠 📚 🎯 ...)
/// - Tên tool (tiếng Việt)
/// - Kết quả tóm tắt
/// - Animation expand/collapse
class AiReasoningTraceWidget extends StatefulWidget {
  const AiReasoningTraceWidget({
    super.key,
    required this.steps,
    required this.conclusion,
    required this.confidence,
    this.isExpanded = false,
  });

  final List<ReasoningStep> steps;
  final String conclusion;
  final double confidence;
  final bool isExpanded;

  @override
  State<AiReasoningTraceWidget> createState() => _AiReasoningTraceWidgetState();
}

class _AiReasoningTraceWidgetState extends State<AiReasoningTraceWidget> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI đã suy luận qua ${widget.steps.length} bước',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _confidenceColor(widget.confidence).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(widget.confidence * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _confidenceColor(widget.confidence),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Conclusion — always visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.conclusion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
          ),

          // Steps timeline — only when expanded
          if (_expanded) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: widget.steps.map((step) => _buildStep(step, theme, colorScheme)).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep(ReasoningStep step, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number + icon
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Text(
                  step.toolIcon,
                  style: const TextStyle(fontSize: 16),
                ),
                if (step.step < widget.steps.length)
                  Container(
                    width: 1,
                    height: 16,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.toolLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (step.resultSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.resultSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
```

### 3.4 Tạo file mới: `lib/shared/widgets/ai_knowledge_card_widget.dart`

**Mục đích:** Widget hiển thị knowledge chunks từ RAG.

```dart
// lib/shared/widgets/ai_knowledge_card_widget.dart

import 'package:flutter/material.dart';
import 'package:growmate_frontend/data/models/agentic_models.dart';

/// Card hiển thị kiến thức từ SGK/công thức được RAG truy vấn.
///
/// Hiển thị:
/// - Source badge (SGK Toán 12, Công thức, Bài giải mẫu)
/// - Nội dung chunk
/// - Similarity score
class AiKnowledgeCardWidget extends StatelessWidget {
  const AiKnowledgeCardWidget({
    super.key,
    required this.chunks,
    this.query = '',
  });

  final List<KnowledgeChunk> chunks;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kiến thức liên quan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chunks
          ...chunks.map((chunk) => _buildChunk(chunk, theme, colorScheme)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChunk(KnowledgeChunk chunk, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _sourceColor(chunk.source).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    chunk.sourceLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _sourceColor(chunk.source),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (chunk.chapter.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    chunk.chapter,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Content
            Text(
              chunk.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sourceColor(String source) {
    return switch (source) {
      'sgk_toan_12' => Colors.blue,
      'cong_thuc' => Colors.teal,
      'bai_giai_mau' => Colors.orange,
      'loi_thuong_gap' => Colors.red,
      _ => Colors.grey,
    };
  }
}
```

### 3.5 Tạo file mới: `lib/shared/widgets/ai_reflection_widget.dart`

**Mục đích:** Widget hiển thị self-reflection summary.

```dart
// lib/shared/widgets/ai_reflection_widget.dart

import 'package:flutter/material.dart';
import 'package:growmate_frontend/data/models/agentic_models.dart';

/// Widget hiển thị kết quả self-reflection của AI.
///
/// Hiển thị:
/// - Effectiveness badge (hiệu quả / trung bình / chưa hiệu quả)
/// - Trend indicators (entropy, accuracy, emotion)
/// - Recommendation (nếu có)
class AiReflectionWidget extends StatelessWidget {
  const AiReflectionWidget({
    super.key,
    required this.reflection,
    required this.stepNumber,
  });

  final ReflectionResult reflection;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI tự đánh giá (sau $stepNumber bước)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildEffectivenessBadge(theme, colorScheme),
            ],
          ),
          const SizedBox(height: 8),

          // Trend indicators
          Row(
            children: [
              _buildTrend('Kiến thức', reflection.entropyTrend, theme, colorScheme),
              const SizedBox(width: 12),
              _buildTrend('Accuracy', reflection.accuracyTrend, theme, colorScheme),
              const SizedBox(width: 12),
              _buildTrend('Cảm xúc', reflection.emotionTrend, theme, colorScheme),
            ],
          ),

          // Recommendation
          if (reflection.shouldChangeStrategy && reflection.recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reflection.recommendation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reasoning
          if (reflection.reasoning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reflection.reasoning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEffectivenessBadge(ThemeData theme, ColorScheme colorScheme) {
    final (label, color) = switch (reflection.effectiveness) {
      'effective' => ('Hiệu quả', Colors.green),
      'ineffective' => ('Chưa hiệu quả', Colors.red),
      _ => ('Trung bình', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrend(String label, String trend, ThemeData theme, ColorScheme colorScheme) {
    final (icon, color) = switch (trend) {
      'improving' || 'decreasing' => (Icons.trending_up, Colors.green),
      'declining' || 'increasing' || 'worsening' => (Icons.trending_down, Colors.red),
      _ => (Icons.trending_flat, Colors.grey),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

### 3.6 Sửa AI Companion Sheet để render blocks mới

Tìm file nơi `AiBlock` types được rendered (companion sheet widget). Thêm cases mới:

```dart
// Trong widget build method nơi switch trên block.type:

Widget _buildBlock(AiBlock block) {
  return switch (block) {
    // ... cases hiện có ...
    DecisionBlock b => _buildDecisionBlock(b),
    EmotionCheckBlock b => _buildEmotionCheckBlock(b),
    InsightBlock b => _buildInsightBlock(b),

    // === BLOCKS MỚI ===
    ReasoningTraceBlock b => AiReasoningTraceWidget(
      steps: b.steps,
      conclusion: b.conclusion,
      confidence: b.confidence,
    ),
    KnowledgeCardBlock b => AiKnowledgeCardWidget(
      chunks: b.chunks,
      query: b.query,
    ),
    ReflectionBlock b => AiReflectionWidget(
      reflection: b.reflection,
      stepNumber: b.stepNumber,
    ),

    _ => const SizedBox.shrink(),
  };
}
```

---

## 4. Phase 3: Knowledge Cards (RAG)

### 4.1 Hiển thị knowledge trong Quiz Hint

Khi backend trả `action: "show_hint"` kèm `knowledgeChunks`, quiz page nên hiển thị knowledge cards bên cạnh hint text.

Sửa file: `lib/features/quiz/presentation/pages/quiz_page.dart`

```dart
// Trong _onAgenticStateChanged(), khi nhận hint:

void _onAgenticStateChanged(AgenticSessionState state) {
  if (!mounted) return;

  // Khi nhận show_hint + có knowledge
  if (state.currentAction == 'show_hint' && state.hasKnowledge) {
    _showHintWithKnowledge(
      hintText: state.currentContent ?? '',
      knowledgeChunks: state.knowledgeChunks,
    );
  }

  // ... rest of existing logic ...
}

void _showHintWithKnowledge({
  required String hintText,
  required List<KnowledgeChunk> knowledgeChunks,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hint text
            Text(
              '💡 Gợi ý',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(hintText),
            const SizedBox(height: 16),

            // Knowledge cards
            if (knowledgeChunks.isNotEmpty) ...[
              AiKnowledgeCardWidget(chunks: knowledgeChunks),
            ],
          ],
        ),
      ),
    ),
  );
}
```

---

## 5. Phase 4: Reflection Summary UI

### 5.1 Hiển thị reflection trong Progress Page

Khi session kết thúc, hiển thị reflection summary.

Sửa file: `lib/features/progress/presentation/pages/progress_page.dart`

```dart
// Thêm section mới trong progress page, sau AI narrative:

// Lấy latest reflection từ AgenticSessionCubit (nếu có)
BlocBuilder<AgenticSessionCubit, AgenticSessionState>(
  buildWhen: (prev, curr) => prev.latestReflection != curr.latestReflection,
  builder: (context, state) {
    if (state.latestReflection == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AiReflectionWidget(
        reflection: state.latestReflection!,
        stepNumber: state.stepCount,
      ),
    );
  },
),
```

### 5.2 Session Complete Overlay

Sửa file: `lib/features/agentic_session/presentation/widgets/` (hoặc tạo mới)

Khi phase == completed, hiển thị summary screen với reasoning stats:

```dart
// lib/features/agentic_session/presentation/widgets/session_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:growmate_frontend/data/models/agentic_models.dart';

/// Summary widget hiển thị khi session kết thúc.
/// Cho HS biết AI đã suy luận bao nhiêu bước, dùng tool gì.
class SessionSummaryWidget extends StatelessWidget {
  const SessionSummaryWidget({
    super.key,
    required this.totalSteps,
    required this.reasoningMode,
    required this.latestReflection,
  });

  final int totalSteps;
  final String reasoningMode;
  final ReflectionResult? latestReflection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              icon: Icons.psychology,
              label: 'Bước suy luận',
              value: '$totalSteps',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildStat(
              icon: Icons.smart_toy,
              label: 'Chế độ AI',
              value: reasoningMode == 'agentic' ? 'Agentic' : 'Adaptive',
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),

        // Reflection summary
        if (latestReflection != null) ...[
          const SizedBox(height: 16),
          AiReflectionWidget(
            reflection: latestReflection!,
            stepNumber: totalSteps,
          ),
        ],
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

---

## 6. Phase 5: Dev Dashboard nâng cao

### 6.1 Reasoning Trace Viewer

Tạo file: `lib/features/agentic_session/presentation/pages/reasoning_dashboard_page.dart`

**Mục đích:** Developer-only page để xem reasoning trace real-time (dùng cho debug & demo).

```dart
// lib/features/agentic_session/presentation/pages/reasoning_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                Text('Reasoning Trace (Step ${state.stepCount})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AiReasoningTraceWidget(
                  steps: state.reasoningTrace,
                  conclusion: state.reasoningContent ?? '',
                  confidence: state.reasoningConfidence ?? 0,
                  isExpanded: true,  // Always expanded in dashboard
                ),
              ],

              // Knowledge chunks
              if (state.hasKnowledge) ...[
                const SizedBox(height: 16),
                Text('Knowledge Retrieved',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AiKnowledgeCardWidget(chunks: state.knowledgeChunks),
              ],

              // Latest reflection
              if (state.latestReflection != null) ...[
                const SizedBox(height: 16),
                Text('Latest Reflection',
                    style: Theme.of(context).textTheme.titleMedium),
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
                  SelectableText(
                    'Phase: ${state.phase}\n'
                    'Mode: ${state.reasoningMode}\n'
                    'Action: ${state.currentAction}\n'
                    'Content: ${state.currentContent}\n'
                    'Confidence: ${state.reasoningConfidence}\n'
                    'Steps: ${state.stepCount}\n'
                    'Entropy: ${state.beliefEntropy}\n',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
        color: (isAgentic ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isAgentic ? Colors.green : Colors.orange).withOpacity(0.3),
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
```

### 6.2 Thêm route cho dev dashboard

Sửa file: `lib/app/router/app_routes.dart` (hoặc `app_router.dart`)

```dart
// Thêm route mới (chỉ trong debug mode):
GoRoute(
  path: '/dev/reasoning',
  builder: (context, state) => const ReasoningDashboardPage(),
),
```

---

## 7. Testing Plan

### 7.1 Unit Tests

| File test | Test gì | Priority |
|---|---|---|
| `test/data/models/agentic_models_test.dart` | Parse ReasoningStep, KnowledgeChunk, ReflectionResult fromJson | P0 |
| `test/data/models/agentic_models_test.dart` | OrchestratorStepResponse backward compat (no reasoning fields) | P0 |
| `test/features/agentic_session/cubit/agentic_session_cubit_test.dart` | State updates with reasoning data | P0 |
| `test/shared/widgets/ai_reasoning_trace_widget_test.dart` | Renders steps, expand/collapse | P1 |
| `test/shared/widgets/ai_knowledge_card_widget_test.dart` | Renders chunks, source badges | P1 |
| `test/shared/widgets/ai_reflection_widget_test.dart` | Renders trends, recommendation | P1 |

### 7.2 Widget Tests chi tiết

```dart
// test/data/models/agentic_models_test.dart

void main() {
  group('ReasoningStep', () {
    test('fromJson parses correctly', () {
      final json = {
        'step': 1,
        'tool': 'get_academic_beliefs',
        'args': {'session_id': 'abc'},
        'result_summary': 'Điểm yếu: Chain Rule',
      };
      final step = ReasoningStep.fromJson(json);
      expect(step.step, 1);
      expect(step.tool, 'get_academic_beliefs');
      expect(step.toolIcon, '🧠');
      expect(step.toolLabel, 'Phân tích kiến thức');
    });

    test('fromJson handles missing fields', () {
      final step = ReasoningStep.fromJson({});
      expect(step.step, 0);
      expect(step.tool, '');
      expect(step.toolIcon, '🔧');
    });
  });

  group('OrchestratorStepResponse', () {
    test('backward compatible — no reasoning fields', () {
      final json = {
        'action': 'next_question',
        'payload': {'text': 'test', 'fallback_used': false},
        'dashboard_update': { /* ... */ },
        'latency_ms': 100,
        // NO reasoning_mode, reasoning_trace, etc.
      };
      final response = OrchestratorStepResponse.fromJson(json);
      expect(response.reasoningMode, 'adaptive');
      expect(response.reasoningTrace, isEmpty);
      expect(response.knowledgeChunks, isEmpty);
      expect(response.reflection, isNull);
      expect(response.isAgenticMode, isFalse);
    });

    test('parses full agentic response', () {
      final json = {
        'action': 'show_hint',
        'payload': {'text': 'hint', 'fallback_used': false},
        'dashboard_update': { /* ... */ },
        'latency_ms': 1200,
        'reasoning_mode': 'agentic',
        'reasoning_trace': [
          {'step': 1, 'tool': 'get_academic_beliefs', 'result_summary': 'test'},
        ],
        'reasoning_content': 'HS yếu chain rule',
        'reasoning_confidence': 0.85,
        'knowledge_chunks': [
          {'content': 'formula', 'source': 'cong_thuc', 'chapter': 'dao_ham', 'similarity': 0.9},
        ],
      };
      final response = OrchestratorStepResponse.fromJson(json);
      expect(response.isAgenticMode, isTrue);
      expect(response.reasoningTrace, hasLength(1));
      expect(response.knowledgeChunks, hasLength(1));
      expect(response.reasoningConfidence, 0.85);
    });
  });

  group('KnowledgeChunk', () {
    test('sourceLabel maps correctly', () {
      expect(KnowledgeChunk(content: '', source: 'sgk_toan_12').sourceLabel, 'SGK Toán 12');
      expect(KnowledgeChunk(content: '', source: 'cong_thuc').sourceLabel, 'Công thức');
      expect(KnowledgeChunk(content: '', source: 'bai_giai_mau').sourceLabel, 'Bài giải mẫu');
      expect(KnowledgeChunk(content: '', source: 'loi_thuong_gap').sourceLabel, 'Lỗi thường gặp');
    });
  });
}
```

```dart
// test/shared/widgets/ai_reasoning_trace_widget_test.dart

void main() {
  testWidgets('renders steps count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiReasoningTraceWidget(
            steps: [
              ReasoningStep(step: 1, tool: 'get_academic_beliefs', resultSummary: 'test'),
              ReasoningStep(step: 2, tool: 'get_empathy_state', resultSummary: 'test2'),
            ],
            conclusion: 'AI decided hint',
            confidence: 0.8,
          ),
        ),
      ),
    );

    expect(find.text('AI đã suy luận qua 2 bước'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('expand shows step details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiReasoningTraceWidget(
            steps: [
              ReasoningStep(step: 1, tool: 'get_academic_beliefs', resultSummary: 'Điểm yếu: Chain Rule'),
            ],
            conclusion: 'test',
            confidence: 0.5,
            isExpanded: false,
          ),
        ),
      ),
    );

    // Initially collapsed — no step details
    expect(find.text('Phân tích kiến thức'), findsNothing);

    // Tap to expand
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('Phân tích kiến thức'), findsOneWidget);
    expect(find.text('Điểm yếu: Chain Rule'), findsOneWidget);
  });
}
```

### 7.3 Integration Tests

```dart
// test/integration/agentic_reasoning_flow_test.dart

void main() {
  testWidgets('full agentic flow: quiz → reasoning → companion', (tester) async {
    // Setup: mock AgenticSessionCubit with reasoning data
    final mockCubit = MockAgenticSessionCubit();
    when(() => mockCubit.state).thenReturn(
      AgenticSessionState.initial().copyWith(
        phase: AgenticPhase.interacting,
        reasoningMode: 'agentic',
        reasoningTrace: [
          ReasoningStep(step: 1, tool: 'get_academic_beliefs', resultSummary: 'test'),
        ],
        reasoningContent: 'HS yếu chain rule',
        reasoningConfidence: 0.82,
      ),
    );

    // Pump app with providers
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AgenticSessionCubit>.value(value: mockCubit),
          BlocProvider<AiCompanionCubit>(create: (_) => AiCompanionCubit()),
        ],
        child: MaterialApp(home: SessionToCompanionBridge(child: TestPage())),
      ),
    );

    // Verify companion receives reasoning block
    final companion = tester.element(find.byType(TestPage)).read<AiCompanionCubit>();
    expect(companion.state.blocks, isNotEmpty);
    expect(companion.state.blocks.last, isA<ReasoningTraceBlock>());
  });
}
```

---

## 8. Rollout Strategy

### Phase 1 (Tuần 1): Models + State + Feature Flag

```
Ngày 1: Sửa agentic_models.dart — thêm ReasoningStep, KnowledgeChunk, ReflectionResult
Ngày 2: Sửa agentic_session_state.dart — thêm reasoning fields
Ngày 3: Sửa agentic_session_cubit.dart — parse reasoning vào state
Ngày 4: Unit tests cho models (backward compat + full parse)
Ngày 5: Unit tests cho cubit state updates
```

**Deliverables:**
- [x] `lib/data/models/agentic_models.dart` (sửa) — ✅ 16/04
- [x] `lib/features/agentic_session/presentation/cubit/agentic_session_state.dart` (sửa) — ✅ 16/04
- [x] `lib/features/agentic_session/presentation/cubit/agentic_session_cubit.dart` (sửa) — ✅ 16/04
- [ ] `test/data/models/agentic_models_test.dart` (sửa/tạo)
- [ ] `test/features/agentic_session/cubit/agentic_session_cubit_test.dart` (sửa)

### Phase 2 (Tuần 2): Widgets + Companion Integration

```
Ngày 1: Tạo AiReasoningTraceWidget
Ngày 2: Tạo AiKnowledgeCardWidget
Ngày 3: Tạo AiReflectionWidget
Ngày 4: Thêm AiBlock types mới (ReasoningTraceBlock, KnowledgeCardBlock, ReflectionBlock)
Ngày 5: Sửa SessionToCompanionBridge — map reasoning → blocks
Ngày 6: Sửa companion sheet — render blocks mới
Ngày 7: Widget tests cho 3 widgets mới
```

**Deliverables:**
- [x] `lib/shared/widgets/ai_reasoning_trace_widget.dart` (mới) — ✅ 17/04
- [x] `lib/shared/widgets/ai_knowledge_card_widget.dart` (mới) — ✅ 17/04
- [x] `lib/shared/widgets/ai_reflection_widget.dart` (mới) — ✅ 17/04
- [x] `lib/shared/widgets/ai_blocks/ai_block_model.dart` (sửa — thêm `ReasoningTraceBlock`, `KnowledgeCardBlock`, `ReflectionBlock`) — ✅ 17/04
- [x] `lib/shared/widgets/ai_blocks/block_renderer.dart` (sửa — dispatch 3 block types mới) — ✅ 17/04
- [x] `lib/features/ai_companion/presentation/session_companion_bridge.dart` (sửa) — ✅ 17/04
- [ ] Widget tests (3 files mới)

> **Ghi chú:** Block types được thêm vào `ai_block_model.dart` (sealed class) thay vì `ai_companion_state.dart` vì đó là nơi `AiBlock` sealed class thực sự được định nghĩa. `block_renderer.dart` đã được cập nhật để dispatch 3 block types mới tới các widget tương ứng.

### Phase 3 (Tuần 3): Quiz Integration + Progress + Dev Dashboard

```
Ngày 1-2: Sửa quiz_page.dart — hint with knowledge cards
Ngày 3: Sửa progress_page.dart — reflection summary
Ngày 4: Tạo SessionSummaryWidget
Ngày 5: Tạo ReasoningDashboardPage (dev only)
Ngày 6: Thêm route cho dev dashboard
Ngày 7: Integration tests
```

**Deliverables:**
- [x] `lib/features/quiz/presentation/pages/quiz_page.dart` (sửa — knowledge cards trong hint) — ✅ 17/04
- [x] `lib/features/progress/presentation/pages/progress_page.dart` (sửa — reflection summary) — ✅ 17/04
- [x] `lib/features/agentic_session/presentation/widgets/session_summary_widget.dart` (mới) — ✅ 17/04
- [x] `lib/features/agentic_session/presentation/pages/reasoning_dashboard_page.dart` (mới) — ✅ 17/04
- [x] `lib/app/router/app_router.dart` (sửa — thêm route `/dev/reasoning`) — ✅ 17/04
- [x] `lib/app/router/app_routes.dart` (sửa — thêm `devReasoning` constant) — ✅ 17/04
- [ ] Integration tests

---

## Tóm tắt file thay đổi

### Files MỚI (tạo mới)

| File | Phase | Mục đích | Trạng thái |
|---|---|---|---|
| `lib/shared/widgets/ai_reasoning_trace_widget.dart` | 2 | Timeline hiển thị reasoning steps | ✅ Done |
| `lib/shared/widgets/ai_knowledge_card_widget.dart` | 2 | Card hiển thị RAG knowledge | ✅ Done |
| `lib/shared/widgets/ai_reflection_widget.dart` | 2 | Self-reflection summary | ✅ Done |
| `lib/features/agentic_session/presentation/widgets/session_summary_widget.dart` | 3 | Session completion stats | ✅ Done |
| `lib/features/agentic_session/presentation/pages/reasoning_dashboard_page.dart` | 3 | Dev debug dashboard | ✅ Done |
| `test/shared/widgets/ai_reasoning_trace_widget_test.dart` | 2 | Widget tests | ⬜ TODO |
| `test/shared/widgets/ai_knowledge_card_widget_test.dart` | 2 | Widget tests | ⬜ TODO |
| `test/shared/widgets/ai_reflection_widget_test.dart` | 2 | Widget tests | ⬜ TODO |

### Files SỬA (edit existing)

| File | Phase | Thay đổi | Trạng thái |
|---|---|---|---|
| `lib/data/models/agentic_models.dart` | 1 | Thêm `ReasoningStep`, `KnowledgeChunk`, `ReflectionResult`; mở rộng `OrchestratorStepResponse` | ✅ Done |
| `lib/features/agentic_session/presentation/cubit/agentic_session_state.dart` | 1 | Thêm reasoning fields vào state | ✅ Done |
| `lib/features/agentic_session/presentation/cubit/agentic_session_cubit.dart` | 1 | Parse reasoning data từ response | ✅ Done |
| `lib/shared/widgets/ai_blocks/ai_block_model.dart` | 2 | Thêm `ReasoningTraceBlock`, `KnowledgeCardBlock`, `ReflectionBlock` sealed subtypes | ✅ Done |
| `lib/shared/widgets/ai_blocks/block_renderer.dart` | 2 | Dispatch 3 block types mới tới widget tương ứng | ✅ Done |
| `lib/features/ai_companion/presentation/session_companion_bridge.dart` | 2 | Map reasoning → companion blocks, push logic | ✅ Done |
| `lib/features/quiz/presentation/pages/quiz_page.dart` | 3 | Knowledge cards hiển thị khi bật hint + có RAG data | ✅ Done |
| `lib/features/progress/presentation/pages/progress_page.dart` | 3 | Reflection summary section sau AI narrative | ✅ Done |
| `lib/app/router/app_router.dart` | 3 | Route `/dev/reasoning` cho dev dashboard | ✅ Done |
| `lib/app/router/app_routes.dart` | 3 | Thêm `devReasoning` route constant | ✅ Done |

### Files KHÔNG đổi

| File | Lý do |
|---|---|
| `lib/core/network/agentic_api_service.dart` | Interface không đổi — response parsing tự handle fields mới |
| `lib/core/services/real_agentic_api_service.dart` | HTTP call không đổi — chỉ response JSON thêm fields |
| `lib/core/network/ws_service.dart` | WebSocket protocol không đổi |
| `lib/features/agentic_session/data/repositories/agentic_session_repository.dart` | Repository pass-through — không cần sửa |
| `lib/features/diagnosis/` | Diagnosis flow giữ nguyên — reasoning data là additive |
| `lib/main.dart` | BlocProvider setup không đổi |

---

## Checklist tổng kết

### Trước khi bắt đầu
- [x] ~~Backend đã deploy Phase 1~~ — Frontend implement trước, chờ backend sau
- [ ] Xác nhận response format với backend team
- [x] Backup branch hiện tại

### Sau mỗi phase
- [x] `flutter analyze` — 0 errors (đã verify 17/04)
- [x] `flutter test` — 53/53 pass, 2 pre-existing e2e failures không liên quan (đã verify 17/04)
- [ ] Test manual trên emulator/device
- [ ] Test backward compat (backend cũ không có reasoning fields)
- [ ] Test agentic mode (backend mới có reasoning fields)

### Validation cuối
- [ ] Reasoning trace hiển thị đúng trong companion sheet
- [ ] Knowledge cards hiển thị khi có RAG data
- [ ] Reflection widget hiển thị khi có reflection data
- [ ] Expand/collapse reasoning trace hoạt động
- [x] Backward compatible — tất cả agentic fields có defaults, widgets trả `SizedBox.shrink()` khi không có data
- [ ] Performance: không có jank khi render reasoning blocks
- [x] Vietnamese text hiển thị đúng dấu trong code
