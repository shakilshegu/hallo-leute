import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/models/meeting_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/services/location_service.dart';
import 'package:poppylo/state/meeting_controller.dart';

export 'package:poppylo/services/cafe_api.dart' show CafeApi, cafeApiProvider;

// --- Nearby cafés via Google Places (`GET /cafes/nearby`) ---------------

const List<int> _radiusStepsMeters = [5000, 10000, 15000];

enum NearbyCafesPhase {
  locating, // asking for / obtaining the device location
  loading, // querying the backend
  ready, // have cafés
  empty, // backend returned none
  locationDenied, // permission denied (can re-ask)
  locationBlocked, // permission permanently denied → Settings
  gpsOff, // location services switched off
  locationUnavailable, // permission OK but no fix (emulator / weak signal)
  error, // API / network failure
}

@immutable
class NearbyCafesState {
  const NearbyCafesState({
    this.phase = NearbyCafesPhase.locating,
    this.cafes = const [],
    this.radiusMeters = 5000,
    this.origin,
    this.message,
  });

  final NearbyCafesPhase phase;
  final List<NearbyCafe> cafes;
  final int radiusMeters;
  final ResolvedPlace? origin;
  final String? message;

  bool get canExpandRadius => radiusMeters < _radiusStepsMeters.last;
  int get nextRadiusMeters => _radiusStepsMeters.firstWhere(
        (r) => r > radiusMeters,
        orElse: () => _radiusStepsMeters.last,
      );

  NearbyCafesState copyWith({
    NearbyCafesPhase? phase,
    List<NearbyCafe>? cafes,
    int? radiusMeters,
    ResolvedPlace? origin,
    String? message,
    bool clearMessage = false,
  }) {
    return NearbyCafesState(
      phase: phase ?? this.phase,
      cafes: cafes ?? this.cafes,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      origin: origin ?? this.origin,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Owns the Choose-Café list: asks for location only when this is created
/// (i.e. when the user reaches Choose Café), fetches nearby cafés from the
/// backend (Google Places), and supports radius expansion + retry. No API
/// calls in the widgets.
class NearbyCafesController extends StateNotifier<NearbyCafesState> {
  NearbyCafesController(this._ref) : super(const NearbyCafesState()) {
    load();
  }

  final Ref _ref;

  /// Full flow: resolve location, then fetch. Called on create + retry.
  Future<void> load() async {
    state =
        state.copyWith(phase: NearbyCafesPhase.locating, clearMessage: true);
    final ResolvedPlace place;
    try {
      place = await _ref.read(locationServiceProvider).currentPlace();
    } on LocationDenied catch (e) {
      state = state.copyWith(
        phase: e.servicesOff
            ? NearbyCafesPhase.gpsOff
            : e.permanent
                ? NearbyCafesPhase.locationBlocked
                : e.unavailable
                    ? NearbyCafesPhase.locationUnavailable
                    : NearbyCafesPhase.locationDenied,
        message: e.message,
      );
      return;
    } catch (_) {
      // Plugin / platform hiccup — treat as "couldn't get a fix", not denial.
      state = state.copyWith(
        phase: NearbyCafesPhase.locationUnavailable,
        message: "Couldn't get your location. Please try again.",
      );
      return;
    }
    state = state.copyWith(origin: place);
    await _fetch();
  }

  Future<void> expandRadius() async {
    if (!state.canExpandRadius || state.origin == null) return;
    state = state.copyWith(radiusMeters: state.nextRadiusMeters);
    await _fetch();
  }

  Future<void> retry() => load();

  /// Manual fallback: geocode a typed area, then search around it.
  Future<void> useTypedLocation(String query) async {
    state = state.copyWith(
      phase: NearbyCafesPhase.locating,
      clearMessage: true,
    );
    try {
      final place =
          await _ref.read(locationServiceProvider).placeFromQuery(query);
      state = state.copyWith(origin: place, radiusMeters: 5000);
      await _fetch();
    } on LocationDenied catch (e) {
      state = state.copyWith(
        phase: NearbyCafesPhase.locationUnavailable,
        message: e.message,
      );
    }
  }

  /// Manual fallback with exact coordinates (e.g. a demo city button).
  Future<void> useCoords(double latitude, double longitude, String name) async {
    state = state.copyWith(
      origin: ResolvedPlace(
        latitude: latitude,
        longitude: longitude,
        name: name,
      ),
      radiusMeters: 5000,
      clearMessage: true,
    );
    await _fetch();
  }

  Future<void> _fetch() async {
    final origin = state.origin;
    if (origin == null) return load();
    state = state.copyWith(phase: NearbyCafesPhase.loading, clearMessage: true);
    try {
      final cafes = await _ref.read(cafeApiProvider).nearbyGoogleCafes(
            latitude: origin.latitude,
            longitude: origin.longitude,
            radiusMeters: state.radiusMeters,
          );
      state = state.copyWith(
        cafes: cafes,
        phase: cafes.isEmpty ? NearbyCafesPhase.empty : NearbyCafesPhase.ready,
      );
    } catch (e) {
      state = state.copyWith(
        phase: NearbyCafesPhase.error,
        message: cafeErrorMessage(e),
      );
    }
  }
}

final nearbyCafesControllerProvider =
    StateNotifierProvider.autoDispose<NearbyCafesController, NearbyCafesState>(
        (ref) {
  return NearbyCafesController(ref);
});

/// One café's full detail (`GET /cafes/:placeId`). Reads the user's origin
/// from [nearbyCafesControllerProvider] so distance can be shown.
final cafePlaceDetailsProvider =
    FutureProvider.autoDispose.family<CafePlaceDetails, String>((ref, placeId) {
  final origin = ref.watch(
    nearbyCafesControllerProvider.select((s) => s.origin),
  );
  return ref.watch(cafeApiProvider).cafePlaceDetails(
        placeId,
        latitude: origin?.latitude,
        longitude: origin?.longitude,
      );
});

/// Bearer header for loading café photos through the backend proxy.
final cafeImageHeadersProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(cafeApiProvider).imageAuthHeaders();
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
