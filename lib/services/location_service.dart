import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

@immutable
class ResolvedPlace {
  const ResolvedPlace({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  final double latitude;
  final double longitude;

  /// e.g. "Kochi, India" — a short human label for the location row.
  final String name;
}

class LocationDenied implements Exception {
  LocationDenied(
    this.message, {
    this.permanent = false,
    this.servicesOff = false,
    this.unavailable = false,
  });

  final String message;

  /// The user chose "Don't allow" permanently — only Settings can fix it.
  final bool permanent;

  /// Device location services (GPS) are switched off.
  final bool servicesOff;

  /// Permission is fine but no fix could be obtained (common on an emulator
  /// with no mock location, or a poor signal).
  final bool unavailable;

  @override
  String toString() => message;
}

/// Device location + reverse geocoding, isolated so it can be faked in tests.
class LocationService {
  static const _fixTimeout = Duration(seconds: 10);

  /// A cached fix older than this is still fine for "cafés near me".
  static const _acceptableStaleness = Duration(minutes: 30);

  Future<ResolvedPlace> currentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationDenied(
        'Turn on location services, then try again.',
        servicesOff: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationDenied(
        'Location permission is needed to find nearby coffee spots.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationDenied(
        'Location is blocked. Enable it for Coffee Meet in Settings.',
        permanent: true,
      );
    }

    final pos = await _getPosition();

    return ResolvedPlace(
      latitude: pos.latitude,
      longitude: pos.longitude,
      name: await _label(pos.latitude, pos.longitude),
    );
  }

  /// Best-effort fix. Order matters for emulators: a recent last-known
  /// position is used immediately (emulator "geo fix" often shows up here but
  /// never as a *fresh* stream fix); otherwise we ask for one, capped by a
  /// timeout; on timeout we accept any last-known fix rather than failing.
  Future<Position> _getPosition() async {
    final cached = await _safeLastKnown();
    if (cached != null && _fresh(cached)) return cached;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // `low` uses the network/passive provider — on an emulator it returns
          // the set mock location straight away instead of waiting for GPS.
          accuracy: LocationAccuracy.low,
          timeLimit: _fixTimeout,
        ),
      );
    } on TimeoutException {
      final last = cached ?? await _safeLastKnown();
      if (last != null) return last;
      throw LocationDenied(
        "Couldn't get your location. On an emulator, open Extended controls "
        '(•••) → Location → set a point → Set location, then tap Try again.',
        unavailable: true,
      );
    } on LocationServiceDisabledException {
      throw LocationDenied(
        'Turn on location services, then try again.',
        servicesOff: true,
      );
    }
  }

  Future<Position?> _safeLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  bool _fresh(Position p) {
    final ts = p.timestamp;
    return DateTime.now().difference(ts) <= _acceptableStaleness;
  }

  /// Forward-geocode a free-text area ("Berlin", "MG Road, Kochi") to coords —
  /// the fallback when the device can't provide a fix.
  Future<ResolvedPlace> placeFromQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) throw LocationDenied('Enter a place to search.');
    try {
      final results = await geocoding
          .locationFromAddress(q)
          .timeout(const Duration(seconds: 8));
      if (results.isEmpty) {
        throw LocationDenied("Couldn't find \"$q\". Try a nearby city.");
      }
      final loc = results.first;
      return ResolvedPlace(
        latitude: loc.latitude,
        longitude: loc.longitude,
        name: q,
      );
    } on LocationDenied {
      rethrow;
    } catch (_) {
      throw LocationDenied(
        "Couldn't look up \"$q\". Check your connection and try again.",
      );
    }
  }

  Future<String> _label(double lat, double lng) async {
    try {
      final marks = await geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));
      if (marks.isEmpty) return 'Current location';
      final m = marks.first;
      final city = m.locality?.isNotEmpty == true
          ? m.locality!
          : (m.subAdministrativeArea ?? m.administrativeArea ?? '');
      final country = m.country ?? '';
      final parts = [city, country].where((s) => s.isNotEmpty).toList();
      return parts.isEmpty ? 'Current location' : parts.join(', ');
    } catch (_) {
      return 'Current location';
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
