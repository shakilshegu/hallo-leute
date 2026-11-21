import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../features/onboarding/onboarding_data.dart';
import 'local_store.dart';
import 'vocabulary.dart';

/// How well a learner knows one word.
enum WordStatus {
  /// Never shown.
  fresh,

  /// Shown, but not answered "Got it" yet.
  seen,

  /// Learned and being reviewed (Leitner box 1–4).
  learning,

  /// Recalled correctly at the longest review interval (box 5).
  mastered,
}

/// Everything we track about one word for this learner.
class WordProgress {
  WordProgress({
    required this.firstSeen,
    required this.lastSeen,
    required this.due,
    this.learnedOn,
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.timesAgain = 0,
    this.box = 0,
  });

  factory WordProgress.fromJson(Map<String, dynamic> j) => WordProgress(
    firstSeen: _date(j['f']),
    lastSeen: _date(j['l']),
    due: _date(j['d']),
    learnedOn: j['lo'] == null ? null : _date(j['lo']),
    timesSeen: j['s'] as int? ?? 0,
    timesCorrect: j['c'] as int? ?? 0,
    timesAgain: j['a'] as int? ?? 0,
    box: j['b'] as int? ?? 0,
  );

  DateTime firstSeen;
  DateTime lastSeen;

  /// The day it was first answered "Got it". Null while only [WordStatus.seen].
  DateTime? learnedOn;

  /// Next day it should be reviewed.
  DateTime due;
  int timesSeen;
  int timesCorrect;
  int timesAgain;

  /// Leitner box: 0 = not learned, 1…5 = growing review intervals.
  int box;

  WordStatus get status => learnedOn == null
      ? WordStatus.seen
      : box >= LearningProgress.masteredBox
      ? WordStatus.mastered
      : WordStatus.learning;

  // Compact keys: thousands of words fit comfortably in device storage.
  Map<String, dynamic> toJson() => {
    'f': _fmt(firstSeen),
    'l': _fmt(lastSeen),
    'd': _fmt(due),
    if (learnedOn != null) 'lo': _fmt(learnedOn!),
    's': timesSeen,
    'c': timesCorrect,
    'a': timesAgain,
    'b': box,
  };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _date(Object? v) => DateTime.parse(v as String);
}

/// Answers given on one day.
class DayActivity {
  DayActivity({
    this.newWords = 0,
    this.reviews = 0,
    this.again = 0,
    this.seconds = 0,
  });

  factory DayActivity.fromJson(Map<String, dynamic> j) => DayActivity(
    newWords: j['n'] as int? ?? 0,
    reviews: j['r'] as int? ?? 0,
    again: j['a'] as int? ?? 0,
    seconds: j['s'] as int? ?? 0,
  );

  int newWords;
  int reviews;
  int again;

  /// Time spent in lessons and practice that day.
  int seconds;

  int get answers => newWords + reviews + again;

  Map<String, dynamic> toJson() => {
    'n': newWords,
    'r': reviews,
    'a': again,
    if (seconds > 0) 's': seconds,
  };
}

/// Ways of practising a word.
enum PracticeMode {
  flashcard,
  article,
  meaning,
  listening,
  spelling;

  static PracticeMode parse(String? name) =>
      values.firstWhere((m) => m.name == name, orElse: () => flashcard);
}

/// One answer. Kept as an append-only history for the backend.
class AnswerEvent {
  AnswerEvent({
    required this.id,
    required this.wordKey,
    required this.knewIt,
    required this.review,
    required this.answeredAt,
    this.mode = PracticeMode.flashcard,
  });

  factory AnswerEvent.fromJson(Map<String, dynamic> j) => AnswerEvent(
    id: j['id'] as String,
    wordKey: j['word_key'] as String,
    knewIt: j['knew_it'] as bool,
    review: j['review'] as bool,
    answeredAt: DateTime.parse(j['answered_at'] as String),
    mode: PracticeMode.parse(j['mode'] as String?),
  );

  /// How the word was practised.
  final PracticeMode mode;

  /// Random UUID made on the phone, so retried uploads never duplicate.
  final String id;
  final String wordKey;
  final bool knewIt;

  /// True when the word had already been learned (a spaced-repetition review).
  final bool review;
  final DateTime answeredAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'word_key': wordKey,
    'knew_it': knewIt,
    'review': review,
    'answered_at': answeredAt.toUtc().toIso8601String(),
    'mode': mode.name,
  };

  static final _random = math.Random.secure();

  /// RFC 4122 version-4 UUID.
  static String newId() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}

