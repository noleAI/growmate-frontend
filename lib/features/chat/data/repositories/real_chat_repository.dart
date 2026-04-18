import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_config.dart';
import '../../../chat/domain/entities/chat_message.dart';
import 'chat_repository.dart';

/// Chat repository that calls POST /api/v1/chatbot/chat
/// — enforces content policy on the backend side.
class RealChatRepository implements ChatRepository {
  static const int _maxLocalHistoryItems = 40;
  static const int _maxHistoryImagesToHydrate = 8;
  static const String _localHistoryCacheKey = 'chat_local_history_v2';
  static const String _historyImagePrefix = '[Ảnh] ';

  RealChatRepository({
    required Future<String?> Function() getAccessToken,
    http.Client? httpClient,
  }) : _getAccessToken = getAccessToken,
       _httpClient = httpClient ?? http.Client();

  final Future<String?> Function() _getAccessToken;
  final http.Client _httpClient;

  /// In-memory history kept for fallback when DB load fails.
  final List<Map<String, dynamic>> _localHistory = [];
  bool _cacheLoaded = false;

  String get _baseUrl => ApiConfig.restApiBaseUrl;

  // ── ChatRepository interface ────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendMessage(String userMessage) async {
    await _ensureCacheLoaded();

    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return _errorMessage('Bạn cần đăng nhập để dùng tính năng này.');
    }

    final uri = Uri.parse('$_baseUrl/chatbot/chat');

    final body = jsonEncode(<String, dynamic>{
      'message': userMessage,
      'history': _requestHistoryWindow(),
    });

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      if (kDebugMode) {
        debugPrint('💬 [Chatbot] ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['reply']?.toString() ?? '';

        await _appendLocalHistory(userMessage: userMessage, aiReply: reply);

        return ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: reply,
          timestamp: DateTime.now(),
        );
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = _extractQuotaMessage(data);
        return _errorMessage(msg);
      }

      return _errorMessage(
        'Lỗi kết nối (${response.statusCode}). Thử lại sau nhé!',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chatbot] Error: $e');
      return _errorMessage(
        'Không thể kết nối đến server. Kiểm tra mạng và thử lại nhé!',
      );
    }
  }

  @override
  Future<ChatMessage> sendImageMessage({
    required String userMessage,
    required Uint8List imageBytes,
    required String imageName,
    required String imageMimeType,
  }) async {
    await _ensureCacheLoaded();

    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return _errorMessage('Bạn cần đăng nhập để dùng tính năng này.');
    }

    final prompt = userMessage.trim().isEmpty
        ? 'Giúp mình phân tích nội dung trong ảnh này.'
        : userMessage.trim();

    final uri = Uri.parse('$_baseUrl/chatbot/chat_with_image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['message'] = prompt
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName.isEmpty ? 'upload.jpg' : imageName,
          contentType: _parseMediaType(imageMimeType),
        ),
      );

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        debugPrint(
          '🖼️ [Chatbot Image] ${response.statusCode}: ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['reply']?.toString() ?? '';

        final imagePath = await _saveImageToDisk(
          imageBytes,
          imageName: imageName,
        );

        await _appendLocalHistory(
          userMessage: '$_historyImagePrefix$prompt',
          aiReply: reply,
          userImagePath: imagePath,
          userImageMimeType: imageMimeType,
          userImageName: imageName,
        );

        return ChatMessage(
          id: 'ai_img_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: reply,
          timestamp: DateTime.now(),
        );
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _errorMessage(_extractQuotaMessage(data));
      }

      final detailMessage = _extractBackendDetailMessage(response.body);
      if (detailMessage != null && detailMessage.isNotEmpty) {
        return _errorMessage(detailMessage);
      }

      return _errorMessage(
        'Không gửi được ảnh (${response.statusCode}). Bạn thử lại nhé!',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chatbot Image] Error: $e');
      return _errorMessage(
        'Không thể gửi ảnh lên server. Kiểm tra mạng và thử lại nhé!',
      );
    }
  }

  @override
  ChatMessage getGreeting() {
    return ChatMessage(
      id: 'greeting_0',
      role: ChatRole.assistant,
      content:
          'Xin chào! Mình là GrowMate AI 🤖\n\n'
          'Mình có thể giúp bạn với bất kỳ môn học THPT nào:\n'
          '• 📐 Toán, Lý, Hóa, Sinh\n'
          '• 📖 Văn, Sử, Địa, GDCD\n'
          '• 🌍 Tiếng Anh, Tin học\n'
          '• 💡 Phương pháp ôn thi THPT Quốc gia\n\n'
          'Hỏi mình bất cứ điều gì về kiến thức học thuật nhé! 📚',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<ChatMessage>> loadHistory() async {
    await _ensureCacheLoaded();

    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return _buildMessagesFromLocalHistory();
    }

    final uri = Uri.parse('$_baseUrl/chatbot/history?limit=40');
    try {
      final response = await _httpClient
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _buildMessagesFromLocalHistory();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = data['messages'] as List<dynamic>? ?? [];

      final serverMessages = await _buildMessagesFromServer(rawList);
      if (serverMessages.isNotEmpty) {
        return serverMessages;
      }

      return _buildMessagesFromLocalHistory();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Chatbot] loadHistory error: $e');
      return _buildMessagesFromLocalHistory();
    }
  }

  @override
  void clearHistory() {
    final removedEntries = List<Map<String, dynamic>>.from(_localHistory);
    _localHistory.clear();
    _cacheLoaded = true;
    unawaited(_clearPersistedHistory(removedEntries));
    unawaited(_clearRemoteHistory());
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Map<String, String>> _requestHistoryWindow() {
    return _localHistory
        .take(20)
        .map(
          (entry) => {
            'role': (entry['role']?.toString() ?? 'user'),
            'content': entry['content']?.toString() ?? '',
          },
        )
        .toList();
  }

  Future<void> _appendLocalHistory({
    required String userMessage,
    required String aiReply,
    String? userImagePath,
    String? userImageMimeType,
    String? userImageName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final userEntry = <String, dynamic>{
      'role': 'user',
      'content': userMessage,
      'created_at': now,
    };

    if (userImagePath != null && userImagePath.isNotEmpty) {
      userEntry['image_path'] = userImagePath;
    }
    if (userImageMimeType != null && userImageMimeType.isNotEmpty) {
      userEntry['image_mime_type'] = userImageMimeType;
    }
    if (userImageName != null && userImageName.isNotEmpty) {
      userEntry['image_name'] = userImageName;
    }

    _localHistory
      ..add(userEntry)
      ..add({'role': 'assistant', 'content': aiReply, 'created_at': now});

    await _trimAndCleanupLocalHistory();
    await _persistLocalHistory();
  }

  Future<void> _trimAndCleanupLocalHistory() async {
    while (_localHistory.length > _maxLocalHistoryItems) {
      final removed = _localHistory.removeAt(0);
      await _deleteImageForEntry(removed);
    }
  }

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localHistoryCacheKey);
    if (raw == null || raw.isEmpty) {
      _cacheLoaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final normalized = _normalizeCacheEntry(item);
            if (normalized != null) {
              _localHistory.add(normalized);
            }
          }
        }
      }
    } catch (_) {
      _localHistory.clear();
    }

    _cacheLoaded = true;
  }

  Map<String, dynamic>? _normalizeCacheEntry(Map<dynamic, dynamic> source) {
    final role = source['role']?.toString();
    final content = source['content']?.toString();
    if (role == null || content == null || content.isEmpty) {
      return null;
    }

    final normalized = <String, dynamic>{
      'role': role == 'assistant' ? 'assistant' : 'user',
      'content': content,
    };

    if (source['created_at'] != null) {
      normalized['created_at'] = source['created_at'].toString();
    }
    if (source['image_path'] != null) {
      normalized['image_path'] = source['image_path'].toString();
    }
    if (source['image_mime_type'] != null) {
      normalized['image_mime_type'] = source['image_mime_type'].toString();
    }
    if (source['image_name'] != null) {
      normalized['image_name'] = source['image_name'].toString();
    }

    return normalized;
  }

  Future<void> _persistLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localHistoryCacheKey, jsonEncode(_localHistory));
  }

  Future<List<ChatMessage>> _buildMessagesFromServer(
    List<dynamic> rawList,
  ) async {
    final imageRefsByKey = <String, List<_CachedImageRef>>{};

    for (final entry in _localHistory) {
      final role = entry['role']?.toString() ?? 'user';
      if (role != 'user') {
        continue;
      }
      final imagePath = entry['image_path']?.toString();
      if (imagePath == null || imagePath.isEmpty) {
        continue;
      }
      final content = entry['content']?.toString() ?? '';
      final key = _historyKey(role: role, content: content);
      imageRefsByKey
          .putIfAbsent(key, () => <_CachedImageRef>[])
          .add(
            _CachedImageRef(
              path: imagePath,
              mimeType: entry['image_mime_type']?.toString(),
              name: entry['image_name']?.toString(),
            ),
          );
    }

    final hydratedUserImageIndices = <int>{};
    var remainingHydrationBudget = _maxHistoryImagesToHydrate;
    for (var i = rawList.length - 1; i >= 0 && remainingHydrationBudget > 0; i--) {
      final raw = rawList[i];
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      if ((raw['role']?.toString() ?? '') != 'user') {
        continue;
      }

      final attachmentRaw = raw['attachment'];
      final hasServerAttachmentImage =
          attachmentRaw is Map && attachmentRaw['type']?.toString() == 'image';
      final rawContent = raw['content']?.toString() ?? '';
      final hasLocalFallbackImage =
          imageRefsByKey[_historyKey(role: 'user', content: rawContent)]
              ?.isNotEmpty ??
          false;

      if (hasServerAttachmentImage || hasLocalFallbackImage) {
        hydratedUserImageIndices.add(i);
        remainingHydrationBudget--;
      }
    }

    final messages = <ChatMessage>[];
    for (final indexed in rawList.indexed) {
      final idx = indexed.$1;
      final raw = indexed.$2;
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final role = raw['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
      final roleString = role == ChatRole.user ? 'user' : 'assistant';
      final rawContent = raw['content']?.toString() ?? '';
      final displayContent = _toDisplayContent(rawContent);

      DateTime ts = DateTime.now();
      try {
        ts = DateTime.parse(raw['created_at'] as String? ?? '');
      } catch (_) {}

      Uint8List? imageBytes;
      String? imageMimeType;
      String? imageName;

      if (role == ChatRole.user) {
        final shouldHydrateImage = hydratedUserImageIndices.contains(idx);
        final attachmentRaw = raw['attachment'];
        if (shouldHydrateImage && attachmentRaw is Map) {
          final attachmentType = attachmentRaw['type']?.toString();
          final attachmentUrl = attachmentRaw['url']?.toString();
          if (attachmentType == 'image') {
            imageMimeType = attachmentRaw['mime_type']?.toString();
            imageName = attachmentRaw['file_name']?.toString();
            imageBytes = await _readImageBytesFromUrl(attachmentUrl);
          }
        }

        final key = _historyKey(role: roleString, content: rawContent);
        final refs = imageRefsByKey[key];
        if (shouldHydrateImage &&
            (imageBytes == null || imageBytes.isEmpty) &&
            refs != null &&
            refs.isNotEmpty) {
          final ref = refs.removeAt(0);
          imageBytes = await _readImageBytesFromPath(ref.path);
          imageMimeType ??= ref.mimeType;
          imageName ??= ref.name;
        }
      }

      messages.add(
        ChatMessage(
          id: 'hist_$idx',
          role: role,
          content: displayContent,
          timestamp: ts,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
          imageName: imageName,
        ),
      );
    }

    return messages;
  }

  Future<List<ChatMessage>> _buildMessagesFromLocalHistory() async {
    final messages = <ChatMessage>[];
    final hydrateFromIndex =
        (_localHistory.length - _maxHistoryImagesToHydrate).clamp(
          0,
          _localHistory.length,
        );

    for (final indexed in _localHistory.indexed) {
      final idx = indexed.$1;
      final entry = indexed.$2;

      final roleString = entry['role']?.toString() ?? 'assistant';
      final role = roleString == 'user' ? ChatRole.user : ChatRole.assistant;
      final rawContent = entry['content']?.toString() ?? '';
      final displayContent = _toDisplayContent(rawContent);

      DateTime ts = DateTime.now();
      try {
        ts = DateTime.parse(entry['created_at'] as String? ?? '');
      } catch (_) {}

      final imagePath = entry['image_path']?.toString();
    final shouldHydrateImage = idx >= hydrateFromIndex;
    final imageBytes = shouldHydrateImage
      ? await _readImageBytesFromPath(imagePath)
      : null;

      messages.add(
        ChatMessage(
          id: 'cached_$idx',
          role: role,
          content: displayContent,
          timestamp: ts,
          imageBytes: imageBytes,
          imageMimeType: entry['image_mime_type']?.toString(),
          imageName: entry['image_name']?.toString(),
        ),
      );
    }

    return messages;
  }

  Future<String?> _saveImageToDisk(
    Uint8List imageBytes, {
    required String imageName,
  }) async {
    try {
      final rootDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(
        '${rootDir.path}${Platform.pathSeparator}chat_images',
      );
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final extension = _fileExtensionFromName(imageName);
      final filePath =
          '${imageDir.path}${Platform.pathSeparator}img_${DateTime.now().millisecondsSinceEpoch}$extension';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _fileExtensionFromName(String imageName) {
    final dotIndex = imageName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= imageName.length - 1) {
      return '.jpg';
    }
    final ext = imageName.substring(dotIndex).toLowerCase();
    if (RegExp(r'^\.[a-z0-9]+$').hasMatch(ext)) {
      return ext;
    }
    return '.jpg';
  }

  Future<Uint8List?> _readImageBytesFromPath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _readImageBytesFromUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return null;
      }
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteImageForEntry(Map<String, dynamic> entry) async {
    final imagePath = entry['image_path']?.toString();
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedHistory(
    List<Map<String, dynamic>> removedEntries,
  ) async {
    for (final entry in removedEntries) {
      await _deleteImageForEntry(entry);
    }
    await _persistLocalHistory();
  }

  Future<void> _clearRemoteHistory() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final uri = Uri.parse('$_baseUrl/chatbot/history');
    try {
      final response = await _httpClient
          .delete(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint('🧹 [Chatbot] clearHistory ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Chatbot] clearHistory error: $e');
      }
    }
  }

  String _historyKey({required String role, required String content}) {
    return '$role|$content';
  }

  String _toDisplayContent(String rawContent) {
    if (rawContent.startsWith(_historyImagePrefix)) {
      return rawContent.substring(_historyImagePrefix.length);
    }

    return rawContent;
  }

  String _extractQuotaMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    return (detail is Map ? detail['message'] : null) as String? ??
        'Bạn đã hết lượt chat hôm nay. Quay lại vào ngày mai nhé! 🌙';
  }

  String? _extractBackendDetailMessage(String rawBody) {
    try {
      final data = jsonDecode(rawBody) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is Map) {
        return detail['message']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  MediaType _parseMediaType(String imageMimeType) {
    try {
      return MediaType.parse(imageMimeType);
    } catch (_) {
      return MediaType('image', 'jpeg');
    }
  }

  ChatMessage _errorMessage(String text) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: text,
      timestamp: DateTime.now(),
    );
  }
}

class _CachedImageRef {
  const _CachedImageRef({
    required this.path,
    required this.mimeType,
    required this.name,
  });

  final String path;
  final String? mimeType;
  final String? name;
}
