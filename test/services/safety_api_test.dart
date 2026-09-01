import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/safety_api.dart';
import 'package:poppylo/state/safety_controller.dart';

SafetyApi _api(MockClient client) => SafetyApi(
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

Map<String, dynamic> _meetingJson({String status = 'CANCELLED'}) => {
      'id': 'mtg1',
      'matchId': 'm1',
      'status': status,
      'date': '2026-09-10',
      'startTime': '14:30',
      'durationMinutes': 45,
      'cafe': {'id': 'c1', 'name': 'Blue Bottle'},
      'partner': {'id': 'u2', 'name': 'Ben', 'profileImage': null},
      'createdAt': '2026-09-01T10:00:00.000Z',
    };

void main() {
  test('reportUser posts the reason (+ trimmed details) with a Bearer token',
      () async {
    String? auth;
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/users/u2/report');
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'success': true,
        'data': {'id': 'r1'}
      }, 201);
    }));

    await api.reportUser('u2', reason: 'harassment', details: '  bad  ');
    expect(auth, 'Bearer tok');
    expect(body, {'reason': 'harassment', 'details': 'bad'});
  });

  test('reportUser omits details when blank', () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'success': true,
        'data': {'id': 'r1'}
      }, 201);
    }));

    await api.reportUser('u2', reason: 'other', details: '   ');
    expect(body, {'reason': 'other'});
  });

  test('blockUser POSTs /users/:id/block', () async {
    var hit = false;
    final api = _api(MockClient((req) async {
      hit = true;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/users/u2/block');
      return _json({
        'success': true,
        'data': {'blocked': true}
      }, 200);
    }));
    await api.blockUser('u2');
    expect(hit, isTrue);
  });

  test('unblockUser DELETEs /users/:id/block', () async {
    var method = '';
    final api = _api(MockClient((req) async {
      method = req.method;
      expect(req.url.path, '/api/v1/users/u2/block');
      return _json({
        'success': true,
        'data': {'blocked': false}
      }, 200);
    }));
    await api.unblockUser('u2');
    expect(method, 'DELETE');
  });

  test('blockedUsers unwraps the list envelope', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/users/blocked');
      return _json({
        'success': true,
        'data': [
          {
            'id': 'u2',
            'name': 'Ben',
            'profileImage': 'ben.jpg',
            'blockedAt': '2026-09-01T10:00:00.000Z',
          },
          {'id': 'u3', 'name': 'Cara', 'profileImage': null, 'blockedAt': null},
        ],
      }, 200);
    }));
    final blocked = await api.blockedUsers();
    expect(blocked.map((b) => b.id), ['u2', 'u3']);
    expect(blocked.first.name, 'Ben');
    expect(blocked.first.blockedAt, isNotNull);
    expect(blocked.last.profileImage, isNull);
  });

  test('cancelMeeting posts {reason} and parses the cancelled meeting',
      () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/meetings/mtg1/cancel');
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({'success': true, 'data': _meetingJson()}, 200);
    }));

    final meeting =
        await api.cancelMeeting('mtg1', reason: 'schedule_conflict');
    expect(body, {'reason': 'schedule_conflict'});
    expect(meeting.matchId, 'm1');
    expect(meeting.status.name.toLowerCase(), contains('cancel'));
  });

  test('a 409 bubbles as ApiException(409) with the server message', () async {
    final api = _api(MockClient((_) async => _json({
          'success': false,
          'message': 'You have already reported this person.',
        }, 409)));
    await expectLater(
      api.reportUser('u2', reason: 'other'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)
          .having((e) => e.message, 'message',
              'You have already reported this person.')),
    );
  });

  test('a network failure surfaces as ApiException(0)', () async {
    final api =
        _api(MockClient((_) async => throw http.ClientException('down')));
    await expectLater(
      api.blockUser('u2'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 0)),
    );
  });

  group('safetyErrorMessage', () {
    test('maps the documented statuses', () {
      expect(safetyErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(safetyErrorMessage(ApiException(403, 'x')),
          "You can't do that here.");
      expect(safetyErrorMessage(ApiException(404, 'x')),
          'This is no longer available.');
      expect(safetyErrorMessage(ApiException(409, 'Already reported.')),
          'Already reported.');
      expect(safetyErrorMessage(ApiException(0, 'x')),
          'Unable to connect. Please try again.');
      expect(safetyErrorMessage(ApiException(500, 'x')),
          'Something went wrong. Please try again.');
    });

    test('falls back for a non-API error', () {
      expect(safetyErrorMessage(Exception('boom')),
          'Something went wrong. Please try again.');
    });
  });
}
