import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/auth/auth_service.dart';
import 'package:hallo_leute/features/landing/landing_screen.dart';
import 'package:hallo_leute/features/profile/account_card.dart';

/// Signed-in account that turns into a guest when signed out or deleted,
/// like the real one does when Supabase reports the change.
class _FakeAuth extends ChangeNotifier implements AuthService {
  bool _guest = false;

  @override
  bool get isGuest => _guest;

  @override
  String? get email => 'learner@example.com';

  @override
  bool get canUseGoogle => true;

  // Supabase reports the sign-out (the card swaps to the guest card) a
  // moment before the network calls finish.
  Future<void> _becomeGuest() async {
    _guest = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
  }

  @override
  Future<void> signOut() => _becomeGuest();

  @override
  Future<void> deleteAccount() => _becomeGuest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpCard(WidgetTester tester, _FakeAuth auth) async {
  await tester.pumpWidget(
    AuthScope(
      auth: auth,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: AccountCard(auth: AuthScope.maybeOf(context)!),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('signing out returns to the landing screen', (tester) async {
    final auth = _FakeAuth();
    await _pumpCard(tester, auth);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    // The dialog's confirm button is the last "Sign out" on screen.
    await tester.tap(find.text('Sign out').last);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(auth.isGuest, isTrue);
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('deleting the account returns to the landing screen', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await _pumpCard(tester, auth);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(auth.isGuest, isTrue);
    expect(find.byType(LandingScreen), findsOneWidget);
  });
}
