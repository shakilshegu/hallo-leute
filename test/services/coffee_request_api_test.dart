import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';
import 'package:poppylo/state/coffee_request_controller.dart';

Map<String, dynamic> _request({String status = 'PENDING'}) => {
      'id': 'req-1',
      'status': status,
      'date': '2026-09-01',
      'startTime': '15:00',
      'durationMinutes': 45,
      'maxDistanceKm': 10,
      'purpose': 'friends',
      'conversationStyle': 'deep',
      'expiresAt': '2026-09-01T15:00:00.000Z',
    };

CoffeeRequestApi _api(MockClient client) => CoffeeRequestApi(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: client,
      ),
    );

void main() {
  test('create() sends the mapped payload and no userId', () async {
    Map<String, dynamic>? sentBody;
    String? authHeader;

    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/coffee-requests');
      authHeader = req.headers['Authorization'];
      sentBody = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'success': true, 'data': _request()}),
        201,
        headers: {'content-type': 'application/json'},
      );
    }));

    final result = await api.create(
      date: '2026-09-01',
      startTime: '15:00',
      durationMinutes: 45,
      maxDistanceKm: 10,
      purpose: 'friends',
      conversationStyle: 'deep',
    );

    expect(authHeader, 'Bearer tok');
    expect(sentBody, {
      'date': '2026-09-01',
      'startTime': '15:00',
      'durationMinutes': 45,
      'maxDistanceKm': 10,
      'purpose': 'friends',
      'conversationStyle': 'deep',
    });
    expect(sentBody!.containsKey('userId'), isFalse);
    expect(result.id, 'req-1');
    expect(result.isPending, isTrue);
  });

  test('getActive() returns null when there is no active request', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/coffee-requests/active');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'request': null},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    expect(await api.getActive(), isNull);
  });

  test('getActive() parses a present request', () async {
    final api = _api(MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {'request': _request()},
          }),
          200,
          headers: {'content-type': 'application/json'},
        )));

    final req = await api.getActive();
    expect(req, isNotNull);
    expect(req!.id, 'req-1');
    expect(req.maxDistanceKm, 10);
  });

  test('cancel() posts to the cancel endpoint', () async {
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/coffee-requests/req-1/cancel');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': _request(status: 'CANCELLED'),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final req = await api.cancel('req-1');
    expect(req.status, CoffeeRequestStatus.cancelled);
  });

  test('a 409 bubbles up as a conflict ApiException', () async {
    final api = _api(MockClient((_) async => http.Response(
          jsonEncode({'success': false, 'message': 'already searching'}),
          409,
          headers: {'content-type': 'application/json'},
        )));

    await expectLater(
      api.create(
        date: '2026-09-01',
        startTime: '15:00',
        durationMinutes: 45,
        maxDistanceKm: 10,
        purpose: 'friends',
        conversationStyle: 'deep',
      ),
      throwsA(
          isA<ApiException>().having((e) => e.isConflict, 'isConflict', true)),
    );
  });

  group('coffeeRequestErrorMessage', () {
    test('401 → session expired', () {
      expect(coffeeRequestErrorMessage(401, 'x'),
          'Your session has expired. Please log in again.');
    });
    test('400 → backend message', () {
      expect(coffeeRequestErrorMessage(400, 'startTime must be HH:mm'),
          'startTime must be HH:mm');
    });
    test('409 → already searching', () {
      expect(coffeeRequestErrorMessage(409, 'x'),
          "You're already searching for a coffee match.");
    });
    test('500 / network → generic', () {
      expect(coffeeRequestErrorMessage(500, 'x'),
          'Something went wrong. Please try again.');
      expect(coffeeRequestErrorMessage(0, 'x'),
          'Something went wrong. Please try again.');
    });
  });
}
