import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/coffee-requests` — the "find me a coffee match" request.
/// The Firebase ID token is attached automatically by [ApiClient].
class CoffeeRequestApi {
  CoffeeRequestApi(this._client);

  final ApiClient _client;

  /// `POST /coffee-requests`. `userId` is never sent — the backend resolves
  /// it from the token.
  Future<CoffeeRequest> create({
    required String date, // YYYY-MM-DD
    required String startTime, // HH:mm
    required int durationMinutes, // 30 | 45 | 60
    required int maxDistanceKm, // 2 | 5 | 10
    required String
        purpose, // friends | networking | shared_interests | dating | good_conversation
    required String
        conversationStyle, // casual | deep | career | hobbies | anything
  }) async {
    final data = await _client.post('/coffee-requests', body: {
      'date': date,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'maxDistanceKm': maxDistanceKm,
      'purpose': purpose,
      'conversationStyle': conversationStyle,
    });
    return CoffeeRequest.fromJson(data);
  }

  /// `GET /coffee-requests/active` → the user's current PENDING request, or null.
  Future<CoffeeRequest?> getActive() async {
    final data = await _client.get('/coffee-requests/active');
    final req = data['request'];
    return req is Map<String, dynamic> ? CoffeeRequest.fromJson(req) : null;
  }

  Future<CoffeeRequest> getById(String id) async {
    final data = await _client.get('/coffee-requests/$id');
    return CoffeeRequest.fromJson(data);
  }

  Future<CoffeeRequest> cancel(String id) async {
    final data = await _client.post('/coffee-requests/$id/cancel');
    return CoffeeRequest.fromJson(data);
  }
}

final coffeeRequestApiProvider = Provider<CoffeeRequestApi>((ref) {
  return CoffeeRequestApi(ref.watch(apiClientProvider));
});
