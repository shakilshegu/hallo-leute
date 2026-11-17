import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Full-width cream pill with a gentle press-down and an arrow nudge.
/// Pass `onPressed: null` to show it disabled.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(20);

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: AppColors.navy950.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Material(
            color: AppColors.cream,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onPressed,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: AppColors.mustard.withValues(alpha: 0.25),
              highlightColor: Colors.transparent,
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          19,
                          weight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSlide(
                      offset: _pressed ? const Offset(0.35, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
