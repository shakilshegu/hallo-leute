import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

/// The Hallo Leute frying-pan mark, drawn in code so it can animate.
///
/// [entrance] runs 0 → 1 once (ring draws, handle slides in, letters pop,
/// "NUR POSITIV" appears). [ambient] loops 0 → 1 forever and drives the
/// steam wisps and twinkling dots.
class PanLogo extends StatelessWidget {
  const PanLogo({
    super.key,
    required this.diameter,
    required this.entrance,
    required this.ambient,
  });

  final double diameter;
  final Animation<double> entrance;
  final Animation<double> ambient;

  /// Total width relative to the pan diameter (pan + handle).
  static const widthFactor = 1.58;

  /// Space above the pan reserved for steam, relative to the diameter.
  static const headroomFactor = 0.24;

  static Size sizeFor(double diameter) =>
      Size(diameter * widthFactor, diameter * (1 + headroomFactor));

  @override
  Widget build(BuildContext context) {
    final d = diameter;
    final top = d * headroomFactor;
    final size = sizeFor(d);

    return Semantics(
      label: 'Hallo Leute – nur positiv',
      image: true,
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PanPainter(
                  entrance: entrance,
                  ambient: ambient,
                  headroom: top,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: top,
              width: d,
              height: d,
              child: ExcludeSemantics(
                child: _Wordmark(diameter: d, entrance: entrance),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "HALLO / LEUTE" in wobbly, hand-lettered style; each letter pops in.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.diameter, required this.entrance});

  final double diameter;
  final Animation<double> entrance;

  // Small per-letter tilt and vertical offset give the bubbly logo feel.
  static const _lines = [
    (
      'HALLO',
      [-0.06, 0.03, -0.03, 0.05, -0.04],
      [0.0, -0.02, 0.012, -0.03, 0.01],
    ),
    (
      'LEUTE',
      [0.04, -0.035, 0.05, -0.02, 0.035],
      [0.02, 0.0, -0.02, 0.012, -0.01],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final d = diameter;
    final style = AppText.display(
      d * 0.235,
      weight: FontWeight.w700,
      color: AppColors.cream,
      height: 0.98,
    );

    var index = 0;
    final rows = <Widget>[];
    for (final (word, tilts, offsets) in _lines) {
      final letters = <Widget>[];
      for (var i = 0; i < word.length; i++) {
        final start = 0.34 + index * 0.034;
        letters.add(
          _PopLetter(
            letter: word[i],
            style: style,
            tilt: tilts[i],
            dy: offsets[i] * d,
            animation: CurvedAnimation(
              parent: entrance,
              curve: Interval(
                start,
                math.min(start + 0.3, 1),
                curve: Curves.elasticOut,
              ),
            ),
          ),
        );
        index++;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: letters));
    }

    return Transform.translate(
      offset: Offset(0, -d * 0.065),
      child: Center(
        // Keep the letters inside the ring whatever the font metrics.
        child: SizedBox(
          width: d * 0.72,
          height: d * 0.56,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: rows),
          ),
        ),
      ),
    );
  }
}

class _PopLetter extends StatelessWidget {
  const _PopLetter({
    required this.letter,
    required this.style,
    required this.tilt,
    required this.dy,
    required this.animation,
  });

  final String letter;
  final TextStyle style;
  final double tilt;
  final double dy;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy + (1 - t) * 6),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(scale: t.clamp(0.0, 1.4), child: child),
            ),
          ),
        );
      },
      child: Text(letter, style: style),
    );
  }
}

class _PanPainter extends CustomPainter {
  _PanPainter({
    required this.entrance,
    required this.ambient,
    required this.headroom,
  }) : super(repaint: Listenable.merge([entrance, ambient]));

  final Animation<double> entrance;
  final Animation<double> ambient;
  final double headroom;

  static const _ink = AppColors.cream;
  static const _bg = AppColors.navy;

