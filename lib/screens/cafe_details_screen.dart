import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';
import 'package:poppylo/state/matching_controller.dart';

class CafeDetailsScreen extends ConsumerStatefulWidget {
  final String matchId;
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

  Future<void> _suggest() async {
    if (_suggesting) return;
    setState(() => _suggesting = true);
    try {
      final match = await ref.read(matchDetailsProvider(widget.matchId).future);
      await ref.read(cafeApiProvider).suggestCafe(
            widget.matchId,
            coffeeShopId: widget.cafeId,
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

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final cafeAsync = ref.watch(cafeProvider(widget.cafeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F5),
      body: cafeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorScaffold(context, cafeErrorMessage(e)),
        data: (cafe) => _content(context, cafe, textTheme, colorScheme),
      ),
      bottomSheet: cafeAsync.hasValue
          ? _bottomBar(context, textTheme, colorScheme)
          : null,
    );
  }

  Widget _errorScaffold(BuildContext context, String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    CoffeeShop cafe,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final meta = <String>[
      if (cafe.rating != null) '${cafe.rating!.toStringAsFixed(1)} ★',
      if (cafe.distanceKm != null) '${cafe.distanceKm!.toStringAsFixed(1)} KM',
      if (cafe.priceLabel.isNotEmpty) cafe.priceLabel,
    ].join('  ·  ');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFFF9F8F5),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
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
            background: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: (cafe.imageUrl != null && cafe.imageUrl!.isNotEmpty)
                  ? Image.network(cafe.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFE2E8DF),
                      child: const Center(
                        child: Icon(Icons.local_cafe,
                            size: 64, color: Color(0xFF2B4739)),
                      ),
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
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                      letterSpacing: 1.0,
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
                if ((cafe.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    cafe.description!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F5),
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
            onPressed: _suggesting ? null : _suggest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B4739),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Suggest this café',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('View on map'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
