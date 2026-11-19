import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/app.dart';
import 'package:hallo_leute/data/local_store.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_screen.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  late DateTime now;
  DateTime clock() => now;
  DateTime day(int d) => DateTime(2026, 11, d, 10);

  setUp(() => now = day(16));

  group('spaced repetition', () {
    test('Got it climbs the review ladder: 1 → 3 → 7 → 14 → 30 days', () {
      final p = LearningProgress(clock: clock);
      final w = vocabulary[100];

      p.recordAnswer(w, knewIt: true);
      final wp = p.progressOf(w)!;
      expect(wp.learnedOn, DateTime(2026, 11, 16));
      expect(wp.box, 1);
      expect(wp.due, DateTime(2026, 11, 17));
      expect(p.statusOf(w), WordStatus.learning);

      final expectedGaps = [3, 7, 14, 30];
      for (final gap in expectedGaps) {
        now = wp.due.add(const Duration(hours: 10));
        expect(p.dueForReview(), contains(w));
        p.recordAnswer(w, knewIt: true);
        expect(
          wp.due,
          DateTime(now.year, now.month, now.day + gap),
          reason: 'gap $gap',
        );
      }
      expect(p.statusOf(w), WordStatus.mastered);
      expect(p.totalMastered, 1);
      expect(wp.timesSeen, 5);
      expect(wp.timesCorrect, 5);
    });

    test('Again on a learned word sends it back to the start', () {
      final p = LearningProgress(clock: clock);
      final w = vocabulary[200];
      p.recordAnswer(w, knewIt: true); // box 1
      now = day(17);
      p.recordAnswer(w, knewIt: true); // box 2
      now = day(20);
      p.recordAnswer(w, knewIt: false);

      final wp = p.progressOf(w)!;
      expect(wp.box, 1);
      expect(wp.due, DateTime(2026, 11, 20)); // due again today
      expect(wp.timesAgain, 1);
      expect(p.isLearned(w), isTrue); // still counts as learned
    });

    test('Again on a new word marks it seen, not learned', () {
      final p = LearningProgress(clock: clock);
      final w = vocabulary[300];
      p.recordAnswer(w, knewIt: false);

      expect(p.statusOf(w), WordStatus.seen);
      expect(p.isLearned(w), isFalse);
      expect(p.totalLearned, 0);
      expect(p.nextNewWords(1).single, isNot(w)); // earlier words first
      expect(p.dueForReview(), isEmpty);
    });

    test('my words are listed most recent first', () {
      final p = LearningProgress(clock: clock);
      p.recordAnswer(vocabulary[10], knewIt: true);
      now = day(17);
      p.recordAnswer(vocabulary[5], knewIt: true);
      expect(p.learnedWords, [vocabulary[5], vocabulary[10]]);
    });

    test('reviews and misses also keep the streak alive', () {
      final p = LearningProgress(clock: clock);
      p.recordAnswer(vocabulary[1], knewIt: true);
      now = day(17);
      p.recordAnswer(vocabulary[1], knewIt: false);
      expect(p.streak, 2);
      expect(p.learnedToday, 0);
    });
  });

  group('saved on the device', () {
    test('progress survives a restart', () async {
      final store = MemoryStore();
      final p = await LearningProgress.load(store, clock: clock);
      p.recordAnswer(vocabulary[0], knewIt: true);
      p.recordAnswer(vocabulary[1], knewIt: false);
      await pumpEventQueue();

      final reloaded = await LearningProgress.load(store, clock: clock);
      expect(reloaded.isLearned(vocabulary[0]), isTrue);
      expect(reloaded.statusOf(vocabulary[1]), WordStatus.seen);
      expect(reloaded.progressOf(vocabulary[1])!.timesAgain, 1);
      expect(reloaded.streak, 1);
      expect(reloaded.learnedToday, 1);
    });

    test('profile survives a restart', () async {
      final store = MemoryStore();
      final p = LearningProgress(store: store);
      await p.saveProfile(
        OnboardingData()
          ..name = 'Anoop'
          ..level = GermanLevel.a2
          ..dailyGoal = DailyGoal.serious
          ..goals.addAll({LearningGoal.work, LearningGoal.study}),
      );
      final loaded = (await p.loadProfile())!;
      expect(loaded.name, 'Anoop');
      expect(loaded.level, GermanLevel.a2);
      expect(loaded.dailyGoal, DailyGoal.serious);
      expect(loaded.goals, {LearningGoal.work, LearningGoal.study});
    });

    test('corrupt data starts fresh instead of crashing', () async {
      final store = MemoryStore({LearningProgress.storageKey: '{not json'});
      final p = await LearningProgress.load(store);
      expect(p.totalLearned, 0);
    });

    test('stored format is compact and versioned', () async {
      final store = MemoryStore();
      final p = LearningProgress(clock: clock, store: store);
      p.recordAnswer(vocabulary[0], knewIt: true);
      await pumpEventQueue();
      final json =
          jsonDecode(store.values[LearningProgress.storageKey]!) as Map;
      expect(json['version'], 1);
      expect(
        (json['words'] as Map).keys.single,
        LearningProgress.keyOf(vocabulary[0]),
      );
    });
  });

  group('screens', () {
    Future<void> settle(WidgetTester tester, [int ms = 1200]) async {
      await tester.pump();
      for (var t = 0; t < ms; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('a returning learner opens straight on Home', (tester) async {
      final profile = OnboardingData()..name = 'Mia';
      await tester.pumpWidget(HalloLeuteApp(profile: profile));
      await settle(tester, 1600);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Home offers a review when words are due', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final p = LearningProgress(clock: clock);
      p.recordAnswer(vocabulary[0], knewIt: true);
      p.recordAnswer(vocabulary[1], knewIt: true);
      now = day(18); // both were due on the 17th

      await tester.pumpWidget(
        ProgressScope(
          progress: p,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: HomeScreen(profile: OnboardingData(), now: clock),
          ),
        ),
      );
      await settle(tester, 1600);
      expect(find.text('2 words are ready to refresh'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await settle(tester, 700);
      expect(find.text('0/2'), findsOneWidget);
    });

    testWidgets('My words lists learned words with their status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final p = LearningProgress(clock: clock);
      final learned = vocabulary.firstWhere((w) => w.word == 'Bahnhof');
      p.recordAnswer(learned, knewIt: true);

      await tester.pumpWidget(
        ProgressScope(
          progress: p,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: HomeScreen(profile: OnboardingData(), now: clock),
          ),
        ),
      );
      await settle(tester, 1600);
      await tester.tap(find.bySemanticsLabel('Words'));
      await settle(tester, 600);
      await tester.tap(find.text('My words  1', findRichText: true));
      await settle(tester, 400);

      expect(find.text('der Bahnhof'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('der Bahnhof'), findsOneWidget);

      await tester.tap(find.text('der Bahnhof'));
      await settle(tester, 400);
      expect(
        find.text('Learned 16 Nov · seen 1× · next review tomorrow'),
        findsOneWidget,
      );
    });
  });
}