  static double _phase(
    double t,
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) {
    final v = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.height - headroom;
    final r = d / 2;
    final c = Offset(r, headroom + r);
    final e = entrance.value;
    final a = ambient.value;

    final ring = _phase(e, 0.0, 0.45, Curves.easeInOutCubic);
    final handle = _phase(e, 0.22, 0.56);
    final caption = _phase(e, 0.62, 0.86);
    final extras = _phase(e, 0.72, 1.0);
    final stroke = d * 0.04;

    if (handle > 0) _paintHandle(canvas, c, d, handle);

    // Pan interior (also hides the handle's neck under the ring). Fades in
    // with the handle so no dark disk shows before the ring is drawn.
    if (handle > 0) {
      canvas.drawCircle(
        c,
        r - stroke / 2,
        Paint()..color = _bg.withValues(alpha: handle),
      );
    }

    // Outer ring draws itself from the top.
    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - stroke / 2),
        -math.pi / 2,
        math.pi * 2 * ring,
        false,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (extras > 0) {
      _paintInnerArcs(canvas, c, d, extras);
      _paintDots(canvas, c, d, extras, a);
      _paintSteam(canvas, c, d, extras, a);
    }
    if (caption > 0) {
      _paintSmile(canvas, c, d, caption);
      _paintCurvedCaption(canvas, c, d, caption);
    }
  }

  void _paintHandle(Canvas canvas, Offset c, double d, double t) {
    final r = d / 2;
    canvas.save();
    canvas.translate(c.dx - (1 - t) * d * 0.14, c.dy);
    canvas.rotate(-0.06);

    final path = Path()
      ..moveTo(r * 0.85, -0.17 * d)
      ..cubicTo(
        r + 0.04 * d,
        -0.15 * d,
        r + 0.07 * d,
        -0.06 * d,
        r + 0.17 * d,
        -0.05 * d,
      )
      ..lineTo(r + 0.50 * d, -0.066 * d)
      ..arcToPoint(
        Offset(r + 0.50 * d, 0.066 * d),
        radius: Radius.circular(0.066 * d),
      )
      ..lineTo(r + 0.17 * d, 0.05 * d)
      ..cubicTo(
        r + 0.07 * d,
        0.06 * d,
        r + 0.04 * d,
        0.15 * d,
        r * 0.85,
        0.17 * d,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = _ink.withValues(alpha: t));

    // Hanging slot.
    canvas.drawRRect(
      RRect.fromLTRBR(
        r + 0.36 * d,
        -0.022 * d,
        r + 0.52 * d,
        0.022 * d,
        Radius.circular(0.022 * d),
      ),
      Paint()..color = _bg,
    );
    canvas.restore();
  }

  void _paintInnerArcs(Canvas canvas, Offset c, double d, double t) {
    final paint = Paint()
      ..color = _ink.withValues(alpha: t * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = d * 0.013
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: c, radius: d * 0.415);
    final sweep = math.pi * 0.26 * t;
    canvas.drawArc(rect, math.pi - sweep / 2, sweep, false, paint);
    canvas.drawArc(rect, -sweep / 2, sweep, false, paint);
  }

  void _paintDots(Canvas canvas, Offset c, double d, double t, double a) {
    const spots = [
      Offset(-0.37, 0.07),
      Offset(0.37, 0.09),
      Offset(0.27, -0.33),
      Offset(-0.26, -0.33),
    ];
    for (var i = 0; i < spots.length; i++) {
      final twinkle =
          0.45 +
          0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * (a * 3 + i * 0.27)));
      canvas.drawCircle(
        c + spots[i] * d,
        d * 0.012,
        Paint()..color = _ink.withValues(alpha: t * twinkle),
      );
    }
  }

  void _paintSteam(Canvas canvas, Offset c, double d, double t, double a) {
    final topY = c.dy - d / 2;
    for (var i = 0; i < 3; i++) {
      // 4 full cycles per ambient loop keeps the animation seamless.
      final p = (a * 4 + i / 3) % 1.0;
      final x = c.dx + (i - 1) * d * 0.15;
      final h = d * 0.11;
      final y = topY - d * 0.035 - p * d * 0.07;
      final sway =
          d *
          0.032 *
          (i.isOdd ? -1 : 1) *
          (1 + 0.35 * math.sin(2 * math.pi * p));
      final path = Path()
        ..moveTo(x, y)
        ..cubicTo(x + sway, y - h * 0.33, x - sway, y - h * 0.66, x, y - h);
      canvas.drawPath(
        path,
        Paint()
          ..color = _ink.withValues(alpha: t * 0.75 * math.sin(math.pi * p))
          ..style = PaintingStyle.stroke
          ..strokeWidth = d * 0.02
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintSmile(Canvas canvas, Offset c, double d, double t) {
    final sweep = 0.75 * t;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: d * 0.25),
      math.pi / 2 - sweep / 2,
      sweep,
      false,
      Paint()
        ..color = _ink.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.017
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintCurvedCaption(Canvas canvas, Offset c, double d, double t) {
    const text = '•  NUR POSITIV  •';
    final radius = d * 0.355;
    final style = AppText.body(
      d * 0.066,
      weight: FontWeight.w800,
      color: _ink.withValues(alpha: t),
      letterSpacing: 0,
    );

    final painters = [
      for (final ch in text.characters)
        TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final spacing = d * 0.008;
    final total =
        painters.fold<double>(0, (sum, p) => sum + p.width + spacing) / radius;

    // Lay characters along the bottom arc, reading left to right.
    var theta = math.pi / 2 + total / 2;
    for (final p in painters) {
      final step = (p.width + spacing) / radius;
      final mid = theta - step / 2;
      canvas.save();
      canvas.translate(
        c.dx + radius * math.cos(mid),
        c.dy + radius * math.sin(mid),
      );
      canvas.rotate(mid - math.pi / 2);
      p.paint(canvas, Offset(-p.width / 2, -p.height / 2));
      canvas.restore();
      theta -= step;
      p.dispose();
    }
  }

  @override
  bool shouldRepaint(_PanPainter old) =>
      old.headroom != headroom ||
      old.entrance != entrance ||
      old.ambient != ambient;
}
