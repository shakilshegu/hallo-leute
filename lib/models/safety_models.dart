import 'package:flutter/foundation.dart';

/// coffee-meet-api safety contract (see `src/modules/safety`).

/// Report-screen label → API `ReportReason` enum value.
const Map<String, String> kReportReasonToApi = {
  'Made me uncomfortable': 'uncomfortable',
  'Harassment': 'harassment',
  'Fake profile': 'fake_profile',
  "Didn't show up": 'no_show',
  'Inappropriate behaviour': 'inappropriate',
  'Other': 'other',
};

/// Cancel-sheet label → API `MeetingCancelReason` enum value.
const Map<String, String> kCancelReasonToApi = {
  'Something came up': 'schedule_conflict',
  "I don't feel comfortable": 'uncomfortable',
  'Plans changed': 'personal_reason',
  'Other': 'other',
};

@immutable
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.blockedAt,
  });

  final String id;
  final String name;
  final String? profileImage;
  final DateTime? blockedAt;

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Coffee Meet member',
      profileImage: json['profileImage'] as String?,
      blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
    );
  }
}
