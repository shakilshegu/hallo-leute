import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/local_store.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_content.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/practice/quiz_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  test('every general word has a level; json parses it', () {
    final general = vocabulary.where((w) => !w.topic.isPack);
    expect(general.every((w) => w.level != null), isTrue);
    final parsed = GermanWord.fromJson({
      'word': 'Haus',
      'topic': 'home',
      'level': 'a2',
    });
    expect(parsed.level, CefrLevel.a2);
    expect(GermanWord.fromJson({'word': 'x'}).level, isNull);
  });

  test('study level defaults from the setup level', () {
    OnboardingData withLevel(GermanLevel? l) => OnboardingData()..level = l;
    expect(withLevel(null).effectiveStudyLevel, CefrLevel.a1);
    expect(withLevel(GermanLevel.a0).effectiveStudyLevel, CefrLevel.a1);
    expect(withLevel(GermanLevel.a1).effectiveStudyLevel, CefrLevel.a1);
    expect(withLevel(GermanLevel.a2).effectiveStudyLevel, CefrLevel.a2);
    expect(withLevel(GermanLevel.b1).effectiveStudyLevel, CefrLevel.b1);
    expect(withLevel(GermanLevel.b2).effectiveStudyLevel, CefrLevel.b2);
    final chosen = withLevel(GermanLevel.a0)..studyLevel = CefrLevel.b1;
    expect(chosen.effectiveStudyLevel, CefrLevel.b1);
  });

  test('study level survives saving and loading the profile', () {
    final p = OnboardingData()..studyLevel = CefrLevel.b2;
    final back = OnboardingData.fromJson(p.toJson());
    expect(back.studyLevel, CefrLevel.b2);
  });

  test('new words come only from the study level', () {
    final p = LearningProgress()..useProfile(OnboardingData());
    expect(p.studyLevel, CefrLevel.a1);
    final a1 = p.nextNewWords(10);
    expect(a1, hasLength(10));
    expect(a1.every((w) => w.level == CefrLevel.a1), isTrue);
    for (final w in a1) {
      p.recordAnswer(w, knewIt: true);
    }

    p.useProfile(OnboardingData()..studyLevel = CefrLevel.b1);
    final b1 = p.nextNewWords(10);
    expect(b1.every((w) => w.level == CefrLevel.b1), isTrue);
    // Switching level keeps what was learned at A1.
    expect(p.totalLearned, 10);
    expect(p.learnedAtLevel, 0);
    expect(
      p.levelTotal,
      vocabulary
          .where((w) => w.level == CefrLevel.b1 && !w.topic.isPack)
          .length,
    );
  });

  test('career packs are not filtered by level', () {
    final p = LearningProgress()
      ..useProfile(OnboardingData()..studyLevel = CefrLevel.b2);
    expect(p.topicTotal(Topic.care), Topic.care.wordCount);
    expect(p.nextNewWords(5, topic: Topic.care), hasLength(5));
  });

  test('topic totals count only words at the study level', () {
    final p = LearningProgress()
      ..useProfile(OnboardingData()..studyLevel = CefrLevel.a2);
    final expected = Topic.food.words
        .where((w) => w.level == CefrLevel.a2)
        .length;
    expect(p.topicTotal(Topic.food), expected);
    expect(p.learnedIn(Topic.food), 0);
  });

  test('setStudyLevel saves the profile and switches words', () async {
    final store = MemoryStore();
    final p = LearningProgress(store: store);
    final profile = OnboardingData()..name = 'Anoop';
    await p.setStudyLevel(profile, CefrLevel.a2);

    expect(p.studyLevel, CefrLevel.a2);
    expect((await p.loadProfile())!.studyLevel, CefrLevel.a2);
    expect(p.nextNewWords(3).every((w) => w.level == CefrLevel.a2), isTrue);
  });

  test('words of the day follow the level, also at B2', () {
    final day = DateTime(2026, 11, 22);
    final b2 = wordsForDay(day, level: CefrLevel.b2);
    expect(b2, isNotEmpty);
    expect(b2.every((w) => w.level == CefrLevel.b2), isTrue);
  });

  test('quizzes practise only words at the study level', () {
    final p = LearningProgress()
      ..useProfile(OnboardingData()..studyLevel = CefrLevel.a2);
    final pool = QuizEngine(p).pool(PracticeMode.meaning);
    expect(pool, isNotEmpty);
    expect(pool.every((w) => w.level == CefrLevel.a2), isTrue);
  });
}
