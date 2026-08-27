import 'package:flutter/material.dart';
import 'dart:ui';

/// INTERACTIVE ADVENTURE homepage concept — learning as a journey.
/// A winding path of milestone nodes (locked / current / completed)
/// replaces the traditional list of cards, with a floating XP/streak HUD
/// and an upcoming-challenge banner up top.
class AdventureHomeScreen extends StatelessWidget {
  const AdventureHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Jungle-at-dusk gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF150B2E),
                    const Color(0xFF0F2A3D),
                    const Color(0xFF063B3A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const _AdventureHud(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                    children: const [
                      _ChallengeBanner(),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Your Learning Path',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      _LearningPath(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _AdventureBottomNav(),
          ),
        ],
      ),
    );
  }
}

/// Floating streak / XP / level HUD pinned under the safe area.
class _AdventureHud extends StatelessWidget {
  const _AdventureHud();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _HudStat(icon: Icons.local_fire_department_rounded, value: '9', color: Color(0xFFFF7A45)),
            _HudDivider(),
            _HudStat(icon: Icons.bolt_rounded, value: '760 XP', color: Color(0xFFFFC857)),
            _HudDivider(),
            _HudStat(icon: Icons.shield_moon_rounded, value: 'Lv 5', color: Color(0xFF7DD3FC)),
          ],
        ),
      ),
    );
  }
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 20, color: Colors.white.withOpacity(0.15));
  }
}

class _HudStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _HudStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner();

  @override
  Widget build(BuildContext context) {
    const progress = 3 / 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFC857), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Challenge',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Complete 5 lessons this week',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC857)),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '3 of 5 · Reward: 100 XP chest',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeState { completed, current, locked }

class _PathNode {
  final String title;
  final String subtitle;
  final IconData icon;
  final _NodeState state;
  const _PathNode(this.title, this.subtitle, this.icon, this.state);
}

class _PathRow {
  final String? header;
  final _PathNode? node;
  const _PathRow.header(this.header) : node = null;
  const _PathRow.node(this.node) : header = null;
}

class _LearningPath extends StatelessWidget {
  const _LearningPath();

  static const _rows = [
    _PathRow.header('LEVEL 1 · FOUNDATIONS'),
    _PathRow.node(_PathNode('Alphabet Basics', '10 words · done', Icons.check_rounded, _NodeState.completed)),
    _PathRow.node(_PathNode('Greetings', '8 phrases · done', Icons.check_rounded, _NodeState.completed)),
    _PathRow.node(_PathNode('Numbers 1-20', 'In progress', Icons.play_arrow_rounded, _NodeState.current)),
    _PathRow.header('LEVEL 2 · EVERYDAY LIFE'),
    _PathRow.node(_PathNode('Everyday Phrases', 'Locked', Icons.lock_rounded, _NodeState.locked)),
    _PathRow.node(_PathNode('Food & Dining', 'Locked', Icons.lock_rounded, _NodeState.locked)),
    _PathRow.node(_PathNode('Travel German', 'Milestone', Icons.emoji_events_rounded, _NodeState.locked)),
  ];

  static const double _nodeRowHeight = 128;
  static const double _headerRowHeight = 44;
  static const double _nodeRadius = 34;
  static const _xFractions = [0.24, 0.5, 0.76, 0.5];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usableWidth = width - (_nodeRadius * 2);

        final centers = <Offset>[];
        final headerPositions = <(double y, String text)>[];
        var y = 0.0;
        var nodeIndex = 0;

        for (final row in _rows) {
          if (row.header != null) {
            headerPositions.add((y, row.header!));
            y += _headerRowHeight;
          } else {
            final fraction = _xFractions[nodeIndex % _xFractions.length];
            final dx = _nodeRadius + usableWidth * fraction;
            final dy = y + _nodeRowHeight / 2;
            centers.add(Offset(dx, dy));
            y += _nodeRowHeight;
            nodeIndex++;
          }
        }

        final totalHeight = y;

        return SizedBox(
          width: width,
          height: totalHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(centers),
                ),
              ),
              for (final h in headerPositions)
                Positioned(
                  top: h.$1 + 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        h.$2,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < centers.length; i++)
                Positioned(
                  left: centers[i].dx - _nodeRadius,
                  top: centers[i].dy - _nodeRadius,
                  child: _PathNodeWidget(
                    node: _nodesOnly[i],
                    radius: _nodeRadius,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static List<_PathNode> get _nodesOnly =>
      _rows.where((r) => r.node != null).map((r) => r.node!).toList();
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 10.0;
    const dashGap = 8.0;
    final totalDistance = (end - start).distance;
    final direction = (end - start) / totalDistance;
    var covered = 0.0;
    var draw = true;
    var current = start;
    while (covered < totalDistance) {
      final segment = draw ? dashWidth : dashGap;
      final next = current + direction * segment;
      if (draw) {
        canvas.drawLine(current, next, paint);
      }
      current = next;
      covered += segment;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => oldDelegate.points != points;
}

class _PathNodeWidget extends StatelessWidget {
  final _PathNode node;
  final double radius;
  const _PathNodeWidget({required this.node, required this.radius});

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final isCurrent = node.state == _NodeState.current;

    Gradient? gradient;
    Color? flatColor;
    Color iconColor = Colors.white;
    List<BoxShadow>? glow;

    switch (node.state) {
      case _NodeState.completed:
        gradient = const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]);
        break;
      case _NodeState.current:
        gradient = const LinearGradient(colors: [Color(0xFFFFC857), Color(0xFFFF8A3D)]);
        glow = [
          BoxShadow(color: const Color(0xFFFFC857).withOpacity(0.6), blurRadius: 20, spreadRadius: 3),
        ];
        break;
      case _NodeState.locked:
        flatColor = Colors.white.withOpacity(0.10);
        iconColor = Colors.white38;
        break;
    }

    return SizedBox(
      width: diameter,
      height: diameter + 40,
      child: Column(
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              color: flatColor,
              border: Border.all(
                color: node.state == _NodeState.locked ? Colors.white24 : Colors.white.withOpacity(0.6),
                width: isCurrent ? 3 : 2,
              ),
              boxShadow: glow,
            ),
            child: Icon(node.icon, color: iconColor, size: isCurrent ? 30 : 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: diameter + 40,
            child: Text(
              node.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: node.state == _NodeState.locked ? Colors.white38 : Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdventureBottomNav extends StatelessWidget {
  const _AdventureBottomNav();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, true),
              _buildNavItem(Icons.route_rounded, false),
              _buildNavItem(Icons.storefront_outlined, false),
              _buildNavItem(Icons.emoji_events_outlined, false),
              _buildNavItem(Icons.person_outline, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFC857) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFF150B2E) : Colors.white70,
        size: 24,
      ),
    );
  }
}