/// Something that needs uploading: an answer (word + day + event) or the
/// profile.
class ProgressChange {
  const ProgressChange.answer(AnswerEvent this.event, DateTime this.day)
    : profile = false;
  const ProgressChange.profile() : event = null, day = null, profile = true;

  /// Only the day's totals changed (e.g. study time).
  const ProgressChange.day(DateTime this.day) : event = null, profile = false;

  final AnswerEvent? event;
  final DateTime? day;
  final bool profile;
}

/// The learner's vocabulary progress, with spaced-repetition scheduling.
///
/// Saved on the device after every answer (see [KeyValueStore]).
class LearningProgress extends ChangeNotifier {
  LearningProgress({DateTime Function()? clock, this.store})
    : _clock = clock ?? DateTime.now;

  static const storageKey = 'progress.v1';
  static const profileKey = 'profile.v1';

  /// Days until the next review for each Leitner box (index = box).
  static const reviewIntervals = [0, 1, 3, 7, 14, 30];
  static const masteredBox = 5;

  final DateTime Function() _clock;

  /// Where progress is saved; null keeps it in memory only (tests).
  final KeyValueStore? store;

  /// Word key → progress. Only words the learner has seen are stored.
  final Map<String, WordProgress> words = {};

  /// Day → answers given that day (drives streak and week strip).
  final Map<DateTime, DayActivity> activity = {};

  final _changes = StreamController<ProgressChange>.broadcast(sync: true);

