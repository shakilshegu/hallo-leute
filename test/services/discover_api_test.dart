import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/discover_api.dart';

void main() {
  DiscoverApi apiReturning(Object data) {
    return DiscoverApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => 'tok',
      httpClient: MockClient((req) async {
        expect(req.url.path, '/api/v1/home');
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ));
  }

  test('maps GET /home into a DiscoverFeed', () async {
    final api = apiReturning({
      'user': {
        'id': 'u1',
        'name': 'Shakil',
        'profileImage': 'https://cdn/x.jpg',
        'location': 'Kochi, India',
      },
      'recommendedMeets': [
        {
          'id': 'm1',
          'host': {
            'id': 'h1',
            'name': 'Ana',
            'age': 27,
            'profileImage': 'a.jpg'
          },
          'coffeeShop': {
            'id': 's1',
            'name': 'Brew Lab',
            'address': 'Kochi',
            'latitude': 9.9,
            'longitude': 76.2,
          },
          'date': '2999-09-02',
          'startTime': '17:00',
          'duration': 60,
          'description': 'Design chat',
          'interests': ['Design', 'Startups'],
          'distance': 2.4,
          'spotsAvailable': 1,
          'maxParticipants': 3,
        },
      ],
      'nearbyPeople': [
        {
          'id': 'p1',
          'name': 'Sara',
          'age': 26,
          'profileImage': null,
          'bio': 'hi',
          'interests': ['Travel'],
          'locationName': 'Kochi',
          'distance': 0.8,
        },
      ],
      'upcomingMeet': null,
      'unreadNotifications': 0,
      'unreadMessages': 0,
    });

    final feed = await api.getFeed();

    expect(feed.location, 'Kochi, India');
    expect(feed.meets, hasLength(1));
    final m = feed.meets.first;
    expect(m.hostName, 'Ana');
    expect(m.hostAge, 27);
    expect(m.bio, 'Design chat');
    expect(m.cafeName, 'Brew Lab');
    expect(m.sharedInterests, ['Design', 'Startups']);
    expect(m.distanceKm, 2.4);
    expect(m.maxParticipants, 3);
    expect(m.participantCount, 2); // 3 - 1 spot
    expect(m.availableNow, isTrue);
    expect(m.startsAt.year, 2999);

    expect(feed.nearbyPeople.single.name, 'Sara');
    expect(feed.nearbyPeople.single.interestTags, ['Travel']);
    expect(feed.nearbyPeople.single.distanceKm, 0.8);
  });

  test('tolerates an empty / partial payload', () async {
    final feed = await apiReturning({'user': {}}).getFeed();
    expect(feed.meets, isEmpty);
    expect(feed.nearbyPeople, isEmpty);
    expect(feed.location, 'Your area');
  });

  test('a failure bubbles up as ApiException', () async {
    final api = DiscoverApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => 'tok',
      httpClient: MockClient((_) async => http.Response(
            jsonEncode({'success': false, 'message': 'nope'}),
            500,
            headers: {'content-type': 'application/json'},
          )),
    ));
    expect(() => api.getFeed(), throwsA(isA<ApiException>()));
  });
}
