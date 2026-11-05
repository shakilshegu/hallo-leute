import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

enum PoppyMood { happy, excited, thinking, wink }

/// Poppy – the Poppylo mascot. A poppy flower with a face that blinks,
/// bobs gently and changes expression with [mood].
class PoppyMascot extends StatefulWidget {
  const PoppyMascot({super.key, this.size = 64, this.mood = PoppyMood.happy});

  final double size;
  final PoppyMood mood;

  @override
  State<PoppyMascot> createState() => _PoppyMascotState();
}

class _PoppyMascotState extends State<PoppyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Poppy, the Poppylo flower',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _MascotPainter(t: _c.value, mood: widget.mood),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.t, required this.mood});

  final double t; // 0..1 animation cycle
  final PoppyMood mood;

  static const _face = Color(0xFFFFF1E6);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * 2 * math.pi);
    final excited = mood == PoppyMood.excited;
    final bob = (excited ? 0.06 : 0.035) * size.height * wave;
    final r = size.shortestSide / 2 * 0.9;
    final c = size.center(Offset.zero) + Offset(0, bob);

    // Petals – sway gently, puff up a bit when excited
    final sway = (excited ? 0.12 : 0.06) * math.sin(t * 2 * math.pi * 2);
    final petalR = r * (excited ? 0.54 + 0.02 * wave.abs() : 0.52);
    final petalPaint = Paint()
      ..shader = AppColors.bloomGradient.createShader(
        Rect.fromCircle(center: c, radius: r),
      );
    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2 + sway;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (r - petalR),
        petalR,
        petalPaint,
      );
    }

    // Face
    final faceR = r * 0.5;
    canvas.drawCircle(c, faceR, Paint()..color = _face);
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = AppColors.ink.withValues(alpha: 0.06),
    );

    final ink = Paint()..color = AppColors.ink;
    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;

    // Blink once per cycle
    final blinking = t > 0.90 && t < 0.94;
    final look = mood == PoppyMood.thinking
        ? Offset(r * 0.04, -r * 0.05)
        : Offset.zero;
    final eyeL = c + Offset(-r * 0.17, -r * 0.06) + look;
    final eyeR = c + Offset(r * 0.17, -r * 0.06) + look;

    void openEye(Offset p) {
      canvas.drawOval(
        Rect.fromCenter(
          center: p,
          width: r * 0.1,
          height: r * (blinking ? 0.02 : 0.14),
        ),
        ink,
      );
      if (!blinking) {
        canvas.drawCircle(
          p + Offset(r * 0.018, -r * 0.03),
          r * 0.022,
          Paint()..color = Colors.white,
        );
      }
    }

    void happyEye(Offset p) => canvas.drawArc(
      Rect.fromCenter(center: p, width: r * 0.14, height: r * 0.12),
      math.pi,
      math.pi,
      false,
      stroke,
    );

    switch (mood) {
      case PoppyMood.excited:
        happyEye(eyeL);
        happyEye(eyeR);
      case PoppyMood.wink:
        openEye(eyeL);
        happyEye(eyeR);
      case PoppyMood.happy || PoppyMood.thinking:
        openEye(eyeL);
        openEye(eyeR);
    }

    // Rosy cheeks
    final cheek = Paint()..color = AppColors.die.withValues(alpha: 0.35);
    for (final dx in [-0.29, 0.29]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(r * dx, r * 0.1),
          width: r * 0.13,
          height: r * 0.08,
        ),
        cheek,
      );
    }

    // Mouth
    final mouthC = c + Offset(0, r * 0.12);
    switch (mood) {
      case PoppyMood.excited:
        final rect = Rect.fromCenter(
          center: mouthC,
          width: r * 0.24,
          height: r * 0.22,
        );
        canvas.drawArc(rect, 0, math.pi, true, ink);
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthC + Offset(0, r * 0.07),
            width: r * 0.12,
            height: r * 0.07,
          ),
          0,
          math.pi,
          true,
          Paint()..color = AppColors.die,
        );
      case PoppyMood.thinking:
        canvas.drawCircle(
          mouthC + Offset(r * 0.05, r * 0.03),
          r * 0.035,
          stroke,
        );
      case PoppyMood.happy || PoppyMood.wink:
        canvas.drawArc(
          Rect.fromCenter(center: mouthC, width: r * 0.2, height: r * 0.14),
          0.15 * math.pi,
          0.7 * math.pi,
          false,
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.t != t || old.mood != mood;
}

/// Poppy with a speech bubble – used to guide the learner.
class PoppySays extends StatelessWidget {
  const PoppySays({
    super.key,
    required this.text,
    this.translation,
    this.mood = PoppyMood.happy,
    this.mascotSize = 60,
  });

  final String text;

  /// Optional small English line under a German [text].
  final String? translation;
  final PoppyMood mood;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PoppyMascot(size: mascotSize, mood: mood)
            .animate()
            .scale(
              begin: const Offset(0.4, 0.4),
              duration: 700.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 150.ms),
        const SizedBox(width: 10),
        Flexible(
          child:
              Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.3,
                          ),
                        ),
                        if (translation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            translation!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 250.ms)
                  .scaleXY(
                    begin: 0.85,
                    alignment: Alignment.centerLeft,
                    delay: 180.ms,
                    duration: 350.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
      ],
    );
  }
}
