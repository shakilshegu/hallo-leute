import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api calls for viewing and editing an existing profile
/// (the Profile tab and its edit screens).
class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<UserMe> getMe() async {
    final data = await _client.get('/users/me');
    return UserMe.fromJson(data);
  }

  /// `PUT /profile` — partial update; only non-null fields are sent.
  Future<void> updateProfile({
    String? firstName,
    int? age,
    String? job,
    String? bio,
  }) {
    return _client.put('/profile', body: {
      if (firstName != null) 'firstName': firstName,
      if (age != null) 'age': age,
      if (job != null) 'job': job,
      if (bio != null) 'bio': bio,
    });
  }

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

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(apiClientProvider));
});
