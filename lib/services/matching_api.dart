import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/matching` + `/matches`. The data/repository layer for the
/// matching flow — screens and controllers never touch [ApiClient] directly.
/// The Firebase ID token is attached automatically by [ApiClient].
class MatchingApi {
  MatchingApi(this._client);

  final ApiClient _client;

  /// `POST /matching/requests/:id/start` — kick off matching for the caller's
  /// own pending coffee request.
  Future<MatchStatusResult> startMatching(String requestId) async {
    final data = await _client.post('/matching/requests/$requestId/start');
    return MatchStatusResult.fromJson(data);
  }

  /// `GET /matching/requests/:id/status` — the Searching screen polls this.
  Future<MatchStatusResult> pollStatus(String requestId) async {
    final data = await _client.get('/matching/requests/$requestId/status');
    return MatchStatusResult.fromJson(data);
  }

  /// `GET /matches/:id` — the Match Found / Details / Waiting / Confirmed
  /// screens read the current match from here.
  Future<MatchDetails> getMatch(String matchId) async {
    final data = await _client.get('/matches/$matchId');
    return MatchDetails.fromJson(data);
  }

  /// `POST /matches/:id/accept`. Returns the updated match — `status` is
  /// `ACCEPTED_BY_ONE` or, once both have accepted, `CONFIRMED`.
  Future<MatchDetails> accept(String matchId) async {
    final data = await _client.post('/matches/$matchId/accept');
    return MatchDetails.fromJson(data);
  }

  /// `POST /matches/:id/pass` — decline. Both coffee requests reopen.
  Future<MatchDetails> pass(String matchId) async {
    final data = await _client.post('/matches/$matchId/pass');
    return MatchDetails.fromJson(data);
  }
}

final matchingApiProvider = Provider<MatchingApi>((ref) {
  return MatchingApi(ref.watch(apiClientProvider));
});
