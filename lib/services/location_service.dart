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
  LocationDenied(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Device location + reverse geocoding, isolated so it can be faked in tests.
class LocationService {
  static const _fixTimeout = Duration(seconds: 12);

  Future<ResolvedPlace> currentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationDenied('Turn on location services, then try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationDenied('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationDenied(
        'Location is blocked. Enable it for Coffee Meet in Settings.',
      );
    }

    final pos = await _getPosition();

    return ResolvedPlace(
      latitude: pos.latitude,
      longitude: pos.longitude,
      name: await _label(pos.latitude, pos.longitude),
    );
  }

  /// A fresh fix, capped by a timeout so it can't hang forever (common on an
  /// emulator with no mock location) — falls back to the last known position.
  Future<Position> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _fixTimeout,
        ),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw LocationDenied(
        "Couldn't get a location fix. On an emulator, set a mock "
        'location first (Extended controls → Location).',
      );
    } on LocationServiceDisabledException {
      throw LocationDenied('Turn on location services, then try again.');
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
