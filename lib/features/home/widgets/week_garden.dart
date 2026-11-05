import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/home_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/poppy_logo.dart';

const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// This week as a row of little flowers – one per day.
/// Weekday labels are German so learners pick them up on the way.
class WeekGarden extends StatelessWidget {
  const WeekGarden({super.key, required this.week, required this.goal});

  final List<DayBloom> week;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, day) in week.indexed)
          _DayFlower(label: _weekdays[i], day: day, goal: goal)
              .animate()
              .fadeIn(delay: (60 * i).ms, duration: 250.ms)
              .scaleXY(
                begin: 0.6,
                delay: (60 * i).ms,
                duration: 450.ms,
                curve: Curves.easeOutBack,
              ),
      ],
    );
  }
}

class _DayFlower extends StatelessWidget {
  const _DayFlower({
    required this.label,
    required this.day,
    required this.goal,
  });

  final String label;
  final DayBloom day;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final flower = switch (day.state) {
      BloomState.bloom => const PoppyLogo(size: 30),
      BloomState.bud => CustomPaint(
        size: const Size.square(30),
        painter: _BudPainter(math.min(day.learned / goal, 1)),
      ),
      BloomState.empty => CustomPaint(
        size: const Size.square(30),
        painter: _DashedCirclePainter(),
      ),
      BloomState.future => const SizedBox.square(
        dimension: 30,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.outline,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 6),
          ),
        ),
      ),
    };

    return Semantics(
      label: '$label: ${day.learned} words',
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: day.isToday
              ? AppColors.sunrise.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            flower,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
                color: day.isToday ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day with some words but below the goal: a filling ring + bud.
class _BudPainter extends CustomPainter {
  _BudPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.outline,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = AppColors.bloomGradient.createShader(
          Rect.fromCircle(center: c, radius: r),
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 0.6, height: r * 0.8),
      Paint()..color = AppColors.poppy.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_BudPainter old) => old.fraction != fraction;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.muted.withValues(alpha: 0.35);
    const dashes = 12;
    for (var i = 0; i < dashes; i++) {
      final a = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
