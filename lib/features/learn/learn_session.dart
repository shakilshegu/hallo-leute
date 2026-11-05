import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/topics.dart';

/// Smallest session we ever offer (also used for "learn a few more").
const minSessionSize = 5;

/// Picks the words for a learning session.
///
/// Unlearned words up to the learner's level; a [topic] narrows it down,
/// otherwise topics that match the learning reason come first.
List<Word> pickSessionWords({
  required List<Word> words,
  required Set<String> learnedIds,
  required Profile? profile,
  required int count,
  String? topic,
}) {
  final level = profile?.level ?? CefrLevel.a1;
  var pool = words
      .where((w) => !learnedIds.contains(w.id))
      .where((w) => topic == null || w.topic == topic)
      .toList();
  final atLevel = pool.where((w) => w.level.index <= level.index).toList();
  if (atLevel.isNotEmpty) pool = atLevel;

  final topicOrder = {
    for (final (i, t) in Topic.forReason(profile?.reason).indexed) t.id: i,
  };
  pool.sort((a, b) {
    final byTopic = (topicOrder[a.topic] ?? 99).compareTo(
      topicOrder[b.topic] ?? 99,
    );
    if (byTopic != 0) return byTopic;
    final byLevel = a.level.index.compareTo(b.level.index);
    return byLevel != 0 ? byLevel : a.id.compareTo(b.id);
  });
  return pool.take(count).toList();
}

/// One card in the deck. [serial] makes re-queued cards unique.
@immutable
class DeckCard {
  const DeckCard(this.word, this.serial);

  final Word word;
  final int serial;

  String get key => '${word.id}#$serial';
}

@immutable
class SessionState {
  const SessionState({
    required this.queue,
    required this.total,
    this.learned = const [],
    this.againCount = 0,
    this.guessCorrect = 0,
    this.guessTotal = 0,
    this.nextSerial = 0,
  });

  /// Remaining cards; the first one is on top of the deck.
  final List<DeckCard> queue;

  /// Number of different words in this session.
  final int total;
  final List<Word> learned;
  final int againCount;
  final int guessCorrect;
  final int guessTotal;
  final int nextSerial;

  bool get isEmpty => total == 0;
  bool get done => total > 0 && queue.isEmpty;
  DeckCard? get current => queue.isEmpty ? null : queue.first;

  SessionState copyWith({
    List<DeckCard>? queue,
    List<Word>? learned,
    int? againCount,
    int? guessCorrect,
    int? guessTotal,
    int? nextSerial,
  }) => SessionState(
    queue: queue ?? this.queue,
    total: total,
    learned: learned ?? this.learned,
    againCount: againCount ?? this.againCount,
    guessCorrect: guessCorrect ?? this.guessCorrect,
    guessTotal: guessTotal ?? this.guessTotal,
    nextSerial: nextSerial ?? this.nextSerial,
  );

  /// "Nochmal": the current card comes back a few cards later.
  SessionState requeueCurrent() {
    final card = current;
    if (card == null) return this;
    final rest = queue.sublist(1);
    final at = math.min(rest.length, 3);
    return copyWith(
      queue: [
        ...rest.take(at),
        DeckCard(card.word, nextSerial),
        ...rest.skip(at),
      ],
      againCount: againCount + 1,
      nextSerial: nextSerial + 1,
    );
  }

  /// "Kann ich!": the current card is learned and leaves the deck.
  SessionState learnCurrent() {
    final card = current;
    if (card == null) return this;
    return copyWith(queue: queue.sublist(1), learned: [...learned, card.word]);
  }
}

/// A flashcard session. The argument is an optional topic id.
class LearnSession extends AsyncNotifier<SessionState> {
  LearnSession(this.topic);

  final String? topic;

  @override
  Future<SessionState> build() async {
    final db = ref.read(databaseProvider);
    final profile = await db.getProfile();
    final words = await db.allWords();
    final progress = await db.allProgress();

    final now = DateTime.now();
    final learnedToday = progress.where((p) {
      final d = p.learnedAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
    final goal = profile?.dailyGoal ?? 10;
    final count = math.max(goal - learnedToday, minSessionSize);

    final picked = pickSessionWords(
      words: words,
      learnedIds: {for (final p in progress) p.wordId},
      profile: profile,
      count: count,
      topic: topic,
    );
    return SessionState(
      queue: [for (final (i, w) in picked.indexed) DeckCard(w, i)],
      total: picked.length,
      nextSerial: picked.length,
    );
  }

  SessionState? get _s => state.value;

  /// Swipe right. The UI updates instantly; saving happens in the background.
  void know() {
    final s = _s;
    final card = s?.current;
    if (s == null || card == null) return;
    state = AsyncData(s.learnCurrent());
    unawaited(ref.read(databaseProvider).markLearned(card.word.id));
  }

  /// Swipe left.
  void again() {
    final s = _s;
    if (s == null) return;
    state = AsyncData(s.requeueCurrent());
  }

  void recordGuess({required bool correct}) {
    final s = _s;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(
        guessTotal: s.guessTotal + 1,
        guessCorrect: s.guessCorrect + (correct ? 1 : 0),
      ),
    );
  }
}

final learnSessionProvider = AsyncNotifierProvider.autoDispose
    .family<LearnSession, SessionState, String?>(LearnSession.new);
