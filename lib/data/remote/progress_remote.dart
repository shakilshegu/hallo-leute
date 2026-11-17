import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/onboarding_data.dart';
import '../progress.dart';

/// Everything one learner has stored on the server.
class RemoteSnapshot {
  const RemoteSnapshot({
    required this.words,
    required this.days,
    required this.profile,
  });

  final Map<String, WordProgress> words;
  final Map<DateTime, DayActivity> days;
  final OnboardingData? profile;
}

/// Server storage for the signed-in learner's progress.
abstract class ProgressRemote {
  /// The current learner's id, or null when no session exists yet.
  String? get userId;

  Future<void> upsertProfile(OnboardingData profile);
  Future<void> upsertWords(Map<String, WordProgress> words);
  Future<void> upsertDays(Map<DateTime, DayActivity> days);
  Future<void> insertAnswers(List<AnswerEvent> answers);
  Future<RemoteSnapshot> fetchAll();
}

/// [ProgressRemote] backed by the Supabase tables in `supabase/migrations`.
class SupabaseProgressRemote implements ProgressRemote {
  SupabaseProgressRemote(this._client);

  final SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  String get _uid {
    final id = userId;
    if (id == null) throw StateError('No Supabase session');
    return id;
  }

  static String _date(DateTime d) => LearningProgress.dayKey(d);

  @override
  Future<void> upsertProfile(OnboardingData profile) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('profiles').upsert({
      'id': _uid,
      'name': profile.name.trim(),
      'level': profile.level?.name,
      'daily_goal': profile.dailyGoal.name,
      'goals': [for (final g in profile.goals) g.name],
      'updated_at': now,
    });
  }

  @override
  Future<void> upsertWords(Map<String, WordProgress> words) async {
    if (words.isEmpty) return;
    final uid = _uid;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = [
      for (final e in words.entries)
        {
          'user_id': uid,
          'word_key': e.key,
          'first_seen': _date(e.value.firstSeen),
          'last_seen': _date(e.value.lastSeen),
          'learned_on': e.value.learnedOn == null
              ? null
              : _date(e.value.learnedOn!),
          'due': _date(e.value.due),
          'times_seen': e.value.timesSeen,
          'times_correct': e.value.timesCorrect,
          'times_again': e.value.timesAgain,
          'box': e.value.box,
          'updated_at': now,
        },
    ];
    for (var i = 0; i < rows.length; i += 500) {
      await _client
          .from('word_progress')
          .upsert(rows.sublist(i, (i + 500).clamp(0, rows.length)));
    }
  }

  @override
  Future<void> upsertDays(Map<DateTime, DayActivity> days) async {
    if (days.isEmpty) return;
    final uid = _uid;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('daily_activity').upsert([
      for (final e in days.entries)
        {
          'user_id': uid,
          'day': _date(e.key),
          'new_words': e.value.newWords,
          'reviews': e.value.reviews,
          'again': e.value.again,
          'updated_at': now,
        },
    ]);
  }

  @override
  Future<void> insertAnswers(List<AnswerEvent> answers) async {
    if (answers.isEmpty) return;
    final uid = _uid;
    final rows = [
      for (final a in answers) {...a.toJson(), 'user_id': uid},
    ];
    for (var i = 0; i < rows.length; i += 500) {
      // Same id twice (a retried upload) is silently ignored.
      await _client
          .from('answer_events')
          .upsert(
            rows.sublist(i, (i + 500).clamp(0, rows.length)),
            onConflict: 'id',
            ignoreDuplicates: true,
          );
    }
  }

  @override
  Future<RemoteSnapshot> fetchAll() async {
    final uid = _uid;
    final wordRows = await _client
        .from('word_progress')
        .select()
        .eq('user_id', uid);
    final dayRows = await _client
        .from('daily_activity')
        .select()
        .eq('user_id', uid);
    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    DateTime d(Object? v) => DateTime.parse(v as String);
    return RemoteSnapshot(
      words: {
        for (final r in wordRows)
          r['word_key'] as String: WordProgress(
            firstSeen: d(r['first_seen']),
            lastSeen: d(r['last_seen']),
            due: d(r['due']),
            learnedOn: r['learned_on'] == null ? null : d(r['learned_on']),
            timesSeen: r['times_seen'] as int,
            timesCorrect: r['times_correct'] as int,
            timesAgain: r['times_again'] as int,
            box: r['box'] as int,
          ),
      },
      days: {
        for (final r in dayRows)
          d(r['day']): DayActivity(
            newWords: r['new_words'] as int,
            reviews: r['reviews'] as int,
            again: r['again'] as int,
          ),
      },
      profile: profileRow == null
          ? null
          : OnboardingData.fromJson({
              'name': profileRow['name'],
              'level': profileRow['level'],
              'dailyGoal': profileRow['daily_goal'],
              'goals': profileRow['goals'],
            }),
    );
  }
}
