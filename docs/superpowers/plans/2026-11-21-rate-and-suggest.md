# Rate & Suggest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Learners rate the app (1–5 stars) and send suggestions from the Profile tab; the owner reads them in the admin panel; everyone gets a "Rate on Google Play" button.

**Architecture:** A `feedback` table in Supabase (insert-only for learners, read through an admin-only function). The app gets a small `FeedbackRemote` (abstract + Supabase implementation) used by a `FeedbackCard` and `FeedbackSheet` on the Profile tab. The admin panel (`admin/index.html`) gets a Feedback section.

**Tech Stack:** Flutter (Dart), supabase_flutter, url_launcher (new), Postgres migrations, plain HTML/JS admin panel.

**Spec:** `docs/superpowers/specs/2026-11-21-rate-and-suggest-design.md`

## Global Constraints

- Learners may only **insert** their own feedback; no select/update/delete for them.
- Feedback is deleted with the account (`on delete cascade` to `auth.users`).
- Stars 1–5 required; both texts optional, max **1000** characters each (client and SQL `check`).
- The Play button is **never** tied to the star rating (no review gating). Shown on Android only.
- Play listing: `market://details?id=com.halloleute.app`, fallback `https://play.google.com/store/apps/details?id=com.halloleute.app`.
- Success copy: `Danke! We read every message.`
- No personal data beyond what the learner types (plus user id, app version, platform).
- Follow existing styles: `AppColors`, `AppText`, bottom sheet look of `_EmailSheet` in `lib/features/profile/account_card.dart`.

## Review Focus

- **Offline / insert fails:** sheet stays open, text kept, friendly error shown. (Task 3 test `send failure keeps text and shows error`.)
- **Double tap on Send:** only one row inserted. (Task 3 test `send button disabled while sending`.)
- **Only spaces typed:** stored as null, not empty strings. (Task 2 test `blank texts become null`.)
- **No session yet (guest never created, e.g. offline at onboarding):** remote calls `ensureSession` before insert. (Task 2 test `ensures a session before inserting`.)
- **Learner tries to read feedback via the API:** returns nothing. (Task 1 SQL check.)

---

### Task 1: Database: `feedback` table and `admin_feedback()`

**Files:**
- Create: `supabase/migrations/20261121120000_feedback.sql`

**Interfaces:**
- Produces: table `public.feedback(id uuid pk default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users on delete cascade, rating smallint not null check (rating between 1 and 5), improve text check (char_length(improve) <= 1000), likes text check (char_length(likes) <= 1000), app_version text, platform text, created_at timestamptz not null default now())`.
- Produces: `public.admin_feedback() returns table (id uuid, user_id uuid, name text, email text, is_guest boolean, level text, rating smallint, improve text, likes text, app_version text, platform text, created_at timestamptz)`, newest first, `perform public._require_admin()` first, `security definer`, `set search_path = ''`, joined with `admin.learners` (same pattern as `admin_learners()` in `20261117120000_practice_modes_and_admin.sql:98`).

- [ ] **Step 1:** Write the migration: table, `enable row level security`, one policy `"add own feedback"` `for insert to authenticated with check (user_id = auth.uid())`, `revoke all on public.feedback from anon`, the admin function with `revoke all … from public, anon; grant execute … to authenticated`.
- [ ] **Step 2:** Apply it to project `brfgzkrvxspeqvysceqj` with the Supabase `apply_migration` tool (name `feedback`).
- [ ] **Step 3: Verify RLS.** Run with `execute_sql`, inside a transaction that is rolled back:
  ```sql
  begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"a8e9d57d-5ff3-404c-bc95-5f558c88fb1f","role":"authenticated"}';
  insert into public.feedback (rating, improve) values (5, 'rls test');
  select count(*) from public.feedback;   -- expected: 0 (no select policy)
  rollback;
  ```
  Expected: insert succeeds, count is 0. Also `select * from public.admin_feedback();` as that non-admin user raises the `_require_admin` error.
- [ ] **Step 4:** Run `get_advisors` (security); expected: no new warning about `feedback`.
- [ ] **Step 5: Commit** `supabase/migrations/20261121120000_feedback.sql` — "Feedback table (insert-only) and admin_feedback()".

### Task 2: `FeedbackRemote`

**Files:**
- Create: `lib/data/remote/feedback_remote.dart`
- Create: `lib/app_info.dart`
- Modify: `lib/features/profile/profile_tab.dart:188` (footer uses `AppInfo.version`)
- Test: `test/feedback_remote_test.dart`

**Interfaces:**
- Produces: `abstract final class AppInfo { static const version = '1.0.0'; }` (single source for the footer and feedback rows).
- Produces: `class FeedbackEntry { const FeedbackEntry({required int rating, String? improve, String? likes}); Map<String, Object?> toRow({required String appVersion, required String platform}); }` — `toRow` trims texts and turns blank ones into `null`; keys `rating, improve, likes, app_version, platform`.
- Produces: `abstract class FeedbackRemote { Future<void> send(FeedbackEntry entry); }`
- Produces: `class SupabaseFeedbackRemote implements FeedbackRemote { SupabaseFeedbackRemote(SupabaseClient client, {required Future<void> Function() ensureSession}); }` — calls `ensureSession()`, then `client.from('feedback').insert(entry.toRow(appVersion: AppInfo.version, platform: defaultTargetPlatform.name))`.

