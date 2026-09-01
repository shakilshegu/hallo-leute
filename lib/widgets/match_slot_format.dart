import 'package:poppylo/models/matching_models.dart';

/// Formatting helpers for a match's proposed slot (`date` "YYYY-MM-DD" +
/// `startTime` "HH:mm" + `durationMinutes`), shared by the Match Found /
/// Details / Confirmed screens so they read consistently.

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime? _parse(MatchDetails m) =>
    DateTime.tryParse('${m.date}T${m.startTime}:00');

String _time(DateTime dt) {
  var h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  return '$h:$m $ampm';
}

/// "Saturday · 5:00 PM · 45 min"
String formatMatchSlot(MatchDetails m) {
  final dt = _parse(m);
  final day = dt == null ? '' : '${_weekdays[dt.weekday - 1]} · ';
  final time = dt == null ? m.startTime : _time(dt);
  return '$day$time · ${m.durationMinutes} min';
}

/// "Thu, Oct 24 · 5:00 PM"
String formatMatchDateTime(MatchDetails m) {
  final dt = _parse(m);
  if (dt == null) return '${m.date} · ${m.startTime}';
  final wd = _weekdays[dt.weekday - 1].substring(0, 3);
  final mon = _monthsShort[dt.month - 1];
  return '$wd, $mon ${dt.day} · ${_time(dt)}';
}

/// "45 mins"
String formatMatchDuration(MatchDetails m) => '${m.durationMinutes} mins';
