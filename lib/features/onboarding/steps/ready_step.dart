import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../landing/widgets/pan_logo.dart';
import '../onboarding_data.dart';

/// Final step: the pan logo cooks up a little burst, then a plan summary.
class ReadyStep extends StatefulWidget {
  const ReadyStep({super.key, required this.data});

  final OnboardingData data;

  @override
  State<ReadyStep> createState() => _ReadyStepState();
}

class _ReadyStepState extends State<ReadyStep> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Animation<double> _interval(double a, double b) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(a, b, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data.name.trim();
    final goals = LearningGoal.values
        .where(data.goals.contains)
        .map((g) => g.label)
        .join(', ');
    final level = data.level;

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(
          140.0,
          (constraints.maxWidth - 40) / PanLogo.widthFactor,
        );
        final logoSize = PanLogo.sizeFor(diameter);

        return Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: logoSize.width,
              height: logoSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: diameter * PanLogo.headroomFactor,
                    width: diameter,
                    height: diameter,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _BurstPainter(_interval(0.45, 1.0)),
                      ),
                    ),
                  ),
                  PanLogo(
                    diameter: diameter,
                    entrance: _entrance,
                    ambient: _ambient,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Reveal(
              animation: _interval(0.5, 0.75),
              child: Text(
                name.isEmpty ? 'Alles klar!' : 'Alles klar, $name!',
                textAlign: TextAlign.center,
                style: AppText.display(
                  30,
                  color: AppColors.cream,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Reveal(
              animation: _interval(0.56, 0.8),
              child: Text(
                "Your plan is ready. Let's cook up your first words!",
                textAlign: TextAlign.center,
                style: AppText.body(
                  15,
                  color: AppColors.creamMuted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Reveal(
              animation: _interval(0.62, 0.88),
              child: _SummaryCard(
                rows: [
                  if (goals.isNotEmpty)
                    (Icons.flag_outlined, 'Your goal', goals),
                  if (level != null)
                    (
                      Icons.signal_cellular_alt_rounded,
                      'Your level',
                      '${level.code} · ${level.title}',
                    ),
                  (
                    Icons.local_fire_department_outlined,
                    'Daily goal',
                    '${data.dailyGoal.words} words a day',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Reveal(animation: _interval(0.7, 0.95), child: const _FirstWord()),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.navyLine.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 20, color: AppColors.mustard),
                  const SizedBox(width: 12),
                  Text(
                    rows[i].$2,
                    style: AppText.body(14, color: AppColors.creamMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.right,
                      style: AppText.body(
                        14,
                        weight: FontWeight.w800,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FirstWord extends StatelessWidget {
  const _FirstWord();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR FIRST WORD',
                  style: AppText.body(
                    11.5,
                    weight: FontWeight.w800,
                    color: AppColors.navy.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'der ',
                        style: AppText.display(
                          22,
                          color: AppColors.mustardDeep,
                        ),
                      ),
                      TextSpan(
                        text: 'Anfang',
                        style: AppText.display(22, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                Text(
                  'the beginning',
                  style: AppText.body(14, color: AppColors.navy700),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.mustard,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Little celebratory dots flying out from the pan.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final d = size.width;
    const count = 16;
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count + (i.isOdd ? 0.18 : 0);
      final dist = d * (0.55 + (i.isOdd ? 0.28 : 0.42) * t);
      final p = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      canvas.drawCircle(
        p,
        d * (i.isOdd ? 0.018 : 0.026) * (1 - t * 0.5),
        Paint()
          ..color = (i % 3 == 0 ? AppColors.cream : AppColors.mustard)
              .withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