- [ ] **Step 1: Failing tests** in `test/feedback_remote_test.dart`:
  - `blank texts become null`: `FeedbackEntry(rating: 4, improve: '  ', likes: ' Words ').toRow(appVersion: '1.0.0', platform: 'android')` equals `{'rating': 4, 'improve': null, 'likes': 'Words', 'app_version': '1.0.0', 'platform': 'android'}`.
  - `ensures a session before inserting`: a real client can't be used in tests, so `SupabaseFeedbackRemote` takes an optional `Future<void> Function(Map<String, Object?> row)? insert` (defaults to the client insert). Record calls from a fake `ensureSession` and `insert`; assert the order is `[ensureSession, insert]` and `insert` got the row from `toRow`.
- [ ] **Step 2:** `flutter test test/feedback_remote_test.dart` → FAIL (files missing).
- [ ] **Step 3:** Implement the interfaces above; footer reads `'Hallo Leute · v${AppInfo.version}'`.
- [ ] **Step 4:** `flutter test test/feedback_remote_test.dart` → PASS; `flutter analyze` → No issues.
- [ ] **Step 5: Commit** — "FeedbackRemote: send rating and suggestions".

### Task 3: Profile card, feedback sheet, Play button

**Files:**
- Create: `lib/features/profile/feedback_card.dart` (`FeedbackCard`, private `_FeedbackSheet`, `_Stars`)
- Modify: `lib/features/profile/profile_tab.dart` (after the `PopupsCard` block: `if (auth != null) ...[FeedbackCard(remote: SupabaseFeedbackRemote(auth.client, ensureSession: auth.ensureGuest)), const SizedBox(height: 16)]`)
- Modify: `pubspec.yaml` (add `url_launcher` via `flutter pub add url_launcher`)
- Test: `test/feedback_card_test.dart`

**Interfaces:**
- Consumes: `FeedbackRemote`, `FeedbackEntry` (Task 2).
- Produces: `class FeedbackCard extends StatelessWidget { const FeedbackCard({super.key, required FeedbackRemote remote, Future<bool> Function(Uri)? openUrl, bool? showPlayButton}); }` — `openUrl` defaults to `launchUrl` (external app mode); `showPlayButton` defaults to `defaultTargetPlatform == TargetPlatform.android`.

Copy (exact): card title `Enjoying Hallo Leute?`, body `Rate the app and tell us what to improve.`, buttons `Send feedback` and `Rate on Google Play`. Sheet title `How do you like Hallo Leute?`, fields `What could be better?` and `What do you like?` (multi-line, `maxLength: 1000`), button `Send` (`Sending…` while busy). Stars are 5 tappable icons with semantics labels `1 star` … `5 stars`.

- [ ] **Step 1: Failing widget tests** (fake `FeedbackRemote` recording entries; optional `Completer` to hold a send open; optional error to throw):
  - `send is disabled until a star is chosen`: open sheet, tap `Send` → fake received nothing; tap `4 stars`, enter `More audio` in `What could be better?`, tap `Send` → fake received `FeedbackEntry` with rating 4, improve `More audio`; sheet closed; `Danke! We read every message.` shown.
  - `send button disabled while sending`: with a pending completer, tap `Send` twice → one entry recorded.
  - `send failure keeps text and shows error`: fake throws → sheet still open, typed text still present, an error text containing `try again` shown.
  - `play button opens the store listing for everyone`: `showPlayButton: true`, tap `Rate on Google Play` → `openUrl` called with `market://details?id=com.halloleute.app`; when it returns false, called again with the https fallback.
  - `play button hidden off Android`: `showPlayButton: false` → `Rate on Google Play` not found.
- [ ] **Step 2:** `flutter test test/feedback_card_test.dart` → FAIL.
- [ ] **Step 3:** Implement `FeedbackCard` and the sheet in the style of `AccountCard`/`_EmailSheet`; insert it in `ProfileTab`; `flutter pub add url_launcher`.
- [ ] **Step 4:** `flutter test` (all) → PASS; `flutter analyze` → No issues.
- [ ] **Step 5: Commit** — "Profile: rate & suggest card, Rate on Google Play".

### Task 4: Admin panel Feedback section

**Files:**
- Modify: `admin/index.html` (section after "All learners", before "Hardest words"; load in `loadAll()` with `db.rpc('admin_feedback')`)

**Interfaces:**
- Consumes: `admin_feedback()` (Task 1).

- [ ] **Step 1:** Add `<h2>Feedback <span class="muted" id="feedbackSummary"></span></h2>` and `<div class="card scroll"><table id="feedback"></table></div>`; add `renderFeedback(rows)`: summary `★ {average to 1 decimal} · {count} messages` (or `No feedback yet.`); table columns Date (`fmtDate`), Stars (`★` repeated), What could be better, What they like, Learner (name + email, `Guest` tag); every text through `esc()`; row click calls `openLearner(user_id)` when that learner is in `learners`.
- [ ] **Step 2: Verify:** insert one test row as your own user via `execute_sql` (rating 5, improve `Test from Claude`), open `admin/index.html` locally signed in as admin, confirm the row and summary show; delete the test row afterwards.
- [ ] **Step 3: Commit** — "Admin: feedback section".

### Task 5: End-to-end check on the emulator

- [ ] **Step 1:** Restart `flutter run -d emulator-5554 --dart-define-from-file=env.json`; Profile → `Send feedback` → 3 stars + text → Send.
- [ ] **Step 2:** `execute_sql`: `select rating, improve, likes, app_version, platform from public.feedback order by created_at desc limit 1;` → the row just sent, `app_version` `1.0.0`, `platform` `android`.
- [ ] **Step 3:** Tap `Rate on Google Play` → Play Store (or browser) opens on the listing.
- [ ] **Step 4:** Update `docs/superpowers/specs/2026-11-21-rate-and-suggest-design.md` status to `built`; commit.
