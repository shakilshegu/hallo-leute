import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/auth_models.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController([this._injectedFirebaseAuth]) : super(const AuthState());

  // Resolved lazily — not at construction — so building an AuthController
  // (which happens on every screen/guard that reads this provider) doesn't
  // require Firebase.initializeApp() to have run, e.g. in widget tests that
  // never touch the phone-auth methods below.
  final FirebaseAuth? _injectedFirebaseAuth;
  FirebaseAuth get _firebaseAuth => _injectedFirebaseAuth ?? FirebaseAuth.instance;
  String? _verificationId;

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
    state = state.copyWith(pendingPhoneNumber: phoneNumber, isNewUser: isNewUser);
    final completer = Completer<void>();

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
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

  void completeOnboardingStep(OnboardingStep next) {
    state = state.copyWith(onboardingStep: next);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
