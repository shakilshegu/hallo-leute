import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/discover_models.dart';

/// The Discover feed. Matching/discovery has no backend yet (out of the
/// coffee-meet-api scope), so this serves realistic sample data behind a
/// short delay — enough to exercise the loading / data / empty / error
/// states. Swap the body for a real endpoint when one exists.
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 700));
  return _sampleFeed;
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

DateTime _at(int addDays, int hour, int minute) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day).add(Duration(days: addDays));
  return DateTime(d.year, d.month, d.day, hour, minute);
}

const _pravatar = 'https://i.pravatar.cc/200?img=';

final DiscoverFeed _sampleFeed = DiscoverFeed(
  location: 'Kochi, India',
  meets: [
    CoffeeMeet(
      id: 'm1',
      hostName: 'Ananya',
      hostAge: 27,
      hostAvatarUrl: '${_pravatar}47',
      bio: 'Product designer who sketches on napkins. Keen to swap notes on '
          'design systems and single-origin roasts.',
      sharedInterests: ['Design', 'Startups', 'Coffee'],
      distanceKm: 1.2,
      cafeName: 'Brew Lab, Panampilly Nagar',
      startsAt: _at(0, 17, 0),
      participantCount: 2,
      maxParticipants: 4,
      availableNow: true,
    ),
    CoffeeMeet(
      id: 'm2',
      hostName: 'Rahul',
      hostAge: 31,
      hostAvatarUrl: '${_pravatar}12',
      bio: 'Backend engineer, weekend trekker. Happy to talk distributed '
          'systems or the best filter kaapi in town.',
      sharedInterests: ['Technology', 'Fitness'],
      distanceKm: 2.6,
      cafeName: 'Kashi Art Café, Fort Kochi',
      startsAt: _at(0, 19, 30),
      participantCount: 1,
      maxParticipants: 3,
      availableNow: false,
    ),
    CoffeeMeet(
      id: 'm3',
      hostName: 'Meera Krishnan',
      hostAge: 24,
      hostAvatarUrl: '${_pravatar}32',
      bio: 'Illustrator and part-time barista. Looking for calm morning '
          'conversations about books and travel.',
      sharedInterests: ['Books', 'Travel', 'Photography'],
      distanceKm: 4.1,
      cafeName: 'Qissa Café, Kadavanthra',
      startsAt: _at(1, 10, 0),
      participantCount: 3,
      maxParticipants: 5,
      availableNow: false,
    ),
    CoffeeMeet(
      id: 'm4',
      hostName: 'Tom',
      hostAge: 29,
      hostAvatarUrl: '${_pravatar}15',
      bio: 'New to Kochi, learning Malayalam slowly. Would love to meet '
          'locals over a flat white.',
      sharedInterests: ['Music', 'Movies'],
      distanceKm: 5.8,
      cafeName: 'Cafe Papaya, Vyttila',
      startsAt: _at(3, 16, 0),
      participantCount: 1,
      maxParticipants: 2,
      availableNow: false,
    ),
  ],
  nearbyPeople: [
    NearbyPerson(
      id: 'p1',
      name: 'Sara',
      avatarUrl: '${_pravatar}5',
      interestTags: ['Travel', 'Food'],
      distanceKm: 0.8,
    ),
    NearbyPerson(
      id: 'p2',
      name: 'Vishnu',
      avatarUrl: '${_pravatar}68',
      interestTags: ['Startups', 'Tech'],
      distanceKm: 1.5,
    ),
    NearbyPerson(
      id: 'p3',
      name: 'Priya Nair',
      avatarUrl: '${_pravatar}45',
      interestTags: ['Books', 'Design'],
      distanceKm: 2.0,
    ),
    NearbyPerson(
      id: 'p4',
      name: 'Alex',
      avatarUrl: '${_pravatar}53',
      interestTags: ['Fitness', 'Music'],
      distanceKm: 3.3,
    ),
  ],
);
