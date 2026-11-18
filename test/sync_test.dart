import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/data/local_store.dart';
import 'package:poppylo/data/progress.dart';
import 'package:poppylo/data/remote/progress_remote.dart';
import 'package:poppylo/data/sync/sync_service.dart';
import 'package:poppylo/data/vocabulary.dart';
import 'package:poppylo/features/onboarding/onboarding_data.dart';

/// In-memory stand-in for Supabase.
class FakeRemote implements ProgressRemote {
  @override
  String? userId = 'user-1';
  bool offline = false;

  /// Makes uploads slow, to simulate changes arriving mid-upload.
  Future<void>? gate;

  OnboardingData? profile;
  final words = <String, WordProgress>{};
  final days = <DateTime, DayActivity>{};
  final answers = <String, AnswerEvent>{}; // keyed by id: retries dedupe

  void _check() {
    if (offline) throw Exception('offline');
  }

  @override
  Future<void> upsertProfile(OnboardingData p) async {
    _check();
    profile = p;
  }

  @override
  Future<void> upsertWords(Map<String, WordProgress> w) async {
    _check();
    await gate;
    // Store a copy, like a real server would.
    w.forEach((k, v) => words[k] = WordProgress.fromJson(v.toJson()));
  }

  @override
  Future<void> upsertDays(Map<DateTime, DayActivity> d) async {
    _check();
    days.addAll(d);
  }

  @override
  Future<void> insertAnswers(List<AnswerEvent> a) async {
    _check();
    for (final e in a) {
      answers.putIfAbsent(e.id, () => e);
    }
  }

  @override
  Future<RemoteSnapshot> fetchAll() async {
    _check();
    return RemoteSnapshot(words: words, days: days, profile: profile);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);

  final now = DateTime(2026, 11, 17, 10);

  Future<(LearningProgress, SyncService, FakeRemote, MemoryStore)> setup({
    MemoryStore? store,
    FakeRemote? remote,
  }) async {
    final s = store ?? MemoryStore();
    final r = remote ?? FakeRemote();
    final p = await LearningProgress.load(s, clock: () => now);
    final sync = SyncService(
      progress: p,
      remote: r,
      store: s,
      debounce: const Duration(milliseconds: 10),
    );
    await sync.start();
    addTearDown(sync.dispose);
    return (p, sync, r, s);
  }

  test('answers upload: word state, day totals and the answer log', () async {
    final (p, sync, remote, _) = await setup();
    p.recordAnswer(vocabulary[0], knewIt: true);
    p.recordAnswer(vocabulary[1], knewIt: false);
    await sync.flush();

    final key0 = LearningProgress.keyOf(vocabulary[0]);
    expect(remote.words[key0]!.learnedOn, DateTime(2026, 11, 17));
    expect(remote.days[DateTime(2026, 11, 17)]!.newWords, 1);
    expect(remote.days[DateTime(2026, 11, 17)]!.again, 1);
    expect(remote.answers, hasLength(2));
    expect(remote.answers.values.where((a) => a.knewIt), hasLength(1));
    expect(sync.hasPending, isFalse);
  });

