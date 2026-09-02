import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/screens/verify_code_screen.dart';

void main() {
  testWidgets('typing digits fills the code boxes', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: VerifyCodeScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 350)); // autofocus delay

    // One real TextField backs the 6 boxes.
    expect(find.byType(TextField), findsOneWidget);

    await t.enterText(find.byType(TextField), '12345');
    await t.pump();

    // Each digit shows in its box.
    for (final d in ['1', '2', '3', '4', '5']) {
      expect(find.text(d), findsOneWidget);
    }
  });

  testWidgets('non-digits are rejected by the field', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: VerifyCodeScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 350));

    await t.enterText(find.byType(TextField), 'a1b2c');
    await t.pump();

    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '12');
  });

  testWidgets('Resend button starts on a countdown then enables', (t) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: VerifyCodeScreen()),
      ),
    );
    await t.pump(const Duration(milliseconds: 350));

    expect(find.textContaining('Resend code in'), findsOneWidget);

    await t.pump(const Duration(seconds: 31));
    expect(find.text('Resend Code'), findsOneWidget);

    // clean up the widget's periodic timer
    await t.pumpWidget(const SizedBox());
  });
}
