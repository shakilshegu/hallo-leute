import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/state/search_controller.dart';

enum SearchState {
  initial,
  stillLooking,
  matchesFound,
}

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key});

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  Timer? _stateTimer;
  final List<_Blip> _blips = [];
  Timer? _blipTimer;

  SearchState _currentState = SearchState.initial;
  int _secondsElapsed = 0; // Start at 0
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    // Actual ticking clock
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    // Pulse animation for the center dot / coffee cup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for the radar sweep
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Randomly generate blips for initial state
    _blipTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _currentState == SearchState.initial) {
        setState(() {
          _blips.add(_Blip(
            angle: math.Random().nextDouble() * 2 * math.pi,
            distance: 0.3 + math.Random().nextDouble() * 0.5,
            createdAt: DateTime.now(),
            imageUrl:
                'https://i.pravatar.cc/100?img=${math.Random().nextInt(70)}',
          ));
          _blips.removeWhere((blip) =>
              DateTime.now().difference(blip.createdAt).inSeconds > 3);
        });
      }
    });

    // Realistic simulated flow
    _simulateSearchFlow();
  }

  void _simulateSearchFlow() {
    // 1. Stay in Initial for 8 seconds
    _stateTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _currentState == SearchState.initial) {
        setState(() {
          _currentState = SearchState.stillLooking;
        });
      }
    });
  }

  void _expandSearch() {
    if (mounted) {
      setState(() {
        _currentState = SearchState.initial;
        // Reset timer for expanded search? Let's keep it running to show total time
      });

      // 2. Simulate finding a match shortly after expanding
      _stateTimer?.cancel();
      _stateTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _currentState = SearchState.matchesFound;
          });

          // MOCK BACKEND RESULT: Auto-transition to Match Found details
          _stateTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) {
              _onMatchFound('test_match');
            }
          });
        }
      });
    }
  }

  void _onMatchFound(String matchId) {
    HapticFeedback.heavyImpact();
    // Searching can't be popped back into from Match found.
    context.go(AppRoutes.matchPath(matchId));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _stateTimer?.cancel();
    _blipTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _timeFormatted {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    // The design shows "0:66" which is odd, but let's just format it normally or match the weirdness if we want.
    // For simplicity, standard format:
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF1F3C2C), // Dark green background matching design
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(builder: (context) {
                    final request = ref.watch(searchControllerProvider);
                    final suffix = request == null
                        ? ''
                        : ' · ${request.timeLabel.toUpperCase()} · ${request.radiusKm.round()} KM';
                    return Text(
                      'SEARCHING · $_timeFormatted$suffix',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  if (_currentState == SearchState.initial)
                    Icon(
                      Icons.radar,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Main Visualization Area
                    SizedBox(
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentState == SearchState.initial) ...[
                            _buildRadarGraphics(),
                          ] else ...[
                            _buildGlowingCoffeeCup(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main Content based on state
                    if (_currentState == SearchState.initial)
                      _buildInitialContent()
                    else if (_currentState == SearchState.stillLooking)
                      _buildStillLookingContent()
                    else if (_currentState == SearchState.matchesFound)
                      _buildMatchesFoundContent(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingCoffeeCup() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow rings
            Container(
              width: 240 * _scaleAnimation.value,
              height: 240 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 160 * _scaleAnimation.value,
              height: 160 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            // Center Cup
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9), // Light green tint
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_cafe,
                color: Color(0xFF1F3C2C),
                size: 32,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadarGraphics() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(280, 280),
          painter: RadarGridPainter(color: Colors.white.withOpacity(0.15)),
        ),
        // Blips
        ..._blips.map((blip) {
          return Positioned(
            left: 140 + (140 * blip.distance * math.cos(blip.angle)) - 16,
            top: 140 + (140 * blip.distance * math.sin(blip.angle)) - 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(seconds: 3),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFFFC107), width: 2),
                      image: DecorationImage(
                        image: NetworkImage(blip.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        // Rotating Sweep
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFFC107).withOpacity(0.05),
                      const Color(0xFFFFC107).withOpacity(0.2),
                      const Color(0xFFFFC107).withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.5, 0.95, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
        // Center Dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text(
            'Finding your coffee match',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for someone free at 5 PM within 5 km',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '14 PEOPLE FREE NEARBY',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Checklist Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WHAT WE'RE MATCHING",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChecklistItem("SAT 5:00 PM", true),
                _buildDivider(),
                _buildChecklistItem("WITHIN 5 KM", true),
                _buildDivider(),
                _buildChecklistItem("SHARED INTERESTS", true),
                _buildDivider(),
                _buildChecklistItem("CASUAL CONVERSATION", false),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'This usually takes under a minute',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildOutlinedButton('Cancel'),
        ],
      ),
    );
  }

  Widget _buildStillLookingContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text(
            'Still looking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nobody free at 5 PM within 5 km yet.\nWant to widen the search?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChecklistItem("Time: 5:00 PM", true, isSmall: true),
                const SizedBox(height: 12),
                _buildChecklistItem("Distance: Within 5 km", true,
                    isSmall: true),
                const SizedBox(height: 12),
                _buildChecklistItem("Vibe: Casual chat", true, isSmall: true),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.9)),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _expandSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8E6C9), // Light green
              foregroundColor: const Color(0xFF1F3C2C), // Dark green text
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Expand to 10 km',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildOutlinedButton('Try another time'),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesFoundContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text(
            '3 STRONG MATCHES',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFFC8E6C9)),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconChecklistItem(
                    Icons.access_time, "Ready in 10 mins", true),
                _buildDivider(),
                _buildIconChecklistItem(
                    Icons.location_on_outlined, "Within 500m", true),
                _buildDivider(),
                _buildIconChecklistItem(
                    Icons.psychology_outlined, "Deep Work focus", true),
                _buildDivider(),
                _buildIconChecklistItem(
                    Icons.chat_bubble_outline, "Quiet conversation", true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildOutlinedButton('Cancel Search', width: 200),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isChecked,
      {bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(isChecked ? 0.9 : 0.5),
            fontSize: isSmall ? 14 : 14,
            fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isChecked
              ? const Color(0xFFFFC107)
              : Colors.white.withOpacity(0.2), // Yellow check
          size: 20,
        ),
      ],
    );
  }

  Widget _buildIconChecklistItem(IconData icon, String title, bool isChecked) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          Icons.check_circle,
          color: const Color(0xFFF48FB1), // Pink check for the matches screen
          size: 20,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        height: 1,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, {double? width}) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          context.pop();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Blip {
  final double angle;
  final double distance;
  final DateTime createdAt;
  final String imageUrl;

  _Blip({
    required this.angle,
    required this.distance,
    required this.createdAt,
    required this.imageUrl,
  });
}

class RadarGridPainter extends CustomPainter {
  final Color color;

  RadarGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
