import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// Reads the Home / Discover feed from `GET /home` and maps the backend
/// payload onto the widgets' models.
class DiscoverApi {
  DiscoverApi(this._client);

  final ApiClient _client;

  Future<DiscoverFeed> getFeed() async {
    final data = await _client.get('/home');
    return _feedFromHome(data);
  }

  // --- People discovery (`GET /discover`) --------------------------

  /// `GET /discover?page&limit&distance&purpose&interest&availability`.
  Future<DiscoverPage> people({
    required int page,
    int limit = 20,
    DiscoverFilters filters = DiscoverFilters.none,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      ...filters.toQuery(),
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final envelope = await _client.getRaw('/discover?$query');
    return DiscoverPage.fromEnvelope(envelope);
  }

  /// `GET /discover/:userId` — the public profile for "View Profile".
  Future<DiscoverUserProfile> profile(String userId) async {
    final data = await _client.get('/discover/$userId');
    return DiscoverUserProfile.fromJson(data);
  }
}

DiscoverFeed _feedFromHome(Map<String, dynamic> data) {
  final user = data['user'] as Map<String, dynamic>? ?? const {};
  final meets = (data['recommendedMeets'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(_meetFromJson)
      .toList();
  final people = (data['nearbyPeople'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(_personFromJson)
      .toList();

  return DiscoverFeed(
    location: user['location'] as String? ?? 'Your area',
    meets: meets,
    nearbyPeople: people,
  );
}

CoffeeMeet _meetFromJson(Map<String, dynamic> j) {
  final host = j['host'] as Map<String, dynamic>? ?? const {};
  final shop = j['coffeeShop'] as Map<String, dynamic>? ?? const {};
  final maxP = (j['maxParticipants'] as num?)?.toInt() ?? 2;
  final spots = (j['spotsAvailable'] as num?)?.toInt() ?? 0;
  final date = j['date'] as String? ?? '';
  final time = j['startTime'] as String? ?? '00:00';

  return CoffeeMeet(
    id: j['id'] as String? ?? '',
    hostName: host['name'] as String? ?? 'Coffee Meet member',
    hostAge: (host['age'] as num?)?.toInt() ?? 0,
    hostAvatarUrl: host['profileImage'] as String? ?? '',
    bio: j['description'] as String? ?? '',
    sharedInterests: (j['interests'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    distanceKm: (j['distance'] as num?)?.toDouble() ?? 0,
    cafeName: shop['name'] as String? ?? 'A cafe nearby',
    startsAt: DateTime.tryParse('${date}T$time:00') ?? DateTime.now(),
    participantCount: (maxP - spots).clamp(0, maxP),
    maxParticipants: maxP,
    availableNow: spots > 0,
  );
}

NearbyPerson _personFromJson(Map<String, dynamic> j) {
  return NearbyPerson(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? 'Coffee Meet member',
    avatarUrl: j['profileImage'] as String? ?? '',
    interestTags: (j['interests'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    distanceKm: (j['distance'] as num?)?.toDouble() ?? 0,
  );
}

final discoverApiProvider = Provider<DiscoverApi>((ref) {
  return DiscoverApi(ref.watch(apiClientProvider));
});
