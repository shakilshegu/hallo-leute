import 'package:flutter/material.dart';

import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_text.dart';
import '../onboarding_data.dart';
import '../widgets/onboarding_widgets.dart';

class LevelStep extends StatelessWidget {
  const LevelStep({super.key, required this.selected, required this.onSelect});

  final GermanLevel? selected;
  final ValueChanged<GermanLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      children: [
        const StepHeader(
          eyebrow: 'Dein Niveau',
          title: 'How much German do you know?',
          subtitle: "No pressure – we'll adjust as you learn.",
        ),
        const SizedBox(height: 24),
        for (final level in GermanLevel.values) ...[
          OptionCard(
            selected: selected == level,
            onTap: () => onSelect(level),
            leading: LeadingBadge(
              selected: selected == level,
              child: Text(level.code, style: AppText.display(17)),
            ),
            title: level.title,
            description: level.description,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
