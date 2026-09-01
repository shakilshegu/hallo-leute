import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/models/profile_models.dart'
    show purposeLabelFromApi, conversationStyleLabelFromApi;
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';
import 'package:poppylo/state/coffee_request_controller.dart';
import 'package:poppylo/state/match_controller.dart';
import 'package:poppylo/state/matching_controller.dart';

const _kGreen = Color(0xFF1F3C2C);
const _kMint = Color(0xFFC8E6C9);
const _kAmber = Color(0xFFFFC107);

/// How often the Searching screen polls the matching status.
const _pollEvery = Duration(seconds: 3);

/// Stop polling after this many attempts (~2 min) rather than forever.
const _maxPolls = 40;

enum _Phase { loading, noRequest, searching, ended, failed, timedOut }

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key, this.requestId});

  /// The `CoffeeRequest` id created on the Create Coffee Meet screen. When
  /// null the screen was opened without an active request and simply says so.
  final String? requestId;

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen>
    with TickerProviderStateMixin {
  AnimationController? _pulse;
  AnimationController? _sweep;
  Timer? _clock;
  Timer? _poll;
  int _elapsed = 0;
  int _pollCount = 0;
  bool _cancelling = false;
  bool _navigated = false;

  _Phase _phase = _Phase.loading;
  CoffeeRequest? _request;
  String? _searchMessage;
  String _endedTitle = '';
  String _endedBody = '';
  String _failedMessage = 'Unable to connect. Please try again.';

  String? get _id => widget.requestId;

  @override
  void initState() {
    super.initState();
    if (_id == null) {
      _phase = _Phase.noRequest;
      return;
    }
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _start();
  }

  @override
  void dispose() {
    _pulse?.dispose();
    _sweep?.dispose();
    _clock?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  void _stopLiveWork() {
    _poll?.cancel();
    _clock?.cancel();
    _pulse?.stop();
    _sweep?.stop();
  }

  // --- polling loop --------------------------------------------------

  Future<void> _start() async {
    unawaited(_loadRequestForDisplay());
    try {
      final result = await ref.read(matchingApiProvider).startMatching(_id!);
      _apply(result);
    } catch (e) {
      _applyError(e);
    }
    if (!mounted || _navigated) return;
    _poll = Timer.periodic(_pollEvery, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_navigated) return;
    _pollCount++;
    if (_pollCount > _maxPolls) {
      _stopLiveWork();
      if (mounted) setState(() => _phase = _Phase.timedOut);
      return;
    }
    try {
      final result = await ref.read(matchingApiProvider).pollStatus(_id!);
      _apply(result);
    } catch (e) {
      _applyError(e);
    }
  }

  void _apply(MatchStatusResult result) {
    if (!mounted || _navigated) return;

    if (result.isMatchFound) {
      final match = result.match!;
      _navigated = true;
      _stopLiveWork();
      ref
          .read(matchRepositoryProvider.notifier)
          .upsert(matchFromDetails(match));
      HapticFeedback.heavyImpact();
      // `go` (not push): Searching must not stay in the back stack.
      context.go(AppRoutes.matchPath(match.id));
      return;
    }

    setState(() {
      _phase = _Phase.searching;
      _searchMessage = result.message;
    });
  }

  void _applyError(Object error) {
    if (!mounted || _navigated) return;

    if (error is ApiException) {
      switch (error.statusCode) {
        case 409:
          _stopLiveWork();
          setState(() {
            _phase = _Phase.ended;
            _endedTitle = 'This search has ended';
            _endedBody =
                'Your coffee request is no longer active. Start a new one '
                'when you\'re ready.';
          });
          return;
        case 404:
          _stopLiveWork();
          setState(() => _phase = _Phase.noRequest);
          return;
        case 401:
          _stopLiveWork();
          setState(() {
            _phase = _Phase.failed;
            _failedMessage = matchingErrorMessage(error);
          });
          return;
      }
    }

    // Transient network error: if we're already showing the search, just
    // keep the loop going — the next poll may succeed.
    if (_phase == _Phase.searching) return;
    setState(() {
      _phase = _Phase.failed;
      _failedMessage = matchingErrorMessage(error);
    });
  }

  Future<void> _loadRequestForDisplay() async {
    try {
      final req = await ref.read(coffeeRequestApiProvider).getById(_id!);
      if (mounted) setState(() => _request = req);
    } catch (_) {
      // The criteria card is cosmetic — ignore a failure to load it.
    }
  }

  Future<void> _cancelSearch() async {
    final id = _id;
    if (id == null || _cancelling) return;
    setState(() => _cancelling = true);
    _navigated = true;
    _stopLiveWork();
    try {
      await ref.read(coffeeRequestApiProvider).cancel(id);
    } catch (_) {
      // Even if the cancel call fails, leaving the screen is the right move.
    }
    ref.invalidate(activeCoffeeRequestProvider);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _resumePolling() {
    setState(() {
      _pollCount = 0;
      _phase = _Phase.searching;
    });
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    _sweep?.repeat();
    _pulse?.repeat(reverse: true);
    _poll = Timer.periodic(_pollEvery, (_) => _pollOnce());
    _pollOnce();
  }

  // --- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGreen,
      body: SafeArea(
        child: switch (_phase) {
          _Phase.loading => const Center(
              child: CircularProgressIndicator(color: _kMint),
            ),
          _Phase.searching => _searchingView(),
          _Phase.noRequest => _message(
              icon: Icons.local_cafe_outlined,
              title: 'No active coffee meet',
              body: 'Start one and we\'ll find you someone free nearby.',
              primaryLabel: 'Start a coffee meet',
              onPrimary: () => context.go(AppRoutes.create),
            ),
          _Phase.failed => _message(
              icon: Icons.cloud_off_outlined,
              title: 'Couldn\'t load your search',
              body: _failedMessage,
              primaryLabel: 'Retry',
              onPrimary: () {
                setState(() => _phase = _Phase.loading);
                _resumePolling();
              },
            ),
          _Phase.timedOut => _message(
              icon: Icons.hourglass_empty,
              title: 'Still looking',
              body: 'No match yet. Your request stays active — keep '
                  'searching or check back later.',
              primaryLabel: 'Keep searching',
              onPrimary: _resumePolling,
            ),
          _Phase.ended => _message(
              icon: Icons.schedule,
              title: _endedTitle,
              body: _endedBody,
              primaryLabel: 'Start over',
              onPrimary: () => context.go(AppRoutes.create),
            ),
        },
      ),
    );
  }

  // --- searching (live) ------------------------------------------------

  Widget _searchingView() {
    final req = _request;
    final timeLabel = req == null ? null : _prettyTime(req.startTime);
    final headerSuffix = req == null
        ? ''
        : ' · ${timeLabel!.toUpperCase()} · ${req.maxDistanceKm} KM';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SEARCHING · ${_clockText()}$headerSuffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.radar, color: Colors.white.withOpacity(0.6), size: 20),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _radar()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Finding your coffee match',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchMessage ??
                          (timeLabel == null
                              ? 'Looking for someone nearby'
                              : 'Someone free around $timeLabel within '
                                  '${req!.maxDistanceKm} km'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (req != null) _criteriaCard(req),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'We\'ll let you know the moment someone matches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _cancelling ? null : _cancelSearch,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _cancelling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Cancel search',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _criteriaCard(CoffeeRequest req) {
    final purpose = purposeLabelFromApi(req.purpose);
    final style = conversationStyleLabelFromApi(req.conversationStyle);
    final vibe = [
      if (style.isNotEmpty) style,
      if (purpose.isNotEmpty) purpose,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _criteriaRow(Icons.access_time, _prettyTime(req.startTime)),
          _thinDivider(),
          _criteriaRow(
              Icons.location_on_outlined, 'Within ${req.maxDistanceKm} km'),
          _thinDivider(),
          _criteriaRow(Icons.timelapse, '${req.durationMinutes} min'),
          if (vibe.isNotEmpty) ...[
            _thinDivider(),
            _criteriaRow(Icons.chat_bubble_outline, vibe),
          ],
        ],
      ),
    );
  }

  Widget _criteriaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thinDivider() =>
      Divider(height: 1, color: Colors.white.withOpacity(0.06));

  Widget _radar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          260.0,
          math.min(constraints.maxWidth, constraints.maxHeight),
        );
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(side, side),
                  painter:
                      RadarGridPainter(color: Colors.white.withOpacity(0.15)),
                ),
                if (_sweep != null)
                  AnimatedBuilder(
                    animation: _sweep!,
                    builder: (context, _) => Transform.rotate(
                      angle: _sweep!.value * 2 * math.pi,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              _kAmber.withOpacity(0.05),
                              _kAmber.withOpacity(0.25),
                              _kAmber.withOpacity(0.5),
                            ],
                            stops: const [0.0, 0.5, 0.95, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_pulse != null)
                  AnimatedBuilder(
                    animation: _pulse!,
                    builder: (context, _) {
                      final s = 0.9 + _pulse!.value * 0.2;
                      return Container(
                        width: 70 * s,
                        height: 70 * s,
                        decoration: const BoxDecoration(
                          color: _kMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_cafe,
                            color: _kGreen, size: 28),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- shared message layout -----------------------------------------

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, color: _kMint, size: 44),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kMint,
                foregroundColor: _kGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                primaryLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(
              'Back home',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  // --- helpers ------------------------------------------------------

  String _clockText() {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _prettyTime(String hhmm) {
    final parts = hhmm.split(':');
    var h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final min = parts.length > 1 ? parts[1] : '00';
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$min $ampm';
  }
}

class RadarGridPainter extends CustomPainter {
  RadarGridPainter({required this.color});

  final Color color;

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
    canvas.drawCircle(
      center,
      3,
      Paint()..color = _kAmber,
    );
  }

  @override
  bool shouldRepaint(covariant RadarGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
