import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A petal that flies from [from] to [to] along a curve, then calls
/// [onDone]. Used when a word is learned: it lands in the progress flower.
class FlyingPetal extends StatefulWidget {
  const FlyingPetal({
    super.key,
    required this.from,
    required this.to,
    required this.color,
    required this.onDone,
  });

  final Offset from;
  final Offset to;
  final Color color;
  final VoidCallback onDone;

  @override
  State<FlyingPetal> createState() => _FlyingPetalState();
}

class _FlyingPetalState extends State<FlyingPetal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward().whenCompleteOrCancel(() => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        // Quadratic bezier with a control point off to the side.
        final a = widget.from;
        final b = widget.to;
        final ctrl = Offset(a.dx + (b.dx - a.dx) * 0.2 - 90, a.dy - 40);
        final p =
            a * ((1 - t) * (1 - t)) + ctrl * (2 * (1 - t) * t) + b * (t * t);
        final scale = 1.6 - 1.2 * t;

        return Positioned(
          left: p.dx - 10,
          top: p.dy - 14,
          child: IgnorePointer(
            child: Opacity(
              opacity: _c.value < 0.9 ? 1 : (1 - _c.value) * 10,
              child: Transform.rotate(
                angle: t * math.pi * 2.5,
                child: Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    size: const Size(20, 28),
                    painter: _PetalShape(widget.color),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetalShape extends CustomPainter {
  _PetalShape(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 1.1, h * 0.75, w * 0.95, h * 0.1, w / 2, 0)
      ..cubicTo(w * 0.05, h * 0.1, -w * 0.1, h * 0.75, w / 2, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color, Color.lerp(color, Colors.white, 0.35)!],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_PetalShape old) => old.color != color;
}
