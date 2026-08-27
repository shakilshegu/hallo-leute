import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final String? learningGoal;
  final String? currentLevel;
  final String? motivation;
  final int? dailyGoalMinutes;
  final bool? notificationsEnabled;

  const OnboardingState({
    this.learningGoal,
    this.currentLevel,
    this.motivation,
    this.dailyGoalMinutes,
    this.notificationsEnabled,
  });

  OnboardingState copyWith({
    String? learningGoal,
    String? currentLevel,
    String? motivation,
    int? dailyGoalMinutes,
    bool? notificationsEnabled,
  }) {
    return OnboardingState(
      learningGoal: learningGoal ?? this.learningGoal,
      currentLevel: currentLevel ?? this.currentLevel,
      motivation: motivation ?? this.motivation,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void setLearningGoal(String goal) {
    state = state.copyWith(learningGoal: goal);
  }

  void setCurrentLevel(String level) {
    state = state.copyWith(currentLevel: level);
  }

  void setMotivation(String motivation) {
    state = state.copyWith(motivation: motivation);
  }

  void setDailyGoal(int minutes) {
    state = state.copyWith(dailyGoalMinutes: minutes);
  }

  void setNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
