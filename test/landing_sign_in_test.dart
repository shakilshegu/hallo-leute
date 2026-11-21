import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/app.dart';
import 'package:hallo_leute/data/auth/auth_service.dart';
import 'package:hallo_leute/data/local_store.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:hallo_leute/features/home/home_screen.dart';

/// Signed-out learner. Google sign-in loads the account's saved profile
/// (when [serverProfile] is set), like the real merge from the server.
class _FakeAuth extends ChangeNotifier implements AuthService {
  _FakeAuth(this.progress, {this.serverProfile});

  @override
  final LearningProgress progress;

  final Map<String, Object?>? serverProfile;
  bool signedIn = false;

  @override
  bool get isGuest => !signedIn;

  @override
  bool get hasSession => signedIn;

  @override
  bool get canUseGoogle => true;

  @override
  String? get email => null;

  @override
  Future<SignInOutcome> continueWithGoogle() async {
    signedIn = true;
    final profile = serverProfile;
    if (profile != null) {
      await progress.store!.write(
        LearningProgress.profileKey,
        jsonEncode(profile),
      );
    }
    notifyListeners();
    return SignInOutcome.switchedAccount;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openSignIn(WidgetTester tester, _FakeAuth auth) async {
  await tester.pumpWidget(HalloLeuteApp(progress: auth.progress, auth: auth));
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.ensureVisible(find.text('Already learning? Sign in'));
  await tester.tap(find.text('Already learning? Sign in'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  testWidgets('sign in with Google on landing opens Home with the profile', (
    tester,
  ) async {
    final auth = _FakeAuth(
      LearningProgress(store: MemoryStore()),
      serverProfile: {'name': 'Anoop', 'dailyGoal': 'regular'},
    );
    await _openSignIn(tester, auth);

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await _frames(tester);

    expect(auth.signedIn, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(home.profile.name, 'Anoop');
  });

  testWidgets('an account without a profile starts onboarding', (tester) async {
    final auth = _FakeAuth(LearningProgress(store: MemoryStore()));
    await _openSignIn(tester, auth);

    await tester.tap(find.text('Continue with Google'));
    await _frames(tester);

    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('What should we call you?'), findsOneWidget);
  });
}
