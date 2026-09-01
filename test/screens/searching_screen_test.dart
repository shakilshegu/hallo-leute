import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/screens/searching_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';
import 'package:poppylo/services/matching_api.dart';

import '../support/fake_coffee_request_api.dart';
import '../support/fake_matching_api.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? requestId,
  FakeMatchingApi? matching,
  FakeCoffeeRequestApi? coffee,
}) async {
  final router = GoRouter(
    initialLocation: '/searching',
    routes: [
      GoRoute(
        path: '/searching',
        builder: (_, __) => SearchingScreen(requestId: requestId),
      ),
      GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
      GoRoute(path: '/create', builder: (_, __) => const Text('CREATE')),
      GoRoute(
        path: '/match/:matchId',
        builder: (_, s) => Text('MATCH:${s.pathParameters['matchId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchingApiProvider.overrideWithValue(matching ?? FakeMatchingApi()),
        coffeeRequestApiProvider.overrideWithValue(
          coffee ?? (FakeCoffeeRequestApi()..detail = sampleCoffee()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

FakeCoffeeRequestApi _coffeeWithDetail() =>
    FakeCoffeeRequestApi()..detail = sampleCoffee();

dynamic sampleCoffee() => FakeCoffeeRequestApi().sample(id: 'r1');

void main() {
  testWidgets('no requestId → "no active meet" message', (t) async {
    await _pump(t);
    expect(find.text('No active coffee meet'), findsOneWidget);
    await t.tap(find.text('Start a coffee meet'));
    await t.pumpAndSettle();
    expect(find.text('CREATE'), findsOneWidget);
  });

  testWidgets('SEARCHING → shows the radar view and keeps polling', (t) async {
    final matching = FakeMatchingApi(statusResult: searchingResult());
    await _pump(t,
        requestId: 'r1', matching: matching, coffee: _coffeeWithDetail());

    expect(find.text('Finding your coffee match'), findsOneWidget);
    expect(find.text('Cancel search'), findsOneWidget);
    expect(matching.startCalls, 1);

    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 10));
    expect(matching.pollCalls, greaterThanOrEqualTo(1));

    await tester_dispose(t);
  });

  testWidgets('MATCH_FOUND on start → navigates to the match route', (t) async {
    final matching =
        FakeMatchingApi(startResult: matchFoundResult(sampleMatch(id: 'm9')));
    await _pump(t,
        requestId: 'r1', matching: matching, coffee: _coffeeWithDetail());
    await t.pumpAndSettle();

    expect(find.text('MATCH:m9'), findsOneWidget);
  });

  testWidgets('MATCH_FOUND while polling → navigates', (t) async {
    final matching = FakeMatchingApi(statusResult: searchingResult());
    await _pump(t,
        requestId: 'r1', matching: matching, coffee: _coffeeWithDetail());
    expect(find.text('Finding your coffee match'), findsOneWidget);

    matching.statusResult = matchFoundResult(sampleMatch(id: 'm7'));
    await t.pump(const Duration(seconds: 3));
    await t.pumpAndSettle();
    expect(find.text('MATCH:m7'), findsOneWidget);
  });

  testWidgets('409 (request no longer active) → ended state', (t) async {
    final matching =
        FakeMatchingApi(statusError: ApiException(409, 'not active'));
    await _pump(t,
        requestId: 'r1', matching: matching, coffee: _coffeeWithDetail());

    expect(find.text('This search has ended'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
  });

  testWidgets('network error before first result → retry state', (t) async {
    final matching = FakeMatchingApi(statusError: Exception('offline'));
    await _pump(t,
        requestId: 'r1', matching: matching, coffee: _coffeeWithDetail());

    expect(find.text("Couldn't load your search"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Cancel search → cancels the request and goes home', (t) async {
    final coffee = _coffeeWithDetail();
    final matching = FakeMatchingApi(statusResult: searchingResult());
    await _pump(t, requestId: 'r1', matching: matching, coffee: coffee);

    await t.tap(find.text('Cancel search'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpAndSettle();

    expect(coffee.cancelCalls, 1);
    expect(find.text('HOME'), findsOneWidget);
  });
}

Future<void> tester_dispose(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
}
