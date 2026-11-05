import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/poppy_mascot.dart';

/// Poppy's speech bubble + title + subtitle at the top of every step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.poppy,
    required this.title,
    this.subtitle,
    this.translation,
    this.mood = PoppyMood.happy,
  });

  /// What Poppy says in the speech bubble.
  final String poppy;
  final String? translation;
  final PoppyMood mood;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: 300.ms,
          child: PoppySays(
            key: ValueKey('$mood${translation != null}'),
            text: poppy,
            translation: translation,
            mood: mood,
          ),
        ),
        const SizedBox(height: 24),
        Text(title, style: text.headlineMedium)
            .animate()
            .fadeIn(delay: 120.ms, duration: 300.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
                subtitle!,
                style: text.bodyLarge?.copyWith(color: AppColors.muted),
              )
              .animate()
              .fadeIn(delay: 180.ms, duration: 300.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        ],
      ],
    );
  }
}

/// A tappable card with an animated selected state and a check badge.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.accent = AppColors.ink,
    this.padding = const EdgeInsets.all(16),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final Color accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.985,
        duration: 200.ms,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: 0.06),
                    AppColors.surface,
                  )
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppColors.outline,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? accent : AppColors.ink).withValues(
                  alpha: selected ? 0.14 : 0.04,
                ),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Stack(
                children: [
                  Padding(padding: padding, child: child),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: 250.ms,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient progress bar for the onboarding steps.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.progress});

  /// 0.0 – 1.0
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.outline,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: 450.ms,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Container(
              width: c.maxWidth * value,
              decoration: BoxDecoration(
                gradient: AppColors.bloomGradient,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
