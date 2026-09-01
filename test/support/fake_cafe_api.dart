import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/services/location_service.dart';

CoffeeShop sampleCafe({
  String id = 'shop-1',
  String name = 'Brew Lab',
  double? rating = 4.6,
  int? priceLevel = 2,
  double? distanceKm = 1.2,
}) {
  return CoffeeShop(
    id: id,
    name: name,
    address: 'Panampilly, Kochi',
    latitude: 9.9631,
    longitude: 76.2934,
    imageUrl: null,
    rating: rating,
    priceLevel: priceLevel,
    description: 'Bright specialty roaster.',
    distanceKm: distanceKm,
  );
}

CafeSuggestion sampleSuggestion({
  CafeSuggestionStatus status = CafeSuggestionStatus.pending,
  bool isMe = true,
  String suggestedByName = 'Ada',
  String? meetingId,
}) {
  return CafeSuggestion(
    id: 's1',
    status: status,
    date: '2026-09-05',
    startTime: '17:00',
    suggestedBy: CafeSuggestedBy(id: 'u1', name: suggestedByName, isMe: isMe),
    cafe: sampleCafe(),
    meetingId: meetingId,
  );
}

NearbyCafe sampleNearbyCafe({
  String placeId = 'ChIJ-1',
  String name = 'Bonanza Coffee',
  double? rating = 4.6,
  int? reviewCount = 245,
  bool? isOpen = true,
  int? distanceMeters = 900,
}) {
  return NearbyCafe(
    placeId: placeId,
    name: name,
    address: 'Oderberger Str. 35, Berlin',
    latitude: 52.5405,
    longitude: 13.4055,
    rating: rating,
    reviewCount: reviewCount,
    isOpen: isOpen,
    distanceMeters: distanceMeters,
    photoUrl: null,
  );
}

MeetingDetails sampleMeeting({String id = 'mt1'}) {
  return MeetingDetails(
    id: id,
    matchId: 'm1',
    status: MeetingLifecycle.confirmed,
    date: '2026-09-05',
    startTime: '17:00',
    durationMinutes: 45,
    cafe: sampleCafe(),
    partner: const MeetingPartner(id: 'u2', name: 'Ben', profileImage: null),
    createdAt: DateTime.utc(2026, 9, 1),
  );
}

class FakeCafeApi implements CafeApi {
  FakeCafeApi({
    this.cafes = const [],
    List<NearbyCafe>? nearbyCafesResult,
    this.cafeDetails,
    this.nearbyError,
    this.suggestion,
    this.meetingDetail,
  }) : nearbyCafesResult = nearbyCafesResult ?? const [];

  List<CoffeeShop> cafes;
  List<NearbyCafe> nearbyCafesResult;
  CafePlaceDetails? cafeDetails;
  Object? nearbyError;
  CafeSuggestion? suggestion;
  MeetingDetails? meetingDetail;
  Object? error;

  Map<String, Object?>? lastSuggestPayload;
  int suggestCalls = 0;
  int acceptCalls = 0;
  final List<int> nearbyRadii = [];

  @override
  Future<List<CoffeeShop>> nearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
    int limit = 20,
  }) async {
    if (error != null) throw error!;
    return cafes;
  }

  @override
  Future<List<NearbyCafe>> nearbyGoogleCafes({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    nearbyRadii.add(radiusMeters);
    if (nearbyError != null) throw nearbyError!;
    return nearbyCafesResult;
  }

  @override
  Future<CafePlaceDetails> cafePlaceDetails(
    String placeId, {
    double? latitude,
    double? longitude,
  }) async {
    if (nearbyError != null) throw nearbyError!;
    if (cafeDetails != null) return cafeDetails!;
    final fromList = nearbyCafesResult
        .where((c) => c.placeId == placeId)
        .cast<NearbyCafe?>()
        .firstWhere((_) => true, orElse: () => null);
    return CafePlaceDetails(
      summary: fromList ?? sampleNearbyCafe(placeId: placeId),
      openingHours: const ['Monday: 8:00 AM – 6:00 PM'],
      photos: const [],
    );
  }

  @override
  String cafePhotoUrl(String proxyPath) => 'https://api.test$proxyPath';

  @override
  Future<Map<String, String>> imageAuthHeaders() async =>
      const {'Authorization': 'Bearer tok'};

  @override
  Future<CoffeeShop> cafe(String id) async {
    if (error != null) throw error!;
    return cafes.firstWhere((c) => c.id == id,
        orElse: () => sampleCafe(id: id));
  }

  @override
  Future<CafeSuggestion> suggestCafe(
    String matchId, {
    String? placeId,
    String? coffeeShopId,
    required String date,
    required String startTime,
  }) async {
    suggestCalls++;
    lastSuggestPayload = {
      if (placeId != null) 'placeId': placeId,
      if (coffeeShopId != null) 'coffeeShopId': coffeeShopId,
      'date': date,
      'startTime': startTime,
    };
    if (error != null) throw error!;
    suggestion = sampleSuggestion();
    return suggestion!;
  }

  @override
  Future<CafeSuggestion?> cafeSuggestion(String matchId) async {
    if (error != null) throw error!;
    return suggestion;
  }

  @override
  Future<AcceptCafeResult> acceptCafeSuggestion(String matchId) async {
    acceptCalls++;
    if (error != null) throw error!;
    final meeting = meetingDetail ?? sampleMeeting();
    suggestion = sampleSuggestion(
      status: CafeSuggestionStatus.accepted,
      meetingId: meeting.id,
    );
    return AcceptCafeResult(suggestion: suggestion!, meeting: meeting);
  }

  @override
  Future<MeetingDetails> meeting(String id) async {
    if (error != null) throw error!;
    return meetingDetail ?? sampleMeeting(id: id);
  }

  @override
  Future<List<MeetingDetails>> upcomingMeetings() async {
    if (error != null) throw error!;
    return meetingDetail == null ? const [] : [meetingDetail!];
  }
}

class FakeLocationService implements LocationService {
  @override
  Future<ResolvedPlace> currentPlace() async => const ResolvedPlace(
        latitude: 9.9631,
        longitude: 76.2934,
        name: 'Kochi',
      );

  @override
  Future<ResolvedPlace> placeFromQuery(String query) async =>
      ResolvedPlace(latitude: 52.52, longitude: 13.405, name: query);
}
