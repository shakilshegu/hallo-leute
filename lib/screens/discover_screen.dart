import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/discover_controller.dart';
import 'package:poppylo/widgets/discover_filters_sheet.dart';
import 'package:poppylo/widgets/discover_person_card.dart';

const _green = Color(0xFF1B3B2B);
const _bg = Color(0xFFF3F1EB);

/// The Discover bottom-nav destination — people you may want to meet for
/// coffee (`GET /discover`). Calm, human, coffee-focused; not a swipe deck.
class DiscoverPeopleScreen extends ConsumerStatefulWidget {
  const DiscoverPeopleScreen({super.key});

  @override
  ConsumerState<DiscoverPeopleScreen> createState() =>
      _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends ConsumerState<DiscoverPeopleScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(discoverControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final current = ref.read(discoverControllerProvider).filters;
    final next = await DiscoverFiltersSheet.show(context, current);
    if (next != null) {
      await ref.read(discoverControllerProvider.notifier).applyFilters(next);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  void _invite() {
    HapticFeedback.lightImpact();
    // Reuse the existing Coffee Request flow — no second request system.
    context.push(AppRoutes.create);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(discoverControllerProvider);
    final controller = ref.read(discoverControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _green,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: textTheme.headlineMedium?.copyWith(
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find someone worth meeting.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _green.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterBar(
                        filters: state.filters,
                        onTap: _openFilters,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recommended for you',
                        style: textTheme.titleLarge?.copyWith(
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              _body(state, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(DiscoverPeopleState state, DiscoverController controller) {
    if (state.loading) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        sliver: _SkeletonList(),
      );
    }
    if (state.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: discoverErrorMessage(state.error!),
          onRetry: controller.load,
        ),
      );
    }
    if (state.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          message: state.emptyMessage,
          onAdjust: _openFilters,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == state.users.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green.withOpacity(0.4),
                    ),
                  ),
                ),
              );
            }
            final user = state.users[i];
            return DiscoverPersonCard(
              user: user,
              onViewProfile: () =>
                  context.push(AppRoutes.discoverProfilePath(user.id)),
              onInvite: _invite,
            );
          },
          childCount: state.users.length + (state.loadingMore ? 1 : 0),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters, required this.onTap});

  final DiscoverFilters filters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = !filters.isEmpty;
    final summary = discoverFilterSummary(filters);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? _green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _green : _green.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: active ? Colors.white : _green.withOpacity(0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                active
                    ? summary
                    : '10 km  ·  Purpose  ·  Interests  ·  Availability',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : _green.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filters.activeCount}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: _green.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, __) => Container(
          height: 210,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _green.withOpacity(0.25),
              ),
            ),
          ),
        ),
        childCount: 4,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onAdjust});

  final String? message;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('☕', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 16),
          Text(
            'No one nearby right now',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                'Try expanding your distance or changing your preferences.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: _green.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onAdjust,
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: BorderSide(color: _green.withOpacity(0.25)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 40, color: _green.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            "Couldn't load Discover.",
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                textTheme.bodySmall?.copyWith(color: _green.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
