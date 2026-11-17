import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/onboarding_data.dart';
import '../progress.dart';
import '../remote/backend_config.dart';
import '../sync/sync_service.dart';

/// What happened after a sign-in step.
enum SignInOutcome {
  /// The guest account now has a login; same user, nothing moved.
  linked,

  /// Signed in to an account that already existed; this phone's progress
  /// was merged into it.
  switchedAccount,

  /// The user closed the Google sheet.
  cancelled,
}

/// Accounts: every learner starts as an anonymous guest (tracked from day
/// one) and can later attach Google or email to the same account.
class AuthService extends ChangeNotifier {
  AuthService({
    required this.client,
    required this.progress,
    required this.sync,
  }) {
    _sub = client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient client;
  final LearningProgress progress;
  final SyncService sync;
  late final StreamSubscription<AuthState> _sub;

  bool _googleReady = false;

  /// Email waiting for its 6-digit code, and whether it links the guest
  /// (email change) or signs in to an existing account.
  String? _pendingEmail;
  bool _pendingIsLink = true;

  User? get user => client.auth.currentUser;
  bool get hasSession => user != null;
  bool get isGuest => user?.isAnonymous ?? true;
  String? get email => user?.email;
  bool get canUseGoogle => BackendConfig.googleConfigured;

  /// Creates the anonymous guest account if there is no session yet.
  /// Needs a connection; quietly retried by sync later when offline.
  Future<void> ensureGuest() async {
    if (hasSession) return;
    try {
      await client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('Guest sign-in postponed: $e');
    }
  }

  // ───────────────────────────── Google ─────────────────────────────

  Future<SignInOutcome> continueWithGoogle() async {
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize(
        serverClientId: BackendConfig.googleWebClientId,
      );
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return SignInOutcome.cancelled;
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException('Google gave no ID token');

    await ensureGuest();
    if (hasSession && isGuest) {
      try {
        // Same user id keeps everything the guest has learned.
        await client.auth.linkIdentityWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
        await client.auth.refreshSession();
        return SignInOutcome.linked;
      } on AuthException catch (e) {
        if (e.code != ErrorCode.identityAlreadyExists.code) rethrow;
        // This Google account already has progress: sign in to it below.
      }
    }
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    await _afterAccountSwitch();
    return SignInOutcome.switchedAccount;
  }

  // ───────────────────────────── Email code ─────────────────────────────

  /// Sends a 6-digit code to [email].
  Future<void> sendEmailCode(String email) async {
    final address = email.trim().toLowerCase();
    await ensureGuest();
    if (hasSession && isGuest) {
      try {
        // Attach the email to the guest account (same user id).
        await client.auth.updateUser(UserAttributes(email: address));
        _pendingEmail = address;
        _pendingIsLink = true;
        return;
      } on AuthException catch (e) {
        if (e.code != ErrorCode.emailExists.code) rethrow;
        // Email already has an account: send a normal sign-in code.
      }
    }
    await client.auth.signInWithOtp(email: address, shouldCreateUser: true);
    _pendingEmail = address;
    _pendingIsLink = false;
  }

  /// Confirms the code from the email.
  Future<SignInOutcome> verifyEmailCode(String code) async {
    final address = _pendingEmail;
    if (address == null) throw StateError('Send a code first');
    await client.auth.verifyOTP(
      email: address,
      token: code.trim(),
      type: _pendingIsLink ? OtpType.emailChange : OtpType.email,
    );
    _pendingEmail = null;
    if (_pendingIsLink) {
      await client.auth.refreshSession();
      return SignInOutcome.linked;
    }
    await _afterAccountSwitch();
    return SignInOutcome.switchedAccount;
  }

  Future<void> _afterAccountSwitch() async {
    final profile = await sync.mergeFromServer();
    if (profile != null) await progress.saveProfile(profile);
    notifyListeners();
  }

  // ─────────────────────── sign out / delete ───────────────────────

  /// Signs out and wipes this phone's copy (it is safe on the server).
  Future<void> signOut() async {
    await sync.flush();
    await client.auth.signOut();
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _wipeLocal();
  }

  /// Permanently deletes the account and all its data (server and phone).
  Future<void> deleteAccount() async {
    await client.rpc<void>('delete_my_account');
    await client.auth.signOut();
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _wipeLocal();
  }

  Future<void> _wipeLocal() async {
    await sync.clear();
    await progress.reset();
    await progress.store?.remove(LearningProgress.profileKey);
    notifyListeners();
  }

  /// Saves onboarding answers and makes sure the guest account exists.
  Future<void> onboarded(OnboardingData profile) async {
    await ensureGuest();
    await progress.saveProfile(profile);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Provides [AuthService] to the widget tree. Null when no backend is
/// configured (offline-only builds).
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService? auth, required super.child})
    : super(notifier: auth);

  static AuthService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
