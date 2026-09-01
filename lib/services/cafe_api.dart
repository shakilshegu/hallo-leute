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

  // --- café suggestion ----------------------------------------------

  Future<CafeSuggestion> suggestCafe(
    String matchId, {
    required String coffeeShopId,
    required String date, // YYYY-MM-DD
    required String startTime, // HH:mm
  }) async {
    final data = await _client.post(
      '/matches/$matchId/cafe-suggestion',
      body: {
        'coffeeShopId': coffeeShopId,
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
}

final cafeApiProvider = Provider<CafeApi>((ref) {
  return CafeApi(ref.watch(apiClientProvider));
});
