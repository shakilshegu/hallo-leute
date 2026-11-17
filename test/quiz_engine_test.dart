import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/practice/quiz_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  QuizEngine engine([LearningProgress? p]) =>
      QuizEngine(p ?? LearningProgress(), random: math.Random(7));

  test('beginners still get a full session of new words', () {
    final qs = engine().build(PracticeMode.meaning);
    expect(qs, hasLength(QuizEngine.sessionLength));
  });

  test('learned words are practised first, weakest first', () {
    final p = LearningProgress();
    final weak = vocabulary[30];
    p.recordAnswer(weak, knewIt: true);
    p.recordAnswer(weak, knewIt: false);
    p.recordAnswer(weak, knewIt: false);
    final pool = engine(p).pool(PracticeMode.meaning);
    expect(pool, contains(weak));
  });

  test('article questions use nouns with der/die/das', () {
    for (final q in engine().build(PracticeMode.article)) {
      expect(['der', 'die', 'das'], contains(q.answer));
      expect(q.options, ['der', 'die', 'das']);
    }
  });

  test('multiple choice has 4 distinct options including the answer', () {
    for (final mode in [PracticeMode.meaning, PracticeMode.listening]) {
      for (final q in engine().build(mode)) {
        expect(q.options, hasLength(4), reason: q.word.word);
        expect(q.options.toSet(), hasLength(4), reason: q.word.word);
        expect(q.options, contains(q.answer));
      }
    }
  });

  test('topic sessions stay inside the topic (career packs too)', () {
    final pack = Topic.care.words.toSet();
    for (final q in engine().build(PracticeMode.meaning, topic: Topic.care)) {
      expect(pack, contains(q.word));
    }
  });

  test('spelling is forgiving about case and umlaut spellings', () {
    expect(QuizEngine.spellingMatches('bahnhof', 'Bahnhof'), isTrue);
    expect(QuizEngine.spellingMatches(' Bahnhof ', 'Bahnhof'), isTrue);
    expect(QuizEngine.spellingMatches('Fruehstueck', 'Frühstück'), isTrue);
    expect(QuizEngine.spellingMatches('Strasse', 'Straße'), isTrue);
    expect(QuizEngine.spellingMatches('Bahnhoff', 'Bahnhof'), isFalse);
  });

  test('career packs load and stay out of the general daily lesson', () {
    expect(Topic.care.wordCount, greaterThanOrEqualTo(30));
    expect(Topic.office.wordCount, greaterThanOrEqualTo(30));
    final p = LearningProgress();
    final general = p.nextNewWords(3000);
    expect(general.where((w) => w.topic.isPack), isEmpty);
    // Shared words (e.g. "der Fehler") are in both a general topic and a pack.
    final fehler = Topic.office.words.firstWhere((w) => w.word == 'Fehler');
    expect(fehler.topic.isPack, isFalse);
  });

  test('quiz answers count but do not move words up the review ladder', () {
    final p = LearningProgress();
    final w = vocabulary[50];
    p.recordAnswer(w, knewIt: true); // learned, box 1
    final dueBefore = p.progressOf(w)!.due;
    p.recordPractice(w, correct: true, mode: PracticeMode.meaning);
    expect(p.progressOf(w)!.box, 1);
    expect(p.progressOf(w)!.due, dueBefore);
    p.recordPractice(w, correct: false, mode: PracticeMode.spelling);
    expect(p.progressOf(w)!.due, p.today); // wrong → review today
    expect(p.progressOf(w)!.timesSeen, 3);
  });

  test('pack words show the job meaning but share progress', () {
    final station = Topic.care.words.firstWhere((w) => w.word == 'Station');
    expect(station.meaning, contains('ward'));
    final p = LearningProgress();
    p.recordAnswer(station, knewIt: true);
    final general = vocabulary.firstWhere(
      (w) => w.word == 'Station' && w.pos == 'noun',
    );
    expect(p.isLearned(general), isTrue);
  });
}
