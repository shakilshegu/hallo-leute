import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/safety_api.dart';

export 'package:poppylo/services/safety_api.dart'
    show SafetyApi, safetyApiProvider;

/// The people the current user has blocked (`GET /users/blocked`).
final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  return ref.watch(safetyApiProvider).blockedUsers();
});

/// User-facing copy for a failed safety call.
String safetyErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return "You can't do that here.";
      case 404:
        return 'This is no longer available.';
      case 409:
        // e.g. "You have already reported this person…" / meeting not confirmed
        return error.message;
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
