import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/auth_models.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  void startPhoneVerification(String phoneNumber, {bool isNewUser = false}) {
    state = state.copyWith(pendingPhoneNumber: phoneNumber, isNewUser: isNewUser);
  }

  void verifyCode() {
    state = state.copyWith(isSignedIn: true);
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
