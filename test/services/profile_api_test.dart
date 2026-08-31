import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/profile_api.dart';

void main() {
  ProfileApi apiWith(
    List<http.Request> log,
    http.Response Function(http.Request) handler,
  ) {
    return ProfileApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => 'tok',
      httpClient: MockClient((r) async {
        log.add(r);
        return handler(r);
      }),
    ));
  }

  http.Response ok(Object data) => http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json'},
      );

  test('getMe parses the full aggregate', () async {
    final api = apiWith(
        [],
        (_) => ok({
              'id': 'u1',
              'phone': '+911',
              'onboardingCompleted': true,
              'profile': {
                'firstName': 'Sam',
                'age': 30,
                'job': 'Engineer',
                'bio': 'hi',
                'photoUrl': 'https://cdn/x.jpg',
              },
              'interests': [
                {'id': 'design', 'label': 'Design'},
                {'id': 'music', 'label': 'Music'},
              ],
              'preferences': {
                'minAge': 25,
                'maxAge': 40,
                'maxDistanceKm': 10,
                'conversationStyles': ['deep'],
              },
              'purpose': 'networking',
            }));

    final me = await api.getMe();

    expect(me.profile!.firstName, 'Sam');
    expect(me.profile!.age, 30);
    expect(me.profile!.photoUrl, 'https://cdn/x.jpg');
    expect(me.interestIds, ['design', 'music']);
    expect(me.preferences!.maxDistanceKm, 10);
    expect(me.preferences!.conversationStyles, ['deep']);
    expect(me.purpose, 'networking');
  });

  test('getMe tolerates a null profile / preferences', () async {
    final api = apiWith(
        [],
        (_) => ok({
              'id': 'u1',
              'phone': null,
              'onboardingCompleted': false,
              'profile': null,
              'interests': [],
              'preferences': null,
              'purpose': null,
            }));

    final me = await api.getMe();
    expect(me.profile, isNull);
    expect(me.preferences, isNull);
    expect(me.interests, isEmpty);
  });

  test('updateProfile sends only the provided fields via PUT', () async {
    final log = <http.Request>[];
    final api = apiWith(log, (_) => ok({'id': 'p1'}));

    await api.updateProfile(firstName: 'Sam', age: 31, bio: '');

    final req = log.single;
    expect(req.method, 'PUT');
    expect(req.url.path, '/api/v1/profile');
    expect(jsonDecode(req.body), {'firstName': 'Sam', 'age': 31, 'bio': ''});
  });

  test('setPreferences PUTs the mapped body', () async {
    final log = <http.Request>[];
    final api = apiWith(log, (_) => ok({}));

    await api.setPreferences(
      minAge: 22,
      maxAge: 44,
      maxDistanceKm: 10,
      conversationStyles: ['deep', 'career'],
    );

    expect(log.single.url.path, '/api/v1/profile/preferences');
    expect(jsonDecode(log.single.body), {
      'minAge': 22,
      'maxAge': 44,
      'maxDistanceKm': 10,
      'conversationStyles': ['deep', 'career'],
    });
  });

  test('a non-2xx bubbles up as ApiException', () async {
    final api = apiWith(
        [],
        (_) => http.Response(
              jsonEncode({'success': false, 'message': 'nope'}),
              400,
              headers: {'content-type': 'application/json'},
            ));

    expect(
      () => api.setPurpose('friends'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'nope')),
    );
  });
}
