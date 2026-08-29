/// Order matches the actual screen-to-screen flow (see each onboarding
/// screen's continue handler), not the order routes.dart happens to list
/// them in — the auth guard relies on this order to find the first
/// unfinished step.
enum OnboardingStep { profile, interests, preferences, purpose, notifications, done }

class AuthState {
  final bool isSignedIn;
  final String? pendingPhoneNumber;
  final OnboardingStep onboardingStep;

  const AuthState({
    this.isSignedIn = false,
    this.pendingPhoneNumber,
    this.onboardingStep = OnboardingStep.profile,
  });

  bool get isOnboardingComplete => onboardingStep == OnboardingStep.done;

  AuthState copyWith({
    bool? isSignedIn,
    String? pendingPhoneNumber,
    OnboardingStep? onboardingStep,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}
