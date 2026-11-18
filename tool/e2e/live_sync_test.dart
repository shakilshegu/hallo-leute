// Live check of the app's sync code against the real Supabase project.
// Creates a temporary guest, syncs, reads back, then deletes the guest.
//
//   flutter test tool/e2e/live_sync_test.dart --dart-define-from-file=env.json
//
// No TestWidgetsFlutterBinding here on purpose: it would block real HTTP.
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/local_store.dart';
import 'package:poppylo/data/progress.dart';
import 'package:poppylo/data/remote/backend_config.dart';
import 'package:poppylo/data/remote/progress_remote.dart';
import 'package:poppylo/data/sync/sync_service.dart';
import 'package:poppylo/data/vocabulary.dart';
import 'package:poppylo/features/onboarding/onboarding_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bahnhof = GermanWord(
  word: 'Bahnhof',
  article: 'der',
  pos: 'noun',
  meaning: 'train station',
  topic: Topic.travel,
);
const _danke = GermanWord(
  word: 'Danke',
  article: '',
  pos: 'other',
  meaning: 'thank you',
  topic: Topic.basics,
);

void main() {
  test('app sync code works against the live project', () async {
    expect(BackendConfig.isConfigured, isTrue, reason: 'pass env.json');
    final client = SupabaseClient(
      BackendConfig.supabaseUrl,
      BackendConfig.supabasePublishableKey,
    );
    await client.auth.signInAnonymously();
    final remote = SupabaseProgressRemote(client);
    expect(remote.userId, isNotNull);

    try {
      final store = MemoryStore();
      final progress = LearningProgress(store: store);
      final sync = SyncService(
        progress: progress,
        remote: remote,
        store: store,
      );
      await sync.start();

      await progress.saveProfile(
        OnboardingData()
          ..name = 'Live Test'
          ..level = GermanLevel.a1
          ..goals.add(LearningGoal.work),
      );
      progress.recordAnswer(_bahnhof, knewIt: false);
      progress.recordAnswer(_bahnhof, knewIt: true);
      progress.recordAnswer(_danke, knewIt: true);
      await sync.flush();
      expect(sync.lastError, isNull, reason: '${sync.lastError}');
      expect(sync.hasPending, isFalse);

      final snap = await remote.fetchAll();
      expect(snap.profile?.name, 'Live Test');
      expect(snap.profile?.goals, {LearningGoal.work});
      final b = snap.words['Bahnhof|noun']!;
      expect(b.timesSeen, 2);
      expect(b.timesAgain, 1);
      expect(b.learnedOn, isNotNull);
      expect(snap.words, hasLength(2));
      expect(snap.days.values.single.newWords, 2);
      expect(snap.days.values.single.again, 1);

      final answers = await client.from('answer_events').select('id');
      expect(answers, hasLength(3));

      // Second phone: empty local copy pulls everything back.
      final store2 = MemoryStore();
      final phone2 = LearningProgress(store: store2);
      final sync2 = SyncService(
        progress: phone2,
        remote: remote,
        store: store2,
      );
      final profile = await sync2.mergeFromServer();
      expect(profile?.name, 'Live Test');
      expect(phone2.words['Bahnhof|noun']!.timesSeen, 2);
      sync.dispose();
      sync2.dispose();
    } finally {
      await client.rpc<void>('delete_my_account');
      await client.dispose();
    }
  });
}
