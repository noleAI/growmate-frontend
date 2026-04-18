import 'package:shared_preferences/shared_preferences.dart';

class DataConsentRepository {
  DataConsentRepository._();

  static final DataConsentRepository instance = DataConsentRepository._();

  static const String _consentAcceptedKey = 'data_consent_accepted';
  static const String _consentAcceptedAtKey = 'data_consent_accepted_at';
  static const String _legacyMigratedToUserKey =
      'data_consent_legacy_migrated_to_user';
  static const String _migrationDonePrefix = 'data_consent_migration_done';

  // Kept for backward compat with existing code that calls without a userKey.
  @Deprecated('Pass userKey to scope consent per user')
  static const String consentAcceptedKey = _consentAcceptedKey;
  @Deprecated('Pass userKey to scope consent per user')
  static const String consentAcceptedAtKey = _consentAcceptedAtKey;

  final Set<String> _migrationCache = <String>{};

  String? _normalizeUserKey(String? userKey) {
    if (userKey == null) {
      return null;
    }

    final normalized = userKey.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _consentKey(String? userKey) => userKey != null && userKey.isNotEmpty
      ? '${_consentAcceptedKey}_$userKey'
      : _consentAcceptedKey;

  String _consentAtKey(String? userKey) => userKey != null && userKey.isNotEmpty
      ? '${_consentAcceptedAtKey}_$userKey'
      : _consentAcceptedAtKey;

  String _migrationDoneKey(String userKey) =>
      '${_migrationDonePrefix}_$userKey';

  Future<void> migrateLegacyConsentToUserScope({
    required String userKey,
  }) async {
    final normalizedUserKey = _normalizeUserKey(userKey);
    if (normalizedUserKey == null) {
      return;
    }

    if (_migrationCache.contains(normalizedUserKey)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final doneKey = _migrationDoneKey(normalizedUserKey);

    if (prefs.getBool(doneKey) == true) {
      _migrationCache.add(normalizedUserKey);
      return;
    }

    final hasUserScopedConsent =
        prefs.getBool(_consentKey(normalizedUserKey)) == true;
    if (hasUserScopedConsent) {
      await prefs.setBool(doneKey, true);
      _migrationCache.add(normalizedUserKey);
      return;
    }

    final legacyAccepted = prefs.getBool(_consentAcceptedKey) == true;
    final legacyMigratedToUser = prefs.getString(_legacyMigratedToUserKey);

    final canMigrateLegacy =
        legacyAccepted &&
        (legacyMigratedToUser == null ||
            legacyMigratedToUser == normalizedUserKey);

    if (canMigrateLegacy) {
      await prefs.setBool(_consentKey(normalizedUserKey), true);

      final legacyAcceptedAt = prefs.getString(_consentAcceptedAtKey);
      if (legacyAcceptedAt != null && legacyAcceptedAt.isNotEmpty) {
        await prefs.setString(
          _consentAtKey(normalizedUserKey),
          legacyAcceptedAt,
        );
      }

      await prefs.setString(_legacyMigratedToUserKey, normalizedUserKey);
    }

    await prefs.setBool(doneKey, true);
    _migrationCache.add(normalizedUserKey);
  }

  Future<bool> isAccepted({String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedUserKey = _normalizeUserKey(userKey);

    final accepted = prefs.getBool(_consentKey(normalizedUserKey)) == true;
    if (accepted) {
      return true;
    }

    if (normalizedUserKey == null) {
      return false;
    }

    // Self-heal legacy global consent for the same user scope.
    final legacyAccepted = prefs.getBool(_consentAcceptedKey) == true;
    final legacyMigratedToUser = prefs.getString(_legacyMigratedToUserKey);
    final canMigrateLegacy =
        legacyAccepted &&
        (legacyMigratedToUser == null ||
            legacyMigratedToUser == normalizedUserKey);

    if (!canMigrateLegacy) {
      return false;
    }

    await prefs.setBool(_consentKey(normalizedUserKey), true);

    final legacyAcceptedAt = prefs.getString(_consentAcceptedAtKey);
    if (legacyAcceptedAt != null && legacyAcceptedAt.isNotEmpty) {
      await prefs.setString(_consentAtKey(normalizedUserKey), legacyAcceptedAt);
    }

    await prefs.setString(_legacyMigratedToUserKey, normalizedUserKey);
    await prefs.setBool(_migrationDoneKey(normalizedUserKey), true);
    _migrationCache.add(normalizedUserKey);
    return true;
  }

  Future<void> saveConsent({required bool accepted, String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedUserKey = _normalizeUserKey(userKey);
    await prefs.setBool(_consentKey(normalizedUserKey), accepted);

    if (accepted) {
      await prefs.setString(
        _consentAtKey(normalizedUserKey),
        DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    await prefs.remove(_consentAtKey(normalizedUserKey));
  }

  Future<DateTime?> acceptedAt({String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consentAtKey(_normalizeUserKey(userKey)));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
