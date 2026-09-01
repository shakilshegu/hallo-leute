import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/services/discover_api.dart';

DiscoverUser sampleDiscoverUser({
  String id = 'u2',
  String name = 'Sarah',
  int score = 87,
}) =>
    DiscoverUser(
      id: id,
      name: name,
      age: 29,
      profileImage: null,
      profession: 'Product Designer',
      bio: 'Love meeting curious people over coffee.',
      distance: 2.4,
      distanceLabel: null,
      interests: const ['Technology', 'Travel', 'Design'],
      coffeePreference: 'CASUAL',
      purpose: 'networking',
      availability: const ['WEEKDAY_EVENING'],
      compatibilityScore: score,
    );

/// Scriptable test double for [DiscoverApi] (people discovery).
class FakeDiscoverApi implements DiscoverApi {
  FakeDiscoverApi({
    List<DiscoverUser>? all,
    this.pageSize = 20,
    this.peopleError,
    this.profileError,
    this.message = 'No people found nearby right now.',
  }) : all = all ?? [];

  final List<DiscoverUser> all;
  final int pageSize;
  Object? peopleError;
  Object? profileError;
  String message;

  final List<Map<String, Object?>> calls = [];

  @override
  Future<DiscoverPage> people({
    required int page,
    int limit = 20,
    DiscoverFilters filters = DiscoverFilters.none,
  }) async {
    calls.add({'page': page, 'limit': limit, 'filters': filters});
    if (peopleError != null) throw peopleError!;
    final start = (page - 1) * pageSize;
    final slice = start >= all.length
        ? <DiscoverUser>[]
        : all.sublist(start, (start + pageSize).clamp(0, all.length));
    final hasNext = start + slice.length < all.length;
    return DiscoverPage(
      users: slice,
      page: page,
      totalPages: (all.length / pageSize).ceil().clamp(1, 999),
      hasNext: hasNext,
      message: all.isEmpty ? message : null,
    );
  }

  @override
  Future<DiscoverUserProfile> profile(String userId) async {
    if (profileError != null) throw profileError!;
    return DiscoverUserProfile(
      id: userId,
      name: 'Sarah',
      age: 29,
      profileImage: null,
      profession: 'Product Designer',
      bio: 'Love coffee.',
      distance: 2.4,
      distanceLabel: null,
      interests: const ['Design'],
      availability: const ['WEEKDAY_EVENING'],
      conversationStyles: const ['casual'],
      purpose: 'networking',
    );
  }

  @override
  Future<DiscoverFeed> getFeed() async =>
      const DiscoverFeed(location: 'Kochi', meets: [], nearbyPeople: []);
}
