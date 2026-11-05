import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fun_icon.dart';
import '../../widgets/poppy_mascot.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_widgets.dart';

const _pagePadding = EdgeInsets.fromLTRB(24, 12, 24, 24);

// ---------------------------------------------------------------------------
// Step 1 – Name
// ---------------------------------------------------------------------------

class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final _controller = TextEditingController(
    text: ref.read(onboardingProvider).name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(onboardingProvider.select((s) => s.displayName));
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poppy reacts live while the learner types.
          StepHeader(
            mood: name == null ? PoppyMood.happy : PoppyMood.excited,
            poppy: name == null
                ? "Hallo! I'm Poppy 🌸 your German buddy."
                : 'Hallo, $name! Schön, dich kennenzulernen!',
            translation: name == null ? null : 'Nice to meet you!',
            title: 'What should I call you?',
            subtitle: 'Just your first name. No account, no email, no stress.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Your first name',
              counterText: '',
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text('✏️', style: TextStyle(fontSize: 20)),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 0),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: notifier.setName,
            onSubmitted: (_) {
              if (ref.read(onboardingProvider).canContinue) notifier.next();
            },
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 – Reason
// ---------------------------------------------------------------------------

extension on LearningReason {
  Color get color => switch (this) {
    LearningReason.studies => AppColors.der,
    LearningReason.work => AppColors.lavender,
    LearningReason.living => AppColors.das,
    LearningReason.fun => AppColors.sunrise,
  };

  FunMotion get motion => switch (this) {
    LearningReason.studies => FunMotion.bounce,
    LearningReason.work => FunMotion.wobble,
    LearningReason.living => FunMotion.float,
    LearningReason.fun => FunMotion.tada,
  };
}

class ReasonStep extends ConsumerWidget {
  const ReasonStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider.select((s) => s.reason));
    final name = ref.watch(onboardingProvider.select((s) => s.displayName));

    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            mood: PoppyMood.wink,
            poppy: name == null
                ? 'Ooh, exciting! Let’s get you started.'
                : 'Super, $name! Let’s make German useful for you.',
            title: 'What brings you to German?',
            subtitle: 'I’ll start with the words you’ll use most.',
          ),
          const SizedBox(height: 22),
          for (var row = 0; row < LearningReason.values.length; row += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Both cards in a row share the height of the taller one.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = row; i < row + 2; i++) ...[
                      if (i > row) const SizedBox(width: 12),
                      Expanded(
                        child:
                            _ReasonCard(
                                  reason: LearningReason.values[i],
                                  selected:
                                      selected == LearningReason.values[i],
                                  onTap: () => ref
                                      .read(onboardingProvider.notifier)
                                      .setReason(LearningReason.values[i]),
                                )
                                .animate()
                                .fadeIn(
                                  delay: (250 + i * 70).ms,
                                  duration: 300.ms,
                                )
                                .slideY(
                                  begin: 0.15,
                                  curve: Curves.easeOutCubic,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final LearningReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SelectableCard(
      selected: selected,
      accent: reason.color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FunIcon(
            reason.emoji,
            color: reason.color,
            size: 52,
            motion: reason.motion,
            active: selected,
            tilt: -0.06,
          ),
          const SizedBox(height: 14),
          Text(reason.title, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            reason.subtitle,
            style: text.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 – Level
// ---------------------------------------------------------------------------

Color _levelColor(CefrLevel l) => switch (l) {
  CefrLevel.a1 => AppColors.dasText,
  CefrLevel.a2 => AppColors.derText,
  CefrLevel.b1 => AppColors.lavenderText,
  CefrLevel.b2 => AppColors.dieText,
  CefrLevel.c1 => AppColors.sunriseText,
};

class LevelStep extends ConsumerWidget {
  const LevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            mood: PoppyMood.thinking,
            poppy: 'No test, I promise! 😌 Just pick what feels right.',
            title: 'How’s your German right now?',
          ),
          const SizedBox(height: 20),
          for (final (i, l) in CefrLevel.values.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  SelectableCard(
                        selected: s.level == l && !s.levelUnsure,
                        accent: _levelColor(l),
                        padding: const EdgeInsets.fromLTRB(14, 12, 40, 12),
                        onTap: () => notifier.setLevel(l),
                        child: Row(
                          children: [
                            _LevelBadge(
                              level: l,
                              active: s.level == l && !s.levelUnsure,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.title, style: text.titleMedium),
                                  Text(
                                    l.description,
                                    style: text.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (220 + i * 50).ms, duration: 280.ms)
                      .slideX(begin: 0.08, curve: Curves.easeOutCubic),
            ),
          const SizedBox(height: 4),
          SelectableCard(
            selected: s.levelUnsure,
            accent: AppColors.ink,
            padding: const EdgeInsets.fromLTRB(14, 12, 40, 12),
            onTap: () => notifier.setLevel(CefrLevel.a1, unsure: true),
            child: Row(
              children: [
                FunIcon(
                  '🤔',
                  color: AppColors.warning,
                  size: 40,
                  motion: FunMotion.wobble,
                  active: s.levelUnsure,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not sure?', style: text.titleMedium),
                      Text(
                        'Start easy at A1. You can change it any time.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 280.ms),
        ],
      ),
    );
  }
}

/// Coloured CEFR badge that pops when its level is picked.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.active});

  final CefrLevel level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _levelColor(level),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        level.code,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );

    return active
        ? badge
              .animate(key: ValueKey('on${level.code}'))
              .scaleXY(end: 1.15, duration: 160.ms, curve: Curves.easeOut)
              .then()
              .scaleXY(
                end: 1 / 1.15,
                duration: 260.ms,
                curve: Curves.elasticOut,
              )
              .shake(hz: 4, rotation: 0.05, duration: 300.ms)
        : badge;
  }
}

// ---------------------------------------------------------------------------
// Step 4 – Daily goal
// ---------------------------------------------------------------------------

({Color color, FunMotion motion}) _goalStyle(int words) => switch (words) {
  5 => (color: AppColors.das, motion: FunMotion.float),
  10 => (color: AppColors.poppy, motion: FunMotion.pulse),
  _ => (color: AppColors.lavender, motion: FunMotion.bounce),
};

class GoalStep extends ConsumerWidget {
  const GoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(onboardingProvider.select((s) => s.dailyGoal));
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: _pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            mood: PoppyMood.happy,
            poppy: 'Tiny daily steps win the race 🐢',
            title: 'How many words a day?',
            subtitle: 'Pick what fits your day. You can change it any time.',
          ),
          const SizedBox(height: 20),
          for (final (i, o) in DailyGoalOption.all.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  SelectableCard(
                        selected: goal == o.words,
                        accent: AppColors.poppy,
                        padding: const EdgeInsets.fromLTRB(14, 14, 40, 14),
                        onTap: () => ref
                            .read(onboardingProvider.notifier)
                            .setDailyGoal(o.words),
                        child: Row(
                          children: [
                            FunIcon(
                              o.emoji,
                              color: _goalStyle(o.words).color,
                              size: 48,
                              motion: _goalStyle(o.words).motion,
                              active: goal == o.words,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${o.words} words a day',
                                        style: text.titleMedium,
                                      ),
                                      if (o.popular) const _PopularPill(),
                                    ],
                                  ),
                                  Text(
                                    '${o.label} · about ${o.minutes} min',
                                    style: text.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (220 + i * 60).ms, duration: 280.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOutCubic),
            ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: 300.ms,
            child: goal == null
                ? const SizedBox.shrink()
                : _MonthProjection(key: const ValueKey('p'), words: goal * 30),
          ),
        ],
      ),
    );
  }
}

class _PopularPill extends StatelessWidget {
  const _PopularPill();

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: AppColors.bloomGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '⭐ Popular',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 1800.ms, duration: 900.ms, color: Colors.white54);
  }
}

/// "That's 300 words in 30 days!" with a count-up number.
class _MonthProjection extends StatelessWidget {
  const _MonthProjection({super.key, required this.words});

  final int words;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sunrise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const FunIcon(
            '🎯',
            color: AppColors.sunrise,
            size: 40,
            motion: FunMotion.tada,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: words.toDouble()),
              duration: 700.ms,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                  children: [
                    const TextSpan(text: "That's "),
                    TextSpan(
                      text: '${v.round()} words',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: ' in 30 days! You’ve got this.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
