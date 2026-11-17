import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/onboarding/onboarding_flow.dart';
import 'package:hallo_leute/theme/app_theme.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  bool continueEnabled(WidgetTester tester) {
    final ink = tester.widget<InkWell>(
      find.ancestor(of: find.text('Continue'), matching: find.byType(InkWell)),
    );
    return ink.onTap != null;
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Continue'));
    await settle(tester);
  }

  testWidgets('walks through every step and returns the answers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    OnboardingData? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: OnboardingFlow(onFinished: (d) => result = d),
      ),
    );
    await settle(tester);

    // 1. Name — Continue stays disabled until a name is typed.
    expect(find.text('1/4'), findsOneWidget);
    expect(continueEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), 'Anoop');
    await tester.pump();
    expect(find.text('Ich heiße Anoop.'), findsOneWidget);
    expect(continueEnabled(tester), isTrue);
    await tapContinue(tester);

    // 2. Goals — multi-select.
    expect(find.text('Why are you learning German?'), findsOneWidget);
    expect(continueEnabled(tester), isFalse);
    await tester.tap(find.text('Work'));
    await tester.tap(find.text('Travel'));
    await tester.pump();
    await tapContinue(tester);

    // 3. Level.
    expect(find.text('How much German do you know?'), findsOneWidget);
    await tester.tap(find.text('A few words'));
    await tester.pump();
    await tapContinue(tester);

    // 4. Daily goal — pre-selected, so Continue is enabled straight away.
    expect(find.text('Set your daily goal'), findsOneWidget);
    expect(continueEnabled(tester), isTrue);
    await tester.tap(find.text('Serious'));
    await tester.pump();
    await tapContinue(tester);

    // 5. Ready.
    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('Alles klar, Anoop!'), findsOneWidget);
    expect(find.text('Work, Travel'), findsOneWidget);
    expect(find.text('A1 · A few words'), findsOneWidget);
    expect(find.text('20 words a day'), findsOneWidget);

    await tester.tap(find.text('Start learning'));
    expect(result?.name, 'Anoop');
    expect(result?.goals, {LearningGoal.work, LearningGoal.travel});
    expect(result?.level, GermanLevel.a1);
    expect(result?.dailyGoal, DailyGoal.serious);
  });

  testWidgets('back goes to the previous step', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const OnboardingFlow()),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Mia');
    await tester.pump();
    await tapContinue(tester);
    expect(find.text('2/4'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('Ich heiße Mia.'), findsOneWidget);
  });
}
