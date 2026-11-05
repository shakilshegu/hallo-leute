import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/database.dart';
import 'package:poppylo/features/learn/learn_session.dart';

Word _w(String id, String topic, CefrLevel level) => Word(
  id: id,
  german: id,
  article: Article.der,
  plural: null,
  english: id,
  example: '',
  exampleEn: '',
  topic: topic,
  level: level,
  emoji: '🌸',
);

Profile _profile(LearningReason reason, CefrLevel level) => Profile(
  id: 1,
  name: null,
  reason: reason,
  level: level,
  dailyGoal: 10,
  createdAt: DateTime(2026),
);

void main() {
  final words = [
    _w('essen-a', 'essen', CefrLevel.a1),
    _w('arbeit-b1', 'arbeit', CefrLevel.b1),
    _w('arbeit-a1', 'arbeit', CefrLevel.a1),
    _w('reisen-a1', 'reisen', CefrLevel.a1),
  ];

  group('pickSessionWords', () {
    test('skips learned words and words above the level', () {
      final picked = pickSessionWords(
        words: words,
        learnedIds: {'essen-a'},
        profile: _profile(LearningReason.fun, CefrLevel.a2),
        count: 10,
      );
      expect(picked.map((w) => w.id), isNot(contains('essen-a')));
      expect(picked.map((w) => w.id), isNot(contains('arbeit-b1')));
    });

    test('topics matching the reason come first, easier words first', () {
      final picked = pickSessionWords(
        words: words,
        learnedIds: {},
        profile: _profile(LearningReason.work, CefrLevel.c1),
        count: 2,
      );
      expect(picked.map((w) => w.id), ['arbeit-a1', 'arbeit-b1']);
    });

    test('a topic narrows the session', () {
      final picked = pickSessionWords(
        words: words,
        learnedIds: {},
        profile: _profile(LearningReason.work, CefrLevel.a1),
        count: 10,
        topic: 'reisen',
      );
      expect(picked.map((w) => w.id), ['reisen-a1']);
    });
  });

  group('SessionState', () {
    SessionState deck(int n) => SessionState(
      queue: [for (var i = 0; i < n; i++) DeckCard(words[i], i)],
      total: n,
      nextSerial: n,
    );

    test('"Nochmal" moves the card three places back with a new key', () {
      final s = deck(4).requeueCurrent();
      expect(s.queue.map((c) => c.word.id).toList(), [
        'arbeit-b1',
        'arbeit-a1',
        'reisen-a1',
        'essen-a',
      ]);
      expect(s.queue.last.key, isNot(deck(4).queue.first.key));
      expect(s.againCount, 1);
      expect(s.done, isFalse);
    });

    test('"Nochmal" on the last card keeps it in the deck', () {
      final s = deck(1).requeueCurrent();
      expect(s.queue.length, 1);
      expect(s.done, isFalse);
    });

    test('"Kann ich" learns cards until the session is done', () {
      var s = deck(2);
      s = s.learnCurrent().learnCurrent();
      expect(s.learned.length, 2);
      expect(s.done, isTrue);
    });
  });
}
