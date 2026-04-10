import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  const GoogleCalendarService._();

  static Uri buildCreateEventUri({
    required String title,
    required DateTime start,
    DateTime? end,
    String? details,
    String? location,
  }) {
    final normalizedStart = start.toUtc();
    final normalizedEnd = (end ?? start.add(const Duration(hours: 1))).toUtc();

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates':
          '${_toCalendarDate(normalizedStart)}/${_toCalendarDate(normalizedEnd)}',
      if (details != null && details.trim().isNotEmpty) 'details': details,
      if (location != null && location.trim().isNotEmpty) 'location': location,
    });
  }

  static Future<bool> openCreateEvent({
    required String title,
    required DateTime start,
    DateTime? end,
    String? details,
    String? location,
  }) {
    final uri = buildCreateEventUri(
      title: title,
      start: start,
      end: end,
      details: details,
      location: location,
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _toCalendarDate(DateTime dateTimeUtc) {
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dateTimeUtc.toUtc());
  }
}
