import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/remote/feedback_remote.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('blank texts become null', () {
    final row = const FeedbackEntry(
      rating: 4,
      improve: '  ',
      likes: ' Words ',
    ).toRow(appVersion: '1.0.0', platform: 'android');

    expect(row, {
      'rating': 4,
      'improve': null,
      'likes': 'Words',
      'app_version': '1.0.0',
      'platform': 'android',
    });
  });

  test('ensures a session before inserting', () async {
    final calls = <String>[];
    Map<String, Object?>? inserted;
    final remote = SupabaseFeedbackRemote(
      SupabaseClient('http://localhost:1', 'test-key'),
      ensureSession: () async => calls.add('ensureSession'),
      insert: (row) async {
        calls.add('insert');
        inserted = row;
      },
    );

    await remote.send(const FeedbackEntry(rating: 2, improve: 'More audio'));

    expect(calls, ['ensureSession', 'insert']);
    expect(inserted?['rating'], 2);
    expect(inserted?['improve'], 'More audio');
    expect(inserted?['likes'], isNull);
    expect(inserted?['app_version'], isNotEmpty);
  });
}
