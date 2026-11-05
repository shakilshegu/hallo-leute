import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'models.dart';

export 'models.dart';

part 'database.g.dart';

/// The learner's profile. MVP: one row, stored only on this device.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get reason => textEnum<LearningReason>()();
  TextColumn get level => textEnum<CefrLevel>()();
  IntColumn get dailyGoal => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Vocabulary, seeded from `assets/words/starter_words.json`.
class Words extends Table {
  TextColumn get id => text()();
  TextColumn get german => text()();
  TextColumn get article => textEnum<Article>().nullable()();
  TextColumn get plural => text().nullable()();
  TextColumn get english => text()();
  TextColumn get example => text()();
  TextColumn get exampleEn => text()();
  TextColumn get topic => text()();
  TextColumn get level => textEnum<CefrLevel>()();
  TextColumn get emoji => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per word the learner has learned.
class WordProgress extends Table {
  TextColumn get wordId => text().references(Words, #id)();
  DateTimeColumn get learnedAt => dateTime()();

  /// When the word should come back for review (spaced repetition).
  DateTimeColumn get nextReview => dateTime()();

  /// Correct reviews in a row – grows the review interval.
  IntColumn get reviewStreak => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {wordId};
}

@DriftDatabase(tables: [Profiles, Words, WordProgress])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'poppylo'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(words);
        await m.createTable(wordProgress);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  // -- Profile ---------------------------------------------------------------

  Future<Profile?> getProfile() =>
      (select(profiles)..limit(1)).getSingleOrNull();

  /// Replaces any existing profile with [profile].
  Future<void> saveProfile(ProfilesCompanion profile) => transaction(() async {
    await delete(profiles).go();
    await into(profiles).insert(profile);
  });

  /// Clears the profile and all learning progress (debug reset).
  Future<void> clearProfile() => transaction(() async {
    await delete(wordProgress).go();
    await delete(profiles).go();
  });

  // -- Words -----------------------------------------------------------------

  /// Inserts or updates the bundled vocabulary from its JSON source.
  Future<void> seedWords(String json) {
    final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return batch((b) {
      b.insertAllOnConflictUpdate(words, [
        for (final w in rows)
          WordsCompanion.insert(
            id: w['id'] as String,
            german: w['german'] as String,
            article: Value(
              w['article'] == null
                  ? null
                  : Article.values.byName(w['article'] as String),
            ),
            plural: Value(w['plural'] as String?),
            english: w['english'] as String,
            example: w['example'] as String,
            exampleEn: w['exampleEn'] as String,
            topic: w['topic'] as String,
            level: CefrLevel.values.byName(w['level'] as String),
            emoji: w['emoji'] as String,
          ),
      ]);
    });
  }

  Future<List<Word>> allWords() =>
      (select(words)..orderBy([(w) => OrderingTerm(expression: w.id)])).get();

  Future<List<WordProgressData>> allProgress() => select(wordProgress).get();

  /// Emits whenever the profile or learning progress changes.
  Stream<void> watchLearningChanges() async* {
    yield null;
    yield* tableUpdates(TableUpdateQuery.onAllTables([profiles, wordProgress]))
        .map((_) {});
  }

  /// Records [wordId] as learned at [at]; first review is the next day.
  Future<void> markLearned(String wordId, {DateTime? at}) {
    final when = at ?? DateTime.now();
    return into(wordProgress).insertOnConflictUpdate(
      WordProgressCompanion.insert(
        wordId: wordId,
        learnedAt: when,
        nextReview: when.add(const Duration(days: 1)),
      ),
    );
  }

  /// Debug helper: fills the last few days with sample progress so the
  /// Home garden, streak and review states can be seen before Flashcards
  /// exist. Never called in release builds.
  Future<void> debugSeedProgress({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final all = await allWords();
    final perDay = {3: 6, 2: 10, 1: 10, 0: 4}; // days ago → words
    var i = 0;
    await transaction(() async {
      await delete(wordProgress).go();
      for (final MapEntry(key: daysAgo, value: count) in perDay.entries) {
        final day = DateTime(today.year, today.month, today.day - daysAgo, 9);
        for (var n = 0; n < count && i < all.length; n++, i += 3) {
          await markLearned(all[i].id, at: day.add(Duration(minutes: n * 3)));
        }
      }
    });
  }
}
