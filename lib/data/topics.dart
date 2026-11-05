import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';
import 'models.dart';

/// A vocabulary topic. Word rows reference it by [id].
class Topic {
  const Topic({
    required this.id,
    required this.german,
    required this.english,
    required this.emoji,
    required this.color,
    required this.reasons,
  });

  final String id;
  final String german;
  final String english;
  final String emoji;
  final Color color;

  /// Learning reasons this topic is most useful for.
  final Set<LearningReason> reasons;

  static const all = [
    Topic(
      id: 'arbeit',
      german: 'Arbeit & Büro',
      english: 'Work & Office',
      emoji: '💼',
      color: AppColors.lavender,
      reasons: {LearningReason.work},
    ),
    Topic(
      id: 'uni',
      german: 'Uni & Schule',
      english: 'Study',
      emoji: '🎓',
      color: AppColors.der,
      reasons: {LearningReason.studies},
    ),
    Topic(
      id: 'zuhause',
      german: 'Zuhause',
      english: 'Home',
      emoji: '🏠',
      color: AppColors.das,
      reasons: {LearningReason.living},
    ),
    Topic(
      id: 'einkaufen',
      german: 'Einkaufen',
      english: 'Shopping',
      emoji: '🛒',
      color: AppColors.sunrise,
      reasons: {LearningReason.living, LearningReason.fun},
    ),
    Topic(
      id: 'essen',
      german: 'Essen & Trinken',
      english: 'Food & Drink',
      emoji: '🍽️',
      color: AppColors.poppy,
      reasons: {
        LearningReason.fun,
        LearningReason.living,
        LearningReason.studies,
      },
    ),
    Topic(
      id: 'stadt',
      german: 'In der Stadt',
      english: 'City & Transport',
      emoji: '🚋',
      color: AppColors.der,
      reasons: {LearningReason.living, LearningReason.work},
    ),
    Topic(
      id: 'gesundheit',
      german: 'Gesundheit',
      english: 'Health',
      emoji: '🩺',
      color: AppColors.das,
      reasons: {LearningReason.living, LearningReason.work},
    ),
    Topic(
      id: 'reisen',
      german: 'Reisen',
      english: 'Travel',
      emoji: '✈️',
      color: AppColors.lavender,
      reasons: {LearningReason.fun},
    ),
  ];

  static Topic? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Topics that match [reason] first, keeping the original order otherwise.
  static List<Topic> forReason(LearningReason? reason) {
    if (reason == null) return all;
    return [
      ...all.where((t) => t.reasons.contains(reason)),
      ...all.where((t) => !t.reasons.contains(reason)),
    ];
  }
}
