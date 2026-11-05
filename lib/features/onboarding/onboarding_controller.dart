import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';

enum OnboardingStep { name, reason, level, goal, celebrate }

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.name,
    this.forward = true,
    this.name = '',
    this.reason,
    this.level,
    this.levelUnsure = false,
    this.dailyGoal,
    this.saving = false,
  });

  final OnboardingStep step;

  /// Direction of the last step change (for the slide animation).
  final bool forward;
  final String name;
  final LearningReason? reason;
  final CefrLevel? level;
  final bool levelUnsure;
  final int? dailyGoal;
  final bool saving;

  /// Number of question steps (the celebration is not counted).
  static const questionCount = 4;

  bool get canContinue => switch (step) {
    OnboardingStep.name => name.trim().isNotEmpty,
    OnboardingStep.reason => reason != null,
    OnboardingStep.level => level != null,
    OnboardingStep.goal => dailyGoal != null && !saving,
    OnboardingStep.celebrate => true,
  };

  String? get displayName => name.trim().isEmpty ? null : name.trim();

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? forward,
    String? name,
    LearningReason? reason,
    CefrLevel? level,
    bool? levelUnsure,
    int? dailyGoal,
    bool? saving,
  }) => OnboardingState(
    step: step ?? this.step,
    forward: forward ?? this.forward,
    name: name ?? this.name,
    reason: reason ?? this.reason,
    level: level ?? this.level,
    levelUnsure: levelUnsure ?? this.levelUnsure,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    saving: saving ?? this.saving,
  );
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setName(String name) => state = state.copyWith(name: name);

  void setReason(LearningReason reason) =>
      state = state.copyWith(reason: reason);

  void setLevel(CefrLevel level, {bool unsure = false}) =>
      state = state.copyWith(level: level, levelUnsure: unsure);

  void setDailyGoal(int words) => state = state.copyWith(dailyGoal: words);

  /// Skips the name step without a name.
  void skipName() {
    state = state.copyWith(name: '');
    next();
  }

  void next() {
    final i = state.step.index;
    if (i < OnboardingStep.values.length - 1) {
      state = state.copyWith(step: OnboardingStep.values[i + 1], forward: true);
    }
  }

  /// Returns `false` when already on the first step.
  bool back() {
    final i = state.step.index;
    if (i == 0 || state.step == OnboardingStep.celebrate) return false;
    state = state.copyWith(step: OnboardingStep.values[i - 1], forward: false);
    return true;
  }

  /// Saves the profile on the device and moves to the celebration.
  Future<void> finish() async {
    final s = state;
    if (s.reason == null || s.level == null || s.dailyGoal == null) return;
    state = s.copyWith(saving: true);
    await ref
        .read(databaseProvider)
        .saveProfile(
          ProfilesCompanion.insert(
            name: Value(s.displayName),
            reason: s.reason!,
            level: s.level!,
            dailyGoal: s.dailyGoal!,
          ),
        );
    ref.invalidate(profileProvider);
    state = state.copyWith(saving: false);
    next();
  }
}

final onboardingProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
