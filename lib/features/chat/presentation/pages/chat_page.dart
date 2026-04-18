import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/i18n/build_context_i18n.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../../mascot/presentation/pages/mascot_selection_page.dart';
import '../../../quota/presentation/cubit/quota_cubit.dart';
import '../../../quota/presentation/cubit/quota_state.dart';
import '../../../quota/presentation/widgets/quota_exceeded_dialog.dart';
import '../../../quota/presentation/widgets/quota_indicator.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_quick_chips.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quotaCubit = context.read<QuotaCubit?>();

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

    final quotaCubit = context.read<QuotaCubit?>();
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

  int _quotaLimitFromState(QuotaState? state) {
    if (state is QuotaLoaded) {
      return state.quota.limit;
    }
    return 30;
  }

  bool _canChatFromQuotaState(QuotaState state) {
    if (state is QuotaLoaded) {
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

      final quotaCubit = context.read<QuotaCubit?>();
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
    final hasQuotaCubit = context.read<QuotaCubit?>() != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: colors.primary),
        titleSpacing: 0,
        title: Row(
          children: [
            if (_selectedMascot != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  Mascot.all.firstWhere((m) => m.id == _selectedMascot!).emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            Text(
              context.t(vi: 'Chat AI', en: 'Chat AI'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        actions: [
          if (hasQuotaCubit)
            const Padding(
              padding: EdgeInsets.only(right: 6),
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
          // Messages list
          Expanded(
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
                      padding: const EdgeInsets.all(32),
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

                  return ListView.builder(
                    controller: _scrollController,
                    cacheExtent: 600,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    itemCount:
                        state.messages.length + (state.isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isAiTyping) {
                        return const ChatTypingIndicator();
                      }
                      final isBot =
                          state.messages[index].role == ChatRole.assistant;
                      return ChatMessageBubble(
                        message: state.messages[index],
                        onCopy: () {
                          Clipboard.setData(
                            ClipboardData(text: state.messages[index].content),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.t(vi: 'Đã sao chép', en: 'Copied'),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                        },
                        botMascot: isBot ? _selectedMascot : null,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Quick chips
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatReady && !state.isAiTyping) {
                if (!hasQuotaCubit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChatQuickChips(
                      onChipTapped: (text) => _sendMessage(text),
                    ),
                  );
                }

                return BlocBuilder<QuotaCubit, QuotaState>(
                  builder: (context, quotaState) {
                    if (!_canChatFromQuotaState(quotaState)) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: colors.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Icon(
                      Icons.mic_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.t(
                      vi: 'Đang nghe... nói câu hỏi của bạn',
                      en: 'Listening... speak your question',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 128,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedImageName ??
                            context.t(vi: 'Ảnh đã chọn', en: 'Selected image'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _clearSelectedImage,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: context.t(vi: 'Bỏ ảnh', en: 'Remove image'),
                    ),
                  ],
                ),
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              8,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2, bottom: 2),
                  child: IconButton(
                    onPressed: _showImageSourceSheet,
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: context.t(vi: 'Thêm ảnh', en: 'Attach image'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  child: _isListening
                      ? ScaleTransition(
                          scale: _pulseAnimation,
                          child: IconButton.filled(
                            onPressed: _stopListening,
                            style: IconButton.styleFrom(
                              backgroundColor: colors.error,
                            ),
                            icon: Icon(
                              Icons.stop_rounded,
                              size: 20,
                              color: colors.onError,
                            ),
                            tooltip: context.t(vi: 'Dừng ghi âm', en: 'Stop'),
                          ),
                        )
                      : IconButton(
                          onPressed: _speechAvailable
                              ? _toggleListening
                              : _showSpeechUnavailableHint,
                          icon: Icon(
                            Icons.mic_none_rounded,
                            size: 22,
                            color: _speechAvailable
                                ? colors.onSurfaceVariant
                                : colors.outline,
                          ),
                          tooltip: context.t(
                            vi: _speechAvailable
                                ? 'Nhập bằng giọng nói'
                                : 'Thiết bị không hỗ trợ giọng nói',
                            en: _speechAvailable
                                ? 'Voice input'
                                : 'Speech unavailable on this device',
                          ),
                        ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      border: _isListening
                          ? Border.all(color: colors.primary, width: 1.5)
                          : null,
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
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
                                vi: 'Hỏi GrowMate AI...',
                                en: 'Ask GrowMate AI...',
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: IconButton.filled(
                        onPressed: isTyping ? null : _handleSendPressed,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary,
                          disabledBackgroundColor:
                              colors.surfaceContainerHighest,
                        ),
                        icon: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: isTyping
                              ? colors.onSurfaceVariant
                              : colors.onPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
