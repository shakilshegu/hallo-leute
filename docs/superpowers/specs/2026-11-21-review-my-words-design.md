# Review my words: design

Date: 2026-11-21 · Status: approved (owner: "you can do your recommendation")

## Why
Learners forget words after learning them. Scheduled reviews (1, 3, 7, 14, 30
days) only appear when words are due, so there is no way to go over learned
words as flashcards on demand.

## Goals
- Flashcards of learned words, any time, weakest first (max 20 per round).
- Practice tab card (respects the topic filter); Home card when nothing is due.
- Extra reviews never push a word's schedule ahead.

## Non-goals
- Changing review intervals. New review modes beyond flashcards.

## Approaches
| | Approach | Trade-off |
|---|---|---|
| **A (chosen)** | "Review my words" flashcards any time | Small; reuses flashcards; active recall |
| B | Shorter review intervals | More work for everyone, still no on-demand button |
| C | More word pop-ups | Already exists; passive, no recall |

## Design
- `LearningProgress.reviewAnytime({Topic? topic, int limit = 20})`: learned
  words, weakest first. Weakness = `timesAgain * 3 - box * 2 + daysOverdue`
  (the formula the quizzes use, moved to `LearningProgress.weaknessOf` and
  shared); ties: earliest due first.
- `recordAnswer` rule: "I know it" on a learned word that is **not due yet**
  counts as a review (stats, streak) but leaves `box` and `due` unchanged.
  "Not yet" works as today (box 1, due today). Due words: unchanged behaviour.
- `ReviewAnytimeCard(learned:, onStart:)` in home_cards.dart:
  title `Review my words`, body `Flip through the N words you learned.
  Weakest first.` (`1 word` singular). Opens `LessonScreen(review: true)`.
- Home: shown in the review slot when `dueCount == 0` and learned > 0.
- Practice: shown after the due Review card when the (topic) has learned words.
