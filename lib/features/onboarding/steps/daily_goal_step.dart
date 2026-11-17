import 'package:flutter/material.dart';

import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_text.dart';
import '../onboarding_data.dart';
import '../widgets/onboarding_widgets.dart';

class DailyGoalStep extends StatelessWidget {
  const DailyGoalStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final DailyGoal selected;
  final ValueChanged<DailyGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      children: [
        const StepHeader(
          eyebrow: 'Jeden Tag',
          title: 'Set your daily goal',
          subtitle: 'Small steps every day beat cramming.',
        ),
        const SizedBox(height: 24),
        for (final goal in DailyGoal.values) ...[
          OptionCard(
            selected: selected == goal,
            onTap: () => onSelect(goal),
            leading: LeadingBadge(
              selected: selected == goal,
              child: Text('${goal.words}', style: AppText.display(19)),
            ),
            title: goal.title,
            description:
                '${goal.words} words · about ${goal.minutes} min a day',
            badge: goal == DailyGoal.regular ? 'Recommended' : null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
