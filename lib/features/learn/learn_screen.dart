import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_data.dart';
import '../../data/providers.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fun_icon.dart';
import '../../widgets/poppy_mascot.dart';
import '../home/widgets/petal_bloom.dart';
import 'learn_session.dart';

/// The "Lernen" tab: start today's flashcards or pick a topic.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider);

    return Scaffold(
      body: home.when(
        loading: () => const Center(
          child: PoppyMascot(size: 72, mood: PoppyMood.thinking),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => _LearnContent(data: data),
      ),
    );
  }
}

class _LearnContent extends StatelessWidget {
  const _LearnContent({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    var i = 0;
    Widget enter(Widget child) {
      final delay = (70 * i++).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 300.ms)
          .slideY(begin: 0.06, delay: delay, curve: Curves.easeOutCubic);
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          enter(Text('Lernen', style: text.displayMedium)),
          enter(
            Text(
              'Learn · swipe through new words',
              style: text.bodyLarge?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          enter(_TodaySessionCard(data: data)),
          const SizedBox(height: 16),
          enter(const _HowItWorks()),
          const SizedBox(height: 28),
          enter(
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Themen', style: text.titleLarge),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'Pick a topic',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final (n, t) in data.topics.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: enter(_TopicTile(progress: t, index: n)),
            ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  const _TodaySessionCard({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final left = data.dailyGoal - data.learnedToday;
    final (title, subtitle, cta) = switch (data.learnedToday) {
      0 => (
        'Today’s words are ready',
        '${data.dailyGoal} fresh words, picked for you.',
        'Start learning',
      ),
      _ when left > 0 => (
        '$left words left today',
        'Your flower is ${(data.learnedToday / data.dailyGoal * 100).round()}% '
            'in bloom.',
        'Continue',
      ),
      _ => (
        'Goal reached! 🎉',
        'Feeling good? Grab $minSessionSize bonus words.',
        'Learn $minSessionSize more',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: PetalBloom(
                  articles: data.todayArticles,
                  goal: data.dailyGoal,
                  size: 84,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(Routes.session);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(cta, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    Widget tip(String emoji, String de, String en) => Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            de,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            en,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.sunrise.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tip('🎯', 'der·die·das?', 'Guess first'),
          tip('👆', 'Tippen', 'Tap to flip'),
          tip('👉', 'Kann ich!', 'Swipe right'),
          tip('👈', 'Nochmal', 'Swipe left'),
        ],
      ),
    );
  }
}

const _motions = [
  FunMotion.wobble,
  FunMotion.bounce,
  FunMotion.float,
  FunMotion.tada,
  FunMotion.pulse,
];

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.progress, required this.index});

  final TopicProgress progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = progress.topic;
    final done = progress.learned >= progress.total;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('${Routes.session}?topic=${t.id}');
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: progress.recommended
                  ? t.color.withValues(alpha: 0.6)
                  : AppColors.outline,
              width: progress.recommended ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              FunIcon(
                t.emoji,
                color: t.color,
                size: 50,
                motion: _motions[index % _motions.length],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.german,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (progress.recommended) ...[
                          const SizedBox(width: 6),
                          const Text('✨', style: TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                    Text(
                      t.english,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 6,
                        backgroundColor: AppColors.outline,
                        color: t.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              done
                  ? const Text('Fertig! ✅', style: TextStyle(fontSize: 12))
                  : Text(
                      '${progress.learned}/${progress.total}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
