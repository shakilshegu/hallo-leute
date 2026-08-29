import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/match_controller.dart';

class ChooseCafeScreen extends ConsumerWidget {
  final String matchId;
  const ChooseCafeScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F5), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colorScheme.primary),
          onPressed: () {},
        ),
        title: Text(
          'Coffee Meet',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=100&auto=format&fit=crop', // Sarah's image
              ),
            ),
          ),
        ],
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

                  // Map Card Mockup
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EAE1),
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop'), // Placeholder map-like texture
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Color(0x88FFFFFF),
                            BlendMode.lighten), // wash it out
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
                        // Center mock pin
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2B4739), // Dark green
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.local_cafe,
                                    size: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Brew & Bloom',
                                  style: textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cafe Cards
                  _buildCafeCard(
                    context: context,
                    ref: ref,
                    cafeId: 'brew-lab',
                    name: 'Brew Lab',
                    rating: '4.6',
                    distance: '1.2 KM',
                    price: '₹₹',
                    description: 'Minimalist space with great pour-...',
                    imageUrl:
                        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=300&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 16),
                  _buildCafeCard(
                    context: context,
                    ref: ref,
                    cafeId: 'third-wave',
                    name: 'Third Wave',
                    rating: '4.4',
                    distance: '2.5 KM',
                    price: '₹₹₹',
                    description: 'Spacious & bright, ideal for long...',
                    imageUrl:
                        'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?q=80&w=300&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 16),
                  _buildCafeCard(
                    context: context,
                    ref: ref,
                    cafeId: 'filter-room',
                    name: 'Filter Room',
                    rating: '4.8',
                    distance: '3.1 KM',
                    price: '₹',
                    description: 'Cozy neighborhood spot, quiet...',
                    imageUrl:
                        'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?q=80&w=300&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 80), // padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCafeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String cafeId,
    required String name,
    required String rating,
    required String distance,
    required String price,
    required String description,
    required String imageUrl,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.cafeDetailsPath(matchId, cafeId));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EAE1), // Warm card background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(rating,
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7))),
                      Icon(Icons.star,
                          size: 12,
                          color: colorScheme.primary.withOpacity(0.7)),
                      Text('  ·  $distance  ·  $price',
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(matchRepositoryProvider.notifier)
                          .proposeCafe(matchId, cafeId, name);
                      context.push(AppRoutes.cafeProposedPath(matchId));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8DF), // Very light green
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Text(
                        'Suggest this café',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF2B4739), // Dark green text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
