import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/models/meeting_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/services/location_service.dart';
import 'package:poppylo/state/meeting_controller.dart';

export 'package:poppylo/services/cafe_api.dart' show CafeApi, cafeApiProvider;

/// Coffee shops near the user's current location, for the Choose Café screen.
final nearbyCafesProvider =
    FutureProvider.autoDispose<List<CoffeeShop>>((ref) async {
  final place = await ref.watch(locationServiceProvider).currentPlace();
  return ref.watch(cafeApiProvider).nearbyCafes(
        latitude: place.latitude,
        longitude: place.longitude,
      );
});

/// A single coffee shop's details (`GET /coffee-shops/:id`).
final cafeProvider = FutureProvider.family<CoffeeShop, String>((ref, cafeId) {
  return ref.watch(cafeApiProvider).cafe(cafeId);
});

/// The current café suggestion for a match, or null. The Café Suggested
/// screen `ref.invalidate`s this on a timer to poll for the other person's
/// acceptance.
final cafeSuggestionProvider =
    FutureProvider.family<CafeSuggestion?, String>((ref, matchId) {
  return ref.watch(cafeApiProvider).cafeSuggestion(matchId);
});

/// A confirmed meeting (`GET /meetings/:id`). Loading it also refreshes the
/// synchronous [meetingRepositoryProvider] cache the route guards read, so
/// the meeting guard stops sending the user back into the café flow.
final meetingDetailsProvider =
    FutureProvider.family<MeetingDetails, String>((ref, meetingId) async {
  final meeting = await ref.watch(cafeApiProvider).meeting(meetingId);
  ref
      .read(meetingRepositoryProvider.notifier)
      .upsert(meetingFromDetails(meeting));
  return meeting;
});

final upcomingMeetingsProvider =
    FutureProvider.autoDispose<List<MeetingDetails>>((ref) {
  return ref.watch(cafeApiProvider).upcomingMeetings();
});

/// Maps the backend `MeetingView` onto the guard-facing [Meeting] model.
Meeting meetingFromDetails(MeetingDetails d) {
  final now = DateTime.now();
  return Meeting(
    id: d.id,
    matchId: d.matchId,
    partnerName: d.partner.name,
    startTime: d.startsAt ?? now,
    endTime: d.endsAt ?? now.add(Duration(minutes: d.durationMinutes)),
    cafeName: d.cafe.name,
    cafeAddress: d.cafe.address,
    status: switch (d.status) {
      MeetingLifecycle.cancelled => MeetingStatus.cancelled,
      MeetingLifecycle.completed => MeetingStatus.completed,
      _ => MeetingStatus.scheduled,
    },
  );
}

/// User-facing copy for a failed café / meeting call.
String cafeErrorMessage(Object error) {
  if (error is LocationDenied) {
    return 'Turn on location to find cafés near you.';
  }
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 404:
        return 'This is no longer available.';
      case 409:
        // e.g. "A café has already been agreed." / "match not confirmed" /
        // "This meeting is already confirmed."
        return error.message;
      case 0:
        return 'Unable to connect. Please try again.';
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}
