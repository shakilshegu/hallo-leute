import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/connections*`. The repository layer for mutual
/// connections. The Firebase ID token is attached automatically by
/// [ApiClient].
class ConnectionApi {
  ConnectionApi(this._client);

  final ApiClient _client;

  /// `GET /connections` — the caller's mutual connections.
  Future<List<Connection>> connections() async {
    final rows = await _client.getList('/connections');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Connection.fromJson)
        .toList();
  }

  /// `GET /connections/:connectionId` — participants only; public profile
  /// info for the other person.
  Future<Connection> connection(String connectionId) async {
    final data = await _client.get('/connections/$connectionId');
    return Connection.fromJson(data);
  }
}

final connectionApiProvider = Provider<ConnectionApi>((ref) {
  return ConnectionApi(ref.watch(apiClientProvider));
});
