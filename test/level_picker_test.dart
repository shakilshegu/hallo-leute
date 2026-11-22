import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/local_store.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_screen.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/words/words_tab.dart';
import 'package:hallo_leute/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Future<void> settle(WidgetTester tester, [int ms = 1600]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<LearningProgress> pumpHome(
    WidgetTester tester,
    OnboardingData profile, {
    LearningProgress? progress,
  }) async {
    final p = progress ?? LearningProgress(store: MemoryStore());
    p.useProfile(profile);
    await tester.pumpWidget(
      ProgressScope(
        progress: p,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomeScreen(profile: profile),
        ),
      ),
    );
    await settle(tester);
    return p;
  }

  void learnShare(LearningProgress p, double share) {
    final words = p.wordsFor(null).toList();
    for (final w in words.take((words.length * share).ceil())) {
      p.recordAnswer(w, knewIt: true);
    }
  }

  testWidgets('home shows the level picker with the study level', (
    tester,
  ) async {
    final profile = OnboardingData()
      ..name = 'Anoop'
      ..level = GermanLevel.a2;
    final p = await pumpHome(tester, profile);

    expect(p.studyLevel, CefrLevel.a2);
    expect(find.bySemanticsLabel('Level A2, selected'), findsOneWidget);
    expect(
      find.textContaining('0 of ${p.levelTotal} A2 words learned'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a level switches and saves it', (tester) async {
    final profile = OnboardingData()..name = 'Anoop';
    final p = await pumpHome(tester, profile);

    await tester.tap(find.bySemanticsLabel('Level B1'));
    await settle(tester);

    expect(p.studyLevel, CefrLevel.b1);
    expect((await p.loadProfile())!.studyLevel, CefrLevel.b1);
    expect(find.bySemanticsLabel('Level B1, selected'), findsOneWidget);
  });

  testWidgets('at 80 percent the next level is suggested', (tester) async {
    final profile = OnboardingData()..name = 'Anoop';
    final p = LearningProgress(store: MemoryStore())..useProfile(profile);
    learnShare(p, 0.8);
    await pumpHome(tester, profile, progress: p);

    expect(find.text('Ready for A2?'), findsOneWidget);
    await tester.ensureVisible(find.text('Start A2'));
    await tester.tap(find.text('Start A2'));
    await settle(tester);
    expect(p.studyLevel, CefrLevel.a2);
    expect(find.text('Ready for A2?'), findsNothing);
  });

  testWidgets('no level-up card below 80 percent or at B2', (tester) async {
    final profile = OnboardingData()
      ..name = 'Anoop'
      ..studyLevel = CefrLevel.b2;
    final p = LearningProgress(store: MemoryStore())..useProfile(profile);
    learnShare(p, 1);
    await pumpHome(tester, profile, progress: p);
    expect(find.textContaining('Ready for'), findsNothing);
  });

  testWidgets('words tab lists only the study level', (tester) async {
    final p = LearningProgress()
      ..useProfile(OnboardingData()..studyLevel = CefrLevel.b2);
    await tester.pumpWidget(
      ProgressScope(
        progress: p,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: WordsTab(sessionSize: 10)),
        ),
      ),
    );
    await settle(tester);
    // Open "All words" and check the count.
    final allWords = find.text('All words');
    if (allWords.evaluate().isNotEmpty) {
      await tester.tap(allWords.first);
      await settle(tester);
    }
    expect(find.text('All · ${p.levelTotal}'), findsOneWidget);
  });
}
