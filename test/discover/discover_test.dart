import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/state/discover_controller.dart';

DiscoverFeed _feed(List<CoffeeMeet> meets) => DiscoverFeed(
      location: 'Kochi, India',
      meets: meets,
      nearbyPeople: const [],
    );

CoffeeMeet _meet({
  required String id,
  required double distanceKm,
  required int addDays,
  bool availableNow = false,
  List<String> interests = const [],
}) {
  final d = DateTime.now().add(Duration(days: addDays));
  return CoffeeMeet(
    id: id,
    hostName: 'H',
    hostAge: 30,
    hostAvatarUrl: 'x',
    bio: 'b',
    sharedInterests: interests,
    distanceKm: distanceKm,
    cafeName: 'c',
    startsAt: DateTime(d.year, d.month, d.day, 15),
    participantCount: 1,
    maxParticipants: 3,
    availableNow: availableNow,
  );
}

void main() {
  test('DiscoverFilter labels are human readable', () {
    expect(DiscoverFilter.thisWeek.label, 'This Week');
    expect(DiscoverFilter.availableNow.label, 'Available Now');
  });

  test('filteredDiscoverProvider applies Nearby + Available Now', () {
    final feed = _feed([
      _meet(id: 'near-now', distanceKm: 1.0, addDays: 0, availableNow: true),
      _meet(id: 'near-later', distanceKm: 2.0, addDays: 0, availableNow: false),
      _meet(id: 'far-now', distanceKm: 8.0, addDays: 0, availableNow: true),
    ]);

    final container = ProviderContainer(overrides: [
      discoverFeedProvider.overrideWith((ref) async => feed),
    ]);
    addTearDown(container.dispose);

    // seed the future
    container.read(discoverFeedProvider);
    return Future(() async {
      await container.read(discoverFeedProvider.future);

      // no filters → all 3
      expect(container.read(filteredDiscoverProvider).value!.meets.length, 3);

      container.read(discoverFiltersProvider.notifier).state = {
        DiscoverFilter.nearby,
        DiscoverFilter.availableNow,
      };
      final ids = container
          .read(filteredDiscoverProvider)
          .value!
          .meets
          .map((m) => m.id)
          .toList();
      expect(ids, ['near-now']);
    });
  });

  test('isToday / isThisWeek helpers', () {
    expect(_meet(id: 'a', distanceKm: 1, addDays: 0).isToday, isTrue);
    expect(_meet(id: 'b', distanceKm: 1, addDays: 2).isToday, isFalse);
    expect(_meet(id: 'c', distanceKm: 1, addDays: 3).isThisWeek, isTrue);
    expect(_meet(id: 'd', distanceKm: 1, addDays: 20).isThisWeek, isFalse);
  });
}
