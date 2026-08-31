import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/state/auth_controller.dart';

import '../support/fake_onboarding_api.dart';

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth(this._user);
  User? _user;
  bool signedOut = false;

  @override
  User? get currentUser => _user;

  @override
  Future<void> signOut() async {
    signedOut = true;
    _user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('no Firebase session → signed out', () async {
    final auth = AuthController(_FakeFirebaseAuth(null));

    await auth.restoreSession(FakeOnboardingApi());

    expect(auth.state.isSignedIn, isFalse);
  });

  test('valid session + completed onboarding → straight to home', () async {
    final auth = AuthController(_FakeFirebaseAuth(_FakeUser()));

    await auth.restoreSession(FakeOnboardingApi(onboardingCompleted: true));

    expect(auth.state.isSignedIn, isTrue);
    expect(auth.state.isOnboardingComplete, isTrue);
    expect(auth.state.onboardingStep, OnboardingStep.done);
  });

  test('valid session + incomplete onboarding → back to step one', () async {
    final auth = AuthController(_FakeFirebaseAuth(_FakeUser()));

    await auth.restoreSession(FakeOnboardingApi(onboardingCompleted: false));

    expect(auth.state.isSignedIn, isTrue);
    expect(auth.state.isNewUser, isTrue);
    expect(auth.state.onboardingStep, OnboardingStep.profile);
  });

  test('stale token (401) → sign out of Firebase and drop the session',
      () async {
    final fb = _FakeFirebaseAuth(_FakeUser());
    final auth = AuthController(fb);

    await auth.restoreSession(
      FakeOnboardingApi(failWith: ApiException(401, 'expired')),
    );

    expect(auth.state.isSignedIn, isFalse);
    expect(fb.signedOut, isTrue);
  });

  test('backend unreachable but session valid → let the returning user in',
      () async {
    final auth = AuthController(_FakeFirebaseAuth(_FakeUser()));

    await auth.restoreSession(
      FakeOnboardingApi(failWith: ApiException(0, 'offline')),
    );

    expect(auth.state.isSignedIn, isTrue);
    expect(auth.state.isNewUser, isFalse);
    expect(auth.state.onboardingStep, OnboardingStep.done);
  });
}
