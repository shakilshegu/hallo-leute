import 'package:flutter/material.dart';

/// Fade + small upward slide driven by [animation].
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// A column whose children fade/slide in one after another when it first
/// appears. Respects the platform "reduce motion" setting.
class StaggeredColumn extends StatefulWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  static const _step = 50;
  static const _each = 340;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _each + _step * (widget.children.length - 1).clamp(0, 99),
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    // Children added after the first build (e.g. a card that appears later)
    // simply show at the end instead of breaking the timeline.
    Interval interval(int i) {
      final end = ((i * _step) + _each) / total;
      if (end <= 1) {
        return Interval((i * _step) / total, end, curve: Curves.easeOutCubic);
      }
      return const Interval(0.999, 1);
    }

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Reveal(
            animation: CurvedAnimation(parent: _controller, curve: interval(i)),
            child: widget.children[i],
          ),
      ],
    );
  }
}
