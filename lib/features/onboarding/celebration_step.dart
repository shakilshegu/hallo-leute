import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/confetti.dart';
import '../../widgets/fun_icon.dart';
import '../../widgets/poppy_mascot.dart';
import 'onboarding_controller.dart';

/// Final onboarding moment: confetti, welcome and the learner's plan.
class CelebrationStep extends ConsumerStatefulWidget {
  const CelebrationStep({super.key});

  @override
  ConsumerState<CelebrationStep> createState() => _CelebrationStepState();
}

class _CelebrationStepState extends ConsumerState<CelebrationStep> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(onboardingProvider);
    final text = Theme.of(context).textTheme;
    final name = s.displayName;

    return Stack(
      children: [
        const Positioned.fill(child: ConfettiBurst()),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.poppy.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const PoppyMascot(size: 96, mood: PoppyMood.excited),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .rotate(begin: -0.1, duration: 800.ms, curve: Curves.easeOut),
              const SizedBox(height: 28),
              Text(
                    name == null ? 'Willkommen! 🎉' : 'Willkommen, $name! 🎉',
                    textAlign: TextAlign.center,
                    style: text.displayMedium?.copyWith(fontSize: 30),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                'Your plan is ready. Let’s grow your German,\none word at a time 🌱',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: AppColors.muted),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 28),
              Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      children: [
                        if (s.reason != null)
                          _PlanRow(
                            emoji: '🎯',
                            color: AppColors.lavender,
                            motion: FunMotion.tada,
                            label: 'Focus',
                            value: '${s.reason!.emoji} ${s.reason!.title}',
                            delay: 550,
                          ),
                        if (s.level != null)
                          _PlanRow(
                            emoji: '🧠',
                            color: AppColors.der,
                            motion: FunMotion.pulse,
                            label: 'Level',
                            value: '${s.level!.code} · ${s.level!.title}',
                            delay: 650,
                          ),
                        if (s.dailyGoal != null)
                          _PlanRow(
                            emoji: '🔥',
                            color: AppColors.poppy,
                            motion: FunMotion.bounce,
                            label: 'Daily goal',
                            value: '${s.dailyGoal} words a day',
                            delay: 750,
                            last: true,
                          ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms)
                  .slideY(begin: 0.1),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.emoji,
    required this.color,
    required this.motion,
    required this.label,
    required this.value,
    required this.delay,
    this.last = false,
  });

  final String emoji;
  final Color color;
  final FunMotion motion;
  final String label;
  final String value;
  final int delay;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          FunIcon(emoji, color: color, size: 40, motion: motion),
          const SizedBox(width: 14),
          Text(label, style: text.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.titleMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 300.ms).slideX(begin: 0.05);
  }
}
