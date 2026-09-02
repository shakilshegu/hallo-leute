import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/auth_api.dart';
import 'package:poppylo/services/onboarding_api.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController([this._injectedFirebaseAuth]) : super(const AuthState());

  // Resolved lazily — not at construction — so building an AuthController
  // (which happens on every screen/guard that reads this provider) doesn't
  // require Firebase.initializeApp() to have run, e.g. in widget tests that
  // never touch the phone-auth methods below.
  final FirebaseAuth? _injectedFirebaseAuth;
  FirebaseAuth get _firebaseAuth =>
      _injectedFirebaseAuth ?? FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Test-only: sets signed-in state directly, bypassing real Firebase
  /// phone auth entirely. Use this in tests instead of the methods below.
  @visibleForTesting
  void debugSignIn({
    required bool isNewUser,
    OnboardingStep onboardingStep = OnboardingStep.done,
  }) {
    state = state.copyWith(
      isSignedIn: true,
      isNewUser: isNewUser,
      onboardingStep: onboardingStep,
    );
  }

  /// Starts real Firebase phone verification for [phoneNumber] (must be in
  /// E.164 format, e.g. +15551234567). Resolves once a code has been sent —
  /// or throws if Firebase rejects the number outright. On some Android
  /// devices Firebase can silently auto-verify via SMS retrieval before a
  /// code is ever shown; when that happens this also completes, and
  /// [AuthState.isSignedIn] is already true by the time it resolves, so the
  /// caller should check that before navigating to the OTP screen.
  Future<void> sendVerificationCode(
    String phoneNumber, {
    required bool isNewUser,
  }) {
    state =
        state.copyWith(pendingPhoneNumber: phoneNumber, isNewUser: isNewUser);
    return _requestCode(phoneNumber);
  }

  /// Ask Firebase to send a fresh code to the number already being verified.
  /// Used by the OTP screen's "Resend" button when the first SMS is slow.
  /// Passes `forceResendingToken` so Firebase treats it as a real resend.
  Future<void> resendCode() {
    final phoneNumber = state.pendingPhoneNumber;
    if (phoneNumber == null) {
      return Future.error(Exception('No number to resend to — start again.'));
    }
    return _requestCode(phoneNumber, forceResend: true);
  }

  Future<void> _requestCode(String phoneNumber, {bool forceResend = false}) {
    final completer = Completer<void>();

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // Longer window so Android SMS auto-retrieval still fires when the
      // carrier is slow to deliver (common for +91 numbers).
      timeout: const Duration(seconds: 120),
      forceResendingToken: forceResend ? _resendToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _firebaseAuth.signInWithCredential(credential);
          state = state.copyWith(isSignedIn: true);
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(e.message ?? 'Could not send a code to that number.'),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Confirms the 6-digit code the user typed. Throws on a wrong/expired
  /// code; callers should catch and show the message.
  Future<void> confirmVerificationCode(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw Exception('That code expired — request a new one.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "That code didn't work — try again.");
    }
    state = state.copyWith(isSignedIn: true);
  }

  /// Cold-start login: if Firebase still holds a session, re-establish it with
  /// the backend so the user skips OTP. Called once before the router mounts.
  ///
  ///  - no Firebase session      → signed out (Welcome)
  ///  - session + `/auth/sync` ok → routed by the backend's onboarding status
  ///  - session + 401            → stale token, sign out (Welcome)
  ///  - session + backend down   → let the returning user in; the profile
  ///    screens re-sync once they're online
  Future<void> restoreSession(OnboardingApi api) async {
    User? user;
    try {
      user = _firebaseAuth.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) {
      state = const AuthState();
      return;
    }

    // A Firebase session exists — treat the user as signed in straight away so
    // a slow / cold backend can't hold them on the splash or bounce them to
    // Welcome. `applyBackendSync` below refines the exact onboarding step, and
    // the router re-runs its guards when it does.
    _keepReturningUser();

    try {
      final sync = await api.syncUser();
      applyBackendSync(onboardingCompleted: sync.onboardingCompleted);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        try {
          await _firebaseAuth.signOut();
        } catch (_) {}
        state = const AuthState();
      } else {
        _keepReturningUser();
      }
    } catch (_) {
      // Any other failure (Firebase couldn't refresh the token, etc.) — a
      // valid Firebase session still exists, so don't bounce them to Welcome.
      _keepReturningUser();
    }
  }

  /// A Firebase session exists but we couldn't confirm onboarding status with
  /// the backend — let the user straight into the app; the home/profile
  /// screens re-sync once they're online.
  void _keepReturningUser() {
    state = state.copyWith(
      isSignedIn: true,
      isNewUser: false,
      onboardingStep: OnboardingStep.done,
    );
  }

  void completeOnboardingStep(OnboardingStep next) {
    state = state.copyWith(onboardingStep: next);
  }

  /// Applies the authoritative onboarding status from `POST /auth/sync`.
  /// A completed user is treated as a returning user (straight to home);
  /// anyone else is put back at the start of the 3-step onboarding.
  void applyBackendSync({required bool onboardingCompleted}) {
    state = state.copyWith(
      isSignedIn: true,
      isNewUser: !onboardingCompleted,
      onboardingStep:
          onboardingCompleted ? OnboardingStep.done : OnboardingStep.profile,
    );
  }

  Future<void> signOut({AuthApi? authApi}) async {
    // Best-effort server-side revocation; never block sign-out on it.
    if (authApi != null) {
      try {
        await authApi.logout();
      } catch (_) {}
    }
    await _firebaseAuth.signOut();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// A one-line note to show right after phone verification when the path the
/// user picked on the welcome screen (Log in vs Get started) doesn't match
/// what the backend actually found. Both cases still continue normally — the
/// message is just so the user isn't confused about where they landed.
///
///  - picked "Log in" but no account existed  -> one was just created for them
///  - picked "Get started" but a finished account was already there -> logged in
///
/// [intendedSignup] is `AuthState.isNewUser` as set from the welcome screen
/// (read it BEFORE `applyBackendSync`, which overwrites it).
String? postAuthNotice({
  required bool intendedSignup,
  required bool isNewUser,
  required bool onboardingCompleted,
}) {
  if (!intendedSignup && isNewUser) {
    return "You don't have an account yet — let's set one up.";
  }
  if (intendedSignup && onboardingCompleted) {
    return 'You already have an account — welcome back.';
  }
  return null;
}
