import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/screens/discover_profile_screen.dart';
import 'package:poppylo/screens/discover_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/state/discover_controller.dart';

import '../support/fake_discover_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/discover',
      routes: [
        GoRoute(
          path: '/discover',
          builder: (_, __) => const DiscoverPeopleScreen(),
        ),
        GoRoute(
          path: '/discover/:userId',
          builder: (_, s) =>
              DiscoverProfileScreen(userId: s.pathParameters['userId']!),
        ),
        GoRoute(path: '/create', builder: (_, __) => const Text('CREATE FLOW')),
      ],
    );

Future<void> _pump(WidgetTester t, FakeDiscoverApi api) async {
  t.view.physicalSize = const Size(1200, 2600);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [discoverApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('loads real users into cards with a compatibility score',
      (t) async {
    final api = FakeDiscoverApi(all: [
      sampleDiscoverUser(id: 'u2', name: 'Sarah', score: 87),
      sampleDiscoverUser(id: 'u3', name: 'Ben', score: 60),
    ]);
    await _pump(t, api);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Find someone worth meeting.'), findsOneWidget);
    expect(find.text('Sarah, 29'), findsOneWidget);
    expect(find.text('Ben, 29'), findsOneWidget);
    expect(find.text('87% match'), findsOneWidget);
    expect(
        find.textContaining('Technology  •  Travel  •  Design'), findsWidgets);
  });

  testWidgets('empty state shows the friendly message + Adjust Filters',
      (t) async {
    await _pump(t, FakeDiscoverApi(all: const []));
    expect(find.text('No one nearby right now'), findsOneWidget);
    expect(
      find.text('No people found nearby right now.'),
      findsOneWidget,
    );
    expect(find.text('Adjust Filters'), findsOneWidget);
  });

  testWidgets('error state shows Try Again and recovers', (t) async {
    final api = FakeDiscoverApi()..peopleError = ApiException(500, 'boom');
    await _pump(t, api);

    expect(find.text("Couldn't load Discover."), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(t.takeException(), isNull);

    api.peopleError = null;
    api.all.add(sampleDiscoverUser(name: 'Sarah'));
    await t.tap(find.text('Try Again'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Sarah, 29'), findsOneWidget);
  });

  testWidgets('infinite scroll loads page 2 without re-requesting page 1',
      (t) async {
    final api = FakeDiscoverApi(
      all: List.generate(
        25,
        (i) => sampleDiscoverUser(id: 'u$i', name: 'User$i'),
      ),
      pageSize: 20,
    );
    await _pump(t, api);
    expect(find.text('User0, 29'), findsOneWidget);

    await t.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    final pagesRequested = api.calls.map((c) => c['page'] as int).toList();
    expect(pagesRequested, [1, 2]);
    expect(pagesRequested.where((p) => p == 1).length, 1); // no double page 1
  });

  testWidgets('View Profile opens the public profile', (t) async {
    await _pump(t, FakeDiscoverApi(all: [sampleDiscoverUser(name: 'Sarah')]));
    await t.tap(find.text('View Profile').first);
    await t.pumpAndSettle();

    expect(
        find.text('Invite for Coffee'), findsOneWidget); // profile screen CTA
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('COFFEE PREFERENCES'), findsOneWidget);
  });

  testWidgets('Invite for Coffee routes into the existing Coffee Request flow',
      (t) async {
    await _pump(t, FakeDiscoverApi(all: [sampleDiscoverUser(name: 'Sarah')]));
    await t.tap(find.text('Invite').first);
    await t.pumpAndSettle();
    expect(find.text('CREATE FLOW'), findsOneWidget);
  });

  testWidgets('applying a filter re-queries with the filter params', (t) async {
    final api = FakeDiscoverApi(all: [sampleDiscoverUser(name: 'Sarah')]);
    await _pump(t, api);

    await t.tap(find.byIcon(Icons.tune));
    await t.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    await t.tap(find.text('10 km'));
    await t.pump();
    await t.tap(find.text('Networking'));
    await t.pump();
    await t.tap(find.text('Apply'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    final lastFilters = api.calls.last['filters'] as DiscoverFilters;
    expect(lastFilters.distanceKm, 10);
    expect(lastFilters.purpose, 'networking');
  });
}
