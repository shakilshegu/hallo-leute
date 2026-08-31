import 'package:flutter/foundation.dart';

/// One quick-filter chip on the Discover screen.
enum DiscoverFilter { nearby, today, thisWeek, interests, availableNow }

extension DiscoverFilterLabel on DiscoverFilter {
  String get label => switch (this) {
        DiscoverFilter.nearby => 'Nearby',
        DiscoverFilter.today => 'Today',
        DiscoverFilter.thisWeek => 'This Week',
        DiscoverFilter.interests => 'Interests',
        DiscoverFilter.availableNow => 'Available Now',
      };
}

@immutable
class CoffeeMeet {
  const CoffeeMeet({
    required this.id,
    required this.hostName,
    required this.hostAge,
    required this.hostAvatarUrl,
    required this.bio,
    required this.sharedInterests,
    required this.distanceKm,
    required this.cafeName,
    required this.startsAt,
    required this.participantCount,
    required this.maxParticipants,
    required this.availableNow,
  });

  final String id;
  final String hostName;
  final int hostAge;
  final String hostAvatarUrl;
  final String bio;
  final List<String> sharedInterests;
  final double distanceKm;
  final String cafeName;
  final DateTime startsAt;
  final int participantCount;
  final int maxParticipants;
  final bool availableNow;

  bool get isToday {
    final now = DateTime.now();
    return startsAt.year == now.year &&
        startsAt.month == now.month &&
        startsAt.day == now.day;
  }

  bool get isThisWeek => startsAt.difference(DateTime.now()).inDays < 7;
}

@immutable
class NearbyPerson {
  const NearbyPerson({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.interestTags,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final List<String> interestTags;
  final double distanceKm;
}

@immutable
class DiscoverFeed {
  const DiscoverFeed({
    required this.location,
    required this.meets,
    required this.nearbyPeople,
  });

  final String location;
  final List<CoffeeMeet> meets;
  final List<NearbyPerson> nearbyPeople;

  bool get isEmpty => meets.isEmpty && nearbyPeople.isEmpty;
}
