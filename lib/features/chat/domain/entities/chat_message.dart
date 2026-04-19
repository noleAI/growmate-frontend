import 'dart:typed_data';

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
    this.imageBytes,
    this.imageUrl,
    this.imageMimeType,
    this.imageName,
    this.processingSummary,
    this.processingTags = const [],
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

  /// Optional image payload attached to this chat message.
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? imageMimeType;
  final String? imageName;

  /// Backend-provided processing summary for the assistant reply.
  final String? processingSummary;

  /// Backend-provided processing badges that explain what was used.
  final List<String> processingTags;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isTyping,
    bool? planRepaired,
    double? beliefEntropy,
    String? nextNodeType,
    Uint8List? imageBytes,
    String? imageUrl,
    String? imageMimeType,
    String? imageName,
    String? processingSummary,
    List<String>? processingTags,
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
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      imageMimeType: imageMimeType ?? this.imageMimeType,
      imageName: imageName ?? this.imageName,
      processingSummary: processingSummary ?? this.processingSummary,
      processingTags: processingTags ?? this.processingTags,
    );
  }
}
