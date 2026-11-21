# Rate & suggest: design

Date: 2026-11-21 · Status: approved (owner delegated the call)

## Why

Learners (especially closed-test testers) should be able to rate the app and
say what to improve, so the owner hears it privately and early, and have an
easy way to rate the app on Google Play.

## Goals

- Rate the app 1–5 stars and write suggestions, from inside the app.
- Owner reads every entry in the existing admin panel.
- A "Rate on Google Play" button for everyone.

## Non-goals

- Reporting a problem with a single word (separate feature, maybe later).
- Replying to learners from the admin panel.
- Automatic pop-ups asking for feedback.

## Anti-goals (a failure even if it works)

- Nagging: feedback is only asked for when the learner opens it.
- Collecting personal data the learner didn't type.
- Review gating: sending only happy learners to Google Play. Google Play's
  in-app review policy forbids asking for an opinion first and showing the
  rating prompt based on it, so the Play button is never tied to the stars.
- Learners being able to read other learners' feedback.

## Approaches considered

| | Approach | Trade-off |
|---|---|---|
| **A (chosen)** | In-app form → Supabase `feedback` table → admin panel, plus a "Rate on Google Play" button for everyone | Most work, but the only one that gives private suggestions and protects the Play rating |
| B | Play Store in-app review only | Tiny, but no private suggestions; only works once live on Play |
| C | Link to a Google Form | No code, but leaves the app, not linked to the learner, outside the admin panel |

The owner chose A (left the pick to Claude). Change after review: the first
draft sent 4–5 star ratings on to Google's in-app review. That is review
gating, which Google Play forbids, so the Play button is now separate and
shown to everyone.

## Design

**App: Profile tab.** A new "Rate & suggest" card, under the reminder cards:

```
┌────────────────────────────────────┐
│ ★  Enjoying Hallo Leute?           │
│    Rate the app and tell us what   │
│    to improve.                     │
│ [Send feedback] [Rate on Google Play]
└────────────────────────────────────┘
```

"Send feedback" opens a bottom sheet (same style as the email sheet):

```
How do you like Hallo Leute?
  ☆ ☆ ☆ ☆ ☆            (required)
What could be better?   [ multi-line, optional, 1000 chars ]
What do you like?       [ multi-line, optional, 1000 chars ]
            [ Send ]
```

- After sending: "Danke! We read every message." (snackbar).
- "Rate on Google Play" opens the Play Store listing for `com.halloleute.app`
  (market:// link, falling back to https://play.google.com/store/apps/details).
  Shown to everyone on Android; hidden on other platforms. No in-app review
  pop-up for now.
- Works for guests and signed-in learners (everyone has a Supabase session).
- Offline / error: the sheet stays open with a friendly error so text isn't lost.
- Learners can send feedback more than once.

**Database:** new migration `public.feedback`:
`id uuid pk, user_id uuid → auth.users (on delete cascade) default auth.uid(),
rating smallint 1–5, improve text, likes text, app_version text,
platform text, created_at timestamptz default now()`.
RLS: learners may only **insert** rows for themselves; no select/update/delete.
`delete_my_account()` already removes the user, so feedback goes with it
(cascade). Admin function `admin_feedback()` (checks `_require_admin()` like
the others) returns feedback joined with name, email, level, words learned.

**Admin panel:** a "Feedback" section: average rating and count, then a table
(date, stars, what could be better, what they like, learner name/email; click
opens the existing learner drawer).

## Left to the builder

- Exact card position and copy polish within the existing Profile style.
- Text length limit enforcement (client and a `check` in SQL).
- Tests: sheet validation (no stars → Send disabled), send path with a fake
  remote, error keeps text, Play button opens the listing.
