import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';
import 'package:poppylo/state/matching_controller.dart';

class ChooseCafeScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChooseCafeScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChooseCafeScreen> createState() => _ChooseCafeScreenState();
}

class _ChooseCafeScreenState extends ConsumerState<ChooseCafeScreen> {
  bool _suggesting = false;

  Future<void> _suggest(String coffeeShopId) async {
    if (_suggesting) return;
    setState(() => _suggesting = true);
    try {
      final match = await ref.read(matchDetailsProvider(widget.matchId).future);
      await ref.read(cafeApiProvider).suggestCafe(
            widget.matchId,
            coffeeShopId: coffeeShopId,
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
    final cafesAsync = ref.watch(nearbyCafesProvider);
    final suggestion =
        ref.watch(cafeSuggestionProvider(widget.matchId)).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Coffee Meet',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where should you meet?',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a comfortable public café.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Map Card Mockup (decorative, unchanged)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EAE1),
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Color(0x88FFFFFF), BlendMode.lighten),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location,
                                    size: 14, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'CURRENT AREA',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2B4739),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.local_cafe,
                                    size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (suggestion != null &&
                      !suggestion.isAccepted &&
                      !suggestion.isDeclined)
                    _suggestionBanner(context, suggestion, textTheme),

                  // Café cards from the backend
                  cafesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _errorBox(
                      context,
                      cafeErrorMessage(e),
                      () => ref.invalidate(nearbyCafesProvider),
                    ),
                    data: (cafes) {
                      if (cafes.isEmpty) {
                        return _errorBox(
                          context,
                          'No cafés found near you.',
                          () => ref.invalidate(nearbyCafesProvider),
                        );
                      }
                      return Column(
                        children: [
                          for (final cafe in cafes) ...[
                            _CafeCard(
                              matchId: widget.matchId,
                              cafe: cafe,
                              suggesting: _suggesting,
                              onSuggest: () => _suggest(cafe.id),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionBanner(
    BuildContext context,
    CafeSuggestion s,
    TextTheme textTheme,
  ) {
    final ink = const Color(0xFF2B4739);
    final mine = s.suggestedBy.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mine
                ? 'You suggested ${s.cafe.name}'
                : '${s.suggestedBy.name} suggested ${s.cafe.name}',
            style: textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: ink),
          ),
          const SizedBox(height: 4),
          Text(
            formatSlotDateTime(s.date, s.startTime),
            style: textTheme.bodySmall?.copyWith(color: ink.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  context.push(AppRoutes.cafeProposedPath(widget.matchId)),
              style: TextButton.styleFrom(
                foregroundColor: ink,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(mine ? 'View suggestion' : 'Review & accept'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, String message, VoidCallback retry) {
    final ink = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: ink.withOpacity(0.7))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// The existing warm café card — same layout, real data.
class _CafeCard extends StatelessWidget {
  const _CafeCard({
    required this.matchId,
    required this.cafe,
    required this.suggesting,
    required this.onSuggest,
  });

  final String matchId;
  final CoffeeShop cafe;
  final bool suggesting;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final meta = <String>[
      if (cafe.distanceKm != null) '${cafe.distanceKm!.toStringAsFixed(1)} KM',
      if (cafe.priceLabel.isNotEmpty) cafe.priceLabel,
    ].join('  ·  ');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.cafeDetailsPath(matchId, cafe.id));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EAE1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (cafe.imageUrl != null && cafe.imageUrl!.isNotEmpty)
                  ? Image.network(cafe.imageUrl!,
                      width: 100, height: 100, fit: BoxFit.cover)
                  : Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFFE2E8DF),
                      child: const Icon(Icons.local_cafe,
                          color: Color(0xFF2B4739)),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cafe.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (cafe.rating != null) ...[
                        Text(cafe.rating!.toStringAsFixed(1),
                            style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.7))),
                        Icon(Icons.star,
                            size: 12,
                            color: colorScheme.primary.withOpacity(0.7)),
                      ],
                      if (meta.isNotEmpty)
                        Text('  ·  $meta',
                            style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.7))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cafe.description ?? cafe.address,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: suggesting ? null : onSuggest,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8DF),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Text(
                        suggesting ? 'Sending…' : 'Suggest this café',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF2B4739),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