  test('uploads happen automatically after a short pause', () async {
    final (p, _, remote, _) = await setup();
    p.recordAnswer(vocabulary[0], knewIt: true);
    expect(remote.answers, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(remote.answers, hasLength(1));
  });

  test('offline: nothing is lost, it uploads once back online', () async {
    final remote = FakeRemote()..offline = true;
    final (p, sync, _, _) = await setup(remote: remote);
    p.recordAnswer(vocabulary[0], knewIt: true);
    await sync.flush();
    expect(sync.hasPending, isTrue);
    expect(sync.lastError, isNotNull);

    remote.offline = false;
    await sync.flush();
    expect(sync.hasPending, isFalse);
    expect(remote.answers, hasLength(1));
  });

  test('the upload queue survives an app restart', () async {
    final store = MemoryStore();
    final remote = FakeRemote()..offline = true;
    final (p, sync, _, _) = await setup(store: store, remote: remote);
    p.recordAnswer(vocabulary[0], knewIt: true);
    await sync.flush();
    sync.dispose();

    // "Restart": new progress + sync from the same storage, now online.
    remote.offline = false;
    final (_, sync2, _, _) = await setup(store: store, remote: remote);
    await sync2.flush();
    expect(remote.answers, hasLength(1));
    expect(remote.words, hasLength(1));
  });

  test('no session yet: asks for a guest session before uploading', () async {
    final store = MemoryStore();
    final remote = FakeRemote()..userId = null;
    final p = await LearningProgress.load(store, clock: () => now);
    var asked = 0;
    final sync = SyncService(
      progress: p,
      remote: remote,
      store: store,
      ensureSession: () async {
        asked++;
        remote.userId = 'guest-1';
      },
    );
    await sync.start();
    addTearDown(sync.dispose);
    p.recordAnswer(vocabulary[0], knewIt: true);
    await sync.flush();
    expect(asked, 1);
    expect(remote.answers, hasLength(1));
  });

  test(
    'progress from before sync existed is uploaded on first start',
    () async {
      final store = MemoryStore();
      final old = await LearningProgress.load(store, clock: () => now);
      old.recordAnswer(vocabulary[0], knewIt: true);
      await old.saveProfile(OnboardingData()..name = 'Anoop');
      await pumpEventQueue();

      final (_, sync, remote, _) = await setup(store: store);
      await sync.flush();
      expect(remote.words, hasLength(1));
      expect(remote.profile?.name, 'Anoop');
    },
  );

  test('signing in on a second phone merges both copies', () async {
    final remote = FakeRemote();
    final key = LearningProgress.keyOf(vocabulary[0]);
    remote.words[key] = WordProgress(
      firstSeen: DateTime(2026, 11, 10),
      lastSeen: DateTime(2026, 11, 12),
      due: DateTime(2026, 11, 15),
      learnedOn: DateTime(2026, 11, 10),
      timesSeen: 3,
      timesCorrect: 3,
      box: 2,
    );
    remote.profile = OnboardingData()..name = 'Anoop';

    final (p, sync, _, _) = await setup(remote: remote);
    p.recordAnswer(vocabulary[0], knewIt: true); // also practised here today
    p.recordAnswer(vocabulary[5], knewIt: true); // only on this phone

    final profile = await sync.mergeFromServer();
    final merged = p.words[key]!;
    expect(merged.timesSeen, 4); // 3 there + 1 here
    expect(merged.learnedOn, DateTime(2026, 11, 10)); // earliest wins
    expect(merged.lastSeen, DateTime(2026, 11, 17)); // newest wins
    expect(p.isLearned(vocabulary[5]), isTrue);
    expect(profile?.name, 'Anoop');
    expect(remote.words, hasLength(2)); // merged result uploaded
  });

  test('a change made during an upload is uploaded too, not lost', () async {
    final remote = FakeRemote();
    final (p, sync, _, _) = await setup(remote: remote);
    await sync.flush();

    final slow = Completer<void>();
    remote.gate = slow.future;
    p.recordAnswer(vocabulary[0], knewIt: false);
    final first = sync.flush(); // upload starts, waits at the gate
    await Future<void>.delayed(Duration.zero);

    p.recordAnswer(vocabulary[0], knewIt: true); // changes mid-upload
    await p.saveProfile(OnboardingData()..name = 'Late');
    slow.complete();
    await first;
    remote.gate = null;
    expect(sync.hasPending, isTrue, reason: 'newer changes still queued');

    await sync.flush();
    final key = LearningProgress.keyOf(vocabulary[0]);
    expect(remote.words[key]!.timesSeen, 2);
    expect(remote.words[key]!.learnedOn, isNotNull);
    expect(remote.profile?.name, 'Late');
    expect(sync.hasPending, isFalse);
  });
}
