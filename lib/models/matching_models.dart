import 'package:flutter/foundation.dart';

/// coffee-meet-api matching contract (see `src/modules/matching`).

/// Whether the backend has found a match for a coffee request yet.
enum MatchOutcome { searching, matchFound }

/// `Match.status` — the lifecycle of a match between two people.
enum MatchLifecycle {
  pending, // created, nobody has responded
  acceptedByOne, // one person accepted, waiting on the other
  confirmed, // both accepted — café flow unlocks
  declined, // someone passed
  expired,
  unknown,
}

MatchLifecycle _lifecycleFrom(String? v) {
  switch (v) {
    case 'PENDING':
      return MatchLifecycle.pending;
    case 'ACCEPTED_BY_ONE':
      return MatchLifecycle.acceptedByOne;
    case 'CONFIRMED':
      return MatchLifecycle.confirmed;
    case 'DECLINED':
      return MatchLifecycle.declined;
    case 'EXPIRED':
      return MatchLifecycle.expired;
    default:
      return MatchLifecycle.unknown;
  }
}

/// One participant's response to a match.
enum MatchResponseStatus { pending, accepted, declined, unknown }

MatchResponseStatus _responseFrom(String? v) {
  switch (v) {
    case 'PENDING':
      return MatchResponseStatus.pending;
    case 'ACCEPTED':
      return MatchResponseStatus.accepted;
    case 'DECLINED':
      return MatchResponseStatus.declined;
    default:
      return MatchResponseStatus.unknown;
  }
}

/// The other person on the Match Found / Match Details screens. No private
/// fields — the backend only sends what these screens display.
@immutable
class MatchProfile {
  const MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.job,
    required this.bio,
    required this.interests,
  });

  final String id;
  final String name;
  final int? age;
  final String? photoUrl;
  final String? job;
  final String? bio;
  final List<String> interests;

  factory MatchProfile.fromJson(Map<String, dynamic> json) {
    return MatchProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Coffee Meet member',
      age: (json['age'] as num?)?.toInt(),
      photoUrl: json['profileImage'] as String?,
      job: json['job'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Mirrors coffee-meet-api `MatchView`.
@immutable
class MatchDetails {
  const MatchDetails({
    required this.id,
    required this.score,
    required this.status,
    required this.myResponse,
    required this.otherResponse,
    required this.whyMatched,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.user,
  });

  final String id;
  final int score; // 0-100, from the backend — never computed on device
  final MatchLifecycle status;
  final MatchResponseStatus myResponse;
  final MatchResponseStatus otherResponse;
  final List<String> whyMatched;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final int durationMinutes;
  final MatchProfile user;

  bool get isConfirmed => status == MatchLifecycle.confirmed;
  bool get isDeclined => status == MatchLifecycle.declined;
  bool get isExpired => status == MatchLifecycle.expired;
  bool get isTerminal => isDeclined || isExpired;

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      id: json['id'] as String? ?? '',
      score: (json['score'] as num?)?.round() ?? 0,
      status: _lifecycleFrom(json['status'] as String?),
      myResponse: _responseFrom(json['myResponse'] as String?),
      otherResponse: _responseFrom(json['otherResponse'] as String?),
      whyMatched: (json['whyMatched'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      user: MatchProfile.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Result of `POST /matching/requests/:id/start` and
/// `GET /matching/requests/:id/status`.
@immutable
class MatchStatusResult {
  const MatchStatusResult._({
    required this.outcome,
    this.match,
    this.requestId,
    this.message,
  });

  final MatchOutcome outcome;
  final MatchDetails? match;
  final String? requestId;
  final String? message;

  bool get isMatchFound => outcome == MatchOutcome.matchFound;

  factory MatchStatusResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;
    if (status == 'MATCH_FOUND' && json['match'] is Map<String, dynamic>) {
      return MatchStatusResult._(
        outcome: MatchOutcome.matchFound,
        match: MatchDetails.fromJson(json['match'] as Map<String, dynamic>),
      );
    }
    return MatchStatusResult._(
      outcome: MatchOutcome.searching,
      requestId: json['requestId'] as String?,
      message: json['message'] as String?,
    );
  }
}
