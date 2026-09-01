import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/discover_api.dart';
import 'package:poppylo/state/discover_controller.dart';

DiscoverApi _api(MockClient client) => DiscoverApi(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: client,
      ),
    );

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _card(String id, String name) => {
      'id': id,
      'name': name,
      'age': 29,
      'profileImage': null,
      'profession': 'Product Designer',
      'bio': 'Love coffee',
      'distance': 2.4,
      'distanceLabel': null,
      'interests': ['Technology', 'Travel', 'Design'],
      'coffeePreference': 'CASUAL',
      'purpose': 'networking',
      'availability': ['WEEKDAY_EVENING'],
      'compatibilityScore': 87,
    };

void main() {
  test('people() sends page/limit/filters + Bearer token, parses pagination',
      () async {
    String? auth;
    Uri? url;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      url = req.url;
      return _json({
        'success': true,
        'data': [_card('u2', 'Sarah')],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 40,
          'totalPages': 2,
          'hasNext': true,
        },
      }, 200);
    }));

    final page = await api.people(
      page: 1,
      limit: 20,
      filters: const DiscoverFilters(
        distanceKm: 10,
        purpose: 'networking',
        interest: 'technology',
        availability: 'THIS_WEEK',
      ),
    );

    expect(auth, 'Bearer tok');
    expect(url!.path, '/api/v1/discover');
    expect(url!.queryParameters, {
      'page': '1',
      'limit': '20',
      'distance': '10',
      'purpose': 'networking',
      'interest': 'technology',
      'availability': 'THIS_WEEK',
    });
    expect(page.users.single.name, 'Sarah');
    expect(page.users.single.compatibilityScore, 87);
    expect(page.hasNext, true);
    expect(page.totalPages, 2);
  });

  test('empty page carries the backend message', () async {
    final api = _api(MockClient((_) async => _json({
          'success': true,
          'data': [],
          'pagination': {'page': 1, 'totalPages': 1, 'hasNext': false},
          'message': 'No people found nearby right now.',
        }, 200)));
    final page = await api.people(page: 1);
    expect(page.users, isEmpty);
    expect(page.message, 'No people found nearby right now.');
  });

  test('profile() GETs /discover/:id and maps coffeePreferences', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/discover/u2');
      return _json({
        'success': true,
        'data': {
          'id': 'u2',
          'name': 'Sarah',
          'age': 29,
          'profileImage': 'p.jpg',
          'profession': 'Designer',
          'bio': 'hi',
          'distance': 2.4,
          'interests': ['Design'],
          'availability': ['WEEKDAY_EVENING'],
          'coffeePreferences': {
            'conversationStyles': ['casual', 'deep'],
            'purpose': 'networking',
          },
        },
      }, 200);
    }));
    final p = await api.profile('u2');
    expect(p.name, 'Sarah');
    expect(p.conversationStyles, ['casual', 'deep']);
    expect(p.purpose, 'networking');
    expect(p.distanceText, '2.4 km away');
  });

  test('a 401 / network error surfaces as ApiException', () async {
    final a401 = _api(MockClient(
        (_) async => _json({'success': false, 'message': 'nope'}, 401)));
    await expectLater(
      a401.people(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 401)),
    );

    final aNet =
        _api(MockClient((_) async => throw http.ClientException('down')));
    await expectLater(
      aNet.people(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 0)),
    );
  });

  group('discoverErrorMessage', () {
    test('maps the documented statuses', () {
      expect(discoverErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(discoverErrorMessage(ApiException(403, 'x')),
          "You can't view this right now.");
      expect(discoverErrorMessage(ApiException(0, 'x')),
          'Check your connection and try again.');
      expect(discoverErrorMessage(ApiException(500, 'x')),
          'Something went wrong. Please try again.');
      expect(discoverErrorMessage(Exception('x')),
          'Something went wrong. Please try again.');
    });
  });

  test('DiscoverFilters.toQuery omits nulls', () {
    expect(const DiscoverFilters().toQuery(), <String, String>{});
    expect(const DiscoverFilters(distanceKm: 5).toQuery(), {'distance': '5'});
  });
}
