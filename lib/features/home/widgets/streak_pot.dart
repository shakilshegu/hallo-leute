import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_theme.dart';

/// Growth stages of the streak plant.
enum StreakStage {
  seed('Samen', 'Seed', 0),
  sprout('Keimling', 'Sprout', 1),
  bud('Knospe', 'Bud', 3),
  bloom('Blüte', 'Bloom', 5),
  fullBloom('Prachtblüte', 'Full bloom', 7);

  const StreakStage(this.german, this.english, this.fromDays);

  final String german;
  final String english;
  final int fromDays;

  static StreakStage of(int streak) =>
      values.lastWhere((s) => streak >= s.fromDays);
}

/// A potted plant that grows with the learner's streak.
class StreakPot extends StatefulWidget {
  const StreakPot({super.key, required this.stage, this.size = 36});

  final StreakStage stage;
  final double size;

  @override
  State<StreakPot> createState() => _StreakPotState();
}

class _StreakPotState extends State<StreakPot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sway.stop();
    } else if (!_sway.isAnimating) {
      _sway.repeat();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _sway,
        builder: (context, _) => CustomPaint(
          painter: _PotPainter(stage: widget.stage, t: _sway.value),
        ),
      ),
    );
  }
}

class _PotPainter extends CustomPainter {
  _PotPainter({required this.stage, required this.t});

  final StreakStage stage;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wave = math.sin(t * 2 * math.pi);

    // Pot
    final potTop = h * 0.64;
    final pot = Path()
      ..moveTo(w * 0.24, potTop)
      ..lineTo(w * 0.76, potTop)
      ..lineTo(w * 0.68, h * 0.98)
      ..lineTo(w * 0.32, h * 0.98)
      ..close();
    canvas.drawPath(pot, Paint()..color = AppColors.sunrise);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, potTop - h * 0.06, w * 0.64, h * 0.12),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = AppColors.sunriseText,
    );
    // Soil
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, potTop - h * 0.06),
        width: w * 0.52,
        height: h * 0.06,
      ),
      Paint()..color = AppColors.ink.withValues(alpha: 0.85),
    );

    final ground = Offset(w / 2, potTop - h * 0.07);
    if (stage == StreakStage.seed) {
      canvas.drawOval(
        Rect.fromCenter(
          center: ground.translate(0, -h * 0.03),
          width: w * 0.12,
          height: h * 0.08,
        ),
        Paint()..color = const Color(0xFF8A5A3B),
      );
      return;
    }

    // Plant sways around the soil point
    canvas.save();
    canvas.translate(ground.dx, ground.dy);
    canvas.rotate(wave * 0.06);

    final stemH = switch (stage) {
      StreakStage.sprout => h * 0.2,
      StreakStage.bud => h * 0.36,
      _ => h * 0.42,
    };
    final green = Paint()
      ..color = AppColors.das
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, -stemH), green);

    // Leaves
    final leaf = Paint()..color = AppColors.das;
    void drawLeaf(double y, double dir) {
      canvas.save();
      canvas.translate(0, y);
      canvas.rotate(dir * (0.7 + wave * 0.08));
      canvas.drawOval(
        Rect.fromLTWH(0, -h * 0.045, w * 0.2 * dir.sign, h * 0.09),
        leaf,
      );
      canvas.restore();
    }

    drawLeaf(-stemH * 0.45, 1);
    drawLeaf(-stemH * 0.6, -1);

    final head = Offset(0, -stemH);
    switch (stage) {
      case StreakStage.sprout:
        break;
      case StreakStage.bud:
        canvas.drawOval(
          Rect.fromCenter(
            center: head.translate(0, -h * 0.05),
            width: w * 0.16,
            height: h * 0.2,
          ),
          Paint()..color = AppColors.poppy,
        );
        canvas.drawArc(
          Rect.fromCenter(center: head, width: w * 0.2, height: h * 0.12),
          0,
          math.pi,
          true,
          leaf,
        );
      case StreakStage.bloom || StreakStage.fullBloom:
        final full = stage == StreakStage.fullBloom;
        final r = w * (full ? 0.2 : 0.16);
        final petals = Paint()
          ..shader = AppColors.bloomGradient.createShader(
            Rect.fromCircle(center: head, radius: r * 2),
          );
        for (var i = 0; i < 4; i++) {
          final a = math.pi / 4 + i * math.pi / 2 + wave * 0.1;
          canvas.drawCircle(
            head + Offset(math.cos(a), math.sin(a)) * r * 0.55,
            r * 0.62,
            petals,
          );
        }
        canvas.drawCircle(head, r * 0.32, Paint()..color = AppColors.ink);
        if (full) {
          // Twinkling sparkles
          for (final (i, o) in [
            Offset(-w * 0.3, -h * 0.1),
            Offset(w * 0.3, -h * 0.16),
            Offset(w * 0.22, h * 0.08),
          ].indexed) {
            final s = (math.sin((t * 2 + i / 3) * 2 * math.pi) + 1) / 2;
            _sparkle(canvas, head + o, w * 0.05 * (0.5 + s), i);
          }
        }
      case StreakStage.seed:
        break;
    }
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset p, double r, int i) {
    final paint = Paint()
      ..color = i.isEven ? AppColors.lavender : AppColors.sunrise;
    final path = Path()
      ..moveTo(p.dx, p.dy - r * 2)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + r * 2, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r * 2)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - r * 2, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r * 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PotPainter old) => old.t != t || old.stage != stage;
}

/// Compact streak pill for the Home header. Tap → streak garden sheet.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final stage = StreakStage.of(streak);

    return Semantics(
      button: true,
      label: '$streak day streak',
      child: Material(
        color: AppColors.surface,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.outline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            showStreakSheet(context, streak);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakPot(stage: stage, size: 34),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      streak == 1 ? 'Tag' : 'Tage',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.1,
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
      ),
    );
  }
}

/// Explains the streak garden and shows every growth stage.
Future<void> showStreakSheet(BuildContext context, int streak) {
  final stage = StreakStage.of(streak);
  final next = StreakStage.values.where((s) => s.fromDays > streak).firstOrNull;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreakPot(stage: stage, size: 120).animate().scale(
                begin: const Offset(0.6, 0.6),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 12),
              Text(
                streak == 0
                    ? 'Plant your first seed 🌱'
                    : '$streak-day streak! ${stage.german}!',
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? 'Your plant is in full bloom. Keep it happy with a few '
                          'words every day.'
                    : 'Learn at least one word a day and your plant keeps '
                          'growing. ${next.fromDays - streak} more '
                          '${next.fromDays - streak == 1 ? 'day' : 'days'} '
                          'until it becomes a ${next.english.toLowerCase()}!',
                style: text.bodyLarge?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final s in StreakStage.values)
                    _StageTile(stage: s, current: s == stage),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.current});

  final StreakStage stage;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 250.ms,
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: current ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current ? AppColors.sunrise : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: current ? 1 : 0.55,
            child: StreakPot(stage: stage, size: 38),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              stage.german,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${stage.fromDays}+ days',
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
