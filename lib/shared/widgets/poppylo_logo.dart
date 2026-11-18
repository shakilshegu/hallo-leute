import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Draws the Poppylo mark: a cream speech bubble (language, speaking) with a
/// mustard poppy blooming inside it (the name).
///
/// Used both by the animated [PoppyloLogo] and by the icon generator in
/// `tool/icon/`, so the app icon and the in-app logo always match.
abstract final class PoppyloMark {
  /// Paints the mark into a square of [size] at the canvas origin.
  ///
  /// [bubble], [petals] and [center] run 0 → 1 for the entrance animation;
  /// [sway] is a small rotation (radians) for the idle animation.
  static void paint(
    Canvas canvas,
    double size, {
    double bubble = 1,
    double petals = 1,
    double center = 1,
    double sway = 0,
    Color bubbleColor = AppColors.cream,
    Color petalColor = AppColors.mustard,
    Color petalShade = AppColors.mustardDeep,
    Color centerColor = AppColors.navy,
    Color dotColor = AppColors.cream,
    bool knockout = false,
  }) {
    final s = size;
    final flowerCenter = Offset(s * 0.5, s * 0.44);

    // Speech bubble with a tail at the bottom left.
    if (bubble > 0) {
      canvas.save();
      canvas.translate(flowerCenter.dx, flowerCenter.dy);
      canvas.scale(bubble);
      canvas.translate(-flowerCenter.dx, -flowerCenter.dy);
      final body = RRect.fromLTRBR(
        s * 0.06,
        s * 0.06,
        s * 0.94,
        s * 0.82,
        Radius.circular(s * 0.27),
      );
      final tail = Path()
        ..moveTo(s * 0.20, s * 0.74)
        ..lineTo(s * 0.42, s * 0.80)
        ..quadraticBezierTo(s * 0.24, s * 0.86, s * 0.13, s * 0.96)
        ..quadraticBezierTo(s * 0.20, s * 0.84, s * 0.20, s * 0.74)
        ..close();
      final path = Path()
        ..addRRect(body)
        ..addPath(tail, Offset.zero);
      canvas.drawPath(path, Paint()..color = bubbleColor);
      canvas.restore();
    }

    // Five rounded petals, blooming one after another.
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.save();
    canvas.translate(flowerCenter.dx, flowerCenter.dy);
    canvas.rotate(sway + (1 - petals) * -0.5);
    for (var i = 0; i < 5; i++) {
      final t = ((petals * 5) - i).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final offset = Offset(math.cos(angle), math.sin(angle)) * (s * 0.125);
      final r = s * 0.135 * Curves.easeOutBack.transform(t);
      canvas.drawCircle(
        offset,
        r,
        knockout
            ? clear
            : (Paint()..color = i.isEven ? petalColor : petalShade),
      );
    }
    // Dark centre.
    if (center > 0) {
      final cr = s * 0.085 * Curves.easeOutBack.transform(center);
      canvas.drawCircle(
        Offset.zero,
        cr,
        knockout
            ? (Paint()..color = bubbleColor)
            : (Paint()..color = centerColor),
      );
      if (!knockout) {
        // A ring of tiny stamens, like a real poppy centre.
        for (var i = 0; i < 6; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 6;
          canvas.drawCircle(
            Offset(math.cos(a), math.sin(a)) * (cr * 0.58),
            s * 0.0105 * center,
            Paint()..color = dotColor,
          );
        }
      }
    }
    canvas.restore();
  }
}

/// The animated Poppylo logo: the bubble pops in, the poppy blooms petal by
/// petal, then the wordmark appears. [ambient] adds a gentle sway.
class PoppyloLogo extends StatelessWidget {
  const PoppyloLogo({
    super.key,
    required this.size,
    required this.entrance,
    required this.ambient,
    this.wordmark = true,
  });

  /// Width of the mark (the wordmark scales with it).
  final double size;
  final Animation<double> entrance;
  final Animation<double> ambient;
  final bool wordmark;

  /// Total height for a given [size].
  static double heightFor(double size, {bool wordmark = true}) =>
      size * (wordmark ? 1.36 : 1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Poppylo',
      image: true,
      child: SizedBox(
        width: size,
        height: heightFor(size, wordmark: wordmark),
        child: Column(
          children: [
            SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _MarkPainter(entrance: entrance, ambient: ambient),
              ),
            ),
            if (wordmark)
              Expanded(
                child: ExcludeSemantics(
                  child: _Wordmark(size: size, entrance: entrance),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.entrance, required this.ambient})
    : super(repaint: Listenable.merge([entrance, ambient]));

  final Animation<double> entrance;
  final Animation<double> ambient;

  static double _phase(
    double t,
    double a,
    double b, [
    Curve c = Curves.linear,
  ]) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final e = entrance.value;
    // Paint in a layer so the knockout-free mark composites cleanly.
    canvas.saveLayer(Offset.zero & size, Paint());
    PoppyloMark.paint(
      canvas,
      size.width,
      bubble: _phase(e, 0.0, 0.4, Curves.elasticOut),
      petals: _phase(e, 0.25, 0.7),
      center: _phase(e, 0.6, 0.8),
      sway: 0.05 * math.sin(2 * math.pi * ambient.value * 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.entrance != entrance || old.ambient != ambient;
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.size, required this.entrance});

  final double size;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    const word = 'Poppylo';
    final style = AppText.display(
      size * 0.26,
      weight: FontWeight.w600,
      color: AppColors.cream,
      height: 1,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < word.length; i++)
            AnimatedBuilder(
              animation: entrance,
              builder: (context, child) {
                final start = 0.6 + i * 0.045;
                final t = Curves.easeOutBack.transform(
                  ((entrance.value - start) / 0.25).clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * size * 0.06),
                    child: child,
                  ),
                );
              },
              child: Text(word[i], style: style),
            ),
        ],
      ),
    );
  }
}
