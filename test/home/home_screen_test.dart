import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/screens/home_screen.dart';
import 'package:poppylo/services/profile_api.dart';

import '../support/fake_profile_api.dart';
import '../support/mock_network_images.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('greets the signed-in user by their real first name',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileApiProvider.overrideWithValue(
              FakeProfileApi(sampleUserMe(firstName: 'Nadia'))),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nadia'), findsOneWidget);
    expect(find.text('Good morning, Aisha'), findsNothing);
  });

  testWidgets('falls back to a plain greeting while the profile loads',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileApiProvider.overrideWithValue(_NeverProfileApi()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data == 'Good morning' ||
              w.data == 'Good afternoon' ||
              w.data == 'Good evening')),
      findsOneWidget,
    );
  });
}

class _NeverProfileApi extends FakeProfileApi {
  _NeverProfileApi() : super(sampleUserMe());

  @override
  Future<UserMe> getMe() => Completer<UserMe>().future;
}
