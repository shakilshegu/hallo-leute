import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/progress.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../home_content.dart';

/// Mon–Sun strip (German day names). Tap a day to see how long you studied,
/// how many words you learned, and a friendly note.
class WeekSection extends StatefulWidget {
  const WeekSection({
    super.key,
    required this.today,
    required this.name,
    required this.dailyGoal,
  });

  final DateTime today;
  final String name;
  final int dailyGoal;

  @override
  State<WeekSection> createState() => _WeekSectionState();
}

class _WeekSectionState extends State<WeekSection> {
  late int _selected = widget.today.weekday; // 1 = Monday

  DateTime get _monday => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day - widget.today.weekday + 1,
  );

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final practised = progress.practisedThisWeek;
    final day = DateTime(
      _monday.year,
      _monday.month,
      _monday.day + _selected - 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 7; i++)
              Expanded(
                child: _Day(
                  label: germanWeekdays[i - 1],
                  isToday: widget.today.weekday == i,
                  done: practised.contains(i),
                  future: i > widget.today.weekday,
                  selected: _selected == i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = i);
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _DayDetail(
              key: ValueKey(_selected),
              day: day,
              isToday: _selected == widget.today.weekday,
              future: _selected > widget.today.weekday,
              seconds: progress.secondsOn(day),
              learned: progress.wordsLearnedOn(day),
              answers: progress.activity[day]?.answers ?? 0,
              name: widget.name,
              dailyGoal: widget.dailyGoal,
            ),
          ),
        ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.label,
    required this.isToday,
    required this.done,
    required this.future,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool isToday;
  final bool done;
  final bool future;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Text(
                label,
                style: AppText.body(
                  12.5,
                  weight: isToday || selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isToday || selected
                      ? AppColors.cream
                      : AppColors.creamMuted,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.mustard
                      : AppColors.cream.withValues(alpha: future ? 0.03 : 0.06),
                  border: selected
                      ? Border.all(color: AppColors.cream, width: 2)
                      : isToday && !done
                      ? Border.all(color: AppColors.mustard, width: 1.6)
                      : null,
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppColors.navy,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({
    super.key,
    required this.day,
    required this.isToday,
    required this.future,
    required this.seconds,
    required this.learned,
    required this.answers,
    required this.name,
    required this.dailyGoal,
  });

  final DateTime day;
  final bool isToday;
  final bool future;
  final int seconds;
  final int learned;
  final int answers;
  final String name;
  final int dailyGoal;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String studyTime(int seconds) {
    if (seconds <= 0) return '0 min';
    if (seconds < 60) return 'under 1 min';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60, m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  (String, String) get _message {
    final you = name.isEmpty ? '' : ', $name';
    final studied = seconds > 0 || answers > 0;
    if (future) return ('🌱', 'Coming up. See you then$you!');
    if (!studied && isToday) {
      return (
        '🔥',
        'Nothing yet today. One short lesson keeps your streak going$you!',
      );
    }
    if (!studied) {
      return ('🌙', 'No study this day. No problem$you, take your time.');
    }
    if (learned >= dailyGoal) {
      return ('🎉', 'Goal reached! Wunderbar$you, keep it up!');
    }
    return ('💪', 'Well done$you! Keep going.');
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, text) = _message;
    final title =
        '${isToday ? 'Today · ' : ''}${_days[day.weekday - 1]}, '
        '${day.day} ${_months[day.month - 1]}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.body(
              13,
              weight: FontWeight.w800,
              color: AppColors.creamMuted,
            ),
          ),
          if (!future) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.timer_outlined,
                    value: studyTime(seconds),
                    label: 'studied',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    icon: Icons.menu_book_rounded,
                    value: '$learned',
                    label: learned == 1 ? 'word learned' : 'words learned',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '$emoji  $text',
            style: AppText.body(
              14.5,
              weight: FontWeight.w700,
              color: AppColors.cream,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mustard),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: value,
              style: AppText.display(18, color: AppColors.cream),
              children: [
                TextSpan(
                  text: '  $label',
                  style: AppText.body(13, color: AppColors.creamMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
