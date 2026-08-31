/// Order matches the actual screen-to-screen flow (see each onboarding
/// screen's continue handler), not the order routes.dart happens to list
/// them in — the auth guard relies on this order to find the first
/// unfinished step.
///
/// The optimized flow is three screens: build your profile, conversation
/// preferences, then coffee-meetup preferences. Notification permission is
/// deliberately not an onboarding step — it's requested contextually later
/// (after a match is confirmed / before a meeting).
enum OnboardingStep { profile, conversation, coffee, done }

class AuthState {
  final bool isSignedIn;
  final bool isNewUser;
  final String? pendingPhoneNumber;
  final OnboardingStep onboardingStep;

  const AuthState({
    this.isSignedIn = false,
    this.isNewUser = false,
    this.pendingPhoneNumber,
    this.onboardingStep = OnboardingStep.profile,
  });

  bool get isOnboardingComplete => !isNewUser || onboardingStep == OnboardingStep.done;

  AuthState copyWith({
    bool? isSignedIn,
    bool? isNewUser,
    String? pendingPhoneNumber,
    OnboardingStep? onboardingStep,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isNewUser: isNewUser ?? this.isNewUser,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}
