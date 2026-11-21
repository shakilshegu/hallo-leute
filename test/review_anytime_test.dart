import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_screen.dart';
import 'package:hallo_leute/features/home/widgets/home_cards.dart';
import 'package:hallo_leute/features/lesson/lesson_screen.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/practice/practice_tab.dart';
import 'package:hallo_leute/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Widget app(LearningProgress progress, Widget home) => ProgressScope(
    progress: progress,
    child: MaterialApp(theme: AppTheme.dark, home: home),
  );

  Future<void> settle(WidgetTester tester, [int ms = 1600]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// [count] words learned today (so none are due until tomorrow).
  LearningProgress learned(int count) {
    final p = LearningProgress();
    for (final w in vocabulary.take(count)) {
      p.recordAnswer(w, knewIt: true);
    }
    return p;
  }

  OnboardingData profile() => OnboardingData()..name = 'Anoop';

  testWidgets('card copy counts the learned words', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ReviewAnytimeCard(learned: 13, onStart: () {}),
              ReviewAnytimeCard(learned: 1, onStart: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Review my words'), findsNWidgets(2));
    expect(
      find.text('Flip through the 13 words you learned. Weakest first.'),
      findsOneWidget,
    );
    expect(
      find.text('Flip through the 1 word you learned. Weakest first.'),
      findsOneWidget,
    );
  });

  testWidgets('practice card opens flashcards of the learned words', (
    tester,
  ) async {
    final p = learned(3);
    await tester.pumpWidget(app(p, const PracticeTab(dailyGoal: 10)));
    await settle(tester);

    await tester.ensureVisible(find.text('Review my words'));
    await tester.tap(find.text('Review my words'));
    await settle(tester);

    final lesson = tester.widget<LessonScreen>(find.byType(LessonScreen));
    expect(lesson.review, isTrue);
    expect(lesson.words.toSet(), vocabulary.take(3).toSet());
  });

  testWidgets('practice hides the card without learned words', (tester) async {
    await tester.pumpWidget(
      app(LearningProgress(), const PracticeTab(dailyGoal: 10)),
    );
    await settle(tester);
    expect(find.text('Review my words'), findsNothing);
  });

  testWidgets('home shows the card when nothing is due', (tester) async {
    await tester.pumpWidget(app(learned(2), HomeScreen(profile: profile())));
    await settle(tester);
    expect(find.text('Review my words'), findsOneWidget);
  });

  testWidgets('home shows the due Review card instead when words are due', (
    tester,
  ) async {
    final p = learned(2)..recordAnswer(vocabulary.first, knewIt: false);
    await tester.pumpWidget(app(p, HomeScreen(profile: profile())));
    await settle(tester);
    expect(find.text('Review my words'), findsNothing);
    expect(find.text('1 word is ready to refresh'), findsOneWidget);
  });

  testWidgets('home hides the card with no learned words', (tester) async {
    await tester.pumpWidget(
      app(LearningProgress(), HomeScreen(profile: profile())),
    );
    await settle(tester);
    expect(find.text('Review my words'), findsNothing);
  });
}
