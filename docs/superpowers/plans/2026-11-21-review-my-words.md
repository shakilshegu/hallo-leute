# Review My Words Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** On-demand flashcard review of learned words without disturbing the review schedule.
**Architecture:** Selection + schedule rule in `LearningProgress`; a card widget; wired into Home and Practice.
**Tech Stack:** Flutter/Dart.
**Spec:** `docs/superpowers/specs/2026-11-21-review-my-words-design.md`

## Global Constraints
- Max 20 words per round. Copy exactly as in the spec.
- Due-word behaviour of `recordAnswer` must not change.

## Review Focus
- Not-due "I know it" twice in a day: box/due unchanged both times (Task 1 test).
- Mastered word (box 5) reviewed early: stays mastered, due unchanged (Task 1 test).
- Not-due "Not yet": box 1, due today, appears in dueForReview (Task 1 test).
- Topic with no learned words: card hidden (Task 2 test).
- No learned words at all: Home shows no card (Task 2 test).

### Task 1: Selection and schedule rule
**Files:** Modify `lib/data/progress.dart`, `lib/features/practice/quiz_engine.dart`; Test `test/progress_test.dart`
**Produces:** `int weaknessOf(GermanWord w)`, `List<GermanWord> reviewAnytime({Topic? topic, int limit = 20})` on `LearningProgress`.
- [ ] Tests: `reviewAnytime returns learned words weakest first, capped`; `early I know it keeps the schedule`; `early I know it counts as a review`; `early not yet resets to due today`; `mastered word reviewed early stays mastered`.
- [ ] Run → FAIL. Implement. Run → PASS. `flutter test` all green. Commit.

### Task 2: Card on Home and Practice
**Files:** Modify `lib/features/home/widgets/home_cards.dart`, `lib/features/home/home_tab.dart`, `lib/features/practice/practice_tab.dart`; Test `test/review_anytime_test.dart`
**Consumes:** `reviewAnytime`, `totalLearned`.
- [ ] Tests: card copy (`13 words` / `1 word`); tap opens LessonScreen with those words; Practice topic without learned words hides the card; Home hides it with no learned words and when words are due.
- [ ] Run → FAIL. Implement. Run → PASS. `flutter analyze` clean, `flutter test` green. Commit.

### Task 3: Emulator check
- [ ] Practice → Review my words → flip cards → counts update; schedule of an early-known word unchanged (Words tab shows same "next review").
