import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shared building blocks for the three optimized onboarding screens, so the
/// progress indicator, section labels and sticky CTA stay identical across
/// all of them and match the rest of the Coffee Meet design language
/// (Space Mono uppercase labels, pill CTA at radius 28, primary green).

/// Transparent app bar with a back arrow and a centered "N of 3" label plus
/// a slim 3-segment progress bar underneath.
class OnboardingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingAppBar({super.key, required this.step});

  /// 1-based step number (1, 2 or 3).
  final int step;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Semantics(
        label: 'Back',
        button: true,
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) context.pop();
          },
        ),
      ),
      title: Text(
        '$step OF 3',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.primary.withOpacity(0.5),
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Semantics(
            label: 'Step $step of 3',
            child: Row(
              children: List.generate(3, (i) {
                final done = i < step;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: done
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large heading + short supporting line, the standard onboarding intro.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.primary.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Uppercase Space Mono section label (e.g. "PURPOSE", "FIRST NAME").
class OnboardingSectionLabel extends StatelessWidget {
  const OnboardingSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final label = Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.primary.withOpacity(0.5),
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );

    if (trailing == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, trailing!],
    );
  }
}

/// The sticky bottom CTA used on every onboarding screen: full width, 56 tall,
/// pill shape, dims to 0.5 when disabled, shows a spinner while loading.
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (enabled && !loading) ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
              disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.8),
            ),
            child: loading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailingIcon, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Inline error shown just above the sticky CTA when an API call fails.
class OnboardingErrorBanner extends StatelessWidget {
  const OnboardingErrorBanner({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final red = Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: textTheme.bodySmall?.copyWith(color: red),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single selectable pill chip (used for interests and single-select rows).
class OnboardingChip extends StatelessWidget {
  const OnboardingChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: selected ? colorScheme.onPrimary : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check, size: 14, color: colorScheme.onPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An equal-width segmented row of single-select options (distance, length).
class OnboardingSegmentedRow extends StatelessWidget {
  const OnboardingSegmentedRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 12),
              child: Semantics(
                button: true,
                selected: options[i] == selected,
                label: options[i],
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(options[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: options[i] == selected
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: options[i] == selected
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      options[i],
                      style: textTheme.bodyMedium?.copyWith(
                        color: options[i] == selected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        fontWeight: options[i] == selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
