import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/services/coffee_request_api.dart';

/// The user's current active (PENDING) coffee request, or null.
///
/// The Create Coffee Meet screen watches this on entry: a non-null value
/// blocks a new request. Edit screens / the create flow `ref.invalidate` it
/// after creating or cancelling.
final activeCoffeeRequestProvider = FutureProvider<CoffeeRequest?>((ref) {
  return ref.watch(coffeeRequestApiProvider).getActive();
});

/// Maps an [ApiException] to a user-facing message for the Create flow.
String coffeeRequestErrorMessage(int statusCode, String backendMessage) {
  switch (statusCode) {
    case 401:
      return 'Your session has expired. Please log in again.';
    case 400:
      return backendMessage;
    case 409:
      return "You're already searching for a coffee match.";
    default:
      return 'Something went wrong. Please try again.';
  }
}
