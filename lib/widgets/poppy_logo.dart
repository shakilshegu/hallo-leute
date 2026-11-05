import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Poppylo logo mark: a stylised poppy with four rounded petals.
class PoppyLogo extends StatelessWidget {
  const PoppyLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PoppyPainter()),
    );
  }
}

class _PoppyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final petalR = r * 0.52;
    final rect = Rect.fromCircle(center: c, radius: r);

    final petalPaint = Paint()
      ..shader = AppColors.bloomGradient.createShader(rect);

    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * (r - petalR);
      canvas.drawCircle(p, petalR, petalPaint);
    }

    // Soft highlight between petals
    canvas.drawCircle(
      c,
      r * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // Dark centre with tiny seeds
    canvas.drawCircle(c, r * 0.24, Paint()..color = AppColors.ink);
    final seed = Paint()..color = AppColors.sunrise;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.13,
        r * 0.03,
        seed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo mark + "poppylo" wordmark.
class PoppyWordmark extends StatelessWidget {
  const PoppyWordmark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PoppyLogo(size: size * 1.15),
        SizedBox(width: size * 0.35),
        Text(
          'poppylo',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
