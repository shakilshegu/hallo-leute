import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/main.dart';

import 'support/mock_network_images.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockNetworkImagesHttpOverrides();
  });
  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('app boots to the welcome screen when signed out',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meet someone new over coffee'), findsOneWidget);
  });
}
