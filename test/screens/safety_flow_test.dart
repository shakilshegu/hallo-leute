import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/screens/blocked_users_screen.dart';
import 'package:poppylo/screens/report_user_screen.dart';
import 'package:poppylo/screens/safety_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/state/safety_controller.dart';

import '../support/fake_cafe_api.dart';
import '../support/fake_safety_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(
          path: '/meeting/:id/safety',
          builder: (_, s) => SafetyScreen(meetingId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/report/:userId',
          builder: (_, s) =>
              ReportUserScreen(userId: s.pathParameters['userId']!),
        ),
        GoRoute(
          path: '/settings/blocked',
          builder: (_, __) => const BlockedUsersScreen(),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester t, {
  required String initial,
  required FakeSafetyApi safety,
  FakeCafeApi? cafe,
}) async {
  t.view.physicalSize = const Size(1200, 2600);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        safetyApiProvider.overrideWithValue(safety),
        cafeApiProvider.overrideWithValue(cafe ?? FakeCafeApi()),
      ],
      child: MaterialApp.router(routerConfig: _router(initial)),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _tap(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder.first);
  await t.pumpAndSettle();
  await t.tap(finder.first);
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('Safety Center opens Report and blocks empty reason', (t) async {
    final safety = FakeSafetyApi();
    await _pump(t, initial: '/meeting/mt1/safety', safety: safety);

    expect(find.text('Meet safely'), findsOneWidget);

    await _tap(t, find.text('Report user'));
    await t.pumpAndSettle();

    // Submit is disabled until a reason is picked.
    final btn = t.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Submit report'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNull);

    await _tap(t, find.text('Harassment'));
    await t.pump();
    await _tap(t, find.text('Submit report'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(safety.reports.single['reason'], 'harassment');
    expect(find.text('Report submitted'), findsOneWidget);
  });

  testWidgets('Block user confirms, calls the API and returns home', (t) async {
    final safety = FakeSafetyApi();
    await _pump(t, initial: '/meeting/mt1/safety', safety: safety);

    await _tap(t, find.text('Block user'));
    await t.pumpAndSettle();

    expect(find.text('Block Ben?'), findsOneWidget);
    await t.tap(find.widgetWithText(TextButton, 'Block'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(safety.blockedIds, ['u2']);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Block error shows a snackbar and stays on the screen',
      (t) async {
    final safety = FakeSafetyApi()..blockError = ApiException(500, 'boom');
    await _pump(t, initial: '/meeting/mt1/safety', safety: safety);

    await _tap(t, find.text('Block user'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, 'Block'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(
        find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(find.text('Meet safely'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Cancel meeting sheet submits a reason and returns home',
      (t) async {
    final safety = FakeSafetyApi();
    await _pump(t, initial: '/meeting/mt1/safety', safety: safety);

    await _tap(t, find.text('Cancel meeting'));
    await t.pumpAndSettle();

    expect(find.text('Cancel this Coffee Meet?'), findsOneWidget);
    await t.tap(find.text('Plans changed'));
    await t.pump();
    await t.tap(find.widgetWithText(TextButton, 'Cancel meeting'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(safety.cancellations.single,
        {'meetingId': 'mt1', 'reason': 'personal_reason'});
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Blocked users screen lists people and unblocks one', (t) async {
    final safety = FakeSafetyApi(blocked: [
      const BlockedUser(
          id: 'u2', name: 'Ben', profileImage: null, blockedAt: null),
      const BlockedUser(
          id: 'u3', name: 'Cara', profileImage: null, blockedAt: null),
    ]);
    await _pump(t, initial: '/settings/blocked', safety: safety);

    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Cara'), findsOneWidget);

    await t.tap(find.widgetWithText(TextButton, 'Unblock').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(safety.unblockedIds, ['u2']);
    expect(find.text('Ben'), findsNothing);
    expect(find.text('Cara'), findsOneWidget);
  });

  testWidgets('Blocked users empty state', (t) async {
    final safety = FakeSafetyApi(blocked: []);
    await _pump(t, initial: '/settings/blocked', safety: safety);

    expect(find.text("You haven't blocked anyone."), findsOneWidget);
  });
}
