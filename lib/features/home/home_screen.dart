import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_data.dart';
import '../../data/providers.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fun_icon.dart';
import '../../widgets/poppy_mascot.dart';
import 'widgets/petal_bloom.dart';
import 'widgets/streak_pot.dart';
import 'widgets/topic_shelf.dart';
import 'widgets/week_garden.dart';
import 'widgets/word_of_day_card.dart';

/// Greeting for the time of day: (German, English, emoji).
({String de, String en, String emoji}) greetingFor(DateTime now) =>
    switch (now.hour) {
      >= 5 && < 11 => (de: 'Guten Morgen', en: 'Good morning', emoji: '☀️'),
      >= 11 && < 17 => (de: 'Guten Tag', en: 'Good afternoon', emoji: '🌤️'),
      >= 17 && < 22 => (de: 'Guten Abend', en: 'Good evening', emoji: '🌆'),
      _ => (de: 'Gute Nacht', en: 'Good night', emoji: '🌙'),
    };

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Re-compute when the app comes back (the date may have changed).
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(homeDataProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeDataProvider);

    return Scaffold(
      body: home.when(
        data: (data) => _HomeContent(data: data),
        loading: () => const Center(
          child: PoppyMascot(size: 72, mood: PoppyMood.thinking),
        ),
        error: (e, _) => Center(child: Text('Oops, something went wrong.\n$e')),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    var i = 0;
    Widget enter(Widget child) {
      final delay = (90 * i++).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 350.ms)
          .slideY(begin: 0.06, delay: delay, curve: Curves.easeOutCubic);
    }

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList.list(
              children: [
                enter(_Header(data: data)),
                const SizedBox(height: 20),
                enter(_TodayBloomCard(data: data)),
                const SizedBox(height: 28),
                enter(
                  _SectionTitle(
                    german: 'Diese Woche',
                    english: 'This week',
                    trailing:
                        '${data.week.fold(0, (s, d) => s + d.learned)} words',
                  ),
                ),
                const SizedBox(height: 10),
                enter(WeekGarden(week: data.week, goal: data.dailyGoal)),
                if (data.wordOfDay != null) ...[
                  const SizedBox(height: 28),
                  enter(
                    const _SectionTitle(
                      german: 'Wort des Tages',
                      english: 'Word of the day',
                    ),
                  ),
                  const SizedBox(height: 12),
                  enter(WordOfDayCard(word: data.wordOfDay!)),
                ],
                const SizedBox(height: 28),
                enter(
                  const _SectionTitle(
                    german: 'Themen für dich',
                    english: 'Topics for you',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: enter(
            TopicShelf(
              topics: data.topics,
              onTap: (t) =>
                  context.push('${Routes.session}?topic=${t.topic.id}'),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
          sliver: SliverToBoxAdapter(child: enter(_ReviewCard(data: data))),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final g = greetingFor(DateTime.now());
    final name = data.profile?.name;
    final mood = data.goalReached
        ? PoppyMood.excited
        : data.learnedToday > 0
        ? PoppyMood.happy
        : PoppyMood.wink;
    final tagline = data.goalReached
        ? 'You’re in full bloom today!'
        : data.learnedToday > 0
        ? 'Your flower is growing!'
        : 'Ready for a few words?';

    return Row(
      children: [
        PoppyMascot(size: 54, mood: mood),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? '${g.de}!' : '${g.de}, $name!',
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${g.en} ${g.emoji} · $tagline',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StreakChip(streak: data.streak),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today's bloom
// ---------------------------------------------------------------------------

class _TodayBloomCard extends StatelessWidget {
  const _TodayBloomCard({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final learned = data.learnedToday;
    final goal = data.dailyGoal;
    final left = goal - learned;

    final (title, subtitle, cta) = switch (learned) {
      0 => (
        'Your first petal is waiting 🌱',
        'Learn $goal words to make today’s flower bloom.',
        'Start today’s words',
      ),
      _ when left > 0 => (
        '$left more to full bloom!',
        '$learned of $goal words today. Weiter so! (Keep it up!)',
        'Keep going',
      ),
      _ => (
        'Full bloom! Wunderbar! 🎉',
        'Goal reached. Extra words help your garden grow.',
        'Learn a few more',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.sunrise.withValues(alpha: 0.12),
            AppColors.surface,
            AppColors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.poppy.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              PetalBloom(articles: data.todayArticles, goal: goal, size: 128),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HEUTE · TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.poppyText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.push(Routes.session),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(cta, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _ArticleLegend(),
        ],
      ),
    );
  }
}

/// Explains the petal colours: der · die · das.
class _ArticleLegend extends StatelessWidget {
  const _ArticleLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Petal colours: ',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        for (final a in Article.values) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: a.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            a.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: a.textColor,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Review
// ---------------------------------------------------------------------------

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final due = data.reviewDue;
    final (emoji, title, body) = switch (due) {
      _ when data.totalLearned == 0 => (
        '🌱',
        'Your review garden is empty',
        'Words you learn will pop back here right before you’d forget them.',
      ),
      0 => (
        '✨',
        'All caught up!',
        'Poppy will bring words back at just the right moment.',
      ),
      1 => (
        '👋',
        '1 word wants to say Hallo again',
        'A quick review keeps it fresh.',
      ),
      _ => (
        '👋',
        '$due words want to say Hallo again',
        'A quick review keeps them fresh.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          FunIcon(
            emoji,
            color: AppColors.lavender,
            size: 48,
            motion: due > 0 ? FunMotion.wave : FunMotion.float,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (due > 0) ...[
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Review now',
              style: IconButton.styleFrom(backgroundColor: AppColors.ink),
              onPressed: () => context.go(Routes.review),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.german,
    required this.english,
    this.trailing,
  });

  final String german;
  final String english;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          flex: 0,
          child: Text(
            german,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              english,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
      ],
    );
  }
}
