import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../shared/widgets/level_bar.dart';
import '../../shared/widgets/reveal.dart';
import '../onboarding/onboarding_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../home/widgets/home_cards.dart';
import '../lesson/lesson_screen.dart';
import 'quiz_screen.dart';

/// All the ways to practise, optionally narrowed to one topic.
class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key, required this.dailyGoal, this.profile});

  /// Learner profile, for the level picker (hidden without one).
  final OnboardingData? profile;

  /// Words per "learn new words" session.
  final int dailyGoal;

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  Topic? _topic;

  static const _modes = [
    PracticeMode.article,
    PracticeMode.meaning,
    PracticeMode.listening,
    PracticeMode.spelling,
  ];

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final due = progress.dueCount;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final newWords = progress.nextNewWords(widget.dailyGoal, topic: _topic);
    final learnedHere = (_topic?.words ?? vocabulary)
        .where(progress.isLearned)
        .length;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 20, 0, bottomInset + 24),
      children: [
        StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pad(
              Text(
                'Practice',
                style: AppText.display(28, color: AppColors.cream),
              ),
            ),
            const SizedBox(height: 2),
            _pad(
              Text(
                'Mix it up. Every answer helps you remember.',
                style: AppText.body(14, color: AppColors.creamMuted),
              ),
            ),
            if (widget.profile case final profile?) ...[
              const SizedBox(height: 16),
              _pad(LevelBar(profile: profile)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _Chip(
                    label: 'All topics',
                    selected: _topic == null,
                    onTap: () => setState(() => _topic = null),
                  ),
                  for (final t in [...Topic.packs, ...Topic.general])
                    _Chip(
                      label: t.english,
                      icon: t.isPack ? Icons.work_outline_rounded : null,
                      selected: _topic == t,
                      onTap: () => setState(() => _topic = t),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (due > 0 && _topic == null) ...[
              _pad(
                ReviewCard(
                  due: due,
                  onStart: () => Navigator.of(context).push(
                    LessonScreen.route(
                      progress.dueForReview(limit: 20),
                      review: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (learnedHere > 0) ...[
              _pad(
                ReviewAnytimeCard(
                  learned: learnedHere,
                  onStart: () => Navigator.of(context).push(
                    LessonScreen.route(
                      progress.reviewAnytime(topic: _topic),
                      review: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _pad(
              _LearnCard(
                topic: _topic,
                available: newWords.length,
                onStart: newWords.isEmpty
                    ? null
                    : () =>
                          Navigator.of(context)
                              .push(LessonScreen.route(newWords)),
              ),
            ),
            const SizedBox(height: 24),
            _pad(const SectionLabel('Practice modes')),
            const SizedBox(height: 12),
            _pad(
              Column(
                children: [
                  for (var r = 0; r < _modes.length; r += 2) ...[
                    if (r > 0) const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _modeCard(_modes[r])),
                          const SizedBox(width: 12),
                          Expanded(child: _modeCard(_modes[r + 1])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeCard(PracticeMode mode) => _ModeCard(
    mode: mode,
    onTap: () =>
        Navigator.of(context)
            .push(QuizScreen.route(context, mode, topic: _topic)),
  );

  static Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: child,
  );
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.topic,
    required this.available,
    required this.onStart,
  });

  final Topic? topic;
  final int available;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final done = onStart == null;
    return Pressable(
      onTap: onStart ?? () {},
      semanticLabel: 'Learn new words',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                done ? Icons.emoji_events_outlined : Icons.layers_outlined,
                color: AppColors.mustard,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'All words learned!' : 'Learn new words',
                    style: AppText.body(
                      16.5,
                      weight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done
                        ? 'You know every word in ${topic?.english ?? 'the app'}.'
                        : '$available words · ${topic?.english ?? 'most useful first'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13.5, color: AppColors.navy700),
                  ),
                ],
              ),
            ),
            if (!done)
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.mustardDeep,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final PracticeMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${mode.title}. ${mode.subtitle}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.mustard.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(mode.icon, size: 21, color: AppColors.mustard),
            ),
            const SizedBox(height: 14),
            Text(
              mode.title,
              style: AppText.body(
                15.5,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mode.subtitle,
              style: AppText.body(13, color: AppColors.creamMuted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.navy : AppColors.cream;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.cream
                  : AppColors.cream.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? AppColors.navy : AppColors.mustard,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.body(13.5, weight: FontWeight.w700, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
