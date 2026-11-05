import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// Today's progress as a flower: one petal per word of the daily goal.
/// Each learned word colours a petal in its article colour; reaching the
/// goal makes the flower glow and breathe. Tap it for a little wiggle.
class PetalBloom extends StatefulWidget {
  const PetalBloom({
    super.key,
    required this.articles,
    required this.goal,
    this.size = 132,
  });

  /// Article of each word learned today (null → no article).
  final List<Article?> articles;
  final int goal;
  final double size;

  @override
  State<PetalBloom> createState() => _PetalBloomState();
}

class _PetalBloomState extends State<PetalBloom> with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: _fillDuration(widget.articles.length),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late Animation<double> _value;

  int get _filled => math.min(widget.articles.length, widget.goal);

  static Duration _fillDuration(int n) =>
      Duration(milliseconds: 500 + 90 * math.min(n, 20));

  @override
  void initState() {
    super.initState();
    _animateTo(_filled, from: 0);
  }

  void _animateTo(int target, {required double from}) {
    _fill.duration = _fillDuration(target);
    _value = Tween(
      begin: from,
      end: target.toDouble(),
    ).animate(CurvedAnimation(parent: _fill, curve: Curves.easeOutCubic));
    _fill.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(PetalBloom old) {
    super.didUpdateWidget(old);
    final oldFilled = math.min(old.articles.length, old.goal);
    if (oldFilled != _filled) _animateTo(_filled, from: _value.value);
    _syncBreath();
  }

  void _syncBreath() {
    final bloomed = widget.articles.length >= widget.goal;
    if (bloomed && !MediaQuery.disableAnimationsOf(context)) {
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _breath.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learned = widget.articles.length;
    final extra = learned - widget.goal;

    return Semantics(
      label: '$learned of ${widget.goal} words learned today',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _wiggle.forward(from: 0);
        },
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fill, _breath, _wiggle]),
                  builder: (context, _) => CustomPaint(
                    painter: _PetalPainter(
                      goal: widget.goal,
                      value: _value.value,
                      colors: [
                        for (final a in widget.articles.take(widget.goal))
                          a?.color ?? AppColors.sunrise,
                      ],
                      bloomed: learned >= widget.goal,
                      breath: _breath.value,
                      wiggle: _wiggle.isAnimating ? _wiggle.value : 0,
                    ),
                  ),
                ),
              ),
              // Centre count
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) => Text(
                      '${_value.value.round() + (extra > 0 ? extra : 0)}',
                      style: TextStyle(
                        fontSize: widget.size * 0.2,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    'of ${widget.goal}',
                    style: TextStyle(
                      fontSize: widget.size * 0.085,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.goal,
    required this.value,
    required this.colors,
    required this.bloomed,
    required this.breath,
    required this.wiggle,
  });

  final int goal;
  final double value;
  final List<Color> colors;
  final bool bloomed;
  final double breath;
  final double wiggle;

  static const _emptyFill = Color(0xFFF4EDE8);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.4;
    final len = outer - inner;
    final step = 2 * math.pi / goal;
    final width = math.min(outer * 0.46, step * (inner + len * 0.55) * 0.92);
    final pulse = bloomed ? 1 + 0.035 * math.sin(breath * 2 * math.pi) : 1.0;

    if (bloomed) {
      canvas.drawCircle(
        c,
        outer * 0.85,
        Paint()
          ..color = AppColors.poppy.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    Path petal(double scale) {
      final l = len * scale;
      final w = width * scale;
      final base = -inner - 2;
      return Path()
        ..moveTo(0, base)
        ..cubicTo(w / 2, base - l * 0.12, w * 0.55, base - l * 0.8, 0, base - l)
        ..cubicTo(-w * 0.55, base - l * 0.8, -w / 2, base - l * 0.12, 0, base)
        ..close();
    }

    final emptyPaint = Paint()..color = _emptyFill;
    final emptyStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.outline;

    for (var i = 0; i < goal; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      // A travelling wiggle when the flower is tapped
      final w = wiggle == 0
          ? 0.0
          : math.sin((wiggle * 3 - i / goal) * 2 * math.pi) *
                0.12 *
                (1 - wiggle);
      canvas.rotate(i * step + w);
      canvas.scale(pulse);

      final f = (value - i).clamp(0.0, 1.0);
      if (f < 1) {
        canvas.drawPath(petal(1), emptyPaint);
        canvas.drawPath(petal(1), emptyStroke);
      }
      if (f > 0 && i < colors.length) {
        final grow = Curves.easeOutBack.transform(f);
        final color = colors[i];
        final rect = Rect.fromLTWH(-width / 2, -outer, width, len);
        canvas.drawPath(
          petal(grow),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color.withValues(alpha: f),
                Color.lerp(color, Colors.white, 0.25)!.withValues(alpha: f),
              ],
            ).createShader(rect),
        );
      }
      canvas.restore();
    }

    // Centre disc
    canvas.drawCircle(c, inner - 1, Paint()..color = AppColors.surface);
  }

  @override
  bool shouldRepaint(_PetalPainter old) =>
      old.value != value ||
      old.goal != goal ||
      old.breath != breath ||
      old.wiggle != wiggle ||
      old.bloomed != bloomed ||
      old.colors.length != colors.length;
}
