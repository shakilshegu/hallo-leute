import 'dart:math' as math;

import '../../data/progress.dart';
import '../../data/vocabulary.dart';

/// One quiz question.
class Question {
  const Question({
    required this.word,
    required this.mode,
    required this.options,
    required this.answer,
  });

  final GermanWord word;
  final PracticeMode mode;

  /// Choices for multiple-choice modes; empty for spelling.
  final List<String> options;

  /// The correct option (or the expected spelling).
  final String answer;
}

/// Builds practice sessions from the learner's words.
class QuizEngine {
  QuizEngine(this.progress, {math.Random? random})
    : _random = random ?? math.Random();

  final LearningProgress progress;
  final math.Random _random;

  static const sessionLength = 10;

  /// Words this mode can use.
  static bool suits(GermanWord w, PracticeMode mode) => switch (mode) {
    PracticeMode.article => w.article.isNotEmpty,
    PracticeMode.spelling => w.word.length <= 14 && !w.word.contains(' '),
    PracticeMode.listening => w.word.length >= 3,
    _ => true,
  };

  /// Learned words first (weakest and most overdue first), topped up with
  /// the next useful new words so beginners can practise right away.
  List<GermanWord> pool(PracticeMode mode, {Topic? topic, int? count}) {
    final n = count ?? sessionLength;
    final source = progress.wordsFor(topic);
    final learned = source
        .where((w) => progress.isLearned(w) && suits(w, mode))
        .toList();
    learned.shuffle(_random);
    learned.sort(
      (a, b) => progress.weaknessOf(b).compareTo(progress.weaknessOf(a)),
    );
    final picked = learned.take(n).toList();
    if (picked.length < n) {
      picked.addAll(
        source
            .where((w) => !progress.isLearned(w) && suits(w, mode))
            .where((w) => topic != null || !w.topic.isPack)
            .take(n - picked.length),
      );
    }
    return picked..shuffle(_random);
  }

  /// A full session of questions for [mode].
  List<Question> build(PracticeMode mode, {Topic? topic}) => [
    for (final w in pool(mode, topic: topic)) question(w, mode),
  ];

  Question question(GermanWord w, PracticeMode mode) => switch (mode) {
    PracticeMode.article => Question(
      word: w,
      mode: mode,
      options: const ['der', 'die', 'das'],
      answer: w.article,
    ),
    PracticeMode.meaning => Question(
      word: w,
      mode: mode,
      options: _withDistractors(w.meaning, _distractors(w, (x) => x.meaning)),
      answer: w.meaning,
    ),
    PracticeMode.listening => Question(
      word: w,
      mode: mode,
      options: _withDistractors(
        _german(w),
        _distractors(w, _german, sameKind: true),
      ),
      answer: _german(w),
    ),
    PracticeMode.spelling => Question(
      word: w,
      mode: mode,
      options: const [],
      answer: w.word,
    ),
    PracticeMode.flashcard => throw ArgumentError('Use LessonScreen'),
  };

  static String _german(GermanWord w) =>
      [w.article, w.word].where((s) => s.isNotEmpty).join(' ');

  /// Three wrong options of the same word class, with distinct text.
  List<String> _distractors(
    GermanWord w,
    String Function(GermanWord) text, {
    bool sameKind = false,
  }) {
    final target = text(w).toLowerCase();
    final candidates =
        vocabulary
            .where((x) => x.pos == w.pos && x != w)
            .where((x) => !sameKind || (x.article.isEmpty == w.article.isEmpty))
            .where((x) => text(x).toLowerCase() != target)
            .take(400)
            .toList()
          ..shuffle(_random);
    final out = <String>[];
    final seen = {target};
    for (final c in candidates) {
      final t = text(c);
      if (seen.add(t.toLowerCase())) out.add(t);
      if (out.length == 3) break;
    }
    return out;
  }

  List<String> _withDistractors(String answer, List<String> wrong) =>
      [answer, ...wrong]..shuffle(_random);

  /// Spelling check: forgives capitalisation, surrounding spaces and
  /// ae/oe/ue/ss typed for ä/ö/ü/ß.
  static bool spellingMatches(String typed, String expected) {
    String norm(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    return norm(typed) == norm(expected);
  }
}
