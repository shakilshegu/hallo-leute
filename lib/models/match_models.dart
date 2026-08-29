enum MatchStatus { pending, proposed, accepted, confirmed, declined, expired }

extension MatchStatusOrdering on MatchStatus {
  static const List<MatchStatus> _activeOrder = [
    MatchStatus.pending,
    MatchStatus.proposed,
    MatchStatus.accepted,
    MatchStatus.confirmed,
  ];

  bool get isTerminal =>
      this == MatchStatus.declined || this == MatchStatus.expired;

  /// True when this status is [other] or a later stage in the active
  /// (non-terminal) lifecycle. Declined/expired matches are never "at least"
  /// anything, so guards gated on this always deny a stale match.
  bool isAtLeast(MatchStatus other) {
    if (isTerminal) return false;
    return _activeOrder.indexOf(this) >= _activeOrder.indexOf(other);
  }
}

class MeetRequest {
  final String dateLabel;
  final String timeLabel;
  final DateTime time;
  final String durationLabel;
  final double radiusKm;
  final List<String> whyLabels;
  final List<String> conversationLabels;

  const MeetRequest({
    required this.dateLabel,
    required this.timeLabel,
    required this.time,
    required this.durationLabel,
    required this.radiusKm,
    required this.whyLabels,
    required this.conversationLabels,
  });
}

class Cafe {
  final String id;
  final String name;
  final String address;
  final double rating;
  final double distanceKm;
  final String imageUrl;

  const Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.distanceKm,
    required this.imageUrl,
  });
}

class Match {
  final String id;
  final String partnerName;
  final MatchStatus status;
  final DateTime proposedTime;
  final String? cafeId;
  final String? cafeName;

  const Match({
    required this.id,
    required this.partnerName,
    required this.status,
    required this.proposedTime,
    this.cafeId,
    this.cafeName,
  });

  Match copyWith({MatchStatus? status, String? cafeId, String? cafeName}) {
    return Match(
      id: id,
      partnerName: partnerName,
      status: status ?? this.status,
      proposedTime: proposedTime,
      cafeId: cafeId ?? this.cafeId,
      cafeName: cafeName ?? this.cafeName,
    );
  }
}
