// Renders every main screen on small/regular/large phones and a tablet,
// at normal and large text, and fails on any layout overflow.
//
// The test font is wider than the real one, so passing here leaves margin.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/app.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_screen.dart';
import 'package:hallo_leute/features/lesson/lesson_screen.dart';
import 'package:hallo_leute/features/onboarding/onboarding_data.dart';
import 'package:hallo_leute/features/onboarding/onboarding_flow.dart';
import 'package:hallo_leute/features/practice/quiz_engine.dart';
import 'package:hallo_leute/features/practice/quiz_screen.dart';
import 'package:hallo_leute/features/topics/topic_screen.dart';
import 'package:hallo_leute/theme/app_theme.dart';

const _sizes = {
  'small 320x568': Size(320, 568),
  'phone 360x640': Size(360, 640),
  'large 412x915': Size(412, 915),
  'tablet 800x1280': Size(800, 1280),
};
const _scales = [1.0, 1.3];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  Future<void> settle(WidgetTester tester, [int ms = 1600]) async {
    await tester.pump();
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  LearningProgress seasoned() {
    final p = LearningProgress();
    for (final w in vocabulary.take(40)) {
      p.recordAnswer(w, knewIt: true);
    }
    return p;
  }

  Widget wrap(Widget home, LearningProgress p, double scale) => ProgressScope(
    progress: p,
    child: MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );

  final profile = OnboardingData()
    ..name = 'Anoop'
    ..level = GermanLevel.a1
    ..goals.addAll({LearningGoal.work, LearningGoal.study});

  for (final size in _sizes.entries) {
    for (final scale in _scales) {
      final label = '${size.key} @${scale}x';

      void setView(WidgetTester tester) {
        tester.view.physicalSize = size.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
      }

      testWidgets('landing + onboarding fit: $label', (tester) async {
        setView(tester);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size.value,
              textScaler: TextScaler.linear(scale),
            ),
            child: const HalloLeuteApp(),
          ),
        );
        await settle(tester, 2600);
        await tester.pumpWidget(
          wrap(const OnboardingFlow(), LearningProgress(), scale),
        );
        await settle(tester);
      });

      testWidgets('all tabs fit: $label', (tester) async {
        setView(tester);
        final p = seasoned();
        await tester.pumpWidget(wrap(HomeScreen(profile: profile), p, scale));
        await settle(tester);
        for (final tab in ['Practice', 'Words', 'Profile', 'Home']) {
          await tester.tap(find.bySemanticsLabel(tab));
          await settle(tester, 800);
          if (tab == 'Words') {
            await tester.tap(find.text('Categories'));
            await settle(tester, 500);
          }
        }
      });

      testWidgets('topic page + career pack fit: $label', (tester) async {
        setView(tester);
        final p = seasoned();
        await tester.pumpWidget(wrap(TopicScreen(topic: Topic.care), p, scale));
        await settle(tester, 900);
        await tester.pumpWidget(
          wrap(const TopicScreen(topic: Topic.basics), p, scale),
        );
        await settle(tester, 900);
      });

      testWidgets('flashcards front, back and summary fit: $label', (
        tester,
      ) async {
        setView(tester);
        final p = LearningProgress();
        final words = vocabulary
            .where((w) => w.plural.isNotEmpty && w.hasExample)
            .take(2)
            .toList();
        await tester.pumpWidget(wrap(LessonScreen(words: words), p, scale));
        await settle(tester, 600);
        await tester.tap(find.byKey(const ValueKey('flashcard')));
        await settle(tester, 600);
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.text('Got it'));
          await settle(tester, 700);
          if (i == 0) {
            await tester.tap(find.byKey(const ValueKey('flashcard')));
            await settle(tester, 600);
          }
        }
        expect(find.text('Super gemacht!'), findsOneWidget);
      });

      for (final mode in [
        PracticeMode.article,
        PracticeMode.meaning,
        PracticeMode.listening,
        PracticeMode.spelling,
      ]) {
        testWidgets('${mode.name} quiz + feedback fit: $label', (tester) async {
          setView(tester);
          final p = seasoned();
          final qs = QuizEngine(p).build(mode).take(1).toList();
          await tester.pumpWidget(
            wrap(QuizScreen(mode: mode, questions: qs), p, scale),
          );
          await settle(tester, 500);
          if (mode == PracticeMode.spelling) {
            await tester.enterText(find.byType(TextField), 'falsch');
            await tester.pump();
            await tester.testTextInput.receiveAction(TextInputAction.done);
          } else {
            // Long words can push the answers below the fold: scroll first,
            // like a learner would.
            final option = find.text(qs.first.options.first).first;
            await tester.ensureVisible(option);
            await tester.pump();
            await tester.tap(option);
          }
          await settle(tester, 500);
          await tester.ensureVisible(find.text('See results'));
          await tester.pump();
          await tester.tap(find.text('See results'));
          await settle(tester, 1200);
        });
      }
    }
  }
}
