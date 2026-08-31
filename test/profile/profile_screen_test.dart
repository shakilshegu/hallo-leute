import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/screens/profile_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/profile_api.dart';

import '../support/fake_profile_api.dart';
import '../support/mock_network_images.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  Future<void> pump(WidgetTester tester, FakeProfileApi fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileApiProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the real profile from GET /users/me', (tester) async {
    await pump(tester, FakeProfileApi(sampleUserMe()));

    expect(find.text('Aisha, 27'), findsOneWidget);
    expect(find.text('Product Designer'), findsOneWidget);
    expect(find.text('Coffee and design.'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Startups'), findsOneWidget);
    // purpose "networking" -> "Networking"
    expect(find.text('Networking'), findsOneWidget);
    expect(find.text('Within 5 km • Ages 24–36'), findsOneWidget);
  });

  testWidgets('shows a retry action when the API errors', (tester) async {
    await pump(
      tester,
      FakeProfileApi(sampleUserMe(), failWith: ApiException(0, 'offline')),
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
