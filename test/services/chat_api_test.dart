import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/chat_api.dart';
import 'package:poppylo/state/chat_controller.dart';

ChatApi _api(MockClient client) => ChatApi(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: client,
      ),
    );

Map<String, dynamic> _message(String id, String sender) => {
      'id': id,
      'senderId': sender,
      'text': 'hi $id',
      'createdAt': '2026-09-05T17:0$id:00.000Z',
      'readAt': null,
    };

void main() {
  test('getChat sends Bearer + parses the participant', () async {
    String? auth;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      expect(req.url.path, '/api/v1/chats/m1');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'chat': {
              'id': 'c1',
              'matchId': 'm1',
              'participant': {
                'id': 'u2',
                'name': 'Ben',
                'profileImage': 'ben.jpg',
              },
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));

    final conv = await api.getChat('m1');
    expect(auth, 'Bearer tok');
    expect(conv.matchId, 'm1');
    expect(conv.participant.name, 'Ben');
  });

  test('getMessages unwraps the list envelope', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/chats/m1/messages');
      expect(req.url.queryParameters, {'page': '1', 'limit': '50'});
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [_message('2', 'u2'), _message('1', 'u1')],
          'pagination': {'total': 2},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    final msgs = await api.getMessages('m1');
    expect(msgs.map((m) => m.id), ['2', '1']); // as returned (newest-first)
  });

  test('sendMessage posts {text} only, no senderId', () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/chats/m1/messages');
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'success': true, 'data': _message('9', 'u1')}),
        201,
        headers: {'content-type': 'application/json'},
      );
    }));
    final m = await api.sendMessage('m1', 'yo');
    expect(body, {'text': 'yo'});
    expect(m.senderId, 'u1');
  });

  test('markRead returns the updated count', () async {
    final api = _api(MockClient((req) async {
      expect(req.url.path, '/api/v1/chats/m1/read');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'updated': 3}
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
    expect(await api.markRead('m1'), 3);
  });

  test('a 403 bubbles as ApiException(403)', () async {
    final api = _api(MockClient((_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': 'Chat is available after the match is confirmed.',
          }),
          403,
          headers: {'content-type': 'application/json'},
        )));
    await expectLater(
      api.getChat('m1'),
      throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });

  group('chatErrorMessage', () {
    test('maps the documented statuses', () {
      expect(chatErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(chatErrorMessage(ApiException(403, 'x')),
          'Chat is available after your match is confirmed.');
      expect(chatErrorMessage(ApiException(404, 'x')), 'Chat not found.');
      expect(chatErrorMessage(ApiException(0, 'x')),
          'Unable to send message. Please try again.');
      expect(chatErrorMessage(ApiException(500, 'x')),
          'Something went wrong. Please try again.');
    });
  });
}
