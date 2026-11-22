# CEFR Levels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** Learn by level A1–B2 with level-filtered lessons.
**Spec:** `docs/superpowers/specs/2026-11-22-cefr-levels-design.md`

## Global Constraints
- Bands: rank 0 → A1; ≤600 A1; ≤1600 A2; ≤2400 B1; else B2. Down-shift topics: basics, time, people, food, home, travel, health. Overrides win.
- Packs and reviews are never level-filtered. Level-up threshold 80 %.

## Review Focus
- Learner with no saved studyLevel (existing users): derived from setup level (Task 2 test).
- Switching level keeps progress of other levels (Task 2 test).
- Pack topic screen at any level shows all pack words (Task 2 test).
- B2 has no level-up card (Task 3 test).
- Words of the day at B2 (ranks > 2000) is not empty (Task 2 test).

### Task 1: Word levels in the data
Files: `tool/vocab/levels.py` (`level_for(word: dict, overrides: dict) -> str`, CLI `--apply`), `tool/vocab/levels.json`, `tool/vocab/test_levels.py`, `tool/vocab/build_vocab.py`, `tool/vocab/export_review.py`, `assets/vocabulary/words.json`.
- [ ] Tests (unittest): basics → a1; rank 500 → a1; 1200 → a2; 2000 → b1; 2900 → b2; health rank 2000 → a2; override wins. FAIL → implement → PASS → apply → commit.

### Task 2: Levels in the model
Files: `lib/data/vocabulary.dart`, `lib/features/onboarding/onboarding_data.dart`, `lib/data/progress.dart`, `lib/features/practice/quiz_engine.dart`, `lib/features/home/home_content.dart`, `lib/data/remote/progress_remote.dart`, migration `supabase/migrations/20261122000000_study_level.sql`, `lib/main.dart`, tests in `test/levels_test.dart`.
Produces: `CefrLevel`, `GermanWord.level`, `OnboardingData.studyLevel` + `effectiveStudyLevel`, `LearningProgress.studyLevel`, `setStudyLevel`, `useProfile`, `topicTotal(Topic)`, `levelTotal`, `learnedAtLevel`, `wordsForDay(day, level:)`.
- [ ] Tests → FAIL → implement → PASS → full suite → commit.

### Task 3: Level picker and level-up
Files: `lib/shared/widgets/level_picker.dart`, Home/Practice/Words tabs, `home_cards.dart` (LevelUpCard), onboarding level step + edit profile (B2, sets studyLevel), test `test/level_picker_test.dart`.
- [ ] Tests → FAIL → implement → PASS → analyze + suite → commit.

### Task 4: Emulator check + push
