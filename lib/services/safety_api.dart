import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/cafe_models.dart' show MeetingDetails;
import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/users/:id/report|block` + `/users/blocked` +
/// `/meetings/:id/cancel`. The data layer for the safety feature — screens
/// call this via providers, never [ApiClient] directly. The Firebase ID token
/// is attached automatically by [ApiClient].
class SafetyApi {
  SafetyApi(this._client);

  final ApiClient _client;

  /// `POST /users/:userId/report`. `reason` is an API enum value.
  Future<void> reportUser(
    String userId, {
    required String reason,
    String? details,
  }) async {
    await _client.post('/users/$userId/report', body: {
      'reason': reason,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim(),
    });
  }

  /// `POST /users/:userId/block` — idempotent.
  Future<void> blockUser(String userId) async {
    await _client.post('/users/$userId/block');
  }

  /// `DELETE /users/:userId/block` — idempotent.
  Future<void> unblockUser(String userId) async {
    await _client.delete('/users/$userId/block');
  }

  /// `GET /users/blocked`.
  Future<List<BlockedUser>> blockedUsers() async {
    final rows = await _client.getList('/users/blocked');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(BlockedUser.fromJson)
        .toList();
  }

  /// `POST /meetings/:meetingId/cancel`. Returns the meeting (status CANCELLED).
  Future<MeetingDetails> cancelMeeting(
    String meetingId, {
    required String reason,
  }) async {
    final data = await _client
        .post('/meetings/$meetingId/cancel', body: {'reason': reason});
    return MeetingDetails.fromJson(data);
  }
}

final safetyApiProvider = Provider<SafetyApi>((ref) {
  return SafetyApi(ref.watch(apiClientProvider));
});
