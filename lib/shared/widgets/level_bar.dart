import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../features/onboarding/onboarding_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A1 · A2 · B1 · B2 picker with progress in the chosen level. Switching
/// saves the level with the learner's [profile] (synced).
class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.profile});

  final OnboardingData profile;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final level = progress.studyLevel;
    final total = progress.levelTotal;
    final learned = progress.learnedAtLevel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final l in CefrLevel.values) ...[
              if (l != CefrLevel.values.first) const SizedBox(width: 8),
              Expanded(
                child: _LevelChip(
                  level: l,
                  selected: l == level,
                  onTap: () => progress.setStudyLevel(profile, l),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$learned of $total ${level.code} words learned',
          style: AppText.body(12.5, color: AppColors.creamMuted),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : learned / total,
            minHeight: 6,
            backgroundColor: AppColors.navyLine.withValues(alpha: 0.5),
            valueColor: const AlwaysStoppedAnimation(AppColors.mustard),
          ),
        ),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final CefrLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Level ${level.code}, selected' : 'Level ${level.code}',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.mustard
            : AppColors.navy800.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide.none
              : BorderSide(color: AppColors.navyLine.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: selected ? null : onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                level.code,
                style: AppText.body(
                  15,
                  weight: FontWeight.w800,
                  color: selected ? AppColors.navy : AppColors.cream,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Suggests the next level once 80 % of the current one is learned.
/// Shows nothing otherwise (or at B2).
class LevelUpCard extends StatelessWidget {
  const LevelUpCard({super.key, required this.profile});

  final OnboardingData profile;

  static const threshold = 0.8;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final level = progress.studyLevel;
    final next = level.next;
    final total = progress.levelTotal;
    if (next == null || total == 0) return const SizedBox.shrink();
    final share = progress.learnedAtLevel / total;
    if (share < threshold) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mustard.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.mustard),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for ${next.code}?',
                  style: AppText.body(
                    15.5,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
                Text(
                  "You've learned ${(share * 100).floor()}% of ${level.code}.",
                  style: AppText.body(13.5, color: AppColors.creamMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => progress.setStudyLevel(profile, next),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mustard,
              foregroundColor: AppColors.navy,
            ),
            child: Text('Start ${next.code}'),
          ),
        ],
      ),
    );
  }
}
