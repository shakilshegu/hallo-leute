import 'package:url_launcher/url_launcher.dart';

String _utcStamp(DateTime dt) {
  final u = dt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
}

/// Opens the Google Calendar "create event" template pre-filled with the
/// meeting. Works via the browser / Calendar app on every platform (no
/// calendar-write permission needed).
Future<bool> addMeetingToCalendar({
  required String title,
  required DateTime start,
  required int durationMinutes,
  String? location,
  String? details,
}) async {
  final end = start.add(Duration(minutes: durationMinutes));
  final params = <String, String>{
    'action': 'TEMPLATE',
    'text': title,
    'dates': '${_utcStamp(start)}/${_utcStamp(end)}',
    if (location != null && location.isNotEmpty) 'location': location,
    if (details != null && details.isNotEmpty) 'details': details,
  };
  final uri = Uri.https('calendar.google.com', '/calendar/render', params);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
