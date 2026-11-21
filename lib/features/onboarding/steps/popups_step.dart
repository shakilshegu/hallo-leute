import 'package:flutter/material.dart';

import '../../../services/reminders.dart';
import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../widgets/onboarding_widgets.dart';

/// "A flashcard pops up on your phone": choose how many word pop-ups a day.
class PopupsStep extends StatelessWidget {
  const PopupsStep({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const options = [
    (3, 'A few', 'Recommended'),
    (5, 'Lots', null),
    (1, 'Just one', null),
    (0, 'Off', null),
  ];

  static String timesLabel(int perDay) {
    if (perDay == 0) return 'No pop-ups. You can turn them on later.';
    final times = popupTimes(perDay)
        .map((t) => '${t.$1}:${t.$2.toString().padLeft(2, '0')}')
        .join(' · ');
    return '$perDay a day · $times';
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      children: [
        const StepHeader(
          eyebrow: 'Wort für Wort',
          title: 'Learn while you use your phone',
          subtitle:
              'German words pop up like flashcards during the day. '
              'Swipe down to see the meaning.',
        ),
        const SizedBox(height: 20),
        const _PopupPreview(),
        const SizedBox(height: 20),
        for (final (count, title, badge) in options) ...[
          OptionCard(
            selected: selected == count,
            onTap: () => onSelect(count),
            leading: LeadingBadge(
              selected: selected == count,
              child: count == 0
                  ? const Icon(Icons.notifications_off_outlined, size: 20)
                  : Text('$count', style: AppText.display(19)),
            ),
            title: title,
            description: timesLabel(count),
            badge: badge,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// A mock notification so learners see what a pop-up looks like.
class _PopupPreview extends StatelessWidget {
  const _PopupPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy950.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  size: 13,
                  color: AppColors.mustard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hallo Leute · Word of the day',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    12,
                    weight: FontWeight.w700,
                    color: AppColors.navy700,
                  ),
                ),
              ),
              Text('now', style: AppText.body(12, color: AppColors.navy700)),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'der ',
                  style: AppText.display(19, color: AppColors.mustardDeep),
                ),
                TextSpan(
                  text: 'Bahnhof',
                  style: AppText.display(19, color: AppColors.navy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Swipe down to see the meaning',
            style: AppText.body(13.5, color: AppColors.navy700),
          ),
        ],
      ),
    );
  }
}
