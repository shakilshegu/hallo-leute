import 'package:flutter/foundation.dart';

enum CoffeeRequestStatus { pending, matched, cancelled, expired, unknown }

CoffeeRequestStatus _statusFrom(String? v) {
  switch (v) {
    case 'PENDING':
      return CoffeeRequestStatus.pending;
    case 'MATCHED':
      return CoffeeRequestStatus.matched;
    case 'CANCELLED':
      return CoffeeRequestStatus.cancelled;
    case 'EXPIRED':
      return CoffeeRequestStatus.expired;
    default:
      return CoffeeRequestStatus.unknown;
  }
}

/// Mirrors the coffee-meet-api `CoffeeRequestResponse`.
@immutable
class CoffeeRequest {
  const CoffeeRequest({
    required this.id,
    required this.status,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.maxDistanceKm,
    required this.purpose,
    required this.conversationStyle,
    required this.expiresAt,
  });

  final String id;
  final CoffeeRequestStatus status;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final int durationMinutes;
  final int maxDistanceKm;
  final String purpose;
  final String conversationStyle;
  final DateTime? expiresAt;

  bool get isPending => status == CoffeeRequestStatus.pending;

  factory CoffeeRequest.fromJson(Map<String, dynamic> json) {
    return CoffeeRequest(
      id: json['id'] as String? ?? '',
      status: _statusFrom(json['status'] as String?),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toInt() ?? 0,
      purpose: json['purpose'] as String? ?? '',
      conversationStyle: json['conversationStyle'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }
}
