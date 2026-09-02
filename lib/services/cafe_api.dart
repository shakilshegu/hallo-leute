import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/coffee-shops` + `/matches/:id/cafe-suggestion*` +
/// `/meetings`. The data/repository layer for the café-selection and meeting
/// screens — widgets never touch [ApiClient] directly. The Firebase ID token
/// is attached automatically by [ApiClient].
class CafeApi {
  CafeApi(this._client);

  final ApiClient _client;

  // --- coffee shops (CoffeeShopRepository) ----------------------------

  Future<List<CoffeeShop>> nearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
    int limit = 20,
  }) async {
    final rows = await _client.getList(
      '/coffee-shops/nearby?latitude=$latitude&longitude=$longitude'
      '&radius=${radiusKm.round()}&limit=$limit',
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CoffeeShop.fromJson)
        .toList();
  }

  Future<CoffeeShop> cafe(String id) async {
    final data = await _client.get('/coffee-shops/$id');
    return CoffeeShop.fromJson(data);
  }

  // --- nearby cafés via Google Places (`GET /cafes/*`) --------------

  /// `GET /api/v1/cafes/nearby?latitude&longitude&radius` — discovery is
  /// Google Places, proxied by the backend (the API key stays server-side).
  Future<List<NearbyCafe>> nearbyGoogleCafes({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final rows = await _client.getList(
      '/cafes/nearby?latitude=$latitude&longitude=$longitude'
      '&radius=$radiusMeters',
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(NearbyCafe.fromJson)
        .toList();
  }

  /// `GET /api/v1/cafes/:placeId` — opening hours + photos. `latitude`/
  /// `longitude` (the user's origin) are optional and only fill in `distance`.
  Future<CafePlaceDetails> cafePlaceDetails(
    String placeId, {
    double? latitude,
    double? longitude,
  }) async {
    final q = (latitude != null && longitude != null)
        ? '?latitude=$latitude&longitude=$longitude'
        : '';
    final data = await _client.get('/cafes/$placeId$q');
    return CafePlaceDetails.fromJson(data);
  }

  /// Full URL for a café photo-proxy path. The backend returns an absolute
  /// path (`/api/v1/cafes/photo?ref=...`), so build it against the API
  /// origin — NOT `baseUrl` (which already ends in `/api/v1`).
  String cafePhotoUrl(String proxyPath) {
    if (proxyPath.startsWith('http')) return proxyPath;
    final base = Uri.parse(_client.baseUrl);
    final origin = '${base.scheme}://${base.authority}';
    final path = proxyPath.startsWith('/') ? proxyPath : '/$proxyPath';
    return '$origin$path';
  }

  /// Bearer header for loading a café photo via `Image.network`.
  Future<Map<String, String>> imageAuthHeaders() async {
    final token = await _client.tokenProvider();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  // --- café suggestion ----------------------------------------------

  /// Propose a café for a confirmed match. Pass a Google `placeId` (preferred —
  /// the backend fetches it from Google and stores a copy) OR an existing
  /// `coffeeShopId` (the hand-seeded demo shops). Exactly one.
  Future<CafeSuggestion> suggestCafe(
    String matchId, {
    String? placeId,
    String? coffeeShopId,
    required String date, // YYYY-MM-DD
    required String startTime, // HH:mm
  }) async {
    assert(
      (placeId == null) != (coffeeShopId == null),
      'Pass exactly one of placeId / coffeeShopId',
    );
    final data = await _client.post(
      '/matches/$matchId/cafe-suggestion',
      body: {
        if (placeId != null) 'placeId': placeId,
        if (coffeeShopId != null) 'coffeeShopId': coffeeShopId,
        'date': date,
        'startTime': startTime,
      },
    );
    return CafeSuggestion.fromJson(data);
  }

  /// `GET /matches/:id/cafe-suggestion` → the current suggestion, or null.
  Future<CafeSuggestion?> cafeSuggestion(String matchId) async {
    final data = await _client.get('/matches/$matchId/cafe-suggestion');
    if (data.isEmpty) return null;
    return CafeSuggestion.fromJson(data);
  }

  /// The non-suggester accepts → the backend confirms the meeting for both.
  Future<AcceptCafeResult> acceptCafeSuggestion(String matchId) async {
    final data = await _client.post('/matches/$matchId/cafe-suggestion/accept');
    return AcceptCafeResult.fromJson(data);
  }

  // --- meetings (MeetingRepository) --------------------------------

  Future<MeetingDetails> meeting(String id) async {
    final data = await _client.get('/meetings/$id');
    return MeetingDetails.fromJson(data);
  }

  Future<List<MeetingDetails>> upcomingMeetings() async {
    final rows = await _client.getList('/meetings/upcoming');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MeetingDetails.fromJson)
        .toList();
  }

  /// `GET /meetings` — every meeting the caller is part of, any status.
  Future<List<MeetingDetails>> allMeetings() async {
    final rows = await _client.getList('/meetings');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MeetingDetails.fromJson)
        .toList();
  }
}

final cafeApiProvider = Provider<CafeApi>((ref) {
  return CafeApi(ref.watch(apiClientProvider));
});
