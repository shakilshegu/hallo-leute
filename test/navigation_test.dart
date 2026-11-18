import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/progress.dart';
import 'package:poppylo/data/vocabulary.dart';
import 'package:poppylo/features/home/home_screen.dart';
import 'package:poppylo/features/onboarding/onboarding_data.dart';
import 'package:poppylo/features/topics/topic_screen.dart';
import 'package:poppylo/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Future<void> settle(WidgetTester tester, [int ms = 1000]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final profile = OnboardingData()
      ..name = 'Anoop'
      ..level = GermanLevel.a1
      ..goals.add(LearningGoal.work);
    await tester.pumpWidget(
      ProgressScope(
        progress: LearningProgress(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomeScreen(
            profile: profile,
            now: () => DateTime(2026, 11, 18, 9),
          ),
        ),
      ),
    );
    await settle(tester, 1600);
  }

  Finder navItem(String label) => find.bySemanticsLabel(label);

  testWidgets('bottom nav switches between Home, Words and Profile', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.text('Guten Morgen, Anoop'), findsOneWidget);

    await tester.tap(navItem('Words'));
    await settle(tester);
    expect(
      find.text('All words  ${vocabulary.length}', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(navItem('Profile'));
    await settle(tester);
    expect(find.text('A1 · A few words'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);

    await tester.tap(navItem('Home'));
    await settle(tester);
    expect(find.text('Guten Morgen, Anoop').hitTestable(), findsOneWidget);
  });

  testWidgets('tapping a topic opens its page with only its words', (
    tester,
  ) async {
    await pumpHome(tester);
    // Scroll the topic row clear of the floating nav bar.
    await tester.drag(find.text('Good morning'), const Offset(0, -700));
    await settle(tester, 400);
    await tester.tap(find.text('Grundlagen'));
    await settle(tester);

    expect(find.byType(TopicScreen), findsOneWidget);
    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('der Bahnhof'), findsNothing);
    expect(find.textContaining('new words'), findsOneWidget);
  });

  testWidgets('career packs open from Home', (tester) async {
    await pumpHome(tester);
    await tester.ensureVisible(find.text('Pflege'));
    await tester.tap(find.text('Pflege'));
    await settle(tester);
    expect(find.text('CAREER PACK'), findsOneWidget);
    expect(find.text('der Patient'), findsOneWidget);
  });

  testWidgets('search filters words and a row expands to its example', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(navItem('Words'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'station');
    await settle(tester, 300);
    expect(find.text('der Bahnhof'), findsOneWidget);
    expect(find.text('die Wohnung'), findsNothing);

    await tester.tap(find.text('der Bahnhof'));
    await settle(tester, 400);
    expect(find.text('Wie komme ich zum Bahnhof?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'xyz');
    await settle(tester, 300);
    expect(find.text('Keine Treffer'), findsOneWidget);
  });

  test('every topic has words', () {
    for (final t in Topic.values) {
      expect(t.wordCount, greaterThan(0), reason: t.english);
    }
  });
}
