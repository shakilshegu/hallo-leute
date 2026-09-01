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

  testWidgets('Choose Café lists backend cafés and suggests one', (t) async {
    final cafe = FakeCafeApi(cafes: [
      sampleCafe(id: 'shop-1', name: 'Brew Lab', rating: 4.6),
      sampleCafe(id: 'shop-2', name: 'The Loft', rating: 4.2),
    ]);
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    expect(find.text('Brew Lab'), findsOneWidget);
    expect(find.text('The Loft'), findsOneWidget);
    expect(find.textContaining('4.6'), findsWidgets);

    await t.tap(find.text('Suggest this café').first);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }

    expect(cafe.suggestCalls, 1);
    expect(cafe.lastSuggestPayload, {
      'coffeeShopId': 'shop-1',
      'date': '2026-09-05', // from the match's agreed slot
      'startTime': '17:00',
    });
    expect(find.text('Café suggestion sent'), findsOneWidget);

    await t.pumpWidget(const SizedBox()); // dispose polling screen
  });

  testWidgets('Choose Café → card opens Café Details → suggest', (t) async {
    final cafe =
        FakeCafeApi(cafes: [sampleCafe(id: 'shop-1', name: 'Brew Lab')]);
    await _pump(t, initial: '/match/m1/cafes', cafe: cafe);

    await t.tap(find.text('Brew Lab'));
    await t.pumpAndSettle();
    expect(find.text('Brew Lab'), findsWidgets);
    expect(find.textContaining('Bright specialty roaster'), findsOneWidget);

    await t.tap(find.text('Suggest this café'));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 40));
    }
    expect(cafe.suggestCalls, 1);
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

ElevatedButton tester_find_button(WidgetTester t, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(ElevatedButton),
  );
  return t.widget<ElevatedButton>(finder);
}
