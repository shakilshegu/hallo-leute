import 'package:flutter/foundation.dart';

/// Parsed shape of `GET /users/me`.
@immutable
class UserMe {
  const UserMe({
    required this.id,
    required this.phone,
    required this.onboardingCompleted,
    required this.profile,
    required this.interests,
    required this.preferences,
    required this.purpose,
  });

  final String id;
  final String? phone;
  final bool onboardingCompleted;
  final MeProfile? profile;
  final List<Interest> interests;
  final MePreferences? preferences;

  /// coffee-meet-api `Purpose` enum value, e.g. `networking`.
  final String? purpose;

  factory UserMe.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    final prefsJson = json['preferences'];
    return UserMe(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      profile: profileJson is Map<String, dynamic>
          ? MeProfile.fromJson(profileJson)
          : null,
      interests: (json['interests'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Interest.fromJson)
          .toList(),
      preferences: prefsJson is Map<String, dynamic>
          ? MePreferences.fromJson(prefsJson)
          : null,
      purpose: json['purpose'] as String?,
    );
  }

  List<String> get interestIds => interests.map((i) => i.id).toList();
}

@immutable
class MeProfile {
  const MeProfile({
    required this.firstName,
    required this.age,
    required this.job,
    required this.bio,
    required this.photoUrl,
  });

  final String firstName;
  final int age;
  final String? job;
  final String? bio;
  final String? photoUrl;

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    return MeProfile(
      firstName: json['firstName'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      job: json['job'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

@immutable
class MePreferences {
  const MePreferences({
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    required this.conversationStyles,
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;

  /// coffee-meet-api values: `casual | deep | career | hobbies | anything`.
  final List<String> conversationStyles;

  factory MePreferences.fromJson(Map<String, dynamic> json) {
    return MePreferences(
      minAge: (json['minAge'] as num?)?.toInt() ?? 18,
      maxAge: (json['maxAge'] as num?)?.toInt() ?? 100,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toInt() ?? 5,
      conversationStyles: (json['conversationStyles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

@immutable
class Interest {
  const Interest({required this.id, required this.label});

  final String id;
  final String label;

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

/// The selectable interest catalogue — chip label is the display, the value is
/// the coffee-meet-api slug (lower-cased label). Kept in sync with the seed in
/// `coffee-meet-api/prisma/seed.ts`.
const List<String> kInterestCatalog = [
  'Travel',
  'Food',
  'Technology',
  'Startups',
  'Music',
  'Movies',
  'Fitness',
  'Books',
  'Design',
  'Photography',
  'Sports',
  'Gaming',
];

/// Purpose: display label ↔ coffee-meet-api enum value.
const Map<String, String> kPurposeLabelToApi = {
  'Make friends': 'friends',
  'Networking': 'networking',
  'Shared interests': 'shared_interests',
  'Dating': 'dating',
  'Good conversation': 'good_conversation',
};

String purposeLabelFromApi(String? apiValue) {
  if (apiValue == null) return '';
  for (final entry in kPurposeLabelToApi.entries) {
    if (entry.value == apiValue) return entry.key;
  }
  return '';
}

/// Conversation style: display label ↔ coffee-meet-api value. Edit Preferences
/// keeps the API's own five options (unlike the onboarding screen, which maps a
/// friendlier four).
const Map<String, String> kConversationStyleLabelToApi = {
  'Casual': 'casual',
  'Deep': 'deep',
  'Career': 'career',
  'Hobbies': 'hobbies',
  'Anything': 'anything',
};

String conversationStyleLabelFromApi(String apiValue) {
  for (final entry in kConversationStyleLabelToApi.entries) {
    if (entry.value == apiValue) return entry.key;
  }
  return apiValue;
}
