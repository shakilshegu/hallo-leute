import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/progress.dart';
import 'package:poppylo/data/vocabulary.dart';
import 'package:poppylo/features/home/home_screen.dart';
import 'package:poppylo/features/lesson/lesson_screen.dart';
import 'package:poppylo/features/onboarding/onboarding_data.dart';
import 'package:poppylo/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Future<void> settle(WidgetTester tester, [int ms = 700]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('flip, answer, repeat missed cards, then summary', (
    tester,
  ) async {
    tallScreen(tester);
    final progress = LearningProgress();
    final words = vocabulary.take(2).toList();
    await tester.pumpWidget(
      ProgressScope(
        progress: progress,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: LessonScreen(words: words),
        ),
      ),
    );
    await settle(tester);

    // Front shows the German word; answers appear only after flipping.
    expect(find.text(words[0].word), findsWidgets);
    expect(find.text('Got it'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('flashcard')));
    await settle(tester);
    expect(find.text(words[0].meaning), findsOneWidget);

    // Miss the first word: it comes back after the next card.
    await tester.tap(find.text('Again'));
    await settle(tester);
    expect(progress.totalLearned, 0);

    // Second word: got it.
    await tester.tap(find.byKey(const ValueKey('flashcard')));
    await settle(tester);
    expect(find.text(words[1].meaning), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(progress.totalLearned, 1);

    // The missed word again — swipe right this time.
    expect(find.text(words[0].word), findsWidgets);
    await tester.drag(
      find.byKey(const ValueKey('flashcard')),
      const Offset(300, 0),
    );
    await settle(tester);

    expect(find.text('Super gemacht!'), findsOneWidget);
    expect(progress.totalLearned, 2);
    expect(progress.isLearned(words[0]), isTrue);
  });

  testWidgets('Start lesson on Home opens flashcards and updates progress', (
    tester,
  ) async {
    tallScreen(tester);
    final progress = LearningProgress();
    final profile = OnboardingData()
      ..name = 'Anoop'
      ..dailyGoal = DailyGoal.casual;
    await tester.pumpWidget(
      ProgressScope(
        progress: progress,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomeScreen(profile: profile),
        ),
      ),
    );
    await settle(tester, 1600);
    expect(find.text('0-day streak'), findsOneWidget);

    await tester.tap(find.text('Start lesson'));
    await settle(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.drag(
        find.byKey(const ValueKey('flashcard')),
        const Offset(300, 0),
      );
      await settle(tester);
    }
    expect(find.text('Super gemacht!'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await settle(tester, 1000);

    expect(progress.learnedToday, 5);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.text('Goal reached!'), findsOneWidget);
  });

  group('LearningProgress', () {
    test('streak counts consecutive days and survives until tonight', () {
      var now = DateTime(2026, 11, 16, 10);
      final p = LearningProgress(clock: () => now);
      final w = vocabulary;
      p.markLearned(w[0]);
      now = DateTime(2026, 11, 17, 9);
      p.markLearned(w[1]);
      expect(p.streak, 2);

      now = DateTime(2026, 11, 18, 8); // nothing yet today
      expect(p.streak, 2);
      now = DateTime(2026, 11, 19, 8); // missed a day
      expect(p.streak, 0);
    });

    test('week strip and next words', () {
      final now = DateTime(2026, 11, 18, 12); // Wednesday
      final p = LearningProgress(clock: () => now);
      p.markLearned(vocabulary.first);
      expect(p.practisedThisWeek, {3});
      expect(p.nextNewWords(3).first, isNot(vocabulary.first));
      expect(p.nextNewWords(3), hasLength(3));
    });
  });
}
