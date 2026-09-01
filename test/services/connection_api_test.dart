import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/connection_api.dart';
import 'package:poppylo/state/connection_controller.dart';

ConnectionApi _api(MockClient client) => ConnectionApi(
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

void main() {
  test('connections unwraps the list envelope', () async {
    String? auth;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      expect(req.url.path, '/api/v1/connections');
      return _json({
        'success': true,
        'data': [
          {
            'id': 'c1',
            'user': {
              'id': 'u2',
              'name': 'Ben',
              'profileImage': null,
              'averageRating': 4.8
            },
            'createdAt': '2026-09-01T10:00:00.000Z',
          },
        ],
      }, 200);
    }));
    final rows = await api.connections();
    expect(auth, 'Bearer tok');
    expect(rows.single.user.name, 'Ben');
    expect(rows.single.user.averageRating, 4.8);
  });

  test('connection detail includes public bio/job + meetingId', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/connections/c1');
      return _json({
        'success': true,
        'data': {
          'id': 'c1',
          'meetingId': 'm1',
          'createdAt': '2026-09-01T10:00:00.000Z',
          'user': {
            'id': 'u2',
            'name': 'Ben',
            'profileImage': 'ben.jpg',
            'averageRating': 4.8,
            'bio': 'Hi there',
            'job': 'Designer',
          },
        },
      }, 200);
    }));
    final c = await api.connection('c1');
    expect(c.meetingId, 'm1');
    expect(c.user.bio, 'Hi there');
    expect(c.user.job, 'Designer');
  });

  test('a 404 bubbles as ApiException(404)', () async {
    final api = _api(MockClient(
        (_) async => _json({'success': false, 'message': 'gone'}, 404)));
    await expectLater(
      api.connection('c1'),
      throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
  });

  test('connectionErrorMessage maps statuses', () {
    expect(connectionErrorMessage(ApiException(401, 'x')),
        'Your session has expired. Please log in again.');
    expect(connectionErrorMessage(ApiException(404, 'x')),
        'This connection is no longer available.');
    expect(connectionErrorMessage(ApiException(0, 'x')),
        'Unable to connect. Please try again.');
  });
}
