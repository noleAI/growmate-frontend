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
    final normalizedUserKey = userKey.trim();
    if (normalizedUserKey.isEmpty) {
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
    return prefs.getBool(_consentKey(userKey)) == true;
  }

  Future<void> saveConsent({required bool accepted, String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey(userKey), accepted);

    if (accepted) {
      await prefs.setString(
        _consentAtKey(userKey),
        DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    await prefs.remove(_consentAtKey(userKey));
  }

  Future<DateTime?> acceptedAt({String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consentAtKey(userKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
