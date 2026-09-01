import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/screens/match_confirmed_screen.dart';
import 'package:poppylo/screens/match_detail_screen.dart';
import 'package:poppylo/screens/match_found_screen.dart';
import 'package:poppylo/screens/waiting_screen.dart';
import 'package:poppylo/services/matching_api.dart';

import '../support/fake_matching_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router({String initialLocation = '/match/m1'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(path: '/create', builder: (_, __) => const Text('CREATE')),
        GoRoute(
          path: '/match/:matchId',
          builder: (_, s) =>
              MatchFoundScreen(matchId: s.pathParameters['matchId']!),
          routes: [
            GoRoute(
              path: 'details',
              builder: (_, s) =>
                  MatchDetailScreen(matchId: s.pathParameters['matchId']!),
            ),
            GoRoute(
              path: 'waiting',
              builder: (_, s) =>
                  MatchStatusScreen(matchId: s.pathParameters['matchId']!),
            ),
            GoRoute(
              path: 'confirmed',
              builder: (_, s) =>
                  MatchConfirmedScreen(matchId: s.pathParameters['matchId']!),
            ),
            GoRoute(
              path: 'cafes',
              builder: (_, __) => const Text('CHOOSE CAFE'),
            ),
          ],
        ),
      ],
    );

Future<void> _pump(WidgetTester t, FakeMatchingApi api) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [matchingApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('Match Found shows backend name + score, then opens Details',
      (t) async {
    final api = FakeMatchingApi(
      matchDetail: sampleMatch(id: 'm1', score: 91),
    );
    await _pump(t, api);

    expect(find.textContaining('Ben'), findsWidgets);
    expect(find.textContaining('91% match'), findsOneWidget);

    await t.tap(find.text('View Match'));
    await t.pumpAndSettle();

    expect(find.text('Ben'), findsWidgets);
    expect(find.text('Why you matched'), findsOneWidget);
    expect(find.textContaining('You both like Travel'), findsOneWidget);
  });

  testWidgets('Pass on Match Found calls the API and goes home', (t) async {
    final api = FakeMatchingApi(matchDetail: sampleMatch(id: 'm1'));
    await _pump(t, api);

    await t.tap(find.text('Pass'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpAndSettle();

    expect(api.passCalls, 1);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Accept (one side) on Details → Waiting screen', (t) async {
    final api = FakeMatchingApi(matchDetail: sampleMatch(id: 'm1'))
      ..acceptResult = sampleMatch(
        id: 'm1',
        status: MatchLifecycle.acceptedByOne,
        myResponse: MatchResponseStatus.accepted,
      );
    await _pump(t, api);
    await t.tap(find.text('View Match'));
    await t.pumpAndSettle();

    await t.ensureVisible(find.text('Accept match'));
    await t.pump();
    await t.tap(find.text('Accept match'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));

    expect(api.acceptCalls, 1);
    expect(find.textContaining('Waiting for'), findsOneWidget);

    await t.pumpWidget(const SizedBox()); // dispose the polling screen
  });

  testWidgets('Accept when backend already CONFIRMED → Match Confirmed',
      (t) async {
    final api = FakeMatchingApi(matchDetail: sampleMatch(id: 'm1'))
      ..acceptResult = sampleMatch(
        id: 'm1',
        status: MatchLifecycle.confirmed,
        myResponse: MatchResponseStatus.accepted,
        otherResponse: MatchResponseStatus.accepted,
      );
    await _pump(t, api);
    await t.tap(find.text('View Match'));
    await t.pumpAndSettle();

    await t.ensureVisible(find.text('Accept match'));
    await t.pump();
    await t.tap(find.text('Accept match'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpAndSettle();

    expect(find.text('Choose a café'), findsOneWidget);
  });

  testWidgets('Waiting screen advances to Confirmed when both have accepted',
      (t) async {
    final api = FakeMatchingApi(
      matchDetail: sampleMatch(
        id: 'm1',
        status: MatchLifecycle.acceptedByOne,
        myResponse: MatchResponseStatus.accepted,
      ),
    );
    // Land directly on the waiting screen.
    await t.pumpWidget(
      ProviderScope(
        overrides: [matchingApiProvider.overrideWithValue(api)],
        child: MaterialApp.router(
          routerConfig: _router(initialLocation: '/match/m1/waiting'),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Waiting for'), findsOneWidget);

    // Next poll: the backend now reports it confirmed.
    api.matchDetail = sampleMatch(
      id: 'm1',
      status: MatchLifecycle.confirmed,
      myResponse: MatchResponseStatus.accepted,
      otherResponse: MatchResponseStatus.accepted,
    );
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpAndSettle();

    expect(find.text('Choose a café'), findsOneWidget);
  });
}
