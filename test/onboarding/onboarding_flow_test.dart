import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/app_router.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/onboarding_controller.dart';
import 'package:poppylo/state/search_controller.dart';

import '../support/fake_onboarding_api.dart';
import '../support/mock_network_images.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockNetworkImagesHttpOverrides();
  });
  tearDownAll(() {
    HttpOverrides.global = null;
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    final container = ProviderContainer(overrides: overrides);
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

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  testWidgets('new user is held on the 3-step onboarding, in order',
      (tester) async {
    final container = await pumpApp(tester);
    container
        .read(authControllerProvider.notifier)
        .debugSignIn(isNewUser: true, onboardingStep: OnboardingStep.profile);

    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(location(container), AppRoutes.onboardProfile);

    container
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.conversation);
    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(location(container), AppRoutes.onboardConversation);

    container
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.coffee);
    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(location(container), AppRoutes.onboardCoffee);

    container
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.done);
    container.read(routerProvider).go(AppRoutes.onboardProfile);
    await tester.pumpAndSettle();
    expect(location(container), AppRoutes.home);
  });

  testWidgets('walks all three screens, calling the API with mapped payloads',
      (tester) async {
    final fakeApi = FakeOnboardingApi();
    final container = await pumpApp(
      tester,
      overrides: [onboardingApiProvider.overrideWithValue(fakeApi)],
    );
    container
        .read(authControllerProvider.notifier)
        .debugSignIn(isNewUser: true, onboardingStep: OnboardingStep.profile);
    // A locally-picked photo path (not yet uploaded).
    container
        .read(onboardingControllerProvider.notifier)
        .setPhoto('/tmp/picked.jpg');

    container.read(routerProvider).go(AppRoutes.onboardProfile);
    await tester.pumpAndSettle();
    expect(find.text('Tell us a little about you'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Your given name'), 'Sam');
    await tester.enterText(find.widgetWithText(TextField, 'Years'), '29');
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Barista, Designer, Student'),
        'Designer');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // The local path isn't sent to POST /profile — it's uploaded separately,
    // and the returned URL replaces it in the store.
    expect(fakeApi.profile, {
      'firstName': 'Sam',
      'age': 29,
      'job': 'Designer',
      'bio': '',
      'photoUrl': null,
    });
    expect(fakeApi.uploadedPhotoPath, '/tmp/picked.jpg');
    expect(
      container.read(onboardingControllerProvider).photoPath,
      'https://cdn.test/uploaded.jpg',
    );
    expect(find.textContaining('coffee conversation'), findsOneWidget);

    for (final label in ['Networking', 'Design', 'Deep']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(fakeApi.interestIds, ['design']);
    expect(fakeApi.purpose, 'networking');
    expect(find.text('Make your coffee meetup work for you'), findsOneWidget);

    await tester.tap(find.text('Start Coffee Meet'));
    await tester.pump();
    await tester.pump();
    expect(location(container), AppRoutes.coffeeReady);
    expect(fakeApi.preferences, {
      'minAge': 18,
      'maxAge': 100,
      'maxDistanceKm': 5,
      'conversationStyles': ['deep'],
    });
    expect(fakeApi.calls, [
      'saveProfile',
      'uploadPhoto',
      'setInterests',
      'setPurpose',
      'setPreferences',
    ]);

    // The local search request is still built from the same preferences.
    expect(container.read(searchControllerProvider), isNotNull);

    await tester.pump(const Duration(seconds: 2));
    expect(location(container), AppRoutes.searching);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a failed profile call keeps the user on screen 1 with an error',
      (tester) async {
    final fakeApi = FakeOnboardingApi(
      failWith: ApiException(0, "Couldn't reach the server"),
    );
    final container = await pumpApp(
      tester,
      overrides: [onboardingApiProvider.overrideWithValue(fakeApi)],
    );
    container
        .read(authControllerProvider.notifier)
        .debugSignIn(isNewUser: true, onboardingStep: OnboardingStep.profile);
    container
        .read(onboardingControllerProvider.notifier)
        .setPhoto('https://cdn.test/p.jpg');

    container.read(routerProvider).go(AppRoutes.onboardProfile);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Your given name'), 'Sam');
    await tester.enterText(find.widgetWithText(TextField, 'Years'), '29');
    await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Barista, Designer, Student'),
        'Designer');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(location(container), AppRoutes.onboardProfile);
    expect(find.text("Couldn't reach the server"), findsOneWidget);
  });
}
