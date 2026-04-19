import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../../mascot/presentation/pages/mascot_selection_page.dart';
import '../../../quota/presentation/widgets/quota_exceeded_dialog.dart';
import '../../../quota/presentation/widgets/quota_indicator.dart';
import '../cubit/chat_quota_cubit.dart';
import '../cubit/chat_quota_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_quick_chips.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quotaCubit = context.read<ChatQuotaCubit?>();

    return BlocProvider(
      create: (_) => ChatCubit(
        repository: context.read<ChatRepository>(),
        quotaCubit: quotaCubit,
      )..initialize(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> with TickerProviderStateMixin {
  MascotId? _selectedMascot;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageMimeType;
  String? _selectedImageName;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadMascot();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (_) => _stopListening(),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _speechAvailable = available;
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speechAvailable = false;
        _isListening = false;
      });
      debugPrint('Speech service unavailable: ${e.code}');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speechAvailable = false;
        _isListening = false;
      });
      debugPrint('Speech initialization failed: $e');
    }
  }

  Future<void> _loadMascot() async {
    final prefs = await SharedPreferences.getInstance();
    final mascotName = prefs.getString('selected_mascot');
    setState(() {
      _selectedMascot = MascotId.values.firstWhere(
        (e) => e.name == mascotName,
        orElse: () => MascotId.cat,
      );
    });
  }

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final quotaCubit = context.read<ChatQuotaCubit?>();
    if (quotaCubit != null && !quotaCubit.canChat) {
      await QuotaExceededDialog.show(
        context,
        limit: _quotaLimitFromState(quotaCubit.state),
      );
      return;
    }

    if (_isListening) {
      _stopListening();
    }

    final outcome = await context.read<ChatCubit>().sendMessage(trimmed);

    if (!mounted) {
      return;
    }

    if (outcome != ChatSendOutcome.ignored) {
      _textController.clear();
      _focusNode.unfocus();
      _scrollToBottom();
    }

    if (outcome == ChatSendOutcome.quotaExceeded) {
      await QuotaExceededDialog.show(
        context,
        limit: _quotaLimitFromState(quotaCubit?.state),
      );
    }
  }

  int _quotaLimitFromState(ChatQuotaState? state) {
    if (state is ChatQuotaLoaded) {
      return state.quota.limit;
    }
    return 30;
  }

  bool _isGreetingOnly(ChatReady state) {
    return state.messages.length == 1 &&
        state.messages.first.id.startsWith('greeting_');
  }

  bool _canChatFromQuotaState(ChatQuotaState state) {
    if (state is ChatQuotaLoaded) {
      return !state.quota.isExceeded;
    }
    return true;
  }

  void _handleSendPressed() {
    final text = _textController.text.trim();
    final imageBytes = _selectedImageBytes;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    if (hasImage) {
      final prompt = text.isEmpty
          ? context.t(
              vi: 'Giúp mình phân tích nội dung trong ảnh này.',
              en: 'Please analyze the content in this image.',
            )
          : text;

      final quotaCubit = context.read<ChatQuotaCubit?>();
      if (quotaCubit != null && !quotaCubit.canChat) {
        QuotaExceededDialog.show(
          context,
          limit: _quotaLimitFromState(quotaCubit.state),
        );
        return;
      }

      if (_isListening) {
        _stopListening();
      }

      context.read<ChatCubit>().sendImageMessage(
        text: prompt,
        imageBytes: imageBytes,
        imageName: _selectedImageName ?? 'upload.jpg',
        imageMimeType: _selectedImageMimeType ?? 'image/jpeg',
      );

      _textController.clear();
      _clearSelectedImage();
      _focusNode.unfocus();
      _scrollToBottom();
      return;
    }

    if (text.isNotEmpty) {
      _sendMessage(text);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    if (!_speechAvailable) {
      _showSpeechUnavailableHint();
      return;
    }

    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    try {
      await _speech.listen(
        localeId: 'vi_VN',
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.collapsed(
              offset: _textController.text.length,
            );
          }
        },
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
      );
    } on PlatformException catch (e) {
      debugPrint('Speech listen unavailable: ${e.code}');
      _stopListening();
      if (mounted) {
        setState(() {
          _speechAvailable = false;
        });
      }
      _showSpeechUnavailableHint();
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      _stopListening();
    }
  }

  void _stopListening() {
    _speech.stop();
    if (!mounted) {
      return;
    }

    setState(() => _isListening = false);
    _pulseController.stop();
    _pulseController.reset();
  }

  void _showSpeechUnavailableHint() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              vi: 'Thiết bị chưa hỗ trợ nhập giọng nói. Bạn vẫn có thể nhập bằng bàn phím.',
              en: 'Speech input is not available on this device. You can keep typing normally.',
            ),
          ),
        ),
      );
  }

  Future<void> _showImageSourceSheet() async {
    if (_isListening) {
      _stopListening();
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  context.t(vi: 'Chọn từ thư viện', en: 'Pick from gallery'),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.t(vi: 'Chụp ảnh', en: 'Take a photo')),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
        requestFullMetadata: false,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Không đọc được ảnh đã chọn.',
                en: 'Could not read the selected image.',
              ),
            ),
          ),
        );
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
        _selectedImageMimeType = _detectMimeType(picked.name);
      });
      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              vi: 'Không thể chọn ảnh lúc này.',
              en: 'Unable to pick an image right now.',
            ),
          ),
        ),
      );
      debugPrint('Pick image failed: $e');
    }
  }

  String _detectMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageMimeType = null;
      _selectedImageName = null;
    });
  }

  void _showClearChatDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t(vi: 'Xóa cuộc trò chuyện?', en: 'Clear chat?')),
        content: Text(
          context.t(
            vi: 'Tất cả tin nhắn sẽ bị xóa.',
            en: 'All messages will be deleted.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t(vi: 'Hủy', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ChatCubit>().clearChat();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(context.t(vi: 'Xóa', en: 'Clear')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasQuotaCubit = context.read<ChatQuotaCubit?>() != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: colors.primary),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.10),
                ),
              ),
              alignment: Alignment.center,
              child: _selectedMascot != null
                  ? Text(
                      Mascot.all
                          .firstWhere((m) => m.id == _selectedMascot!)
                          .emoji,
                      style: const TextStyle(fontSize: 20),
                    )
                  : Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.onPrimaryContainer,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.t(vi: 'GrowMate AI', en: 'GrowMate AI'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.t(
                      vi: 'Gia sư THPT cho Android',
                      en: 'Study coach for Android',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (hasQuotaCubit)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(child: QuotaIndicator()),
            ),
          IconButton(
            onPressed: _showClearChatDialog,
            icon: Icon(Icons.delete_outline_rounded, color: colors.primary),
            tooltip: context.t(vi: 'Xóa cuộc trò chuyện', en: 'Clear chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BlocConsumer<ChatCubit, ChatState>(
                    listener: (context, state) {
                      if (state is ChatReady) {
                        _scrollToBottom();
                      }
                    },
                    builder: (context, state) {
                      if (state is ChatInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is ChatError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: ZenCard(
                              radius: 24,
                              padding: const EdgeInsets.all(22),
                              color: colors.surface,
                              border: Border.all(
                                color: colors.error.withValues(alpha: 0.18),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: colors.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.message,
                                    style: theme.textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (state is ChatReady) {
                        if (state.messages.isEmpty) {
                          return Center(
                            child: Text(
                              context.t(
                                vi: 'Bắt đầu cuộc trò chuyện!',
                                en: 'Start a conversation!',
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        final showWelcomeCard = _isGreetingOnly(state);

                        return Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: false,
                          child: ListView(
                            controller: _scrollController,
                            cacheExtent: 700,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            children: [
                              if (showWelcomeCard)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    10,
                                  ),
                                  child: _ChatWelcomeCard(
                                    onSuggestionSelected: (value) {
                                      _sendMessage(value);
                                    },
                                  ),
                                ),
                              ...state.messages.map((message) {
                                final isBot =
                                    message.role == ChatRole.assistant;
                                return ChatMessageBubble(
                                  message: message,
                                  onCopy: () {
                                    Clipboard.setData(
                                      ClipboardData(text: message.content),
                                    );
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context.t(
                                              vi: 'Đã sao chép',
                                              en: 'Copied',
                                            ),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                  },
                                  botMascot: isBot ? _selectedMascot : null,
                                );
                              }),
                              if (state.isAiTyping) const ChatTypingIndicator(),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatReady && !state.isAiTyping) {
                if (!hasQuotaCubit) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: ChatQuickChips(
                      onChipTapped: (text) => _sendMessage(text),
                    ),
                  );
                }

                return BlocBuilder<ChatQuotaCubit, ChatQuotaState>(
                  builder: (context, quotaState) {
                    if (!_canChatFromQuotaState(quotaState)) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: ChatQuickChips(
                        onChipTapped: (text) => _sendMessage(text),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _ListeningStatusBanner(pulseAnimation: _pulseAnimation),
            ),
          if (_selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _SelectedImagePreviewCard(
                imageBytes: _selectedImageBytes!,
                imageName:
                    _selectedImageName ??
                    context.t(vi: 'Ảnh đã chọn', en: 'Selected image'),
                onRemove: _clearSelectedImage,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: ZenCard(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              color: colors.surface,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.40),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ComposerToolButton(
                    icon: Icons.add_photo_alternate_outlined,
                    onPressed: _showImageSourceSheet,
                    tooltip: context.t(vi: 'Thêm ảnh', en: 'Attach image'),
                  ),
                  const SizedBox(width: 6),
                  _isListening
                      ? ScaleTransition(
                          scale: _pulseAnimation,
                          child: _ComposerToolButton(
                            icon: Icons.stop_rounded,
                            onPressed: _stopListening,
                            tooltip: context.t(vi: 'Dừng ghi âm', en: 'Stop'),
                            backgroundColor: colors.errorContainer,
                            foregroundColor: colors.onErrorContainer,
                          ),
                        )
                      : _ComposerToolButton(
                          icon: Icons.mic_none_rounded,
                          onPressed: _speechAvailable
                              ? _toggleListening
                              : _showSpeechUnavailableHint,
                          tooltip: context.t(
                            vi: _speechAvailable
                                ? 'Nhập bằng giọng nói'
                                : 'Thiết bị không hỗ trợ giọng nói',
                            en: _speechAvailable
                                ? 'Voice input'
                                : 'Speech unavailable on this device',
                          ),
                          foregroundColor: _speechAvailable
                              ? colors.onSurfaceVariant
                              : colors.outline,
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isListening
                              ? colors.primary.withValues(alpha: 0.40)
                              : colors.outlineVariant.withValues(alpha: 0.38),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? context.t(
                                  vi: 'Đang nhận giọng nói...',
                                  en: 'Listening...',
                                )
                              : context.t(
                                  vi: 'Hỏi bài hoặc gửi ảnh đề...',
                                  en: 'Ask a question or attach an image...',
                                ),
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.82,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _handleSendPressed(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      final isTyping = state is ChatReady && state.isAiTyping;
                      return IconButton.filled(
                        onPressed: isTyping ? null : _handleSendPressed,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          disabledBackgroundColor:
                              colors.surfaceContainerHighest,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: isTyping
                              ? colors.onSurfaceVariant
                              : colors.onPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningStatusBanner extends StatelessWidget {
  const _ListeningStatusBanner({required this.pulseAnimation});

  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: colors.surfaceContainerLowest,
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      child: Row(
        children: [
          ScaleTransition(
            scale: pulseAnimation,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.mic_rounded, color: colors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                vi: 'Đang nghe giọng nói của bạn. Hãy nói tự nhiên, GrowMate sẽ tự chèn vào khung chat.',
                en: 'Listening to your voice. Speak naturally and GrowMate will fill the composer.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedImagePreviewCard extends StatelessWidget {
  const _SelectedImagePreviewCard({
    required this.imageBytes,
    required this.imageName,
    required this.onRemove,
  });

  final Uint8List imageBytes;
  final String imageName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ZenCard(
      radius: 18,
      padding: const EdgeInsets.all(10),
      color: colors.surface,
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              imageBytes,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              cacheWidth: 136,
              filterQuality: FilterQuality.low,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh đã chọn',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imageName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            tooltip: context.t(vi: 'Bỏ ảnh', en: 'Remove image'),
          ),
        ],
      ),
    );
  }
}

class _ComposerToolButton extends StatelessWidget {
  const _ComposerToolButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? colors.surfaceContainerLow,
        foregroundColor: foregroundColor ?? colors.primary,
        padding: const EdgeInsets.all(14),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _ChatWelcomeCard extends StatelessWidget {
  const _ChatWelcomeCard({required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final suggestions = <({IconData icon, String title, String prompt})>[
      (
        icon: Icons.fact_check_rounded,
        title: 'Giải từng bước dễ hiểu',
        prompt: 'Giải thích lại bài này từng bước giúp mình',
      ),
      (
        icon: Icons.functions_rounded,
        title: 'Tóm tắt công thức trọng tâm',
        prompt: 'Tóm tắt nhanh công thức đạo hàm quan trọng',
      ),
      (
        icon: Icons.school_rounded,
        title: 'Cho ví dụ từ dễ đến khó',
        prompt: 'Cho mình một ví dụ dễ hơn rồi nâng dần',
      ),
    ];

    return ZenCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      color: colors.surfaceContainerLowest,
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.40)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GrowMate AI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t(
                        vi: 'Hỏi bằng chữ, giọng nói hoặc ảnh để nhận lời giải gọn, rõ và đúng trọng tâm.',
                        en: 'Ask by text, voice, or image for sharper and clearer help.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'Gợi ý',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WelcomeFeatureRow(
            icon: Icons.rule_folder_outlined,
            label: context.t(
              vi: 'Giải thích công thức và cách làm theo từng bước',
              en: 'Break down formulas and solution steps',
            ),
          ),
          const SizedBox(height: 8),
          _WelcomeFeatureRow(
            icon: Icons.image_search_rounded,
            label: context.t(
              vi: 'Phân tích nhanh ảnh bài tập hoặc đề thi',
              en: 'Analyze exercise or exam images quickly',
            ),
          ),
          const SizedBox(height: 8),
          _WelcomeFeatureRow(
            icon: Icons.timeline_rounded,
            label: context.t(
              vi: 'Gợi ý hướng học tiếp theo khi bạn đang bí',
              en: 'Suggest the next learning step when you get stuck',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((suggestion) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSuggestionSelected(suggestion.prompt),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            suggestion.icon,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            suggestion.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFeatureRow extends StatelessWidget {
  const _WelcomeFeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: colors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
