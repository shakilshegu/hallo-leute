import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/screens/home_screen.dart';
import 'package:poppylo/services/profile_api.dart';
import 'package:poppylo/state/discover_controller.dart';

import '../support/fake_profile_api.dart';
import '../support/mock_network_images.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  DiscoverFeed feed({List<CoffeeMeet>? meets, List<NearbyPerson>? people}) {
    return DiscoverFeed(
      location: 'Kochi, India',
      meets: meets ??
          [
            CoffeeMeet(
              id: 'm1',
              hostName: 'Ananya',
              hostAge: 27,
              hostAvatarUrl: 'https://x/a.jpg',
              bio: 'Designer.',
              sharedInterests: const ['Design'],
              distanceKm: 1.2,
              cafeName: 'Brew Lab',
              startsAt: DateTime.now().add(const Duration(hours: 3)),
              participantCount: 2,
              maxParticipants: 4,
              availableNow: true,
            ),
          ],
      nearbyPeople: people ??
          const [
            NearbyPerson(
              id: 'p1',
              name: 'Sara',
              avatarUrl: 'https://x/s.jpg',
              interestTags: ['Travel'],
              distanceKm: 0.8,
            ),
          ],
    );
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required FakeProfileApi profile,
    required DiscoverFeed Function() feedBuilder,
  }) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/create',
          builder: (_, __) => const Scaffold(body: Text('create'))),
      GoRoute(
          path: '/match/:id',
          builder: (_, __) => const Scaffold(body: Text('match'))),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileApiProvider.overrideWithValue(profile),
          discoverFeedProvider.overrideWith((ref) async => feedBuilder()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('greets by real name and renders the discover feed',
      (tester) async {
    await pump(
      tester,
      profile: FakeProfileApi(sampleUserMe(firstName: 'Nadia')),
      feedBuilder: feed,
    );

    expect(find.textContaining('Nadia'), findsOneWidget);
    expect(find.text('Find someone to share a coffee with.'), findsOneWidget);
    expect(find.text('Recommended for you'), findsOneWidget);
    expect(find.text('Ananya, 27'), findsOneWidget);
    expect(find.text('View Meet'), findsOneWidget);
    expect(find.text('People nearby'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no meets', (tester) async {
    await pump(
      tester,
      profile: FakeProfileApi(sampleUserMe()),
      feedBuilder: () => feed(meets: []),
    );

    expect(find.text('No coffee meets nearby yet'), findsOneWidget);
    expect(find.text('Create a Meet'), findsOneWidget);
  });

  testWidgets('a quick filter narrows the list to an empty state',
      (tester) async {
    // one meet, not available now → the "Available Now" filter clears it
    final oneMeet = feed(meets: [
      CoffeeMeet(
        id: 'm9',
        hostName: 'Rahul',
        hostAge: 31,
        hostAvatarUrl: 'https://x/r.jpg',
        bio: 'Engineer.',
        sharedInterests: const [],
        distanceKm: 2.6,
        cafeName: 'Kashi',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        participantCount: 1,
        maxParticipants: 3,
        availableNow: false,
      ),
    ]);
    await pump(
      tester,
      profile: FakeProfileApi(sampleUserMe()),
      feedBuilder: () => oneMeet,
    );
    expect(find.text('Rahul, 31'), findsOneWidget);

    await tester.tap(find.text('Available Now'));
    await tester.pumpAndSettle();

    expect(find.text('Rahul, 31'), findsNothing);
    expect(find.text('No coffee meets nearby yet'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });
}

// ignore: unused_element
class _NeverProfileApi extends FakeProfileApi {
  _NeverProfileApi() : super(sampleUserMe());
  @override
  Future<UserMe> getMe() => Completer<UserMe>().future;
}
