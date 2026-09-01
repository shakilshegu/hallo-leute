import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/cafe_api.dart';
import 'package:poppylo/state/cafe_controller.dart';

CafeApi _api(MockClient client) => CafeApi(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: client,
      ),
    );

Map<String, dynamic> _cafe(String id) => {
      'id': id,
      'name': 'Brew Lab',
      'address': 'Kochi',
      'latitude': 9.9,
      'longitude': 76.2,
      'imageUrl': null,
      'rating': 4.6,
      'priceLevel': 2,
      'description': 'Nice',
      'distance': 1.2,
    };

Map<String, dynamic> _suggestion(
        {String status = 'PENDING', String? meetingId}) =>
    {
      'id': 's1',
      'status': status,
      'date': '2026-09-05',
      'startTime': '17:00',
      'suggestedBy': {'id': 'u1', 'name': 'Ada', 'isMe': true},
      'cafe': _cafe('shop-1'),
      'meetingId': meetingId,
    };

Map<String, dynamic> _meeting() => {
      'id': 'mt1',
      'matchId': 'm1',
      'status': 'CONFIRMED',
      'date': '2026-09-05',
      'startTime': '17:00',
      'durationMinutes': 45,
      'cafe': _cafe('shop-1'),
      'partner': {'id': 'u2', 'name': 'Ben', 'profileImage': null},
      'createdAt': '2026-09-01T10:00:00.000Z',
    };

void main() {
  test('nearbyCafes unwraps the list envelope + Bearer header', () async {
    String? auth;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      expect(req.url.path, '/api/v1/coffee-shops/nearby');
      expect(req.url.queryParameters['latitude'], '9.96');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [_cafe('a'), _cafe('b')],
          'pagination': {'total': 2},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final cafes = await api.nearbyCafes(latitude: 9.96, longitude: 76.29);
    expect(auth, 'Bearer tok');
    expect(cafes, hasLength(2));
    expect(cafes.first.rating, 4.6);
    expect(cafes.first.priceLabel, '₹₹');
    expect(cafes.first.distanceKm, 1.2);
  });

  test('cafe(id) fetches details', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/coffee-shops/shop-1');
      return http.Response(
        jsonEncode({'success': true, 'data': _cafe('shop-1')}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    expect((await api.cafe('shop-1')).name, 'Brew Lab');
  });

  test('suggestCafe posts the right body', () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/matches/m1/cafe-suggestion');
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'success': true, 'data': _suggestion()}),
        201,
        headers: {'content-type': 'application/json'},
      );
    }));

    final s = await api.suggestCafe(
      'm1',
      coffeeShopId: 'shop-1',
      date: '2026-09-05',
      startTime: '17:00',
    );
    expect(body, {
      'coffeeShopId': 'shop-1',
      'date': '2026-09-05',
      'startTime': '17:00',
    });
    expect(s.status, CafeSuggestionStatus.pending);
    expect(s.suggestedBy.isMe, isTrue);
  });

  test('cafeSuggestion returns null when data is null', () async {
    final api = _api(MockClient((_) async => http.Response(
          jsonEncode({'success': true, 'data': null}),
          200,
          headers: {'content-type': 'application/json'},
        )));
    expect(await api.cafeSuggestion('m1'), isNull);
  });

  test('acceptCafeSuggestion parses suggestion + meeting', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/matches/m1/cafe-suggestion/accept');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'suggestion': _suggestion(status: 'ACCEPTED', meetingId: 'mt1'),
            'meeting': _meeting(),
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final result = await api.acceptCafeSuggestion('m1');
    expect(result.suggestion.isAccepted, isTrue);
    expect(result.meeting.id, 'mt1');
    expect(result.meeting.partner.name, 'Ben');
    expect(result.meeting.durationMinutes, 45);
  });

  test('upcomingMeetings unwraps the list', () async {
    final api = _api(MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [_meeting()],
          }),
          200,
          headers: {'content-type': 'application/json'},
        )));
    expect(await api.upcomingMeetings(), hasLength(1));
  });

  group('cafeErrorMessage', () {
    test('maps the documented statuses', () {
      expect(cafeErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(cafeErrorMessage(ApiException(404, 'x')),
          'This is no longer available.');
      expect(
          cafeErrorMessage(
              ApiException(409, 'A café has already been agreed.')),
          'A café has already been agreed.');
      expect(cafeErrorMessage(ApiException(0, 'x')),
          'Unable to connect. Please try again.');
    });
  });

  group('Google Places cafés (/cafes/*)', () {
    test('nearbyGoogleCafes sends lat/lng/radius + Bearer, parses cards',
        () async {
      String? auth;
      Uri? url;
      final api = _api(MockClient((req) async {
        auth = req.headers['Authorization'];
        url = req.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'placeId': 'ChIJ1',
                'name': 'Bonanza Coffee',
                'address': 'Berlin',
                'latitude': 52.54,
                'longitude': 13.40,
                'rating': 4.6,
                'reviewCount': 245,
                'isOpen': true,
                'distanceMeters': 850,
                'photoUrl':
                    '/api/v1/cafes/photo?ref=places%2FChIJ1%2Fphotos%2Fx',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }));

      final cafes = await api.nearbyGoogleCafes(
        latitude: 52.52,
        longitude: 13.405,
        radiusMeters: 5000,
      );
      expect(auth, 'Bearer tok');
      expect(url!.path, '/api/v1/cafes/nearby');
      expect(url!.queryParameters,
          {'latitude': '52.52', 'longitude': '13.405', 'radius': '5000'});
      expect(cafes.single.placeId, 'ChIJ1');
      expect(cafes.single.reviewCount, 245);
      expect(cafes.single.distanceText, '850 m away');
      expect(cafes.single.openLabel, 'Open now');
    });

    test('cafePlaceDetails parses opening hours + photos', () async {
      final api = _api(MockClient((req) async {
        expect(req.url.path, '/api/v1/cafes/ChIJ1');
        expect(req.url.queryParameters,
            {'latitude': '52.52', 'longitude': '13.405'});
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'placeId': 'ChIJ1',
              'name': 'Bonanza Coffee',
              'address': 'Berlin',
              'latitude': 52.54,
              'longitude': 13.40,
              'rating': 4.6,
              'reviewCount': 245,
              'isOpen': true,
              'distanceMeters': 850,
              'openingHours': ['Monday: 8:00 AM – 6:00 PM'],
              'photos': [
                '/api/v1/cafes/photo?ref=a',
                '/api/v1/cafes/photo?ref=b'
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }));
      final d = await api.cafePlaceDetails('ChIJ1',
          latitude: 52.52, longitude: 13.405);
      expect(d.name, 'Bonanza Coffee');
      expect(d.openingHours, ['Monday: 8:00 AM – 6:00 PM']);
      expect(d.photos, hasLength(2));
    });

    test('suggestCafe sends placeId (not coffeeShopId)', () async {
      Map<String, dynamic>? body;
      final api = _api(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'success': true, 'data': _suggestion()}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }));
      await api.suggestCafe('m1',
          placeId: 'ChIJ1', date: '2026-09-05', startTime: '17:00');
      expect(body, {
        'placeId': 'ChIJ1',
        'date': '2026-09-05',
        'startTime': '17:00',
      });
    });

    test('a 503 from the backend surfaces the message', () {
      expect(
        cafeErrorMessage(ApiException(
            503, 'Café search is temporarily unavailable. Please try again.')),
        'Café search is temporarily unavailable. Please try again.',
      );
    });
  });
}
