import 'package:flutter/foundation.dart';

import 'package:poppylo/models/match_models.dart';

/// Everything the three onboarding screens collect, held in one place so the
/// final "Start Coffee Meet" tap can build a [MeetRequest] and kick off the
/// search without threading values screen-to-screen.
@immutable
class OnboardingProfile {
  // --- Screen 1: build your profile ---
  final String? photoPath;
  final String firstName;
  final String age;
  final String work;
  final String bio;

  // --- Screen 2: conversation preferences ---
  final String? purpose;
  final List<String> interests;
  final String? conversationStyle;

  // --- Screen 3: coffee-meetup preferences ---
  final int distanceKm;
  final String meetingLength;
  final String when; // 'Today' | 'Tomorrow' | 'Choose a date'
  final DateTime? chosenDate;

  const OnboardingProfile({
    this.photoPath,
    this.firstName = '',
    this.age = '',
    this.work = '',
    this.bio = '',
    this.purpose,
    this.interests = const [],
    this.conversationStyle,
    this.distanceKm = 5,
    this.meetingLength = '45 min',
    this.when = 'Today',
    this.chosenDate,
  });

  static const int maxInterests = 7;
  static const int bioMaxLength = 150;

  /// Age-range preference isn't collected in the optimized 3-screen flow, so
  /// onboarding sends a wide-open default that the user can narrow later from
  /// profile preferences.
  static const int defaultMinAge = 18;
  static const int defaultMaxAge = 100;

  /// Screen labels → coffee-meet-api `Purpose` enum values.
  static const Map<String, String> purposeApiValues = {
    'Make friends': 'friends',
    'Networking': 'networking',
    'Shared interests': 'shared_interests',
    'Dating': 'dating',
    'Good conversation': 'good_conversation',
  };

  /// Screen labels → coffee-meet-api conversation-style values. The backend
  /// enum has no exact "professional"/"playful", so they map to the closest
  /// available option.
  static const Map<String, String> conversationStyleApiValues = {
    'Casual': 'casual',
    'Deep': 'deep',
    'Professional': 'career',
    'Playful': 'anything',
  };

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  bool get _isRemote {
    final p = photoPath;
    return p != null && (p.startsWith('http://') || p.startsWith('https://'));
  }

  /// True while [photoPath] is a device file path that hasn't been uploaded
  /// to `POST /profile/photo` yet.
  bool get hasPendingLocalPhoto => hasPhoto && !_isRemote;

  /// Already-hosted photo URL, or null while the photo is still a local file
  /// (the backend's `photoUrl` must be a real URL).
  String? get photoUrlForApi => _isRemote ? photoPath : null;

  int? get ageValue => int.tryParse(age.trim());

  /// Interest chip labels are the API's slugs, lower-cased ("Startups" →
  /// "startups").
  List<String> get interestIds =>
      interests.map((i) => i.toLowerCase()).toList();

  String? get purposeApiValue =>
      purpose == null ? null : purposeApiValues[purpose];

  String get conversationStyleApiValue =>
      conversationStyleApiValues[conversationStyle] ?? 'anything';

  OnboardingProfile copyWith({
    String? photoPath,
    String? firstName,
    String? age,
    String? work,
    String? bio,
    String? purpose,
    List<String>? interests,
    String? conversationStyle,
    int? distanceKm,
    String? meetingLength,
    String? when,
    DateTime? chosenDate,
  }) {
    return OnboardingProfile(
      photoPath: photoPath ?? this.photoPath,
      firstName: firstName ?? this.firstName,
      age: age ?? this.age,
      work: work ?? this.work,
      bio: bio ?? this.bio,
      purpose: purpose ?? this.purpose,
      interests: interests ?? this.interests,
      conversationStyle: conversationStyle ?? this.conversationStyle,
      distanceKm: distanceKm ?? this.distanceKm,
      meetingLength: meetingLength ?? this.meetingLength,
      when: when ?? this.when,
      chosenDate: chosenDate ?? this.chosenDate,
    );
  }

  /// The time the meetup is anchored to. MVP keeps this simple: "Today" and
  /// "Tomorrow" resolve to a mid-afternoon slot; a chosen date keeps its day
  /// at the same default hour.
  DateTime resolvedTime() {
    final now = DateTime.now();
    switch (when) {
      case 'Tomorrow':
        final d = now.add(const Duration(days: 1));
        return DateTime(d.year, d.month, d.day, 15);
      case 'Choose a date':
        final d = chosenDate ?? now;
        return DateTime(d.year, d.month, d.day, 15);
      case 'Today':
      default:
        return DateTime(now.year, now.month, now.day, 15);
    }
  }

  String get timeLabel {
    if (when == 'Choose a date' && chosenDate != null) {
      const months = [
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
      return '${months[chosenDate!.month - 1]} ${chosenDate!.day}';
    }
    return when;
  }

  MeetRequest toMeetRequest() {
    return MeetRequest(
      dateLabel: timeLabel,
      timeLabel: timeLabel,
      time: resolvedTime(),
      durationLabel: meetingLength,
      radiusKm: distanceKm.toDouble(),
      whyLabels: purpose == null ? const [] : [purpose!],
      conversationLabels:
          conversationStyle == null ? const [] : [conversationStyle!],
    );
  }
}
