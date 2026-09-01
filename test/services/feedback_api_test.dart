import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/feedback_api.dart';
import 'package:poppylo/state/feedback_controller.dart';

FeedbackApi _api(MockClient client) => FeedbackApi(
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
  test('status GETs /feedback/status with a Bearer token', () async {
    String? auth;
    final api = _api(MockClient((req) async {
      auth = req.headers['Authorization'];
      expect(req.method, 'GET');
      expect(req.url.path, '/api/v1/meetings/m1/feedback/status');
      return _json({
        'success': true,
        'data': {
          'canSubmit': false,
          'submitted': false,
          'reason': 'MEETING_NOT_COMPLETED'
        },
      }, 200);
    }));
    final status = await api.status('m1');
    expect(auth, 'Bearer tok');
    expect(status.canSubmit, false);
    expect(status.reason, 'MEETING_NOT_COMPLETED');
  });

  test('submit posts the mapped payload, no user ids', () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/meetings/m1/feedback');
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'success': true,
        'data': {
          'feedbackSubmitted': true,
          'mutualConnection': {'created': false},
        },
      }, 201);
    }));

    final res = await api.submit(
      'm1',
      rating: 5,
      conversationFeeling: 'GREAT',
      wouldMeetAgain: true,
      tags: ['friendly', 'great_conversation'],
      comment: '  loved it  ',
    );
    expect(body, {
      'rating': 5,
      'conversationFeeling': 'GREAT',
      'wouldMeetAgain': true,
      'tags': ['friendly', 'great_conversation'],
      'comment': 'loved it',
    });
    expect(body!.containsKey('fromUserId'), isFalse);
    expect(res.mutualConnectionCreated, false);
  });

  test('submit omits empty tags / comment', () async {
    Map<String, dynamic>? body;
    final api = _api(MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({
        'success': true,
        'data': {
          'feedbackSubmitted': true,
          'mutualConnection': {'created': false}
        },
      }, 201);
    }));
    await api.submit('m1',
        rating: 3, conversationFeeling: 'OKAY', wouldMeetAgain: false);
    expect(body,
        {'rating': 3, 'conversationFeeling': 'OKAY', 'wouldMeetAgain': false});
  });

  test('submit parses a created mutual connection', () async {
    final api = _api(MockClient((_) async => _json({
          'success': true,
          'data': {
            'feedbackSubmitted': true,
            'mutualConnection': {'created': true, 'id': 'conn-9'},
          },
        }, 201)));
    final res = await api.submit('m1',
        rating: 5, conversationFeeling: 'GREAT', wouldMeetAgain: true);
    expect(res.mutualConnectionCreated, true);
    expect(res.connectionId, 'conn-9');
  });

  test('a 409 bubbles as ApiException(409)', () async {
    final api = _api(MockClient((_) async => _json(
          {
            'success': false,
            'message': "You've already left feedback for this meeting."
          },
          409,
        )));
    await expectLater(
      api.submit('m1',
          rating: 5, conversationFeeling: 'GREAT', wouldMeetAgain: true),
      throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  group('feedbackErrorMessage', () {
    test('maps the required statuses', () {
      expect(feedbackErrorMessage(ApiException(401, 'x')),
          'Your session has expired. Please log in again.');
      expect(feedbackErrorMessage(ApiException(403, 'x')),
          'You cannot submit feedback for this meeting.');
      expect(feedbackErrorMessage(ApiException(409, 'x')),
          'Feedback has already been submitted.');
      expect(feedbackErrorMessage(ApiException(0, 'x')),
          'Unable to submit feedback. Please try again.');
      expect(feedbackErrorMessage(ApiException(500, 'x')),
          'Something went wrong. Please try again.');
      expect(feedbackErrorMessage(Exception('x')),
          'Something went wrong. Please try again.');
    });
  });
}
