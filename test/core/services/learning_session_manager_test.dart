import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

import 'package:growmate_frontend/core/services/learning_session_manager.dart';
import 'package:growmate_frontend/core/network/api_config.dart';

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

String? _getStringArg(MethodCall call, String key) {
  final arguments = call.arguments;
  if (arguments is Map) {
    final value = arguments[key];
    if (value is String) {
      return value;
    }
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> inMemoryStorage = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
          switch (call.method) {
            case 'read':
              final key = _getStringArg(call, 'key');
              return key == null ? null : inMemoryStorage[key];
            case 'write':
              final key = _getStringArg(call, 'key');
              final value = _getStringArg(call, 'value');
              if (key != null && value != null) {
                inMemoryStorage[key] = value;
              }
              return null;
            case 'delete':
              final key = _getStringArg(call, 'key');
              if (key != null) {
                inMemoryStorage.remove(key);
              }
              return null;
            case 'deleteAll':
              inMemoryStorage.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(inMemoryStorage);
            case 'containsKey':
              final key = _getStringArg(call, 'key');
              return key != null && inMemoryStorage.containsKey(key);
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  group('LearningSessionManager', () {
    late FlutterSecureStorage secureStorage;
    late LearningSessionManager sessionManager;

    setUp(() {
      secureStorage = const FlutterSecureStorage();
      sessionManager = LearningSessionManager(secureStorage: secureStorage);
    });

    tearDown(() async {
      // Cleanup
      await secureStorage.deleteAll();
    });

    test('tạo local session khi không có Supabase', () async {
      final sessionId = await sessionManager.getActiveSessionId();

      expect(sessionId, isNotEmpty);
      expect(sessionId, startsWith('session_'));
    });

    test('cached session được reuse trong vòng 2 giờ', () async {
      final sessionId1 = await sessionManager.getActiveSessionId();
      final sessionId2 = await sessionManager.getActiveSessionId();

      expect(sessionId1, equals(sessionId2));
    });

    test('reset() xóa cached session', () async {
      final sessionId1 = await sessionManager.getActiveSessionId();
      await sessionManager.reset();
      final sessionId2 = await sessionManager.getActiveSessionId();

      // Session ID mới sẽ khác vì đã reset
      expect(sessionId1, isNot(equals(sessionId2)));
    });
  });

  group('Session ID Storage Keys', () {
    test('ApiConfig.sessionIdStorageKey đúng value', () {
      expect(ApiConfig.sessionIdStorageKey, equals('learning_session_id'));
    });

    test('ApiConfig.accessTokenStorageKey đúng value', () {
      expect(ApiConfig.accessTokenStorageKey, equals('access_token'));
    });

    test('ApiConfig.refreshTokenStorageKey đúng value', () {
      expect(ApiConfig.refreshTokenStorageKey, equals('refresh_token'));
    });
  });
}
