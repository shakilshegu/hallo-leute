import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';

/// The short success beat between "Start Coffee Meet" and the search. Shows
/// for ~1.6s then auto-advances into [AppRoutes.searching]; there is no way
/// back — onboarding is already complete by the time this appears.
class ProfileReadyScreen extends ConsumerStatefulWidget {
  const ProfileReadyScreen({super.key});

  @override
  ConsumerState<ProfileReadyScreen> createState() => _ProfileReadyScreenState();
}

class _ProfileReadyScreenState extends ConsumerState<ProfileReadyScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF1F3C2C);
  static const _mint = Color(0xFFC8E6C9);

  late final AnimationController _controller;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _advanceTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) context.go(AppRoutes.searching);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(_controller.value);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180 + 40 * t,
                          height: 180 + 40 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04 + 0.04 * t),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _mint,
                          ),
                          child: const Icon(
                            Icons.local_cafe,
                            color: _bg,
                            size: 44,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your coffee profile is ready ☕',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Finding someone for you…',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
