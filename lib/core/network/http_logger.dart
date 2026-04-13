import 'dart:convert';

import 'package:flutter/foundation.dart';

/// HTTP Logger cho việc debug API requests/responses.
///
/// Chỉ hoạt động trong debug mode để tránh leak thông tin trong production.
class HttpLogger {
  HttpLogger._();

  static final List<_HttpLogEntry> _entries = <_HttpLogEntry>[];
  static const int _maxEntries = 100;

  /// Log một request.
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
  }) {
    if (!kDebugMode) return;

    final entry = _HttpLogEntry(
      timestamp: DateTime.now(),
      type: 'REQUEST',
      method: method,
      url: url,
      headers: _sanitizeHeaders(headers),
      body: _formatBody(body),
    );

    _addEntry(entry);
    debugPrint(_formatEntry(entry));
  }

  /// Log một response.
  static void logResponse({
    required int statusCode,
    required String url,
    String? body,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final emoji = isSuccess ? '✅' : '❌';
    final type = isSuccess ? 'RESPONSE' : 'ERROR';

    final entry = _HttpLogEntry(
      timestamp: DateTime.now(),
      type: type,
      method: '',
      url: url,
      statusCode: statusCode,
      body: _truncate(body, 500),
      duration: duration,
      emoji: emoji,
    );

    _addEntry(entry);

    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    debugPrint('$emoji [$type] $statusCode $url$durationStr');
  }

  /// Log một error.
  static void logError({
    required String url,
    required Object error,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final entry = _HttpLogEntry(
      timestamp: DateTime.now(),
      type: 'ERROR',
      method: '',
      url: url,
      error: error.toString(),
      duration: duration,
      emoji: '💥',
    );

    _addEntry(entry);

    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    debugPrint('💥 [ERROR] $url$durationStr: $error');

    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Lấy danh sách logs gần đây.
  static List<Map<String, dynamic>> getRecentLogs({int limit = 20}) {
    final recent = _entries.reversed.take(limit).toList();
    return recent.map((e) => e.toJson()).toList();
  }

  /// Xóa tất cả logs.
  static void clearLogs() {
    _entries.clear();
  }

  /// Summary thống kê requests.
  static Map<String, dynamic> getStats() {
    final total = _entries.length;
    final success = _entries.where((e) => e.statusCode != null && e.statusCode! >= 200 && e.statusCode! < 300).length;
    final errors = _entries.where((e) => e.type == 'ERROR').length;

    final avgDuration = _entries
        .where((e) => e.duration != null)
        .fold<Duration>(
          Duration.zero,
          (sum, e) => sum + e.duration!,
        );

    final requestsWithDuration = _entries.where((e) => e.duration != null).length;
    final avgMs = requestsWithDuration > 0
        ? avgDuration.inMilliseconds / requestsWithDuration
        : 0;

    return <String, dynamic>{
      'total_entries': total,
      'success_count': success,
      'error_count': errors,
      'avg_response_time_ms': avgMs.round(),
    };
  }

  static void _addEntry(_HttpLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  static Map<String, String> _sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null) return <String, String>{};

    return Map<String, String>.fromEntries(
      headers.entries.map((e) {
        final key = e.key.toLowerCase();
        if (key.contains('authorization') ||
            key.contains('token') ||
            key.contains('cookie') ||
            key.contains('api-key')) {
          return MapEntry(e.key, '***REDACTED***');
        }
        return e;
      }),
    );
  }

  static String? _formatBody(Object? body) {
    if (body == null) return null;

    try {
      if (body is String) {
        // Thử pretty-print JSON
        final parsed = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      if (body is Map || body is List) {
        return const JsonEncoder.withIndent('  ').convert(body);
      }
      return body.toString();
    } catch (_) {
      return body.toString();
    }
  }

  static String _truncate(String? value, int maxLength) {
    if (value == null) return '';
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}... (truncated)';
  }

  static String _formatEntry(_HttpLogEntry entry) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.write('${entry.emoji} [$time] [${entry.type}]');

    if (entry.method.isNotEmpty) {
      buffer.write(' ${entry.method}');
    }

    buffer.write(' ${entry.url}');

    if (entry.statusCode != null) {
      buffer.write(' → ${entry.statusCode}');
    }

    if (entry.duration != null) {
      buffer.write(' (${entry.duration!.inMilliseconds}ms)');
    }

    return buffer.toString();
  }
}

class _HttpLogEntry {
  _HttpLogEntry({
    required this.timestamp,
    required this.type,
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.statusCode,
    this.error,
    this.duration,
    this.emoji = '📝',
  });

  final DateTime timestamp;
  final String type;
  final String method;
  final String url;
  final Map<String, String>? headers;
  final String? body;
  final int? statusCode;
  final String? error;
  final Duration? duration;
  final String emoji;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'method': method,
      'url': url,
      if (headers != null && headers!.isNotEmpty) 'headers': headers,
      if (body != null && body!.isNotEmpty) 'body': body,
      if (statusCode != null) 'statusCode': statusCode,
      if (error != null) 'error': error,
      if (duration != null) 'duration_ms': duration!.inMilliseconds,
    };
  }
}
