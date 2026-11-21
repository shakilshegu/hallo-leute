import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/remote/feedback_remote.dart';
import 'package:hallo_leute/features/profile/feedback_card.dart';

class _FakeRemote implements FeedbackRemote {
  final sent = <FeedbackEntry>[];
  Completer<void>? hold;
  Object? error;

  @override
  Future<void> send(FeedbackEntry entry) async {
    sent.add(entry);
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
  }
}

Future<void> _pump(
  WidgetTester tester,
  FeedbackRemote remote, {
  bool showPlayButton = true,
  Future<bool> Function(Uri)? openUrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FeedbackCard(
            remote: remote,
            showPlayButton: showPlayButton,
            openUrl: openUrl ?? (_) async => true,
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Send feedback'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('send is disabled until a star is chosen', (tester) async {
    final remote = _FakeRemote();
    await _pump(tester, remote);
    await _openSheet(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(remote.sent, isEmpty);

    await tester.tap(find.bySemanticsLabel('4 stars'));
    await tester.enterText(
      find.widgetWithText(TextField, 'What could be better?'),
      'More audio',
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(remote.sent, hasLength(1));
    expect(remote.sent.single.rating, 4);
    expect(remote.sent.single.improve, 'More audio');
    expect(find.text('How do you like Hallo Leute?'), findsNothing);
    expect(find.text('Danke! We read every message.'), findsOneWidget);
  });

  testWidgets('send button disabled while sending', (tester) async {
    final remote = _FakeRemote()..hold = Completer<void>();
    await _pump(tester, remote);
    await _openSheet(tester);

    await tester.tap(find.bySemanticsLabel('5 stars'));
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.tap(find.text('Sending…'));
    await tester.pump();

    expect(remote.sent, hasLength(1));
    remote.hold!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('send failure keeps text and shows error', (tester) async {
    final remote = _FakeRemote()..error = Exception('offline');
    await _pump(tester, remote);
    await _openSheet(tester);

    await tester.tap(find.bySemanticsLabel('2 stars'));
    await tester.enterText(
      find.widgetWithText(TextField, 'What do you like?'),
      'The packs',
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.text('How do you like Hallo Leute?'), findsOneWidget);
    expect(find.text('The packs'), findsOneWidget);
    expect(find.textContaining('try again'), findsOneWidget);
  });

  testWidgets('play button opens the store listing for everyone', (
    tester,
  ) async {
    final opened = <Uri>[];
    await _pump(
      tester,
      _FakeRemote(),
      openUrl: (uri) async {
        opened.add(uri);
        return false; // no Play Store app: fall back to the web page
      },
    );

    await tester.tap(find.text('Rate on Google Play'));
    await tester.pumpAndSettle();

    expect(opened, [
      Uri.parse('market://details?id=com.halloleute.app'),
      Uri.parse(
        'https://play.google.com/store/apps/details?id=com.halloleute.app',
      ),
    ]);
  });

  testWidgets('play button hidden off Android', (tester) async {
    await _pump(tester, _FakeRemote(), showPlayButton: false);
    expect(find.text('Rate on Google Play'), findsNothing);
    expect(find.text('Send feedback'), findsOneWidget);
  });
}
