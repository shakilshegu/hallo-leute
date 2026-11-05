import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/database.dart';
import 'package:poppylo/data/home_data.dart';

Word _word(
  String id, {
  Article? article = Article.die,
  String topic = 'essen',
}) => Word(
  id: id,
  german: id,
  article: article,
  plural: null,
  english: id,
  example: '',
  exampleEn: '',
  topic: topic,
  level: CefrLevel.a1,
  emoji: '🌸',
);

WordProgressData _learned(String id, DateTime at, {DateTime? review}) =>
    WordProgressData(
      wordId: id,
      learnedAt: at,
      nextReview: review ?? at.add(const Duration(days: 1)),
      reviewStreak: 0,
    );

final _profile = Profile(
  id: 1,
  name: 'Anna',
  reason: LearningReason.work,
  level: CefrLevel.a1,
  dailyGoal: 3,
  createdAt: DateTime(2026),
);

void main() {
  // Thursday 5 Nov 2026, 14:00
  final now = DateTime(2026, 11, 5, 14);
  final words = [
    _word('a', article: Article.der),
    _word('b', article: Article.die),
    _word('c', article: Article.das),
    _word('d', article: null),
    _word('e', topic: 'arbeit'),
    _word('f', topic: 'arbeit'),
  ];

  HomeData compute(List<WordProgressData> progress) => HomeData.compute(
    profile: _profile,
    words: words,
    progress: progress,
    now: now,
  );

  test('fresh learner: no petals, no streak, empty week up to today', () {
    final h = compute([]);
    expect(h.learnedToday, 0);
    expect(h.streak, 0);
    expect(h.goalReached, isFalse);
    expect(h.week.map((d) => d.state), [
      BloomState.empty, // Mo
      BloomState.empty, // Di
      BloomState.empty, // Mi
      BloomState.empty, // Do (today)
      BloomState.future,
      BloomState.future,
      BloomState.future,
    ]);
    expect(h.week[3].isToday, isTrue);
  });

  test('today petals keep learning order and article colours', () {
    final h = compute([
      _learned('c', now.subtract(const Duration(hours: 1))),
      _learned('a', now.subtract(const Duration(hours: 3))),
      _learned('d', now.subtract(const Duration(hours: 2))),
    ]);
    expect(h.todayArticles, [Article.der, null, Article.das]);
    expect(h.goalReached, isTrue);
    expect(h.week[3].state, BloomState.bloom);
  });

  test('streak counts consecutive days and survives an empty today', () {
    final h = compute([
      _learned('a', DateTime(2026, 11, 4, 9)), // yesterday
      _learned('b', DateTime(2026, 11, 3, 9)),
      _learned('c', DateTime(2026, 11, 1, 9)), // gap on the 2nd
    ]);
    expect(h.streak, 2);
    expect(h.week[1].state, BloomState.bud); // Tue: 1 of 3
  });

  test('streak includes today once the learner practised', () {
    final h = compute([
      _learned('a', DateTime(2026, 11, 5, 8)),
      _learned('b', DateTime(2026, 11, 4, 8)),
    ]);
    expect(h.streak, 2);
  });

  test('review due counts words whose review time has passed', () {
    final h = compute([
      _learned('a', DateTime(2026, 11, 3), review: DateTime(2026, 11, 4)),
      _learned('b', DateTime(2026, 11, 5, 9)), // due tomorrow
    ]);
    expect(h.reviewDue, 1);
  });

  test('topics matching the learning reason come first', () {
    final h = compute([_learned('e', DateTime(2026, 11, 5, 9))]);
    expect(h.topics.first.topic.id, 'arbeit');
    expect(h.topics.first.recommended, isTrue);
    expect(h.topics.first.learned, 1);
    expect(h.topics.first.total, 2);
  });

  test('word of the day is a noun and stable within a day', () {
    final morning = HomeData.compute(
      profile: _profile,
      words: words,
      progress: const [],
      now: DateTime(2026, 11, 5, 7),
    );
    final evening = HomeData.compute(
      profile: _profile,
      words: words,
      progress: const [],
      now: DateTime(2026, 11, 5, 23),
    );
    expect(morning.wordOfDay?.article, isNotNull);
    expect(morning.wordOfDay?.id, evening.wordOfDay?.id);
  });
}
