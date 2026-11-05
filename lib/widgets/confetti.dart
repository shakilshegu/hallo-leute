import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One-shot burst of poppy-coloured confetti. Plays once when shown.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.originY = 0.18});

  /// Vertical origin as a fraction of the available height.
  final double originY;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_c.isAnimating) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            progress: _c.value,
            originY: widget.originY,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.originY});

  final double progress;
  final double originY;

  static const _colors = [
    AppColors.poppy,
    AppColors.sunrise,
    AppColors.lavender,
    AppColors.der,
    AppColors.die,
    AppColors.das,
  ];

  static final _particles = List.generate(48, (i) {
    final rnd = math.Random(i * 7919);
    return (
      angle: -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.3,
      speed: 0.55 + rnd.nextDouble() * 0.6,
      size: 5 + rnd.nextDouble() * 6,
      spin: (rnd.nextDouble() - 0.5) * 12,
      color: _colors[i % _colors.length],
      round: rnd.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final origin = Offset(size.width / 2, size.height * originY);
    final t = Curves.easeOut.transform(progress);
    final fade = progress < 0.7 ? 1.0 : 1 - (progress - 0.7) / 0.3;

    for (final p in _particles) {
      final dist = p.speed * size.height * 0.55 * t;
      final gravity = size.height * 0.45 * progress * progress;
      final pos =
          origin +
          Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist + gravity);
      final paint = Paint()..color = p.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * progress);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 1.8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
