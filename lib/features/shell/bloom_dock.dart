import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class DockItem {
  const DockItem({
    required this.icon,
    required this.german,
    required this.english,
  });

  final IconData icon;
  final String german;
  final String english;
}

/// Floating dark dock. The selected tab grows into a gradient "bloom"
/// with its German label, and a burst of tiny petals pops on tap.
class BloomDock extends StatelessWidget {
  const BloomDock({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    this.badges = const {},
  });

  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  /// Tab index → show a small dot (e.g. reviews waiting).
  final Set<int> badges;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF26262F), AppColors.ink],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final selectedW = c.maxWidth * 0.4;
              final otherW = (c.maxWidth - selectedW) / (items.length - 1);
              return Row(
                children: [
                  for (final (i, item) in items.indexed)
                    _DockTab(
                      item: item,
                      selected: i == index,
                      width: i == index ? selectedW : otherW,
                      badge: badges.contains(i),
                      onTap: () {
                        if (i != index) HapticFeedback.lightImpact();
                        onSelect(i);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatefulWidget {
  const _DockTab({
    required this.item,
    required this.selected,
    required this.width,
    required this.badge,
    required this.onTap,
  });

  final DockItem item;
  final bool selected;
  final double width;
  final bool badge;
  final VoidCallback onTap;

  @override
  State<_DockTab> createState() => _DockTabState();
}

class _DockTabState extends State<_DockTab> with TickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _jelly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didUpdateWidget(_DockTab old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _burst.forward(from: 0);
      _jelly.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _jelly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    const duration = Duration(milliseconds: 420);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.english,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Width springs (overshoot is safe: the growing and shrinking tabs
        // use the same curve, so the total width stays constant).
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.width),
          duration: duration,
          curve: Curves.easeOutBack,
          builder: (context, w, child) => SizedBox(width: w, child: child),
          // Colour + glow fade smoothly (no overshoot).
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: selected
                    ? const [AppColors.poppy, AppColors.sunrise]
                    : [
                        AppColors.poppy.withValues(alpha: 0),
                        AppColors.sunrise.withValues(alpha: 0),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.poppy.withValues(alpha: selected ? 0.45 : 0),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRect(
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with jelly bounce + petal burst + badge
                  SizedBox.square(
                    dimension: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _burst,
                              builder: (context, _) => CustomPaint(
                                painter: _BurstPainter(_burst.value),
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _jelly,
                          builder: (context, child) {
                            final t = _jelly.value;
                            final s = _jelly.isAnimating
                                ? 1 + 0.25 * math.sin(t * math.pi) * (1 - t)
                                : 1.0;
                            return Transform.scale(
                              scaleX: s,
                              scaleY: 2 - s,
                              child: child,
                            );
                          },
                          child: Icon(
                            widget.item.icon,
                            size: 24,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        if (widget.badge)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : AppColors.sunrise,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.poppy
                                      : AppColors.ink,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // German label slides in for the selected tab
                  AnimatedSize(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: duration,
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(8 * (1 - v), 0),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                widget.item.german,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Six tiny petals flying out from the icon.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  static const _colors = [
    Colors.white,
    AppColors.sunrise,
    AppColors.lavender,
    AppColors.die,
    AppColors.der,
    AppColors.das,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final p = c + Offset(math.cos(a), math.sin(a)) * (10 + 18 * ease);
      canvas.drawCircle(
        p,
        3 * (1 - t),
        Paint()..color = _colors[i].withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
