import 'package:flutter/foundation.dart';

/// coffee-meet-api connections contract (see `src/modules/connections`).
/// Only ever public profile fields — no ratings breakdown, no feedback.

@immutable
class ConnectionUser {
  const ConnectionUser({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.averageRating,
    this.bio,
    this.job,
  });

  final String id;
  final String name;
  final String? profileImage;
  final double? averageRating;

  /// Present only on the connection-detail response.
  final String? bio;
  final String? job;

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    return ConnectionUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Coffee Meet member',
      profileImage: json['profileImage'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      job: json['job'] as String?,
    );
  }
}

/// A row from `GET /connections`.
@immutable
class Connection {
  const Connection({
    required this.id,
    required this.user,
    required this.createdAt,
    this.meetingId,
  });

  final String id;
  final ConnectionUser user;
  final DateTime? createdAt;

  /// Present only on the detail response.
  final String? meetingId;

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String? ?? '',
      user: ConnectionUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      meetingId: json['meetingId'] as String?,
    );
  }
}
