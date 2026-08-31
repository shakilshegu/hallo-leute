import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/screens/edit_profile_screen.dart';
import 'package:poppylo/services/profile_api.dart';

import '../support/fake_profile_api.dart';
import '../support/mock_network_images.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  Future<GoRouter> pump(WidgetTester tester, FakeProfileApi fake) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/edit', builder: (_, __) => const EditProfileScreen()),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileApiProvider.overrideWithValue(fake)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('prefills from GET /users/me and saves the edited fields',
      (tester) async {
    final fake = FakeProfileApi(sampleUserMe());
    final router = await pump(tester, fake);

    // name field is prefilled with "Aisha"
    expect(find.text('Aisha'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Aisha K');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(fake.updatedProfile!['firstName'], 'Aisha K');
    expect(fake.updatedProfile!['age'], 27);
    expect(fake.updatedProfile!['job'], 'Product Designer');
    expect(fake.interestIds, containsAll(<String>['design', 'startups']));
    expect(fake.purpose, 'networking');
    expect(fake.calls, containsAllInOrder(<String>['getMe', 'updateProfile']));

    // returned to the previous route after a successful save
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/',
    );
  });

  testWidgets('a blank name blocks the save', (tester) async {
    final fake = FakeProfileApi(sampleUserMe());
    await pump(tester, fake);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Add your name'), findsOneWidget);
    expect(fake.updatedProfile, isNull);
  });
}
