import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Signs requests with HMAC-SHA256 for endpoints that require it
/// (e.g. POST /quiz/submit).
///
/// Matches the backend `verify_quiz_signature` algorithm in `security.py`:
///   payload = "{METHOD}\n{PATH}\n{TIMESTAMP}\n{SHA256(body)}"
///   signature = HMAC-SHA256(secret, payload)
class HmacSigner {
  HmacSigner._();

  /// Returns HMAC headers if a shared secret is configured, otherwise empty.
  static Map<String, String> sign({
    required String method,
    required String path,
    required List<int> bodyBytes,
  }) {
    final secret = _secret;
    if (secret == null || secret.isEmpty) return const {};

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final bodyHash = sha256.convert(bodyBytes).toString();
    final payload = '${method.toUpperCase()}\n$path\n$timestamp\n$bodyHash';
    final hmacDigest = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(payload));

    return {
      'X-Growmate-Timestamp': timestamp,
      'X-Growmate-Signature': 'sha256=$hmacDigest',
    };
  }

  static String? get _secret {
    try {
      return dotenv.env['QUIZ_SUBMIT_SECRET']?.trim();
    } catch (_) {
      return null;
    }
  }
}
