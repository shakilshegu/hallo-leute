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

/// Words of the day: ten useful words with examples, a new set every day.
/// The same ten stay all day (also used for the word pop-ups).
List<GermanWord> wordsForDay(DateTime day, {int count = 10}) {
  final pool = vocabulary
      .where((w) => w.hasExample && !w.topic.isPack)
      .where((w) => w.rank == 0 || w.rank <= 2000)
      .toList();
  if (pool.isEmpty) return const [];
  final dayIndex = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2026)).inDays;
  // A stride that shares no factor with the pool size visits every word
  // before repeating, and mixes topics within a day.
  var stride = 7;
  while (stride.gcd(pool.length) != 1) {
    stride++;
  }
  final n = pool.length;
  return [
    for (var i = 0; i < count; i++)
      pool[(((dayIndex * count + i) * stride) % n + n) % n],
  ];
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
