import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/services/discover_api.dart';

/// The Home / Discover feed, loaded from `GET /home`.
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) {
  return ref.watch(discoverApiProvider).getFeed();
});

/// The currently selected quick-filter chips (client-side filtering of the
/// sample feed).
final discoverFiltersProvider = StateProvider<Set<DiscoverFilter>>((ref) => {});

/// The feed after the selected filters are applied.
final filteredDiscoverProvider = Provider<AsyncValue<DiscoverFeed>>((ref) {
  final feed = ref.watch(discoverFeedProvider);
  final filters = ref.watch(discoverFiltersProvider);

  return feed.whenData((f) {
    if (filters.isEmpty) return f;
    var meets = f.meets;
    if (filters.contains(DiscoverFilter.today)) {
      meets = meets.where((m) => m.isToday).toList();
    }
    if (filters.contains(DiscoverFilter.thisWeek)) {
      meets = meets.where((m) => m.isThisWeek).toList();
    }
    if (filters.contains(DiscoverFilter.availableNow)) {
      meets = meets.where((m) => m.availableNow).toList();
    }
    if (filters.contains(DiscoverFilter.nearby)) {
      meets = meets.where((m) => m.distanceKm <= 3).toList();
    }
    if (filters.contains(DiscoverFilter.interests)) {
      meets = meets.where((m) => m.sharedInterests.isNotEmpty).toList();
    }
    return DiscoverFeed(
      location: f.location,
      meets: meets,
      nearbyPeople: f.nearbyPeople,
    );
  });
});
