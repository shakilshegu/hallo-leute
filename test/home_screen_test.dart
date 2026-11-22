import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_content.dart';
import 'package:hallo_leute/features/home/home_screen.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/onboarding/onboarding_flow.dart';
import 'package:hallo_leute/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Widget app(Widget home) => ProgressScope(
    progress: LearningProgress(),
    child: MaterialApp(theme: AppTheme.dark, home: home),
  );

  Future<void> settle(WidgetTester tester, [int ms = 1200]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  OnboardingData profile() => OnboardingData()
    ..name = 'Anoop'
    ..dailyGoal = DailyGoal.regular;

  testWidgets('greets in German by time of day and shows today\'s goal', (
    tester,
  ) async {
    final morning = DateTime(2026, 11, 16, 8);
    await tester.pumpWidget(
      app(HomeScreen(profile: profile(), now: () => morning)),
    );
    await settle(tester);

    expect(find.text('Guten Morgen, Anoop'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('10 new words'), findsOneWidget);
    expect(find.text('Start lesson'), findsOneWidget);
    expect(find.text('Mo'), findsOneWidget);
  });

  testWidgets('words of the day: 10 cards, flip for meaning, mark learned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 11, 16, 15);
    final progress = LearningProgress(clock: () => day);
    final words = wordsForDay(day, level: progress.studyLevel);
    expect(words, hasLength(10));
    await tester.pumpWidget(
      ProgressScope(
        progress: progress,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomeScreen(profile: profile(), now: () => day),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('WORD 1 OF 10'), findsOneWidget);
    expect(find.text(words.first.example), findsNothing);
    await tester.tap(find.text('WORD 1 OF 10'));
    await settle(tester, 600);
    expect(find.text(words.first.example), findsOneWidget);

    await tester.tap(find.text('I know it').first);
    await settle(tester, 800);
    expect(progress.isLearned(words.first), isTrue);
    expect(find.text('1/10 known'), findsOneWidget);
  });

  test('words of the day change every day and never repeat within a day', () {
    final a = wordsForDay(DateTime(2026, 11, 16));
    final b = wordsForDay(DateTime(2026, 11, 17));
    expect(a.toSet(), hasLength(10));
    expect(a.toSet().intersection(b.toSet()), isEmpty);
    expect(wordsForDay(DateTime(2026, 11, 16, 23)), a); // stable all day
  });

  testWidgets('tapping a day shows study time, words and a friendly note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var now = DateTime(2026, 11, 16, 10); // Monday
    final progress = LearningProgress(clock: () => now);
    for (final w in vocabulary.take(3)) {
      progress.recordAnswer(w, knewIt: true);
    }
    progress.addStudyTime(const Duration(minutes: 25));
    now = DateTime(2026, 11, 18, 9); // Wednesday, nothing yet
    await tester.pumpWidget(
      ProgressScope(
        progress: progress,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomeScreen(profile: profile(), now: () => now),
        ),
      ),
    );
    await settle(tester);
    await tester.drag(find.text('Good morning'), const Offset(0, -500));
    await settle(tester, 300);

    expect(find.textContaining('Nothing yet today'), findsOneWidget);
    await tester.tap(find.text('Mo'));
    await settle(tester, 400);
    expect(find.textContaining('25 min', findRichText: true), findsOneWidget);
    expect(find.textContaining('Well done, Anoop'), findsOneWidget);
    await tester.tap(find.text('Di'));
    await settle(tester, 400);
    expect(find.textContaining('No problem, Anoop'), findsOneWidget);
  });

  test('greeting changes through the day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 9)).$1, 'Guten Morgen');
    expect(greetingFor(DateTime(2026, 1, 1, 14)).$1, 'Guten Tag');
    expect(greetingFor(DateTime(2026, 1, 1, 21)).$1, 'Guten Abend');
  });

  testWidgets('finishing onboarding lands on home', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const OnboardingFlow()));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Anoop');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Brand new'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.text('Continue')); // word pop-ups step
    await settle(tester, 2400);
    await tester.tap(find.text('Start learning'));
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });
}
