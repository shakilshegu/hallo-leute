import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/config/app_config.dart';
import 'package:poppylo/services/api_client.dart';

/// Result of `POST /auth/sync` — creates or finds the backend User for the
/// already-verified Firebase account.
class SyncResult {
  const SyncResult({
    required this.isNewUser,
    required this.onboardingCompleted,
  });

  final bool isNewUser;
  final bool onboardingCompleted;
}

/// The coffee-meet-api calls the onboarding flow makes, in order:
/// `POST /auth/sync` → `POST /profile` → `PUT /profile/interests` →
/// `PUT /profile/purpose` → `PUT /profile/preferences` (the last call
/// flips `onboardingCompleted` server-side once all four pieces exist).
class OnboardingApi {
  OnboardingApi(this._client);

  final ApiClient _client;

  Future<SyncResult> syncUser() async {
    final data = await _client.post('/auth/sync');
    final user = data['user'];
    return SyncResult(
      isNewUser: data['isNewUser'] as bool? ?? false,
      onboardingCompleted: user is Map<String, dynamic>
          ? user['onboardingCompleted'] as bool? ?? false
          : false,
    );
  }

  /// Creates the profile, or updates it if one already exists (a retry, or a
  /// user resuming onboarding).
  Future<void> saveProfile({
    required String firstName,
    required int age,
    String? job,
    String? bio,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName,
      'age': age,
      if (job != null && job.isNotEmpty) 'job': job,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    };
    try {
      await _client.post('/profile', body: body);
    } on ApiException catch (e) {
      if (e.isConflict) {
        await _client.put('/profile', body: body);
      } else {
        rethrow;
      }
    }
  }

  /// Uploads the picked image to `POST /profile/photo` (multipart) and
  /// returns the hosted URL the backend stored on the profile.
  Future<String> uploadPhoto(String filePath) async {
    final data = await _client.upload(
      '/profile/photo',
      fieldName: 'file',
      filePath: filePath,
    );
    final url = data['photoUrl'];
    if (url is! String || url.isEmpty) {
      throw ApiException(0, 'The photo upload did not return a URL.');
    }
    return url;
  }

  Future<void> setInterests(List<String> interestIds) =>
      _client.put('/profile/interests', body: {'interestIds': interestIds});

  Future<void> setPurpose(String purpose) =>
      _client.put('/profile/purpose', body: {'purpose': purpose});

  Future<void> setPreferences({
    required int minAge,
    required int maxAge,
    required int maxDistanceKm,
    required List<String> conversationStyles,
  }) =>
      _client.put('/profile/preferences', body: {
        'minAge': minAge,
        'maxAge': maxAge,
        'maxDistanceKm': maxDistanceKm,
        'conversationStyles': conversationStyles,
      });
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenProvider: () async {
      final user = FirebaseAuth.instance.currentUser;
      return user == null ? null : await user.getIdToken();
    },
  );
  ref.onDispose(client.close);
  return client;
});

final onboardingApiProvider = Provider<OnboardingApi>((ref) {
  return OnboardingApi(ref.watch(apiClientProvider));
});
