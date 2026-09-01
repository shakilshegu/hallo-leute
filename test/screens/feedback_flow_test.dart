import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/feedback_models.dart';
import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/screens/connection_detail_screen.dart';
import 'package:poppylo/screens/connections_screen.dart';
import 'package:poppylo/screens/feedback_screen.dart';
import 'package:poppylo/screens/feedback_sent_screen.dart';
import 'package:poppylo/screens/meeting_details_screen.dart';
import 'package:poppylo/screens/mutual_connection_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/state/feedback_controller.dart';
import 'package:poppylo/state/connection_controller.dart';

import '../support/fake_cafe_api.dart';
import '../support/fake_connection_api.dart';
import '../support/fake_feedback_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/meeting/mt1/feedback',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(
          path: '/meeting/:meetingId/feedback',
          builder: (_, s) =>
              FeedbackScreen(meetingId: s.pathParameters['meetingId']!),
          routes: [
            GoRoute(
              path: 'sent',
              builder: (_, s) => FeedbackSentScreen(
                meetingId: s.pathParameters['meetingId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/meeting/:meetingId/connection',
          builder: (_, s) => MutualConnectionScreen(
            meetingId: s.pathParameters['meetingId']!,
            connectionId: s.extra as String?,
          ),
        ),
        GoRoute(
          path: '/connections/:connectionId',
          builder: (_, s) => ConnectionDetailScreen(
            connectionId: s.pathParameters['connectionId']!,
          ),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester t, {
  required FakeFeedbackApi feedback,
  FakeConnectionApi? connection,
}) async {
  t.view.physicalSize = const Size(1200, 2800);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        feedbackApiProvider.overrideWithValue(feedback),
        connectionApiProvider.overrideWithValue(
          connection ?? FakeConnectionApi(),
        ),
        cafeApiProvider.overrideWithValue(FakeCafeApi()),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _fillValidFeedback(WidgetTester t,
    {String meetAgain = 'YES'}) async {
  await t.tap(find.byIcon(Icons.star_border).at(4)); // 5 stars
  await t.pump();
  await t.ensureVisible(find.text('GREAT').first);
  await t.tap(find.text('GREAT').first);
  await t.pump();
  await t.ensureVisible(find.text(meetAgain));
  await t.tap(find.text(meetAgain));
  await t.pump();
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('submit is disabled until rating + feeling + meet-again chosen',
      (t) async {
    await _pump(t, feedback: FakeFeedbackApi());

    ElevatedButton btn() => t.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('SUBMIT FEEDBACK'),
            matching: find.byType(ElevatedButton),
          ),
        );
    expect(btn().onPressed, isNull);

    await _fillValidFeedback(t);
    expect(btn().onPressed, isNotNull);
  });

  testWidgets('valid submit with no mutual connection → Feedback Sent',
      (t) async {
    final feedback = FakeFeedbackApi(
      submitResult: const SubmitFeedbackResult(mutualConnectionCreated: false),
    );
    await _pump(t, feedback: feedback);

    await _fillValidFeedback(t, meetAgain: 'YES');
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(feedback.submissions.single, {
      'meetingId': 'mt1',
      'rating': 5,
      'conversationFeeling': 'GREAT',
      'wouldMeetAgain': true,
      'tags': <String>[],
      'comment': null,
    });
    expect(find.text('Thanks.'), findsOneWidget); // Feedback Sent screen
    expect(find.text('You both enjoyed meeting.'), findsNothing);
  });

  testWidgets('mutual connection created → Mutual Connection screen',
      (t) async {
    final feedback = FakeFeedbackApi(
      submitResult: const SubmitFeedbackResult(
        mutualConnectionCreated: true,
        connectionId: 'conn-1',
      ),
    );
    await _pump(t, feedback: feedback);

    await _fillValidFeedback(t);
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('You both enjoyed meeting.'), findsOneWidget);

    // View profile is enabled and opens the connection detail
    await t.tap(find.text('View profile'));
    await t.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget); // detail app bar
  });

  testWidgets('NOT_GREAT + NO maps to wouldMeetAgain:false', (t) async {
    final feedback = FakeFeedbackApi();
    await _pump(t, feedback: feedback);

    await t.tap(find.byIcon(Icons.star_border).at(2));
    await t.pump();
    await t.ensureVisible(find.text('NOT GREAT').first);
    await t.tap(find.text('NOT GREAT').first);
    await t.pump();
    await t.tap(find.text('NO'));
    await t.pump();
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(feedback.submissions.single['conversationFeeling'], 'NOT_GOOD');
    expect(feedback.submissions.single['wouldMeetAgain'], false);
  });

  testWidgets('a 409 is treated as done → Feedback Sent (no crash)', (t) async {
    final feedback = FakeFeedbackApi()..submitError = ApiException(409, 'dupe');
    await _pump(t, feedback: feedback);

    await _fillValidFeedback(t);
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Thanks.'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a 500 shows a snackbar and stays on the form', (t) async {
    final feedback = FakeFeedbackApi()..submitError = ApiException(500, 'boom');
    await _pump(t, feedback: feedback);

    await _fillValidFeedback(t);
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(
        find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('How was your coffee?'), findsOneWidget); // still here
    expect(t.takeException(), isNull);
  });

  testWidgets('privacy: no screen ever shows the other person’s answer',
      (t) async {
    await _pump(
      t,
      feedback: FakeFeedbackApi(
        submitResult: const SubmitFeedbackResult(
          mutualConnectionCreated: true,
          connectionId: 'conn-1',
        ),
      ),
    );
    await _fillValidFeedback(t);
    await t.tap(find.text('SUBMIT FEEDBACK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    // The only thing the mutual screen may claim:
    expect(find.text('You both enjoyed meeting.'), findsOneWidget);
    expect(find.textContaining('said NO'), findsNothing);
    expect(find.textContaining('rated you'), findsNothing);
    expect(find.textContaining('stars'), findsNothing);
  });

  _meetingDetailsTests();
}

Future<void> _pumpScreen(
  WidgetTester t,
  Widget child, {
  required List<Override> overrides,
}) async {
  t.view.physicalSize = const Size(1200, 2800);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const SizedBox()),
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void _meetingDetailsTests() {
  testWidgets('Meeting Details hides "Leave feedback" until the backend allows',
      (t) async {
    await _pumpScreen(
      t,
      const MeetingDetailsScreen(meetingId: 'demo-meeting'),
      overrides: [
        feedbackApiProvider.overrideWithValue(
          FakeFeedbackApi(
            statusResult:
                const FeedbackStatus(canSubmit: false, submitted: false),
          ),
        ),
        cafeApiProvider.overrideWithValue(FakeCafeApi()),
        connectionApiProvider.overrideWithValue(FakeConnectionApi()),
      ],
    );
    expect(find.text('Leave feedback'), findsNothing);
  });

  testWidgets('Meeting Details shows "Leave feedback" when canSubmit',
      (t) async {
    await _pumpScreen(
      t,
      const MeetingDetailsScreen(meetingId: 'demo-meeting'),
      overrides: [
        feedbackApiProvider.overrideWithValue(
          FakeFeedbackApi(
            statusResult:
                const FeedbackStatus(canSubmit: true, submitted: false),
          ),
        ),
        cafeApiProvider.overrideWithValue(FakeCafeApi()),
        connectionApiProvider.overrideWithValue(FakeConnectionApi()),
      ],
    );
    expect(find.text('Leave feedback'), findsOneWidget);
  });

  testWidgets('Connections screen lists people and shows the empty state',
      (t) async {
    await _pumpScreen(
      t,
      const ConnectionsScreen(),
      overrides: [
        connectionApiProvider.overrideWithValue(
          FakeConnectionApi(list: [
            Connection(
              id: 'c1',
              user: sampleConnectionUser(name: 'Ben', rating: 4.8),
              createdAt: DateTime.utc(2026, 9, 1),
            ),
          ]),
        ),
      ],
    );
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('Connections screen empty state', (t) async {
    await _pumpScreen(
      t,
      const ConnectionsScreen(),
      overrides: [
        connectionApiProvider.overrideWithValue(FakeConnectionApi(list: [])),
      ],
    );
    expect(find.text('No connections yet.'), findsOneWidget);
  });
}
