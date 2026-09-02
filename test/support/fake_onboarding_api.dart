import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';

/// Records every onboarding API call so widget tests can assert the flow
/// hit the backend with the right, mapped payloads — without a real server.
class FakeOnboardingApi implements OnboardingApi {
  FakeOnboardingApi({
    this.onboardingCompleted = false,
    this.failWith,
    this.failWithRaw,
  });

  bool onboardingCompleted;

  /// When set, every method throws it (simulates an offline / server error).
  ApiException? failWith;

  /// When set, `syncUser` throws this non-[ApiException] error (simulates
  /// e.g. Firebase failing to refresh the ID token on a cold start).
  Object? failWithRaw;

  final List<String> calls = [];
  Map<String, Object?>? profile;
  String? uploadedPhotoPath;
  String uploadedPhotoUrl = 'https://cdn.test/uploaded.jpg';
  List<String>? interestIds;
  String? purpose;
  Map<String, Object?>? preferences;

  @override
  Future<SyncResult> syncUser() async {
    calls.add('syncUser');
    if (failWithRaw != null) throw failWithRaw!;
    if (failWith != null) throw failWith!;
    return SyncResult(
      isNewUser: !onboardingCompleted,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<void> saveProfile({
    required String firstName,
    required int age,
    String? job,
    String? bio,
    String? photoUrl,
  }) async {
    calls.add('saveProfile');
    if (failWith != null) throw failWith!;
    profile = {
      'firstName': firstName,
      'age': age,
      'job': job,
      'bio': bio,
      'photoUrl': photoUrl,
    };
  }

  @override
  Future<String> uploadPhoto(String filePath) async {
    calls.add('uploadPhoto');
    if (failWith != null) throw failWith!;
    uploadedPhotoPath = filePath;
    return uploadedPhotoUrl;
  }

  @override
  Future<void> setInterests(List<String> interestIds) async {
    calls.add('setInterests');
    if (failWith != null) throw failWith!;
    this.interestIds = interestIds;
  }

  @override
  Future<void> setPurpose(String purpose) async {
    calls.add('setPurpose');
    if (failWith != null) throw failWith!;
    this.purpose = purpose;
  }

  @override
  Future<void> setPreferences({
    required int minAge,
    required int maxAge,
    required int maxDistanceKm,
    required List<String> conversationStyles,
  }) async {
    calls.add('setPreferences');
    if (failWith != null) throw failWith!;
    preferences = {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistanceKm': maxDistanceKm,
      'conversationStyles': conversationStyles,
    };
  }
}
