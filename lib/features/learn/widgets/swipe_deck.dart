import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../learn_session.dart';

enum SwipeDir { left, right }

/// Fraction of the card width a drag must pass to count as a swipe.
/// The stamp reaches full strength exactly at this point.
const _swipeThreshold = 0.25;

/// Lets buttons trigger the same fly-out animation as a swipe.
class SwipeController extends ChangeNotifier {
  SwipeDir? _pending;

  void swipe(SwipeDir dir) {
    _pending = dir;
    notifyListeners();
  }

  SwipeDir? _take() {
    final p = _pending;
    _pending = null;
    return p;
  }
}

/// A stack of cards: drag the top one right ("Kann ich!") or left
/// ("Nochmal"). The next cards wait behind it and move up smoothly.
class SwipeDeck extends StatelessWidget {
  const SwipeDeck({
    super.key,
    required this.cards,
    required this.cardBuilder,
    required this.onSwiped,
    required this.controller,
    this.hint = false,
  });

  /// Top card first. Only the first three are drawn.
  final List<DeckCard> cards;
  final Widget Function(DeckCard card, bool isTop) cardBuilder;
  final ValueChanged<SwipeDir> onSwiped;
  final SwipeController controller;

  /// Wiggle the top card once to teach swiping.
  final bool hint;

  @override
  Widget build(BuildContext context) {
    final visible = cards.take(3).toList();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = visible.length - 1; i >= 0; i--)
          _DeckSlot(
            key: ValueKey(visible[i].key),
            depth: i,
            controller: controller,
            hint: hint && i == 0,
            onSwiped: onSwiped,
            child: cardBuilder(visible[i], i == 0),
          ),
      ],
    );
  }
}

class _DeckSlot extends StatefulWidget {
  const _DeckSlot({
    super.key,
    required this.depth,
    required this.controller,
    required this.hint,
    required this.onSwiped,
    required this.child,
  });

  final int depth;
  final SwipeController controller;
  final bool hint;
  final ValueChanged<SwipeDir> onSwiped;
  final Widget child;

  @override
  State<_DeckSlot> createState() => _DeckSlotState();
}

class _DeckSlotState extends State<_DeckSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this);
  Animation<Offset>? _motion;
  Offset _drag = Offset.zero;
  bool _leaving = false;
  bool _pastThreshold = false;
  double _width = 360;

  bool get _isTop => widget.depth == 0;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_motion != null) setState(() => _drag = _motion!.value);
    });
    widget.controller.addListener(_onControllerSwipe);
    if (widget.hint) _scheduleHint();
  }

  @override
  void didUpdateWidget(_DeckSlot old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerSwipe);
      widget.controller.addListener(_onControllerSwipe);
    }
    if (widget.hint && !old.hint) _scheduleHint();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerSwipe);
    _anim.dispose();
    super.dispose();
  }

  void _scheduleHint() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || !_isTop || _drag != Offset.zero || _leaving) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _animate(
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset.zero, end: const Offset(46, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: const Offset(46, 0), end: const Offset(-46, 0)),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween(begin: const Offset(-46, 0), end: Offset.zero),
            weight: 1,
          ),
        ]),
        const Duration(milliseconds: 1400),
        Curves.easeInOut,
      );
    });
  }

  TickerFuture _animate(Animatable<Offset> tween, Duration d, Curve curve) {
    _anim.duration = d;
    _motion = _anim.drive(CurveTween(curve: curve)).drive(tween);
    return _anim.forward(from: 0);
  }

  void _onControllerSwipe() {
    if (!_isTop || _leaving) return;
    final dir = widget.controller._take();
    if (dir != null) _flyOut(dir, velocity: Offset.zero);
  }

  void _flyOut(SwipeDir dir, {required Offset velocity}) {
    _leaving = true;
    HapticFeedback.lightImpact();
    final sign = dir == SwipeDir.right ? 1.0 : -1.0;
    final end = Offset(sign * _width * 1.5, _drag.dy + velocity.dy * 0.08 - 40);
    _animate(
      Tween(begin: _drag, end: end),
      const Duration(milliseconds: 280),
      Curves.easeIn,
    ).whenCompleteOrCancel(() {
      if (mounted) widget.onSwiped(dir);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isTop || _leaving) return;
    _anim.stop();
    setState(() => _drag += Offset(d.delta.dx, d.delta.dy * 0.35));
    final past = _drag.dx.abs() > _width * _swipeThreshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      if (past) HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_isTop || _leaving) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_drag.dx.abs() > _width * _swipeThreshold || vx.abs() > 900) {
      final dir = (vx.abs() > 900 ? vx : _drag.dx) > 0
          ? SwipeDir.right
          : SwipeDir.left;
      _flyOut(dir, velocity: d.velocity.pixelsPerSecond);
    } else {
      _animate(
        Tween(begin: _drag, end: Offset.zero),
        const Duration(milliseconds: 550),
        Curves.elasticOut,
      );
    }
    _pastThreshold = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _width = c.maxWidth;
        final progress = (_drag.dx / (_width * _swipeThreshold)).clamp(
          -1.0,
          1.0,
        );

        // Depth: cards behind are smaller, lower and lighter.
        final card = TweenAnimationBuilder<double>(
          tween: Tween(end: widget.depth.toDouble()),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, d, child) => Transform.translate(
            offset: Offset(0, 16 * d),
            child: Transform.scale(
              scale: 1 - 0.05 * d,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: (1 - 0.25 * math.max(0, d - 1)).clamp(0, 1),
                child: child,
              ),
            ),
          ),
          child: widget.child,
        );

        return GestureDetector(
          // Track the finger from the first touch (no lost distance).
          dragStartBehavior: DragStartBehavior.down,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _drag,
            child: Transform.rotate(
              angle: _drag.dx / _width * 0.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  card,
                  if (_isTop && progress != 0) ...[
                    // Glowing outline towards the decision
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          // Border only – a shadow here would show through
                          // the transparent overlay and tint the card.
                          border: Border.all(
                            width: 4,
                            color:
                                (progress > 0
                                        ? AppColors.success
                                        : AppColors.poppy)
                                    .withValues(alpha: progress.abs()),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      left: progress > 0 ? 22 : null,
                      right: progress < 0 ? 22 : null,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: progress.abs(),
                          child: _Stamp(right: progress > 0),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.right});

  final bool right;

  @override
  Widget build(BuildContext context) {
    final color = right ? AppColors.success : AppColors.poppyText;
    return Transform.rotate(
      angle: right ? -0.22 : 0.22,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 3),
        ),
        child: Text(
          right ? 'KANN ICH! ✓' : 'NOCHMAL ↺',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: color,
          ),
        ),
      ),
    );
  }
}
