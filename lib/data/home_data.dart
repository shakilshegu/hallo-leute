import 'database.dart';
import 'topics.dart';

/// How a single day looks in the weekly garden.
enum BloomState { future, empty, bud, bloom }

class DayBloom {
  const DayBloom({
    required this.date,
    required this.learned,
    required this.state,
    required this.isToday,
  });

  final DateTime date;
  final int learned;
  final BloomState state;
  final bool isToday;
}

class TopicProgress {
  const TopicProgress({
    required this.topic,
    required this.total,
    required this.learned,
    required this.recommended,
  });

  final Topic topic;
  final int total;
  final int learned;
  final bool recommended;

  double get fraction => total == 0 ? 0 : learned / total;
}

/// Everything the Home dashboard shows, computed from the database.
class HomeData {
  const HomeData({
    required this.profile,
    required this.dailyGoal,
    required this.todayArticles,
    required this.streak,
    required this.week,
    required this.reviewDue,
    required this.totalLearned,
    required this.topics,
    required this.wordOfDay,
  });

  final Profile? profile;
  final int dailyGoal;

  /// Article of each word learned today, in learning order
  /// (`null` for words without an article).
  final List<Article?> todayArticles;
  final int streak;
  final List<DayBloom> week;
  final int reviewDue;
  final int totalLearned;
  final List<TopicProgress> topics;
  final Word? wordOfDay;

  int get learnedToday => todayArticles.length;
  bool get goalReached => learnedToday >= dailyGoal;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Pure computation – easy to unit test.
  factory HomeData.compute({
    required Profile? profile,
    required List<Word> words,
    required List<WordProgressData> progress,
    required DateTime now,
  }) {
    final goal = profile?.dailyGoal ?? 10;
    final today = _day(now);
    final byId = {for (final w in words) w.id: w};

    // Words learned per calendar day
    final perDay = <DateTime, int>{};
    for (final p in progress) {
      final d = _day(p.learnedAt.toLocal());
      perDay[d] = (perDay[d] ?? 0) + 1;
    }

    // Today's petals in learning order
    final todays =
        progress.where((p) => _day(p.learnedAt.toLocal()) == today).toList()
          ..sort((a, b) => a.learnedAt.compareTo(b.learnedAt));
    final todayArticles = [for (final p in todays) byId[p.wordId]?.article];

    // Streak: consecutive days with at least one word. Today still counts
    // as "alive" if the learner hasn't practised yet.
    var cursor = perDay.containsKey(today)
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var streak = 0;
    while (perDay.containsKey(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    // Monday-first week
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final week = [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(monday.year, monday.month, monday.day + i);
          final n = perDay[d] ?? 0;
          return DayBloom(
            date: d,
            learned: n,
            isToday: d == today,
            state: d.isAfter(today)
                ? BloomState.future
                : n >= goal
                ? BloomState.bloom
                : n > 0
                ? BloomState.bud
                : BloomState.empty,
          );
        }(),
    ];

    // Words up to the learner's level (fallback: everything)
    final level = profile?.level ?? CefrLevel.a1;
    var pool = words.where((w) => w.level.index <= level.index).toList();
    if (pool.isEmpty) pool = words;

    final learnedIds = {for (final p in progress) p.wordId};
    final ordered = Topic.forReason(profile?.reason);
    final topics = [
      for (final (i, t) in ordered.indexed)
        TopicProgress(
          topic: t,
          total: pool.where((w) => w.topic == t.id).length,
          learned: pool
              .where((w) => w.topic == t.id && learnedIds.contains(w.id))
              .length,
          recommended:
              i == 0 && profile != null && t.reasons.contains(profile.reason),
        ),
    ].where((t) => t.total > 0).toList();

    // Word of the day: same noun all day, changes at midnight.
    final nouns = pool.where((w) => w.article != null).toList();
    final dayNumber = today.difference(DateTime(2024)).inDays;
    final wordOfDay = nouns.isEmpty
        ? null
        : nouns[(dayNumber * 37) % nouns.length];

    return HomeData(
      profile: profile,
      dailyGoal: goal,
      todayArticles: todayArticles,
      streak: streak,
      week: week,
      reviewDue: progress.where((p) => !p.nextReview.isAfter(now)).length,
      totalLearned: progress.length,
      topics: topics,
      wordOfDay: wordOfDay,
    );
  }
}

extension HomeDataQueries on AppDatabase {
  /// Live Home data – re-computed whenever progress or profile changes.
  Stream<HomeData> watchHomeData() async* {
    final words = await allWords();
    await for (final _ in watchLearningChanges()) {
      yield HomeData.compute(
        profile: await getProfile(),
        words: words,
        progress: await allProgress(),
        now: DateTime.now(),
      );
    }
  }
}
