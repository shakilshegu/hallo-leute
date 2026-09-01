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

// --- People discovery (coffee-meet-api `GET /discover`) ----------------

/// A person card in the Discover feed. Public, discovery-safe fields only.
@immutable
class DiscoverUser {
  const DiscoverUser({
    required this.id,
    required this.name,
    required this.age,
    required this.profileImage,
    required this.profession,
    required this.bio,
    required this.distance,
    required this.distanceLabel,
    required this.interests,
    required this.coffeePreference,
    required this.purpose,
    required this.availability,
    required this.compatibilityScore,
  });

  final String id;
  final String name;
  final int? age;
  final String? profileImage;
  final String? profession;
  final String? bio;
  final double? distance; // km
  final String? distanceLabel; // e.g. "Nearby" when km isn't shown
  final List<String> interests;
  final String? coffeePreference; // e.g. "CASUAL"
  final String? purpose; // api enum value
  final List<String> availability; // e.g. ["WEEKDAY_EVENING"]
  final int compatibilityScore; // 0-100

  /// "2.4 km away" · "Nearby" · "" when there's nothing to show.
  String get distanceText {
    if (distance != null) return '${distance!.toStringAsFixed(1)} km away';
    if (distanceLabel != null && distanceLabel!.isNotEmpty) {
      return distanceLabel!;
    }
    return '';
  }

  factory DiscoverUser.fromJson(Map<String, dynamic> json) {
    return DiscoverUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Coffee Meet member',
      age: (json['age'] as num?)?.toInt(),
      profileImage: json['profileImage'] as String?,
      profession: json['profession'] as String?,
      bio: json['bio'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceLabel: json['distanceLabel'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      coffeePreference: json['coffeePreference'] as String?,
      purpose: json['purpose'] as String?,
      availability: (json['availability'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      compatibilityScore: (json['compatibilityScore'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One page of `GET /discover`.
@immutable
class DiscoverPage {
  const DiscoverPage({
    required this.users,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.message,
  });

  final List<DiscoverUser> users;
  final int page;
  final int totalPages;
  final bool hasNext;

  /// Backend-supplied empty-state message ("No people found nearby right now.").
  final String? message;

  factory DiscoverPage.fromEnvelope(Map<String, dynamic> env) {
    final data = env['data'];
    final pag = env['pagination'] as Map<String, dynamic>? ?? const {};
    return DiscoverPage(
      users: (data is List ? data : const [])
          .whereType<Map<String, dynamic>>()
          .map(DiscoverUser.fromJson)
          .toList(),
      page: (pag['page'] as num?)?.toInt() ?? 1,
      totalPages: (pag['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: pag['hasNext'] as bool? ?? false,
      message: env['message'] as String?,
    );
  }
}

/// The full public profile behind "View Profile" (`GET /discover/:userId`).
@immutable
class DiscoverUserProfile {
  const DiscoverUserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.profileImage,
    required this.profession,
    required this.bio,
    required this.distance,
    required this.distanceLabel,
    required this.interests,
    required this.availability,
    required this.conversationStyles,
    required this.purpose,
  });

  final String id;
  final String name;
  final int? age;
  final String? profileImage;
  final String? profession;
  final String? bio;
  final double? distance;
  final String? distanceLabel;
  final List<String> interests;
  final List<String> availability;
  final List<String> conversationStyles;
  final String? purpose;

  String get distanceText {
    if (distance != null) return '${distance!.toStringAsFixed(1)} km away';
    if (distanceLabel != null && distanceLabel!.isNotEmpty) {
      return distanceLabel!;
    }
    return '';
  }

  factory DiscoverUserProfile.fromJson(Map<String, dynamic> json) {
    final prefs =
        json['coffeePreferences'] as Map<String, dynamic>? ?? const {};
    return DiscoverUserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Coffee Meet member',
      age: (json['age'] as num?)?.toInt(),
      profileImage: json['profileImage'] as String?,
      profession: json['profession'] as String?,
      bio: json['bio'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      distanceLabel: json['distanceLabel'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      availability: (json['availability'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      conversationStyles:
          (prefs['conversationStyles'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      purpose: prefs['purpose'] as String?,
    );
  }
}

/// The Discover filter selection. All fields null/empty == no filter.
@immutable
class DiscoverFilters {
  const DiscoverFilters({
    this.distanceKm,
    this.purpose,
    this.interest,
    this.availability,
  });

  final int? distanceKm; // 5 / 10 / 25
  final String? purpose; // api enum value
  final String? interest; // interest slug
  final String? availability; // THIS_WEEK / THIS_WEEKEND

  static const none = DiscoverFilters();

  bool get isEmpty =>
      distanceKm == null &&
      purpose == null &&
      interest == null &&
      availability == null;

  int get activeCount => [
        distanceKm,
        purpose,
        interest,
        availability,
      ].where((v) => v != null).length;

  Map<String, String> toQuery() => {
        if (distanceKm != null) 'distance': '$distanceKm',
        if (purpose != null) 'purpose': purpose!,
        if (interest != null) 'interest': interest!,
        if (availability != null) 'availability': availability!,
      };

  DiscoverFilters copyWith({
    int? distanceKm,
    String? purpose,
    String? interest,
    String? availability,
    bool clearDistance = false,
    bool clearPurpose = false,
    bool clearInterest = false,
    bool clearAvailability = false,
  }) {
    return DiscoverFilters(
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      interest: clearInterest ? null : (interest ?? this.interest),
      availability:
          clearAvailability ? null : (availability ?? this.availability),
    );
  }
}

/// Pretty label for a backend availability slot ("WEEKDAY_EVENING" →
/// "Weekday evenings").
String prettyAvailability(String slot) {
  const map = {
    'WEEKDAY_MORNING': 'Weekday mornings',
    'WEEKDAY_AFTERNOON': 'Weekday afternoons',
    'WEEKDAY_EVENING': 'Weekday evenings',
    'WEEKEND_MORNING': 'Weekend mornings',
    'WEEKEND_AFTERNOON': 'Weekend afternoons',
    'WEEKEND_EVENING': 'Weekend evenings',
  };
  return map[slot] ??
      slot
          .toLowerCase()
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
}
