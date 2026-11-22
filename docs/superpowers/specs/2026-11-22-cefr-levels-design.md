# CEFR levels (A1–B2): design

Date: 2026-11-22 · Status: approved ("Okay, you can do that start")

## Why
A tester asked for learning by level, beginner to intermediate: choosing A1
shows only A1 words, A2 only A2, and so on. Today the setup level is saved
but changes nothing; words have no level.

## Goals
- Every general word has a level A1, A2, B1 or B2.
- A study level per learner; new lessons, quizzes, topics, Words of the day
  and the Words tab use only that level.
- Switch level any time; at 80 % of a level, suggest the next.

## Non-goals / anti-goals
- Not copying the Goethe-Institut lists (copyrighted). Levels are our own,
  checked by a German reviewer via the review sheet.
- Reviews (due + Review my words) stay across all levels: nothing learned is
  hidden from review.
- Career packs (Pflege, IT & Büro) are not level-filtered.

## Approaches
| | Source of levels | Trade-off |
|---|---|---|
| A | Goethe official lists | Matches exams; copyrighted, no B2 list |
| B | Frequency bands only | Fast; often wrong for survival words |
| **C (chosen)** | Own assignment (basics A1, frequency bands, survival topics pulled one level down) + overrides from a German reviewer | No legal risk; improves with review |

## Design
**Data** (`tool/vocab/levels.py`, applied in `build_vocab.py` and runnable
on the existing `words.json`): rank 0 → A1; rank ≤ 600 → A1, ≤ 1600 → A2,
≤ 2400 → B1, else B2; topics basics, time, people, food, home, travel,
health move one level down (not below A1); `tool/vocab/levels.json`
overrides (`"der Krankenhaus": "A1"`, key = `article word` or `word`) win.
`words.json` rows get `"level": "a1"…"b2"`. Review sheet gets a Level column.

**App**
- `CefrLevel { a1, a2, b1, b2 }`; `GermanWord.level` (null for pack-only).
- `OnboardingData.studyLevel`; default from setup: A0/A1 → A1, A2 → A2,
  B1 → B1, B2 → B2. `GermanLevel` gains `b2`.
- `LearningProgress.studyLevel` (set from the profile on load / save);
  `setStudyLevel(profile, level)` saves the profile (syncs).
- Level-aware: `nextNewWords`, `learnedIn`/`topicTotal`, quiz pool,
  `wordsForDay`, Words tab. Packs and reviews unchanged.
- `LevelPicker` (A1 · A2 · B1 · B2 + "N of M learned") on Home, Practice,
  Words. `LevelUpCard` on Home at ≥ 80 % (not at B2): "Ready for B1?".
- Server: `profiles.study_level` (a1–b2), sent with the profile.
