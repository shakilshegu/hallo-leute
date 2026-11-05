import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// How a [FunIcon] moves while idle.
enum FunMotion { wave, bounce, wobble, pulse, float, tada }

/// An emoji "sticker" that comes alive: it moves every few seconds and
/// does a happy jump when [active] turns true (e.g. its card is selected).
class FunIcon extends StatefulWidget {
  const FunIcon(
    this.emoji, {
    super.key,
    this.color = AppColors.sunrise,
    this.size = 48,
    this.motion = FunMotion.bounce,
    this.active = false,
    this.tilt = 0,
  });

  final String emoji;
  final Color color;
  final double size;
  final FunMotion motion;
  final bool active;

  /// Static rotation in radians for a playful sticker look.
  final double tilt;

  @override
  State<FunIcon> createState() => _FunIconState();
}

class _FunIconState extends State<FunIcon> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      // Different start point per emoji so icons don't move in sync.
      _idle.value = (widget.emoji.hashCode % 100) / 100;
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(FunIcon old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final sticker = Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color.withValues(alpha: 0.28),
            widget.color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.25),
            blurRadius: s * 0.25,
            offset: Offset(0, s * 0.08),
          ),
        ],
      ),
      child: Text(widget.emoji, style: TextStyle(fontSize: s * 0.52)),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _pop]),
      builder: (context, child) {
        var dy = 0.0, angle = widget.tilt, scale = 1.0;
        var pivot = Alignment.center;

        // Idle motion happens in the first 35% of the cycle, then rests.
        final v = _idle.value;
        final a = v < 0.35 ? v / 0.35 : -1.0;
        if (a >= 0) {
          final decay = 1 - a;
          switch (widget.motion) {
            case FunMotion.wave:
              angle += math.sin(a * math.pi * 4) * 0.35 * decay;
              pivot = const Alignment(0.6, 0.8);
            case FunMotion.bounce:
              dy = -(math.sin(a * math.pi * 2)).abs() * s * 0.14 * decay;
            case FunMotion.wobble:
              angle += math.sin(a * math.pi * 6) * 0.14 * decay;
            case FunMotion.pulse:
              scale = 1 + 0.1 * math.sin(a * math.pi);
            case FunMotion.tada:
              scale = 1 + 0.1 * math.sin(a * math.pi);
              angle += math.sin(a * math.pi * 6) * 0.1 * decay;
            case FunMotion.float:
              break;
          }
        }
        if (widget.motion == FunMotion.float) {
          dy = math.sin(v * 2 * math.pi) * s * 0.06;
        }

        // Happy jump when activated
        final p = _pop.value;
        if (_pop.isAnimating) {
          dy -= math.sin(p * math.pi) * s * 0.25;
          scale *= 1 + 0.22 * math.sin(p * math.pi);
          angle += math.sin(p * math.pi * 4) * 0.18 * (1 - p);
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            alignment: pivot,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: ExcludeSemantics(child: sticker),
    );
  }
}
