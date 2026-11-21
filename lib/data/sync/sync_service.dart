import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/onboarding/onboarding_data.dart';
import '../local_store.dart';
import '../progress.dart';
import '../remote/progress_remote.dart';

/// Uploads progress to the server in the background.
///
/// Local-first: answers are saved on the phone immediately. This service
/// queues what changed (words, days, answer log, profile), persists the
/// queue so nothing is lost offline or on restart, and flushes it a few
/// seconds after the last change. Failed uploads stay queued for later.
class SyncService {
  SyncService({
    required this.progress,
    required this.remote,
    required this.store,
    this.debounce = const Duration(seconds: 3),
    this.ensureSession,
  });

  static const pendingKey = 'sync.pending.v1';
  static const seededKey = 'sync.seeded.v1';

  final LearningProgress progress;
  final ProgressRemote remote;
  final KeyValueStore store;
  final Duration debounce;

  /// Creates the anonymous guest session if there isn't one yet.
  final Future<void> Function()? ensureSession;

  // What needs uploading, tagged with when it last changed (a counter), so
  // a change that lands *during* an upload is never marked as sent.
  int _seq = 0;
  final Map<String, int> _words = {};
  final Map<String, int> _days = {};
  final List<AnswerEvent> _answers = [];
  int _profile = 0; // 0 = nothing to send

  StreamSubscription<ProgressChange>? _sub;
  Timer? _timer;
  Timer? _retry;
  Future<void>? _flushing;

  /// Last error from an upload attempt (null after a successful flush).
  Object? lastError;

  bool get hasPending =>
      _words.isNotEmpty ||
      _days.isNotEmpty ||
      _answers.isNotEmpty ||
      _profile != 0;

  /// Restores the saved queue, starts listening and tries an upload.
  Future<void> start() async {
    await _restoreQueue();
    // First run with sync: upload what was learned before sync existed.
    if (await store.read(seededKey) == null) {
      queueEverything();
      await store.write(seededKey, '1');
    }
    _sub = progress.changes.listen(_onChange);
    // Offline or failed uploads are retried every couple of minutes.
    _retry = Timer.periodic(const Duration(minutes: 2), (_) {
      if (hasPending) unawaited(flush());
    });
    unawaited(flush());
  }

  void dispose() {
    _timer?.cancel();
    _retry?.cancel();
    _sub?.cancel();
  }

  void _onChange(ProgressChange c) {
    final seq = ++_seq;
    if (c.profile) {
      _profile = seq;
    } else if (c.event == null) {
      _days[LearningProgress.dayKey(c.day!)] = seq; // study time only
    } else {
      final e = c.event!;
      _words[e.wordKey] = seq;
      _days[LearningProgress.dayKey(c.day!)] = seq;
      _answers.add(e);
    }
    unawaited(_persistQueue());
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Marks everything local as needing upload (after signing in / merging).
  void queueEverything() {
    final seq = ++_seq;
    for (final k in progress.words.keys) {
      _words[k] = seq;
    }
    for (final d in progress.activity.keys) {
      _days[LearningProgress.dayKey(d)] = seq;
    }
    _profile = seq;
    unawaited(_persistQueue());
  }

  /// Uploads the queue. If an upload is already running, waits for it and
  /// then sends whatever arrived meanwhile, so the caller's changes are
  /// always included.
  Future<void> flush() async {
    while (_flushing != null) {
      await _flushing;
    }
    if (!hasPending) return;
    final run = _flushing = _doFlush();
    try {
      await run;
    } finally {
      _flushing = null;
    }
  }

  Future<void> _doFlush() async {
    if (!hasPending) return;
    try {
      if (remote.userId == null) await ensureSession?.call();
      if (remote.userId == null) return; // still offline / not configured

      // Snapshot what we're sending, with each item's change counter.
      final wordSeqs = Map<String, int>.of(_words);
      final daySeqs = Map<String, int>.of(_days);
      final answers = List<AnswerEvent>.of(_answers);
      final profileSeq = _profile;

      final profile = profileSeq != 0 ? await progress.loadProfile() : null;
      final words = {
        for (final k in wordSeqs.keys)
          if (progress.words[k] != null) k: progress.words[k]!,
      };
      final days = {
        for (final k in daySeqs.keys)
          if (progress.activity[DateTime.parse(k)] != null)
            DateTime.parse(k): progress.activity[DateTime.parse(k)]!,
      };

      if (profile != null) await remote.upsertProfile(profile);
      await remote.upsertWords(words);
      await remote.upsertDays(days);
      await remote.insertAnswers(answers);

      // Clear only items that didn't change again while uploading.
      if (_profile == profileSeq) _profile = 0;
      wordSeqs.forEach((k, seq) {
        if (_words[k] == seq) _words.remove(k);
      });
      daySeqs.forEach((k, seq) {
        if (_days[k] == seq) _days.remove(k);
      });
      _answers.removeWhere(answers.contains);
      lastError = null;
      await _persistQueue();
    } catch (e) {
      lastError = e;
      debugPrint('Sync failed, will retry: $e');
    }
  }

  /// After signing in to an existing account (new phone, or a guest who
  /// already had an account): pull the server copy, merge it with what's on
  /// this phone, then upload the merged result.
  Future<OnboardingData?> mergeFromServer() async {
    final snapshot = await remote.fetchAll();
    progress.merge(snapshot.words, snapshot.days);
    final local = await progress.loadProfile();
    final profile = snapshot.profile ?? local;
    if (snapshot.profile != null) {
      await progress.saveProfile(snapshot.profile!);
    }
    queueEverything();
    await flush();
    return profile;
  }

  /// Drops the queue (sign-out / account deletion).
  Future<void> clear() async {
    _timer?.cancel();
    _words.clear();
    _days.clear();
    _answers.clear();
    _profile = 0;
    await store.remove(pendingKey);
    await store.remove(seededKey);
  }

  Future<void> _persistQueue() => store.write(
    pendingKey,
    jsonEncode({
      'words': _words.keys.toList(),
      'days': _days.keys.toList(),
      'answers': [for (final a in _answers) a.toJson()],
      'profile': _profile != 0,
    }),
  );

  Future<void> _restoreQueue() async {
    final raw = await store.read(pendingKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final seq = ++_seq;
      for (final k in (j['words'] as List).cast<String>()) {
        _words[k] = seq;
      }
      for (final k in (j['days'] as List).cast<String>()) {
        _days[k] = seq;
      }
      _answers.addAll(
        (j['answers'] as List).map(
          (a) => AnswerEvent.fromJson(a as Map<String, dynamic>),
        ),
      );
      if (j['profile'] == true) _profile = seq;
    } on Object {
      await store.remove(pendingKey);
    }
  }
}
