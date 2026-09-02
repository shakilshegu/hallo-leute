import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/models/match_models.dart';
import 'package:poppylo/router/app_router.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/match_controller.dart';
import 'package:poppylo/state/meeting_controller.dart';

import '../support/mock_network_images.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockNetworkImagesHttpOverrides();
  });
  tearDownAll(() {
    HttpOverrides.global = null;
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String currentLocation(ProviderContainer container) {
    final router = container.read(routerProvider);
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  void signInAndCompleteOnboarding(ProviderContainer container) {
    container
        .read(authControllerProvider.notifier)
        .debugSignIn(isNewUser: true, onboardingStep: OnboardingStep.done);
  }

  testWidgets('auth guard redirects a signed-out user away from /home',
      (tester) async {
    final container = await pumpApp(tester);

    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(currentLocation(container), AppRoutes.welcome);
  });

  testWidgets(
      'auth guard sends a returning user (isNewUser: false) straight to home, skipping onboarding',
      (tester) async {
    final container = await pumpApp(tester);
    container
        .read(authControllerProvider.notifier)
        .debugSignIn(isNewUser: false);
    // Onboarding step is still at its default (profile) — a new user in
    // this state would be held on /onboarding/profile by the guard.

    container.read(routerProvider).go(AppRoutes.onboardProfile);
    await tester.pumpAndSettle();

    expect(currentLocation(container), AppRoutes.home);
  });

  testWidgets(
      'chat guard redirects to match details when the match is not yet accepted',
      (tester) async {
    final container = await pumpApp(tester);
    signInAndCompleteOnboarding(container);

    const matchId = 'guard-test-match';
    const meetingId = 'guard-test-meeting';
    container.read(matchRepositoryProvider.notifier).setStatus(
          matchId,
          MatchStatus.proposed, // not yet accepted
        );
    container.read(meetingRepositoryProvider.notifier).confirm(
          meetingId,
          matchId,
          cafeName: 'Brew Lab',
          partnerName: 'Sarah',
          startTime: DateTime.now(),
        );

    container.read(routerProvider).go(AppRoutes.chatPath(meetingId));
    await tester.pumpAndSettle();

    expect(currentLocation(container), AppRoutes.matchDetailsPath(matchId));
  });

  testWidgets(
      'meeting guard does NOT bounce an unknown meeting into the café flow',
      (tester) async {
    final container = await pumpApp(tester);
    signInAndCompleteOnboarding(container);

    // A meeting the repository has never seen (e.g. tapped straight from the
    // Meetings list on a fresh launch). The screen fetches it; the guard must
    // not redirect on the synchronous placeholder.
    container.read(routerProvider).go(AppRoutes.meetingPath('unseen-meeting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(currentLocation(container), AppRoutes.meetingPath('unseen-meeting'));
  });

  testWidgets(
      'cafe guard redirects to match details when the match is accepted but not confirmed',
      (tester) async {
    final container = await pumpApp(tester);
    signInAndCompleteOnboarding(container);

    const matchId = 'guard-test-match-2';
    container.read(matchRepositoryProvider.notifier).setStatus(
          matchId,
          MatchStatus.accepted, // one step short of confirmed
        );

    container.read(routerProvider).go(AppRoutes.chooseCafePath(matchId));
    await tester.pumpAndSettle();

    expect(currentLocation(container), AppRoutes.matchDetailsPath(matchId));
  });
}
