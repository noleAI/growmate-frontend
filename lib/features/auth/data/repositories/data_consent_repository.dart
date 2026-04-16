import 'package:shared_preferences/shared_preferences.dart';

class DataConsentRepository {
  DataConsentRepository._();

  static final DataConsentRepository instance = DataConsentRepository._();

  static const String _consentAcceptedKey = 'data_consent_accepted';
  static const String _consentAcceptedAtKey = 'data_consent_accepted_at';

  // Kept for backward compat with existing code that calls without a userKey.
  @Deprecated('Pass userKey to scope consent per user')
  static const String consentAcceptedKey = _consentAcceptedKey;
  @Deprecated('Pass userKey to scope consent per user')
  static const String consentAcceptedAtKey = _consentAcceptedAtKey;

  String _consentKey(String? userKey) => userKey != null && userKey.isNotEmpty
      ? '${_consentAcceptedKey}_$userKey'
      : _consentAcceptedKey;

  String _consentAtKey(String? userKey) => userKey != null && userKey.isNotEmpty
      ? '${_consentAcceptedAtKey}_$userKey'
      : _consentAcceptedAtKey;

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
