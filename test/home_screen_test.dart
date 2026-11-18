import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/progress.dart';
import 'package:poppylo/data/vocabulary.dart';
import 'package:poppylo/features/home/home_content.dart';
import 'package:poppylo/features/home/home_screen.dart';
import 'package:poppylo/features/onboarding/onboarding_data.dart';
import 'package:poppylo/features/onboarding/onboarding_flow.dart';
import 'package:poppylo/theme/app_theme.dart';

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

  testWidgets('word of the day flips to an example sentence', (tester) async {
    final day = DateTime(2026, 11, 16, 15);
    final word = wordForDay(day);
    await tester.pumpWidget(
      app(HomeScreen(profile: profile(), now: () => day)),
    );
    await settle(tester);

    expect(find.text(word.example), findsNothing);
    await tester.tap(find.text(word.meaning));
    await settle(tester, 600);
    expect(find.text(word.example), findsOneWidget);
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
    await settle(tester, 2400);
    await tester.tap(find.text('Start learning'));
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow), findsNothing);
  });
}
