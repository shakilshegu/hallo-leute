import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';

void main() {
  ApiClient clientThatReturns(
    List<http.Request> log,
    http.Response Function(http.Request) handler, {
    String? token = 'test-token',
  }) {
    return ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => token,
      httpClient: MockClient((request) async {
        log.add(request);
        return handler(request);
      }),
    );
  }

  http.Response ok(Object data) => http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json'},
      );

  /// Multipart requests go through `Client.send(BaseRequest)`, which the plain
  /// [MockClient] can't represent — use the streaming variant for uploads.
  ApiClient uploadClientThatReturns(
    List<http.BaseRequest> log,
    ({int status, String body}) Function() handler, {
    String? token = 'test-token',
  }) {
    return ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => token,
      httpClient: MockClient.streaming((request, _) async {
        log.add(request);
        final r = handler();
        return http.StreamedResponse(
          Stream.value(utf8.encode(r.body)),
          r.status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  test('unwraps the success envelope and attaches the bearer token', () async {
    final log = <http.Request>[];
    final api = OnboardingApi(clientThatReturns(
      log,
      (_) => ok({
        'user': {'onboardingCompleted': true},
        'isNewUser': false,
      }),
    ));

    final result = await api.syncUser();

    expect(result.onboardingCompleted, isTrue);
    expect(result.isNewUser, isFalse);
    expect(log.single.url.toString(), 'https://api.test/api/v1/auth/sync');
    expect(log.single.headers['Authorization'], 'Bearer test-token');
  });

  test('maps a non-2xx envelope to an ApiException with the server message',
      () async {
    final log = <http.Request>[];
    final api = OnboardingApi(clientThatReturns(
      log,
      (_) => http.Response(
        jsonEncode({
          'success': false,
          'message': 'Age must be at least 18.',
          'errorCode': 'BadRequestException',
        }),
        400,
        headers: {'content-type': 'application/json'},
      ),
    ));

    expect(
      () => api.setPurpose('friends'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.message, 'message', 'Age must be at least 18.')),
    );
  });

  test('saveProfile falls back to PUT when POST /profile returns 409',
      () async {
    final log = <http.Request>[];
    final api = OnboardingApi(clientThatReturns(log, (request) {
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Profile already exists.'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      }
      return ok({'id': 'p1'});
    }));

    await api.saveProfile(firstName: 'Sam', age: 29, job: 'Designer');

    expect(log.map((r) => r.method), ['POST', 'PUT']);
    expect(log.every((r) => r.url.path.endsWith('/profile')), isTrue);
    expect(jsonDecode(log.last.body), {
      'firstName': 'Sam',
      'age': 29,
      'job': 'Designer',
    });
  });

  test('uploadPhoto posts the file as multipart and returns the hosted URL',
      () async {
    final tmp = await File(
      '${Directory.systemTemp.path}/onboarding_api_test_${DateTime.now().microsecondsSinceEpoch}.png',
    ).create();
    await tmp.writeAsBytes([1, 2, 3, 4]);
    addTearDown(() => tmp.delete());

    final log = <http.BaseRequest>[];
    final api = OnboardingApi(uploadClientThatReturns(
      log,
      () => (
        status: 200,
        body: jsonEncode({
          'success': true,
          'data': {'photoUrl': 'https://cdn.test/hosted.jpg'},
        }),
      ),
    ));

    final url = await api.uploadPhoto(tmp.path);

    expect(url, 'https://cdn.test/hosted.jpg');
    final request = log.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/profile/photo');
    expect(request.headers['content-type'], contains('multipart/form-data'));
    expect(request.headers['Authorization'], 'Bearer test-token');
  });

  test('uploadPhoto throws when the server rejects the file', () async {
    final tmp = await File(
      '${Directory.systemTemp.path}/onboarding_api_bad_${DateTime.now().microsecondsSinceEpoch}.png',
    ).create();
    await tmp.writeAsBytes([0]);
    addTearDown(() => tmp.delete());

    final api = OnboardingApi(uploadClientThatReturns(
      [],
      () => (
        status: 400,
        body: jsonEncode({
          'success': false,
          'message': 'Photo must be an image.',
        }),
      ),
    ));

    await expectLater(
      api.uploadPhoto(tmp.path),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Photo must be an image.')),
    );
  });

  test('surfaces a transport failure as a network ApiException', () async {
    final api = OnboardingApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => null,
      httpClient: MockClient((_) async => throw http.ClientException('boom')),
    ));

    await expectLater(
      api.setInterests(['travel']),
      throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'network', true)),
    );
  });
}
