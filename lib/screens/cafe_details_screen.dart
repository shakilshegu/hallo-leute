import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/maps_launcher.dart';
import 'package:poppylo/state/cafe_controller.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/widgets/cafe_photo.dart';

const _bg = Color(0xFFF9F8F5);
const _ink = Color(0xFF2B4739);

class CafeDetailsScreen extends ConsumerStatefulWidget {
  final String matchId;

  /// A Google Places place id (the route segment is historically `:cafeId`).
  final String cafeId;
  const CafeDetailsScreen({
    super.key,
    required this.matchId,
    required this.cafeId,
  });

  @override
  ConsumerState<CafeDetailsScreen> createState() => _CafeDetailsScreenState();
}

class _CafeDetailsScreenState extends ConsumerState<CafeDetailsScreen> {
  bool _suggesting = false;

  Future<void> _choose() async {
    if (_suggesting) return;
    setState(() => _suggesting = true);
    try {
      final match = await ref.read(matchDetailsProvider(widget.matchId).future);
      await ref.read(cafeApiProvider).suggestCafe(
            widget.matchId,
            placeId: widget.cafeId,
            date: match.date,
            startTime: match.startTime,
          );
      ref.invalidate(cafeSuggestionProvider(widget.matchId));
      if (!mounted) return;
      context.push(AppRoutes.cafeProposedPath(widget.matchId));
    } catch (e) {
      if (!mounted) return;
      _snack(cafeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _openInMaps(NearbyCafe cafe) async {
    final ok = await openCafeInMaps(
      latitude: cafe.latitude,
      longitude: cafe.longitude,
      name: cafe.name,
      placeId: cafe.placeId,
    );
    if (!ok && mounted) _snack("Couldn't open Maps.");
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(cafePlaceDetailsProvider(widget.cafeId));

    return Scaffold(
      backgroundColor: _bg,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _ink),
        ),
        error: (e, _) => _ErrorView(
          message: cafeErrorMessage(e),
          onRetry: () =>
              ref.invalidate(cafePlaceDetailsProvider(widget.cafeId)),
        ),
        data: (detail) => _content(context, detail),
      ),
      bottomSheet:
          detailAsync.hasValue ? _bottomBar(detailAsync.value!.summary) : null,
    );
  }

  Widget _content(BuildContext context, CafePlaceDetails detail) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final cafe = detail.summary;

    final meta = <String>[
      if (cafe.rating != null) '${cafe.rating!.toStringAsFixed(1)} ★',
      if (cafe.reviewCount != null) '${cafe.reviewCount} reviews',
      if (cafe.distanceText.isNotEmpty) cafe.distanceText,
    ].join('  ·  ');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: CafePhoto(
              proxyPath: cafe.photoUrl,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cafe.name,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meta,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
                if (cafe.openLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    cafe.openLabel!,
                    style: textTheme.labelMedium?.copyWith(
                      color: cafe.isOpen == true
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB03A2E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: colorScheme.primary.withOpacity(0.6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cafe.address,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.openingHours.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'OPENING HOURS',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final line in detail.openingHours)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 160),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(NearbyCafe cafe) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, -10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _suggesting ? null : _choose,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: _suggesting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Choose this café',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _openInMaps(cafe),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Open in Maps'),
            style: TextButton.styleFrom(foregroundColor: _ink),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
