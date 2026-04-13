import 'package:shared_preferences/shared_preferences.dart';

class DataConsentRepository {
  DataConsentRepository._();

  static final DataConsentRepository instance = DataConsentRepository._();

  static const String consentAcceptedKey = 'data_consent_accepted';
  static const String consentAcceptedAtKey = 'data_consent_accepted_at';

  Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(consentAcceptedKey) == true;
  }

  Future<void> saveConsent({required bool accepted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(consentAcceptedKey, accepted);

    if (accepted) {
      await prefs.setString(
        consentAcceptedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    await prefs.remove(consentAcceptedAtKey);
  }

  Future<DateTime?> acceptedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(consentAcceptedAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
