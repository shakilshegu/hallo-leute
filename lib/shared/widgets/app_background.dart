import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The brand navy backdrop with a soft glow near the top.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.1,
          colors: [AppColors.navy800, AppColors.navy, AppColors.navy950],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}
