import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

/// Eyebrow (German), title and helper line at the top of each step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppText.body(
            12.5,
            weight: FontWeight.w800,
            color: AppColors.mustard,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppText.display(28, color: AppColors.cream, height: 1.15),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppText.body(15, color: AppColors.creamMuted, height: 1.45),
          ),
        ],
      ],
    );
  }
}

/// Shared look for selectable cards: animated fill, border and press scale.
class SelectableSurface extends StatefulWidget {
  const SelectableSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  State<SelectableSurface> createState() => _SelectableSurfaceState();
}

class _SelectableSurfaceState extends State<SelectableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.mustard.withValues(alpha: 0.12)
                  : AppColors.navy800.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.mustard
                    : AppColors.navyLine.withValues(alpha: 0.6),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Round tick that pops in when selected.
class SelectionTick extends StatelessWidget {
  const SelectionTick({super.key, required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      child: selected
          ? Container(
              key: const ValueKey(true),
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.mustard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: size * 0.7,
                color: AppColors.navy,
              ),
            )
          : Container(
              key: const ValueKey(false),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.navyLine.withValues(alpha: 0.9),
                  width: 1.5,
                ),
              ),
            ),
    );
  }
}

/// A list-style option: leading badge, title, description, tick.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.description,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String description;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SelectableSurface(
      selected: selected,
      onTap: onTap,
      semanticLabel: '$title. $description',
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppText.body(
                        16,
                        weight: FontWeight.w800,
                        color: AppColors.cream,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mustard,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badge!,
                          style: AppText.body(
                            11,
                            weight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppText.body(
                    13.5,
                    color: AppColors.creamMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SelectionTick(selected: selected),
        ],
      ),
    );
  }
}

/// Square-ish badge used as the leading element of an [OptionCard].
class LeadingBadge extends StatelessWidget {
  const LeadingBadge({
    super.key,
    required this.selected,
    required this.child,
    this.width = 48,
  });

  final bool selected;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.mustard
            : AppColors.cream.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: selected ? AppColors.navy : AppColors.cream),
        child: IconTheme.merge(
          data: IconThemeData(
            color: selected ? AppColors.navy : AppColors.mustard,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Soft card used for German mini-lessons ("Say it in German").
class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.label,
    required this.german,
    required this.english,
  });

  final String label;
  final String german;
  final String english;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.mustard.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: AppColors.mustard,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.body(
                    12,
                    weight: FontWeight.w800,
                    color: AppColors.creamMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    german,
                    key: ValueKey(german),
                    style: AppText.display(20, color: AppColors.cream),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  english,
                  style: AppText.body(13.5, color: AppColors.creamMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
