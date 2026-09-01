import 'package:flutter/foundation.dart';

/// coffee-meet-api café-selection + meeting contract
/// (see `src/modules/coffee-shops`, `cafe-proposals`, `meetings`).

@immutable
class CoffeeShop {
  const CoffeeShop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.rating,
    required this.priceLevel,
    required this.description,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double? rating;
  final int? priceLevel; // 1-4
  final String? description;
  final double? distanceKm; // null when the query had no location

  /// "₹".."₹₹₹₹", or '' when unknown.
  String get priceLabel {
    final n = priceLevel;
    if (n == null || n < 1) return '';
    return '₹' * n.clamp(1, 4);
  }

  factory CoffeeShop.fromJson(Map<String, dynamic> json) {
    return CoffeeShop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Café',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: (json['priceLevel'] as num?)?.toInt(),
      description: json['description'] as String?,
      distanceKm: (json['distance'] as num?)?.toDouble(),
    );
  }
}

enum CafeSuggestionStatus { pending, changed, accepted, declined, unknown }

CafeSuggestionStatus _suggestionStatusFrom(String? v) {
  switch (v) {
    case 'PENDING':
      return CafeSuggestionStatus.pending;
    case 'CHANGED':
      return CafeSuggestionStatus.changed;
    case 'ACCEPTED':
      return CafeSuggestionStatus.accepted;
    case 'DECLINED':
      return CafeSuggestionStatus.declined;
    default:
      return CafeSuggestionStatus.unknown;
  }
}

@immutable
class CafeSuggestedBy {
  const CafeSuggestedBy({
    required this.id,
    required this.name,
    required this.isMe,
  });

  final String id;
  final String name;
  final bool isMe;
}

@immutable
class CafeSuggestion {
  const CafeSuggestion({
    required this.id,
    required this.status,
    required this.date,
    required this.startTime,
    required this.suggestedBy,
    required this.cafe,
    required this.meetingId,
  });

  final String id;
  final CafeSuggestionStatus status;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final CafeSuggestedBy suggestedBy;
  final CoffeeShop cafe;
  final String? meetingId;

  bool get isAccepted => status == CafeSuggestionStatus.accepted;
  bool get isDeclined => status == CafeSuggestionStatus.declined;

  /// The other person still needs to accept (and it wasn't me who proposed
  /// the current version).
  bool get awaitingMyResponse =>
      !isAccepted && !isDeclined && !suggestedBy.isMe;

  factory CafeSuggestion.fromJson(Map<String, dynamic> json) {
    final by = json['suggestedBy'] as Map<String, dynamic>? ?? const {};
    return CafeSuggestion(
      id: json['id'] as String? ?? '',
      status: _suggestionStatusFrom(json['status'] as String?),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      suggestedBy: CafeSuggestedBy(
        id: by['id'] as String? ?? '',
        name: by['name'] as String? ?? 'Your match',
        isMe: by['isMe'] as bool? ?? false,
      ),
      cafe: CoffeeShop.fromJson(
        json['cafe'] as Map<String, dynamic>? ?? const {},
      ),
      meetingId: json['meetingId'] as String?,
    );
  }
}

enum MeetingLifecycle { confirmed, cancelled, completed, unknown }

MeetingLifecycle _meetingStatusFrom(String? v) {
  switch (v) {
    case 'CONFIRMED':
      return MeetingLifecycle.confirmed;
    case 'CANCELLED':
      return MeetingLifecycle.cancelled;
    case 'COMPLETED':
      return MeetingLifecycle.completed;
    default:
      return MeetingLifecycle.unknown;
  }
}

@immutable
class MeetingPartner {
  const MeetingPartner({
    required this.id,
    required this.name,
    required this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;
}

/// Mirrors coffee-meet-api `MeetingView`.
@immutable
class MeetingDetails {
  const MeetingDetails({
    required this.id,
    required this.matchId,
    required this.status,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.cafe,
    required this.partner,
    required this.createdAt,
  });

  final String id;
  final String matchId;
  final MeetingLifecycle status;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final int durationMinutes;
  final CoffeeShop cafe;
  final MeetingPartner partner;
  final DateTime? createdAt;

  DateTime? get startsAt => DateTime.tryParse('${date}T$startTime:00');
  DateTime? get endsAt => startsAt?.add(Duration(minutes: durationMinutes));

  factory MeetingDetails.fromJson(Map<String, dynamic> json) {
    final p = json['partner'] as Map<String, dynamic>? ?? const {};
    return MeetingDetails(
      id: json['id'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      status: _meetingStatusFrom(json['status'] as String?),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      cafe: CoffeeShop.fromJson(
        json['cafe'] as Map<String, dynamic>? ?? const {},
      ),
      partner: MeetingPartner(
        id: p['id'] as String? ?? '',
        name: p['name'] as String? ?? 'Your match',
        profileImage: p['profileImage'] as String?,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

@immutable
class AcceptCafeResult {
  const AcceptCafeResult({required this.suggestion, required this.meeting});

  final CafeSuggestion suggestion;
  final MeetingDetails meeting;

  factory AcceptCafeResult.fromJson(Map<String, dynamic> json) {
    return AcceptCafeResult(
      suggestion: CafeSuggestion.fromJson(
        json['suggestion'] as Map<String, dynamic>? ?? const {},
      ),
      meeting: MeetingDetails.fromJson(
        json['meeting'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

// --- shared formatting -------------------------------------------------

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String prettyClock(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  return '$h:$m $ampm';
}

/// "Thu, Oct 24 · 5:00 PM"
String formatSlotDateTime(String date, String startTime) {
  final dt = DateTime.tryParse('${date}T$startTime:00');
  if (dt == null) return '$date · ${prettyClock(startTime)}';
  final wd = _weekdays[dt.weekday - 1].substring(0, 3);
  final mon = _monthsShort[dt.month - 1];
  return '$wd, $mon ${dt.day} · ${prettyClock(startTime)}';
}

/// "SATURDAY 5:00 PM – 5:45 PM"
String formatMeetingTimeRange(MeetingDetails m) {
  final start = m.startsAt;
  final end = m.endsAt;
  if (start == null || end == null) {
    return '${prettyClock(m.startTime)} · ${m.durationMinutes} min';
  }
  final day = _weekdays[start.weekday - 1].toUpperCase();
  return '$day ${prettyClock(m.startTime)} – '
      '${prettyClock('${end.hour.toString().padLeft(2, '0')}:'
          '${end.minute.toString().padLeft(2, '0')}')}';
}
