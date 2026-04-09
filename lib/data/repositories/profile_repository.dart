import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileRepository {
  ProfileRepository({
    SupabaseClient? supabaseClient,
    FlutterSecureStorage? secureStorage,
  }) : _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  static const String _cachePrefix = 'profile_cache_v1_';

  final SupabaseClient? _supabaseClient;
  final FlutterSecureStorage _secureStorage;

  Future<UserProfile?> fetchProfile(String uid) async {
    if (uid.trim().isEmpty) {
      return null;
    }

    final normalizedUid = uid.trim();
    final client = _supabaseClient;

    if (client == null) {
      return _fetchCachedOrMock(normalizedUid, null);
    }

    try {
      // RLS + explicit id filter ensures only owner profile is fetched.
      final row = await client
          .from('profiles')
          .select()
          .eq('id', normalizedUid)
          .maybeSingle();

      if (row == null) {
        final created = _defaultProfileFromAuth(
          uid: normalizedUid,
          user: client.auth.currentUser,
        );

        await _upsertProfile(client: client, profile: created);
        await _cacheProfile(created);
        return created;
      }

      final profile = _profileFromRow(
        row,
        fallbackUser: client.auth.currentUser,
        fallbackUid: normalizedUid,
      );
      await _cacheProfile(profile);
      return profile;
    } on PostgrestException catch (error) {
      final cached = await _fetchCachedOrMock(
        normalizedUid,
        client.auth.currentUser,
      );
      if (cached != null) {
        return cached;
      }
      throw ProfileRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      final cached = await _fetchCachedOrMock(
        normalizedUid,
        client.auth.currentUser,
      );
      if (cached != null) {
        return cached;
      }
      throw const ProfileRepositoryException(
        'Mình chưa tải được hồ sơ lúc này, bạn thử lại sau một chút nhé.',
      );
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final uid = profile.id.trim();
    if (uid.isEmpty) {
      throw const ProfileRepositoryException('Thiếu định danh người dùng.');
    }

    final normalized = profile.copyWith(
      id: uid,
      updatedAt: DateTime.now().toUtc(),
      lastActive: DateTime.now().toUtc(),
      consentBehavioral: profile.consentBehavioral,
      consentAnalytics: profile.consentAnalytics,
    );

    final client = _supabaseClient;
    if (client == null) {
      await _cacheProfile(normalized);
      return;
    }

    try {
      await _upsertProfile(client: client, profile: normalized);
      await _cacheProfile(normalized);
    } on PostgrestException catch (error) {
      throw ProfileRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const ProfileRepositoryException(
        'Mình chưa cập nhật được hồ sơ lúc này, bạn thử lại nhé.',
      );
    }
  }

  Future<void> clearCachedProfile(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return;
    }

    await _secureStorage.delete(key: '$_cachePrefix$normalizedUid');
  }

  Future<void> deleteProfile(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const ProfileRepositoryException('Thiếu định danh người dùng.');
    }

    final client = _supabaseClient;
    if (client != null) {
      try {
        await client.from('profiles').delete().eq('id', normalizedUid);
      } on PostgrestException catch (error) {
        throw ProfileRepositoryException(_mapPostgrestError(error));
      } catch (_) {
        throw const ProfileRepositoryException(
          'Mình chưa xóa được dữ liệu tài khoản lúc này, bạn thử lại nhé.',
        );
      }
    }

    await clearCachedProfile(normalizedUid);
  }

  Stream<UserProfile> profileStream(String uid) async* {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw const ProfileRepositoryException('Thiếu định danh người dùng.');
    }

    final client = _supabaseClient;
    if (client == null) {
      final fallback = await _fetchCachedOrMock(normalizedUid, null);
      if (fallback == null) {
        throw const ProfileRepositoryException(
          'Không có dữ liệu hồ sơ để hiển thị.',
        );
      }
      yield fallback;
      return;
    }

    final initial = await fetchProfile(normalizedUid);
    if (initial != null) {
      yield initial;
    }

    yield* client
        .from('profiles')
        .stream(primaryKey: const ['id'])
        .eq('id', normalizedUid)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            final profile = await fetchProfile(normalizedUid);
            if (profile == null) {
              throw const ProfileRepositoryException(
                'Không tìm thấy hồ sơ phù hợp.',
              );
            }
            return profile;
          }

          final profile = _profileFromRow(
            rows.first,
            fallbackUser: client.auth.currentUser,
            fallbackUid: normalizedUid,
          );
          await _cacheProfile(profile);
          return profile;
        });
  }

  Future<void> _upsertProfile({
    required SupabaseClient client,
    required UserProfile profile,
  }) {
    final payload = profile.toUpsertJson()
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String()
      ..['last_active'] = DateTime.now().toUtc().toIso8601String();

    // RLS is enforced server-side. Client still scopes by id to avoid accidental writes.
    return client.from('profiles').upsert(payload, onConflict: 'id');
  }

  Future<UserProfile?> _fetchCachedOrMock(String uid, User? user) async {
    final cachedRaw = await _secureStorage.read(key: '$_cachePrefix$uid');
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        return UserProfile.fromJson(
          jsonDecode(cachedRaw) as Map<String, dynamic>,
        );
      } catch (_) {
        await _secureStorage.delete(key: '$_cachePrefix$uid');
      }
    }

    final mock = _defaultProfileFromAuth(uid: uid, user: user);
    await _cacheProfile(mock);
    return mock;
  }

  Future<void> _cacheProfile(UserProfile profile) {
    return _secureStorage.write(
      key: '$_cachePrefix${profile.id}',
      value: jsonEncode(profile.toJson()),
    );
  }

  UserProfile _profileFromRow(
    Map<String, dynamic> row, {
    required User? fallbackUser,
    required String fallbackUid,
  }) {
    final consentFlags = _toMap(row['consent_flags']);

    return UserProfile(
      id: row['id']?.toString() ?? fallbackUid,
      fullName:
          row['full_name']?.toString() ??
          fallbackUser?.userMetadata?['display_name']?.toString() ??
          'Bạn',
      email: row['email']?.toString() ?? fallbackUser?.email ?? '',
      avatarUrl: row['avatar_url']?.toString(),
      gradeLevel: row['grade_level']?.toString(),
      activeSubjects: _toStringList(row['active_subjects']),
      learningPreferences: _toMap(row['learning_preferences']),
      recoveryModeEnabled: _toBool(
        row['recovery_mode_enabled'],
        fallback: false,
      ),
      consentBehavioral: _toBool(
        row['consent_behavioral'],
        fallback: _toBool(consentFlags['behavioral'], fallback: false),
      ),
      consentAnalytics: _toBool(
        row['consent_analytics'],
        fallback: _toBool(consentFlags['analytics'], fallback: false),
      ),
      subscriptionTier: row['subscription_tier']?.toString() ?? 'free',
      createdAt: _toDateTime(row['created_at']),
      updatedAt: _toDateTime(row['updated_at']),
      lastActive: _toDateTime(row['last_active']),
    );
  }

  UserProfile _defaultProfileFromAuth({
    required String uid,
    required User? user,
  }) {
    final displayName =
        user?.userMetadata?['display_name']?.toString().trim() ?? 'Bạn';

    return UserProfile(
      id: uid,
      fullName: displayName.isEmpty ? 'Bạn' : displayName,
      email: user?.email ?? '',
      avatarUrl: user?.userMetadata?['avatar_url']?.toString(),
      gradeLevel: null,
      activeSubjects: const <String>[],
      learningPreferences: const <String, dynamic>{
        'pace': 'gentle',
        'session_length_minutes': 15,
        'hint_style': 'step_by_step',
      },
      recoveryModeEnabled: false,
      consentBehavioral: false,
      consentAnalytics: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      lastActive: DateTime.now().toUtc(),
    );
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String _mapPostgrestError(PostgrestException error) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();

    if (code == '42501' || message.contains('row-level security')) {
      return 'Bạn chưa có quyền cập nhật mục này. Mình giữ dữ liệu an toàn cho bạn.';
    }

    if (code == '23505') {
      return 'Thông tin này đã tồn tại rồi, mình thử giá trị khác nhé.';
    }

    return 'Mình chưa xử lý được yêu cầu hồ sơ lúc này, bạn thử lại sau một chút nhé.';
  }

  static Map<String, dynamic> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static bool _toBool(Object? value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
    return fallback;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
