import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/match_controller.dart';

class CafeDetailsScreen extends ConsumerWidget {
  final String matchId;
  final String cafeId;
  const CafeDetailsScreen({
    super.key,
    required this.matchId,
    required this.cafeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F5),
      body: CustomScrollView(
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
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.bookmark_border, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Image.network(
                  'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=600&auto=format&fit=crop', // Cafe hero image
                  fit: BoxFit.cover,
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
                    'The Local Roastery',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('4.6',
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7))),
                      Icon(Icons.star,
                          size: 12,
                          color: colorScheme.primary.withOpacity(0.7)),
                      Text('  ·  1.2 KM  ·  OPEN TILL 11 PM',
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7),
                              letterSpacing: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: colorScheme.primary.withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '124 Artisanal Ave, Floor 2\nCoffee District, Metropolis',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'A calm, sunlit space featuring exposed brick and pour-over specialties. Ideal for deep conversations or quiet afternoon reading.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(context, 'Quiet'),
                      _buildTag(context, 'Good for conversation'),
                      _buildTag(context, 'Indoor seating'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Mock map snippet
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop', // Placeholder map
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.6), // wash out
                      colorBlendMode: BlendMode.screen,
                    ),
                  ),
                  const SizedBox(height: 100), // padding for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
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
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(matchRepositoryProvider.notifier)
                    .proposeCafe(matchId, cafeId, 'The Local Roastery');
                context.push(AppRoutes.cafeProposedPath(matchId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B4739), // Dark green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Row(
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
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8DF), // Very light green
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF2B4739), // Dark green text
            ),
      ),
    );
  }
}
