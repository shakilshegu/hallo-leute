import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/onboarding_models.dart';

/// Holds the in-progress onboarding profile for the three optimized
/// onboarding screens. Local-only for the MVP — mirrors how the rest of the
/// onboarding flow currently works (nothing is POSTed to coffee-meet-api
/// yet). The final screen reads [OnboardingProfile.toMeetRequest] to start
/// the search.
class OnboardingController extends StateNotifier<OnboardingProfile> {
  OnboardingController() : super(const OnboardingProfile());

  void setPhoto(String? path) => state = state.copyWith(photoPath: path);

  void saveProfile({
    required String firstName,
    required String age,
    required String work,
    required String bio,
  }) {
    state = state.copyWith(
      firstName: firstName.trim(),
      age: age.trim(),
      work: work.trim(),
      bio: bio.trim(),
    );
  }

  void setPurpose(String purpose) => state = state.copyWith(purpose: purpose);

  void toggleInterest(String interest) {
    final next = [...state.interests];
    if (next.contains(interest)) {
      next.remove(interest);
    } else {
      if (next.length >= OnboardingProfile.maxInterests) return;
      next.add(interest);
    }
    state = state.copyWith(interests: next);
  }

  void setConversationStyle(String style) =>
      state = state.copyWith(conversationStyle: style);

  void setDistance(int km) => state = state.copyWith(distanceKm: km);

  void setMeetingLength(String length) =>
      state = state.copyWith(meetingLength: length);

  void setWhen(String when, {DateTime? chosenDate}) =>
      state = state.copyWith(when: when, chosenDate: chosenDate);

  void reset() => state = const OnboardingProfile();
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingProfile>((ref) {
  return OnboardingController();
});
