import 'package:flutter/material.dart';

import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../onboarding_data.dart';
import '../widgets/onboarding_widgets.dart';

class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.selected, required this.onToggle});

  final Set<LearningGoal> selected;
  final ValueChanged<LearningGoal> onToggle;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      children: [
        const StepHeader(
          eyebrow: 'Warum Deutsch?',
          title: 'Why are you learning German?',
          subtitle: 'Pick as many as you like.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final tileWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final goal in LearningGoal.values)
                  SizedBox(
                    width: tileWidth,
                    child: _GoalTile(
                      goal: goal,
                      selected: selected.contains(goal),
                      onTap: () => onToggle(goal),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final LearningGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableSurface(
      selected: selected,
      onTap: onTap,
      semanticLabel: '${goal.label}, in German ${goal.german}',
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeadingBadge(
                selected: selected,
                width: 42,
                child: Icon(goal.icon, size: 20),
              ),
              const Spacer(),
              SelectionTick(selected: selected, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            goal.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              15,
              weight: FontWeight.w800,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            goal.german,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              13,
              color: selected ? AppColors.mustard : AppColors.creamMuted,
            ),
          ),
        ],
      ),
    );
  }
}
