import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../shared/widgets/reveal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../lesson/lesson_screen.dart';
import '../onboarding/onboarding_data.dart';
import 'home_content.dart';
import 'widgets/home_cards.dart';
import 'widgets/week_section.dart';
import 'widgets/words_of_day.dart';

/// Daily hub: greeting, today's goal, words of the day, week, topics.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.profile,
    required this.today,
    required this.onOpenTopic,
    required this.onOpenProfile,
  });

  final OnboardingData profile;
  final DateTime today;
  final ValueChanged<Topic> onOpenTopic;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final (greeting, greetingEnglish) = greetingFor(today);
    final name = profile.name.trim();
    final daily = profile.dailyGoal;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final progress = ProgressScope.of(context);
    final streak = progress.streak;
    final dueCount = progress.dueCount;
    final todaysWords = wordsForDay(today);

    return ListView(
      padding: EdgeInsets.fromLTRB(0, 20, 0, bottomInset + 24),
      children: [
        StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _padded(
              _Header(
                greeting: name.isEmpty ? greeting : '$greeting, $name',
                translation: greetingEnglish,
                initial: name.isEmpty
                    ? null
                    : name.characters.first.toUpperCase(),
                onAvatarTap: onOpenProfile,
              ),
            ),
            const SizedBox(height: 24),
            _padded(
              TodayCard(
                learned: progress.learnedToday,
                goal: daily.words,
                minutes: daily.minutes,
                onStart: () {
                  final words = progress.nextNewWords(daily.words);
                  if (words.isEmpty) return;
                  Navigator.of(context).push(LessonScreen.route(words));
                },
              ),
            ),
            // Always present (keeps the staggered entrance stable); it only
            // takes space when words are due for review.
            _padded(
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: dueCount == 0
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ReviewCard(
                          due: dueCount,
                          onStart: () => Navigator.of(context).push(
                            LessonScreen.route(
                              progress.dueForReview(limit: 20),
                              review: true,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            _padded(
              SectionLabel(
                'Words of the day',
                trailing:
                    '${todaysWords.where(progress.isLearned).length}'
                    '/${todaysWords.length} known',
              ),
            ),
            const SizedBox(height: 12),
            WordsOfDay(words: todaysWords),
            const SizedBox(height: 28),
            _padded(SectionLabel('This week', trailing: '$streak-day streak')),
            const SizedBox(height: 14),
            _padded(
              WeekSection(today: today, name: name, dailyGoal: daily.words),
            ),
            const SizedBox(height: 28),
            _padded(const SectionLabel('Topics')),
            const SizedBox(height: 12),
            SizedBox(
              // Grows with the phone's text size so cards never clip.
              height:
                  168 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: Topic.general.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final t = Topic.general[i];
                  return TopicCard(
                    topic: t,
                    learned: progress.learnedIn(t),
                    onTap: () => onOpenTopic(t),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: child,
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.translation,
    required this.initial,
    required this.onAvatarTap,
  });

  final String greeting;
  final String translation;
  final String? initial;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppText.display(
                  26,
                  color: AppColors.cream,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                translation,
                style: AppText.body(14, color: AppColors.creamMuted),
              ),
            ],
          ),
        ),
        if (initial != null) ...[
          const SizedBox(width: 16),
          Pressable(
            onTap: onAvatarTap,
            semanticLabel: 'Open profile',
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cream.withValues(alpha: 0.07),
                border: Border.all(
                  color: AppColors.cream.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                initial!,
                style: AppText.display(19, color: AppColors.cream),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
