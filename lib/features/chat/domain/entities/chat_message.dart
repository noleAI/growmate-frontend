enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isTyping = false,
    this.planRepaired = false,
    this.beliefEntropy,
    this.nextNodeType,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isTyping;

  /// Whether the agentic planner had to repair its plan for this response.
  final bool planRepaired;

  /// Bayesian belief entropy from the backend (0 = certain, higher = uncertain).
  final double? beliefEntropy;

  /// The orchestrator node type that produced this response (e.g. "hint",
  /// "de_stress", "recovery", "hitl_pending").
  final String? nextNodeType;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
    bool? planRepaired,
    double? beliefEntropy,
    String? nextNodeType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      planRepaired: planRepaired ?? this.planRepaired,
      beliefEntropy: beliefEntropy ?? this.beliefEntropy,
      nextNodeType: nextNodeType ?? this.nextNodeType,
    );
  }
}
