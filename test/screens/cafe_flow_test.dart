import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/screens/cafe_details_screen.dart';
import 'package:poppylo/screens/cafe_suggested_screen.dart';
import 'package:poppylo/screens/choose_cafe_screen.dart';
import 'package:poppylo/screens/meeting_confirmed_screen.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/services/location_service.dart';
import 'package:poppylo/services/matching_api.dart';

import '../support/fake_cafe_api.dart';
import '../support/fake_matching_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(
          path: '/match/:matchId/cafes',
          builder: (_, s) =>
              ChooseCafeScreen(matchId: s.pathParameters['matchId']!),
          routes: [
            GoRoute(
              path: 'proposed',
              builder: (_, s) =>
                  CafeSuggestedScreen(matchId: s.pathParameters['matchId']!),
            ),
            GoRoute(
              path: ':cafeId',
              builder: (_, s) => CafeDetailsScreen(
                matchId: s.pathParameters['matchId']!,
                cafeId: s.pathParameters['cafeId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/meeting/:meetingId',
          builder: (_, __) => const Text('MEETING DETAILS'),
          routes: [
            GoRoute(
              path: 'confirmed',
              builder: (_, s) => MeetingConfirmedScreen(
                meetingId: s.pathParameters['meetingId']!,
              ),
            ),
          ],
        ),
      ],
    );

Future<void> _pump(
  WidgetTester t, {
  required String initial,
  required FakeCafeApi cafe,
  FakeMatchingApi? matching,
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        cafeApiProvider.overrideWithValue(cafe),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        matchingApiProvider.overrideWithValue(
          matching ?? FakeMatchingApi(matchDetail: sampleMatch(id: 'm1')),
        ),
      ],
      child: MaterialApp.router(routerConfig: _router(initial)),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('Choose Café lists Google cafés and selects one via placeId',
      (t) async {
    final cafe = FakeCafeApi(nearbyCafesResult: [
      sampleNearbyCafe(placeId: 'p-1', name: 'Bonanza Coffee', rating: 4.6),
      sampleNearbyCafe(placeId: 'p-2', name: 'The Barn', rating: 4.2),
    ]);
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    expect(find.text('Choose a coffee spot ☕'), findsOneWidget);
    expect(find.text('Bonanza Coffee'), findsOneWidget);
    expect(find.text('The Barn'), findsOneWidget);
    expect(find.textContaining('245 reviews'), findsWidgets);
    expect(find.text('Open now'), findsWidgets);
    expect(cafe.nearbyRadii, [5000]); // default radius

    await t.tap(find.text('Select').first);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }

    expect(cafe.suggestCalls, 1);
    expect(cafe.lastSuggestPayload, {
      'placeId': 'p-1',
      'date': '2026-09-05',
      'startTime': '17:00',
    });
    expect(find.text('Café suggestion sent'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('empty → "Search within 10 km" expands the radius', (t) async {
    final cafe = FakeCafeApi(nearbyCafesResult: const []);
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    expect(find.text('No coffee spots found nearby'), findsOneWidget);
    await t.tap(find.text('Search within 10 km'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(cafe.nearbyRadii, [5000, 10000]);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('API failure shows "Try again" and recovers', (t) async {
    final cafe = FakeCafeApi()..nearbyError = Exception('boom');
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    expect(find.text("Couldn't load nearby coffee shops"), findsOneWidget);
    cafe.nearbyError = null;
    cafe.nearbyCafesResult = [sampleNearbyCafe(name: 'Bonanza Coffee')];
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text('Bonanza Coffee'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('location permission denied → "Enable location"', (t) async {
    final cafe = FakeCafeApi(nearbyCafesResult: const []);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          cafeApiProvider.overrideWithValue(cafe),
          locationServiceProvider.overrideWithValue(_DeniedLocationService()),
          matchingApiProvider.overrideWithValue(
            FakeMatchingApi(matchDetail: sampleMatch(id: 'm1')),
          ),
        ],
        child: MaterialApp.router(routerConfig: _router('/match/m1/cafes')),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Location needed'), findsOneWidget);
    expect(find.text('Enable location'), findsOneWidget);

    // manual fallback: tapping the Berlin demo chip searches there
    await t.tap(find.widgetWithText(ActionChip, 'Berlin'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(cafe.nearbyRadii.isNotEmpty, isTrue);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Choose Café → card opens Café Details → choose', (t) async {
    final cafe = FakeCafeApi(
      nearbyCafesResult: [sampleNearbyCafe(placeId: 'p-9', name: 'Bonanza')],
    );
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    await t.tap(find.text('Bonanza'));
    await t.pumpAndSettle();
    expect(find.text('Bonanza'), findsWidgets);
    expect(find.text('OPENING HOURS'), findsOneWidget);

    await t.tap(find.text('Choose this café'));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }
    expect(cafe.suggestCalls, 1);
    expect(cafe.lastSuggestPayload!['placeId'], 'p-9');
    expect(find.text('Café suggestion sent'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Café Suggested (mine) → waiting for partner, no accept button',
      (t) async {
    final cafe = FakeCafeApi(
      suggestion: sampleSuggestion(isMe: true, suggestedByName: 'Ada'),
    );
    await _pump(t, initial: '/match/m1/cafes/proposed', cafe: cafe);

    expect(find.text('Café suggestion sent'), findsOneWidget);
    expect(find.textContaining('WAITING FOR BEN'), findsOneWidget);
    expect(find.text('Accept café'), findsNothing);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Café Suggested (theirs) → Accept confirms the meeting',
      (t) async {
    final cafe = FakeCafeApi(
      suggestion: sampleSuggestion(isMe: false, suggestedByName: 'Ben'),
      meetingDetail: sampleMeeting(id: 'mt9'),
    );
    await _pump(t, initial: '/match/m1/cafes/proposed', cafe: cafe);

    expect(find.textContaining('Ben suggested a café'), findsOneWidget);

    await t.tap(find.text('Accept café'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));

    expect(cafe.acceptCalls, 1);
    expect(find.text('Your Coffee Meet is confirmed.'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Café Suggested advances when the backend reports ACCEPTED',
      (t) async {
    final cafe = FakeCafeApi(
      suggestion: sampleSuggestion(isMe: true),
      meetingDetail: sampleMeeting(id: 'mt7'),
    );
    await _pump(t, initial: '/match/m1/cafes/proposed', cafe: cafe);
    expect(find.text('Café suggestion sent'), findsOneWidget);

    // the other person accepts elsewhere
    cafe.suggestion = sampleSuggestion(
      status: CafeSuggestionStatus.accepted,
      meetingId: 'mt7',
    );
    await t.pump(const Duration(seconds: 3)); // poll tick
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }

    expect(find.text('Your Coffee Meet is confirmed.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Meeting Confirmed shows real cafe / partner / time', (t) async {
    final cafe = FakeCafeApi(meetingDetail: sampleMeeting(id: 'mt1'));
    await _pump(t, initial: '/meeting/mt1/confirmed', cafe: cafe);

    expect(find.text('Your Coffee Meet is confirmed.'), findsOneWidget);
    expect(find.textContaining('BEN'), findsWidgets);
    expect(find.textContaining('BREW LAB'), findsOneWidget);
    expect(find.textContaining('45 MIN'), findsOneWidget);
    // chat button is now enabled (chat feature wired)
    final msgBtn = tester_find_button(t, 'Message Ben');
    expect(msgBtn.enabled, isTrue);
  });
}

class _DeniedLocationService implements LocationService {
  @override
  Future<ResolvedPlace> currentPlace() async =>
      throw LocationDenied('Location permission is needed.');

  @override
  Future<ResolvedPlace> placeFromQuery(String query) async =>
      const ResolvedPlace(latitude: 52.52, longitude: 13.405, name: 'Berlin');
}

ElevatedButton tester_find_button(WidgetTester t, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(ElevatedButton),
  );
  return t.widget<ElevatedButton>(finder);
}
