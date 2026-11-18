import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/app.dart';

void main() {
  testWidgets('landing shows brand promise and CTA after entrance', (
    tester,
  ) async {
    await tester.pumpWidget(const PoppyloApp());
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.text('Deutsch lernen · A1 – B2'), findsOneWidget);
    expect(find.text("Los geht's"), findsOneWidget);
    expect(find.bySemanticsLabel('Poppylo'), findsOneWidget);
  });

  testWidgets('CTA opens onboarding', (tester) async {
    await tester.pumpWidget(const PoppyloApp());
    await tester.pump(const Duration(milliseconds: 2600));

    await tester.ensureVisible(find.text("Los geht's"));
    await tester.tap(find.text("Los geht's"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('What should we call you?'), findsOneWidget);
  });

  testWidgets('reduced motion shows everything immediately', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: PoppyloApp(),
      ),
    );
    await tester.pump();

    final cta = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text("Los geht's"),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(cta.opacity.value, 1.0);
  });

  testWidgets('fits a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PoppyloApp());
    await tester.pump(const Duration(milliseconds: 2600));

    expect(tester.takeException(), isNull);
  });
}
