import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../theme/app_theme.dart';
import 'celebration_step.dart';
import 'onboarding_controller.dart';
import 'onboarding_steps.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final celebrating = s.step == OnboardingStep.celebrate;

    void goBack() {
      FocusScope.of(context).unfocus();
      if (celebrating) {
        context.go(Routes.home);
      } else if (!notifier.back()) {
        context.go(Routes.welcome);
      }
    }

    Future<void> onContinue() async {
      FocusScope.of(context).unfocus();
      switch (s.step) {
        case OnboardingStep.goal:
          await notifier.finish();
        case OnboardingStep.celebrate:
          context.go(Routes.home);
        default:
          notifier.next();
      }
    }

    final buttonLabel = switch (s.step) {
      OnboardingStep.goal => 'Create my plan',
      OnboardingStep.celebrate => "Los geht's! 🚀",
      _ => 'Continue',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: back · progress · skip
              AnimatedOpacity(
                opacity: celebrating ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: celebrating,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: goBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: StepProgressBar(
                            progress:
                                (s.step.index + 1) /
                                OnboardingState.questionCount,
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: s.step == OnboardingStep.name
                              ? TextButton(
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    notifier.skipName();
                                  },
                                  child: const Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    '${s.step.index + 1}/${OnboardingState.questionCount}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Step content with a shared-axis slide
              Expanded(
                child: PageTransitionSwitcher(
                  reverse: !s.forward,
                  // Fill the area so every step starts at the top.
                  layoutBuilder: (entries) =>
                      Stack(fit: StackFit.expand, children: entries),
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, primary, secondary) =>
                      SharedAxisTransition(
                        animation: primary,
                        secondaryAnimation: secondary,
                        transitionType: SharedAxisTransitionType.horizontal,
                        fillColor: Colors.transparent,
                        child: child,
                      ),
                  child: KeyedSubtree(
                    key: ValueKey(s.step),
                    child: switch (s.step) {
                      OnboardingStep.name => const NameStep(),
                      OnboardingStep.reason => const ReasonStep(),
                      OnboardingStep.level => const LevelStep(),
                      OnboardingStep.goal => const GoalStep(),
                      OnboardingStep.celebrate => const CelebrationStep(),
                    },
                  ),
                ),
              ),

              // Main action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: FilledButton(
                  onPressed: s.canContinue ? onContinue : null,
                  child: s.saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
