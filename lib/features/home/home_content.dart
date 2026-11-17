import '../../data/vocabulary.dart';

/// Word of the day: rotates through common nouns that have an example.
GermanWord wordForDay(DateTime day) {
  var pool = vocabulary
      .where((w) => w.article.isNotEmpty && w.hasExample && w.rank <= 1500)
      .toList();
  if (pool.isEmpty) pool = vocabulary;
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return pool[dayOfYear % pool.length];
}

/// German greeting for the time of day, with its English meaning.
(String, String) greetingFor(DateTime time) {
  final h = time.hour;
  if (h >= 5 && h < 12) return ('Guten Morgen', 'Good morning');
  if (h >= 12 && h < 18) return ('Guten Tag', 'Good afternoon');
  return ('Guten Abend', 'Good evening');
}

/// Monday-first German weekday abbreviations.
const germanWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
