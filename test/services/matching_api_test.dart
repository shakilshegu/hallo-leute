import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/matching_api.dart';
import 'package:poppylo/state/matching_controller.dart';

MatchingApi _api(MockClient client) => MatchingApi(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: client,
      ),
    );

Map<String, dynamic> _matchJson({String status = 'PENDING'}) => {
      'id': 'm1',
      'score': 87,
      'status': status,
      'myResponse': 'PENDING',
      'otherResponse': 'PENDING',
      'whyMatched': ['You both like Technology', 'You are 2.4 km apart'],
      'date': '2026-09-05',
      'startTime': '17:00',
      'durationMinutes': 45,
      'user': {
        'id': 'u2',
        'name': 'Sam',
        'age': 28,
        'profileImage': 'https://cdn/x.jpg',
        'job': 'Designer',
        'bio': 'hi',
        'interests': ['Technology', 'Coffee'],
      },
    };

void main() {
  test('startMatching sends a Bearer POST and parses MATCH_FOUND', () async {
    String? method;
    String? auth;
    final api = _api(MockClient((req) async {
      method = req.method;
      auth = req.headers['Authorization'];
      expect(req.url.path, '/api/v1/matching/requests/r1/start');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'status': 'MATCH_FOUND', 'match': _matchJson()},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final result = await api.startMatching('r1');
    expect(method, 'POST');
    expect(auth, 'Bearer tok');
    expect(result.isMatchFound, isTrue);
    expect(result.match!.score, 87);
    expect(result.match!.user.name, 'Sam');
    expect(result.match!.whyMatched, hasLength(2));
    expect(result.match!.startTime, '17:00');
  });

  test('pollStatus parses SEARCHING', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/matching/requests/r1/status');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'status': 'SEARCHING',
            'requestId': 'r1',
            'message': 'Looking…',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final result = await api.pollStatus('r1');
    expect(result.outcome, MatchOutcome.searching);
    expect(result.message, 'Looking…');
  });

  test('accept parses the updated match', () async {
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/matches/m1/accept');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': _matchJson(status: 'CONFIRMED'),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final match = await api.accept('m1');
    expect(match.status, MatchLifecycle.confirmed);
    expect(match.isConfirmed, isTrue);
  });

  test('getMatch hits GET /matches/:id', () async {
    final api = _api(MockClient((req) async {
      expect(req.method, 'GET');
      expect(req.url.path, '/api/v1/matches/m1');
      return http.Response(
        jsonEncode({'success': true, 'data': _matchJson()}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    expect((await api.getMatch('m1')).id, 'm1');
  });

  group('matchingErrorMessage', () {
    test('maps the documented statuses', () {
      expect(matchingErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(matchingErrorMessage(ApiException(404, 'x')),
          'Match no longer exists.');
      expect(matchingErrorMessage(ApiException(409, 'x')),
          'Your match has already been updated.');
      expect(matchingErrorMessage(ApiException(0, 'x')),
          'Unable to connect. Please try again.');
    });
    test('falls back to the backend message for 400', () {
      expect(matchingErrorMessage(ApiException(400, 'bad slot')), 'bad slot');
    });
  });
}
