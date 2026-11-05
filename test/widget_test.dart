import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/data/database.dart';
import 'package:poppylo/data/providers.dart';
import 'package:poppylo/main.dart';
import 'package:poppylo/features/learn/widgets/flash_card.dart';
import 'package:poppylo/services/speaker.dart';

void main() {
  late AppDatabase db;
  late _FakeSpeaker speaker;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    speaker = _FakeSpeaker();
    await db.seedWords(
      File('assets/words/starter_words.json').readAsStringSync(),
    );
  });

  tearDown(() => db.close());

  Widget app({String? initialLocation}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      speakerProvider.overrideWithValue(speaker),
    ],
    child: initialLocation == null
        ? const PoppyloApp()
        : PoppyloApp(initialLocation: initialLocation),
  );

  /// Pumps frames for [d] (pumpAndSettle can't be used on the welcome
  /// screen because its bloom animation repeats forever).
  Future<void> wait(WidgetTester t, [int ms = 800]) async {
    for (var i = 0; i < ms ~/ 50; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Welcome screen shows brand, headline and Get Started', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text('poppylo'), findsOneWidget);
    expect(find.text('Deutsch lernen.'), findsOneWidget);
    expect(find.text('Wort für Wort.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Onboarding: name → reason → level → goal → saved profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.tap(find.text('Get Started'));
    await wait(tester);

    // 1 – Name: Continue disabled until a name is typed
    expect(find.text('What should I call you?'), findsOneWidget);
    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Anna');
    await wait(tester, 400);
    expect(find.textContaining('Hallo, Anna!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await wait(tester);

    // 2 – Reason
    expect(find.textContaining('Super, Anna!'), findsOneWidget);
    await tester.tap(find.text('Work'));
    await wait(tester, 300);
    await tester.tap(find.text('Continue'));
    await wait(tester);

    // 3 – Level
    expect(find.text('How’s your German right now?'), findsOneWidget);
    await tester.tap(find.text('Elementary'));
    await wait(tester, 300);
    await tester.tap(find.text('Continue'));
    await wait(tester);

    // 4 – Goal
    expect(find.text('How many words a day?'), findsOneWidget);
    await tester.tap(find.text('10 words a day'));
    await wait(tester, 800);
    expect(find.textContaining('300 words'), findsOneWidget);
    await tester.tap(find.text('Create my plan'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await wait(tester, 1500);

    // Celebration + saved profile
    expect(find.text('Willkommen, Anna! 🎉'), findsOneWidget);
    final profile = await tester.runAsync(db.getProfile);
    expect(profile?.name, 'Anna');
    expect(profile?.reason, LearningReason.work);
    expect(profile?.level, CefrLevel.a2);
    expect(profile?.dailyGoal, 10);

    await tester.tap(find.text("Los geht's! 🚀"));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await wait(tester, 1500);
    expect(find.textContaining(', Anna!'), findsOneWidget);
    expect(find.text('Your first petal is waiting 🌱'), findsOneWidget);
  });

  testWidgets('Skip name and "Not sure" level still finish onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(initialLocation: '/onboarding'));
    await wait(tester);

    await tester.tap(find.text('Skip'));
    await wait(tester);
    expect(find.text('What brings you to German?'), findsOneWidget);
    await tester.tap(find.text('Just for fun'));
    await wait(tester, 300);
    await tester.tap(find.text('Continue'));
    await wait(tester);

    await tester.ensureVisible(find.textContaining('Not sure?'));
    await wait(tester, 300);
    await tester.tap(find.textContaining('Not sure?'));
    await wait(tester, 300);
    await tester.tap(find.text('Continue'));
    await wait(tester);

    await tester.tap(find.text('5 words a day'));
    await wait(tester, 300);
    await tester.tap(find.text('Create my plan'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await wait(tester, 1500);

    expect(find.text('Willkommen! 🎉'), findsOneWidget);
    final profile = await tester.runAsync(db.getProfile);
    expect(profile?.name, isNull);
    expect(profile?.level, CefrLevel.a1);
  });

  testWidgets('Home shows streak, petals, flip card, topics and dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await db.saveProfile(
        ProfilesCompanion.insert(
          name: const Value('Anna'),
          reason: LearningReason.work,
          level: CefrLevel.b1,
          dailyGoal: 10,
        ),
      );
      await db.debugSeedProgress();
    });

    await tester.pumpWidget(app(initialLocation: '/home'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await wait(tester, 200);
    }
    await wait(tester, 1500);

    // Header + streak pot (sample data = 4 days in a row)
    expect(find.textContaining(', Anna!'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Tage'), findsOneWidget);

    // Today's bloom: 4 of 10 words
    expect(find.text('6 more to full bloom!'), findsOneWidget);
    expect(find.text('of 10'), findsOneWidget);

    // German weekday labels
    for (final d in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']) {
      expect(find.text(d), findsOneWidget);
    }

    // Word of the day flips to its meaning
    final card = find.text('Tap to reveal');
    await tester.ensureVisible(card);
    await wait(tester, 300);
    await tester.tap(card);
    await wait(tester, 900);
    expect(find.text('Tap to reveal'), findsNothing);

    // Work learner sees the work topic first, marked "Für dich"
    expect(find.text('Für dich'), findsOneWidget);
    expect(find.text('Arbeit & Büro'), findsOneWidget);

    // Dock: German label of the selected tab, switch to "Lernen"
    expect(find.text('Heute'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Learn'));
    await wait(tester, 800);
    expect(find.text('Lernen'), findsWidgets);
    expect(find.text('6 words left today'), findsOneWidget);
    expect(find.text('Themen'), findsOneWidget);
  });

  Future<void> openSession(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => db.saveProfile(
        ProfilesCompanion.insert(
          name: const Value('Anna'),
          reason: LearningReason.work,
          level: CefrLevel.a1,
          dailyGoal: 5,
        ),
      ),
    );
    await tester.pumpWidget(app(initialLocation: '/session'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await wait(tester, 200);
    }
    await wait(tester, 2500); // let the hint wiggle finish
  }

  testWidgets('Flashcards: guess the article, learn 5 words, celebrate', (
    tester,
  ) async {
    await openSession(tester);

    // Work learner, A1 → first card is "Arbeit" (die)
    expect(find.text('0 of 5 learned'), findsOneWidget);
    expect(find.text('Arbeit'), findsWidgets);
    await tester.tap(find.text('die').last);
    await wait(tester, 400);
    expect(find.textContaining('Richtig!'), findsOneWidget);

    // Card auto-flips to the meaning after a guess
    await wait(tester, 1200);
    expect(find.text('work'), findsOneWidget);

    // Speaker reads the full word with its article
    await tester.tap(
      find
          .descendant(
            of: find.byType(FlashCard).last,
            matching: find.byTooltip('Listen'),
          )
          .first,
    );
    expect(speaker.spoken, contains('die Arbeit'));

    for (var n = 1; n <= 5; n++) {
      await tester.tap(find.bySemanticsLabel('I know it'));
      await wait(tester, 900);
    }
    expect(find.text('Super gemacht! 🎉'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget); // one article guessed, right

    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    final progress = await tester.runAsync(db.allProgress);
    expect(progress, hasLength(5));
  });

  testWidgets('Flashcards: swipe right learns, swipe left shows it again', (
    tester,
  ) async {
    await openSession(tester);
    final card = find.byType(FlashCard).last;

    // Swipe left → "Nochmal": nothing learned, card goes back in the deck
    await tester.drag(card, const Offset(-320, 0));
    await wait(tester, 900);
    expect(find.text('0 of 5 learned'), findsOneWidget);

    // Swipe right → learned
    await tester.drag(find.byType(FlashCard).last, const Offset(320, 0));
    await wait(tester, 900);
    expect(find.text('1 of 5 learned'), findsOneWidget);

    // Regression: a drag made of several moves counts from the first touch
    final g = await tester.startGesture(
      tester.getCenter(find.byType(FlashCard).last),
    );
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.up();
    await wait(tester, 900);
    expect(find.text('2 of 5 learned'), findsOneWidget);

    // A short drag springs back
    await tester.drag(find.byType(FlashCard).last, const Offset(40, 0));
    await wait(tester, 900);
    expect(find.text('2 of 5 learned'), findsOneWidget);
  });
}

class _FakeSpeaker implements Speaker {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}
