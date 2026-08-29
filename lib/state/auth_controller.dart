import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/auth_models.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  void startPhoneVerification(String phoneNumber) {
    state = state.copyWith(pendingPhoneNumber: phoneNumber);
  }

  void verifyCode() {
    state = state.copyWith(isSignedIn: true);
  }

  /// Email/password login for a returning user — unlike phone verification,
  /// this skips onboarding entirely since the account already exists.
  void signInExistingUser() {
    state = state.copyWith(
      isSignedIn: true,
      onboardingStep: OnboardingStep.done,
    );
  }

  void completeOnboardingStep(OnboardingStep next) {
    state = state.copyWith(onboardingStep: next);
  }

  void signOut() {
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