  /// Every answer and profile save, for background sync.
  Stream<ProgressChange> get changes => _changes.stream;

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }

  /// Loads saved progress (or starts empty) from [store].
  static Future<LearningProgress> load(
    KeyValueStore store, {
    DateTime Function()? clock,
  }) async {
    final p = LearningProgress(clock: clock, store: store);
    final raw = await store.read(storageKey);
    if (raw != null) {
      try {
        p._restore(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        // Corrupt data: start fresh rather than crash.
      }
    }
    return p;
  }

  void _restore(Map<String, dynamic> json) {
    final w = (json['words'] as Map?) ?? {};
    w.forEach((k, v) {
      words[k as String] = WordProgress.fromJson(v as Map<String, dynamic>);
    });
    final a = (json['activity'] as Map?) ?? {};
    a.forEach((k, v) {
      activity[DateTime.parse(k as String)] = DayActivity.fromJson(
        v as Map<String, dynamic>,
      );
    });
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'words': {for (final e in words.entries) e.key: e.value.toJson()},
    'activity': {
      for (final e in activity.entries)
        WordProgress._fmt(e.key): e.value.toJson(),
    },
  };

  Future<void> _save() async {
    await store?.write(storageKey, jsonEncode(toJson()));
  }

  // ───────────────────────────── profile ─────────────────────────────

  Future<OnboardingData?> loadProfile() async {
    final raw = await store?.read(profileKey);
    if (raw == null) return null;
    try {
      return OnboardingData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveProfile(OnboardingData profile) async {
    await store?.write(profileKey, jsonEncode(profile.toJson()));
    notifyListeners();
    if (!_changes.isClosed) _changes.add(const ProgressChange.profile());
  }

  // ───────────────────────────── recording ─────────────────────────────

  static String keyOf(GermanWord w) => '${w.word}|${w.pos}';

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  DateTime get today => _day(_clock());

  /// Records one flashcard answer and reschedules the word.
  void recordAnswer(GermanWord word, {required bool knewIt}) {
    final now = today;
    final key = keyOf(word);
    final p = words.putIfAbsent(
      key,
      () => WordProgress(firstSeen: now, lastSeen: now, due: now),
    );
    final wasLearned = p.learnedOn != null;
    final day = activity.putIfAbsent(now, DayActivity.new);
    p
      ..timesSeen += 1
      ..lastSeen = now;

    if (knewIt) {
      p.timesCorrect += 1;
      if (p.learnedOn == null) {
        p.learnedOn = now;
        day.newWords += 1;
      } else {
        day.reviews += 1;
      }
      // Reviewing before the word is due ("Review my words") must not push
      // it up the ladder: flipping it five times today isn't mastery.
      final early = wasLearned && p.due.isAfter(now);
      if (!early) {
        p.box = (p.box + 1).clamp(1, masteredBox);
        p.due = _addDays(now, reviewIntervals[p.box]);
      }
    } else {
      p.timesAgain += 1;
      day.again += 1;
      // Forgotten: start the review ladder again, due right away.
      if (p.learnedOn != null) p.box = 1;
      p.due = now;
    }
    notifyListeners();
    _save();
    if (!_changes.isClosed) {
      _changes.add(
        ProgressChange.answer(
          AnswerEvent(
            id: AnswerEvent.newId(),
            wordKey: key,
            knewIt: knewIt,
            review: wasLearned,
            answeredAt: _clock(),
          ),
          now,
        ),
      );
    }
  }

  /// Records a quiz answer (article, meaning, listening, spelling).
  ///
  /// Quizzes don't move a word up the review ladder (only flashcards and
  /// reviews do), but a wrong answer makes a learned word due again, and
  /// everything counts towards stats, streak and the answer history.
  void recordPractice(
    GermanWord word, {
    required bool correct,
    required PracticeMode mode,
  }) {
    final now = today;
    final key = keyOf(word);
    final p = words.putIfAbsent(
      key,
      () => WordProgress(firstSeen: now, lastSeen: now, due: now),
    );
    final day = activity.putIfAbsent(now, DayActivity.new);
    final wasLearned = p.learnedOn != null;
    p
      ..timesSeen += 1
      ..lastSeen = now;
    if (correct) {
      p.timesCorrect += 1;
      day.reviews += 1;
    } else {
      p.timesAgain += 1;
      day.again += 1;
      if (wasLearned) p.due = now;
    }
    notifyListeners();
    _save();
    if (!_changes.isClosed) {
      _changes.add(
        ProgressChange.answer(
          AnswerEvent(
            id: AnswerEvent.newId(),
            wordKey: key,
            knewIt: correct,
            review: wasLearned,
            answeredAt: _clock(),
            mode: mode,
          ),
          now,
        ),
      );
    }
  }

  /// Folds progress from another device or account into this one: counts
  /// add up, the earliest first-seen/learned dates win, and the schedule
  /// comes from whichever copy was practised most recently.
  void merge(
    Map<String, WordProgress> otherWords,
    Map<DateTime, DayActivity> otherDays,
  ) {
    otherWords.forEach((key, o) {
      final p = words[key];
      if (p == null) {
        words[key] = o;
        return;
      }
      final newer = o.lastSeen.isAfter(p.lastSeen) ? o : p;
      words[key] = WordProgress(
        firstSeen: o.firstSeen.isBefore(p.firstSeen)
            ? o.firstSeen
            : p.firstSeen,
        lastSeen: newer.lastSeen,
        due: newer.due,
        box: newer.box,
        learnedOn: [p.learnedOn, o.learnedOn]
            .whereType<DateTime>()
            .fold<DateTime?>(
              null,
              (a, b) => a == null || b.isBefore(a) ? b : a,
            ),
        timesSeen: p.timesSeen + o.timesSeen,
        timesCorrect: p.timesCorrect + o.timesCorrect,
        timesAgain: p.timesAgain + o.timesAgain,
      );
    });
    otherDays.forEach((day, o) {
      final d = activity.putIfAbsent(day, DayActivity.new);
      d
        ..newWords += o.newWords
        ..reviews += o.reviews
        ..again += o.again
        ..seconds += o.seconds;
    });
    notifyListeners();
    _save();
  }

  /// Day key in storage format (yyyy-mm-dd).
  static String dayKey(DateTime d) => WordProgress._fmt(d);

  /// Adds time spent learning today (lessons, practice). Sessions are capped
  /// at an hour so a forgotten open screen doesn't inflate the numbers.
  void addStudyTime(Duration time) {
    final seconds = time.inSeconds.clamp(0, 3600);
    if (seconds < 3) return;
    final now = today;
    activity.putIfAbsent(now, DayActivity.new).seconds += seconds;
    notifyListeners();
    _save();
    if (!_changes.isClosed) _changes.add(ProgressChange.day(now));
  }

  int secondsOn(DateTime day) => activity[_day(day)]?.seconds ?? 0;

  int wordsLearnedOn(DateTime day) => activity[_day(day)]?.newWords ?? 0;

  /// Shortcut used by tests and previews.
  void markLearned(GermanWord w) {
    if (!isLearned(w)) recordAnswer(w, knewIt: true);
  }

  // ───────────────────────────── queries ─────────────────────────────

  WordProgress? progressOf(GermanWord w) => words[keyOf(w)];

  WordStatus statusOf(GermanWord w) =>
      progressOf(w)?.status ?? WordStatus.fresh;

  bool isLearned(GermanWord w) => progressOf(w)?.learnedOn != null;

  int get totalLearned => words.values.where((p) => p.learnedOn != null).length;

  int get totalMastered =>
      words.values.where((p) => p.status == WordStatus.mastered).length;

  int get learnedToday => activity[today]?.newWords ?? 0;

  /// True once the learner answered anything today.
  bool get practisedToday => (activity[today]?.answers ?? 0) > 0;

  /// Learned words whose review day has come, most overdue first.
  List<GermanWord> dueForReview({int? limit}) {
    final due = [
      for (final w in vocabulary)
        if (progressOf(w) case final p?
            when p.learnedOn != null && !p.due.isAfter(today))
          w,
    ]..sort((a, b) => progressOf(a)!.due.compareTo(progressOf(b)!.due));
    return limit == null ? due : due.take(limit).toList();
  }

  int get dueCount => dueForReview().length;

  /// How much a learned word needs practice: missed often, low on the
  /// ladder or overdue scores higher. Shared by quizzes and reviews.
  int weaknessOf(GermanWord w) {
    final p = progressOf(w)!;
    final overdue = today.difference(p.due).inDays;
    return p.timesAgain * 3 - p.box * 2 + overdue.clamp(0, 30);
  }

  /// Learned words for an on-demand review, weakest first (ties: the one
  /// due soonest). Optionally only one [topic].
  List<GermanWord> reviewAnytime({Topic? topic, int limit = 20}) {
    final learned = (topic?.words ?? vocabulary).where(isLearned).toList()
      ..sort((a, b) {
        final byWeakness = weaknessOf(b).compareTo(weaknessOf(a));
        return byWeakness != 0
            ? byWeakness
            : progressOf(a)!.due.compareTo(progressOf(b)!.due);
      });
    return learned.take(limit).toList();
  }

  /// The next [count] words not learned yet, most useful first.
  /// Words answered "Again" but never learned come back here first.
  /// Without a [topic], career-pack-only words are left out (they're
  /// learned from their pack page).
  List<GermanWord> nextNewWords(int count, {Topic? topic}) =>
      (topic == null ? vocabulary.where((w) => !w.topic.isPack) : topic.words)
          .where((w) => !isLearned(w))
          .take(count)
          .toList(growable: false);

  /// Words the learner has learned, most recent first.
  List<GermanWord> get learnedWords {
    final list = vocabulary.where(isLearned).toList();
    list.sort((a, b) {
      final byDay = progressOf(b)!.learnedOn!
          .compareTo(progressOf(a)!.learnedOn!);
      return byDay != 0
          ? byDay
          : progressOf(b)!.lastSeen.compareTo(progressOf(a)!.lastSeen);
    });
    return list;
  }

  int learnedIn(Topic topic) => topic.words.where(isLearned).length;

  /// Weekdays (1 = Monday … 7 = Sunday) practised in the current week.
  Set<int> get practisedThisWeek {
    final monday = _addDays(today, 1 - today.weekday);
    return {
      for (final e in activity.entries)
        if (e.value.answers > 0 &&
            !e.key.isBefore(monday) &&
            !e.key.isAfter(today))
          e.key.weekday,
    };
  }

  /// Consecutive days with practice, ending today (or yesterday, so the
  /// streak survives until the end of today).
  int get streak {
    bool practised(DateTime d) => (activity[d]?.answers ?? 0) > 0;
    var day = practised(today) ? today : _addDays(today, -1);
    var count = 0;
    while (practised(day)) {
      count++;
      day = _addDays(day, -1);
    }
    return count;
  }

  /// Wipes all progress (keeps the profile).
  Future<void> reset() async {
    words.clear();
    activity.clear();
    notifyListeners();
    await store?.remove(storageKey);
  }
}

/// Makes [LearningProgress] available to the widget tree and rebuilds
/// dependants when it changes.
class ProgressScope extends InheritedNotifier<LearningProgress> {
  const ProgressScope({
    super.key,
    required LearningProgress progress,
    required super.child,
  }) : super(notifier: progress);

  static LearningProgress of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'No ProgressScope above this widget.');
    return scope!.notifier!;
  }
}
