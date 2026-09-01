import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/screens/create_coffee_meet_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';

import '../support/fake_coffee_request_api.dart';

CoffeeRequest _activeRequest() => CoffeeRequest(
      id: 'req-active',
      status: CoffeeRequestStatus.pending,
      date: '2026-09-01',
      startTime: '15:00',
      durationMinutes: 45,
      maxDistanceKm: 10,
      purpose: 'friends',
      conversationStyle: 'deep',
      expiresAt: DateTime.utc(2026, 9, 1, 15),
    );

Future<void> _pump(WidgetTester tester, FakeCoffeeRequestApi api) async {
  final router = GoRouter(
    initialLocation: '/create',
    routes: [
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateCoffeeMeetScreen(),
      ),
      GoRoute(
        path: '/searching',
        builder: (_, s) => Scaffold(
          body: Text('searching:${s.extra ?? ''}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coffeeRequestApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('submits the mapped payload and navigates to Searching',
      (tester) async {
    final api = FakeCoffeeRequestApi();
    await _pump(tester, api);

    // Defaults: Today / 3:00 PM / 45 min / 10 km / Make friends / Deep.
    await tester.tap(find.text('Find my match'));
    await tester.pumpAndSettle();

    expect(api.lastCreatePayload, isNotNull);
    expect(api.lastCreatePayload!['startTime'], '15:00');
    expect(api.lastCreatePayload!['durationMinutes'], 45);
    expect(api.lastCreatePayload!['maxDistanceKm'], 10);
    expect(api.lastCreatePayload!['purpose'], 'friends');
    expect(api.lastCreatePayload!['conversationStyle'], 'deep');
    expect(api.lastCreatePayload!.containsKey('userId'), isFalse);

    expect(find.text('searching:req-new'), findsOneWidget);
  });

  testWidgets('a 409 keeps the user on the screen with a message',
      (tester) async {
    final api = FakeCoffeeRequestApi()
      ..createError = ApiException(409, 'already searching');
    await _pump(tester, api);

    await tester.tap(find.text('Find my match'));
    await tester.pumpAndSettle();

    expect(find.text("You're already searching for a coffee match."),
        findsOneWidget);
    expect(find.text('Find my match'), findsOneWidget); // still on the form
  });

  testWidgets('an existing active request shows the blocked state',
      (tester) async {
    final api = FakeCoffeeRequestApi(active: _activeRequest());
    await _pump(tester, api);

    expect(find.text("You're already searching for a coffee match."),
        findsOneWidget);
    expect(find.text('Continue searching'), findsOneWidget);
    expect(find.text('Find my match'), findsNothing);

    await tester.tap(find.text('Continue searching'));
    await tester.pumpAndSettle();
    expect(find.text('searching:req-active'), findsOneWidget);
  });

  testWidgets('cancelling the active request returns to the form',
      (tester) async {
    final api = FakeCoffeeRequestApi(active: _activeRequest());
    await _pump(tester, api);

    await tester.tap(find.text('Cancel this request'));
    await tester.pumpAndSettle();

    expect(api.cancelCalls, 1);
    expect(find.text('Find my match'), findsOneWidget);
  });
}
