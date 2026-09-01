import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/profile_api.dart';

class FakeProfileApi implements ProfileApi {
  FakeProfileApi(this.me, {this.failWith});

  UserMe me;
  ApiException? failWith;

  final List<String> calls = [];
  Map<String, Object?>? updatedProfile;
  List<String>? interestIds;
  String? purpose;
  Map<String, Object?>? preferences;
  String? uploadedPhotoPath;

  @override
  Future<UserMe> getMe() async {
    calls.add('getMe');
    if (failWith != null) throw failWith!;
    return me;
  }

  @override
  Future<void> updateProfile({
    String? firstName,
    int? age,
    String? job,
    String? bio,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    calls.add('updateProfile');
    if (failWith != null) throw failWith!;
    updatedProfile = {
      'firstName': firstName,
      'age': age,
      'job': job,
      'bio': bio,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationName != null) 'locationName': locationName,
    };
  }

  @override
  Future<String> uploadPhoto(String filePath) async {
    calls.add('uploadPhoto');
    if (failWith != null) throw failWith!;
    uploadedPhotoPath = filePath;
    return 'https://cdn.test/new.jpg';
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

UserMe sampleUserMe({
  String firstName = 'Aisha',
  int age = 27,
  String? job = 'Product Designer',
  String? bio = 'Coffee and design.',
  String? photoUrl,
  List<Interest> interests = const [
    Interest(id: 'design', label: 'Design'),
    Interest(id: 'startups', label: 'Startups'),
  ],
  String? purpose = 'networking',
  double? latitude,
  double? longitude,
  String? locationName,
  MePreferences? preferences = const MePreferences(
    minAge: 24,
    maxAge: 36,
    maxDistanceKm: 5,
    conversationStyles: ['deep', 'anything'],
  ),
}) {
  return UserMe(
    id: 'u1',
    phone: '+910000000000',
    onboardingCompleted: true,
    profile: MeProfile(
      firstName: firstName,
      age: age,
      job: job,
      bio: bio,
      photoUrl: photoUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    ),
    interests: interests,
    preferences: preferences,
    purpose: purpose,
  );
}
