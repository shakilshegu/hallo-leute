import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/connection_api.dart';

export 'package:poppylo/services/connection_api.dart'
    show ConnectionApi, connectionApiProvider;

/// The current user's mutual connections (`GET /connections`).
final connectionsProvider = FutureProvider.autoDispose<List<Connection>>((ref) {
  return ref.watch(connectionApiProvider).connections();
});

/// One connection's public detail (`GET /connections/:id`).
final connectionDetailProvider =
    FutureProvider.autoDispose.family<Connection, String>((ref, id) {
  return ref.watch(connectionApiProvider).connection(id);
});

/// User-facing copy for a failed connections call.
String connectionErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 404:
        return 'This connection is no longer available.';
      case 0:
        return 'Unable to connect. Please try again.';
      case 500:
        return 'Something went wrong. Please try again.';
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}
