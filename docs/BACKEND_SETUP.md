# Backend setup (Supabase): about 30 minutes

The app already contains all the code. Until these steps are done it runs
offline as before. Once `env.json` exists, every learner is tracked.

## 1. Create the project

1. Go to **supabase.com**, sign up and click **New project**.
   Region: **Mumbai (ap-south-1)**, closest to Kerala.
2. In **Project Settings → API Keys**, copy:
   - the **Project URL** (`https://xxxx.supabase.co`);
   - the **Publishable key** (`sb_publishable_…`). Never use the *secret* key
     in the app.

## 2. Create the tables

1. Open **SQL Editor → New query**.
2. Paste all of `supabase/migrations/20261117000000_learner_tracking.sql`
   and click **Run**.
3. Check that **Table Editor** shows `profiles`, `word_progress`,
   `daily_activity` and `answer_events`.

## 3. Turn on guest accounts

**Authentication → Sign In / Providers → Allow anonymous sign-ins → ON.**

This is what lets every learner be tracked from their first launch.

## 4. Email sign-in with a 6-digit code

1. **Authentication → Sign In / Providers → Email**: enabled, with
   *Confirm email* ON.
2. **Authentication → Emails → Templates.** In **each** of these templates,
   **Magic Link**, **Confirm signup** and **Change Email Address**, add the
   code so learners can type it in the app:
   ```html
   <h2>Your Poppylo code</h2>
   <p>Enter this code in the app: <strong>{{ .Token }}</strong></p>
   ```
3. **Set up your own email sender (SMTP).** ⚠️ Supabase's built-in email only
   sends to your own team's addresses and is heavily rate-limited, so real
   learners would never get their code.
   - In **Authentication → Emails → SMTP Settings**, add a provider.
     **Resend** and **Brevo** both have free tiers.
   - Use a sender like `no-reply@yourdomain.com`.

## 5. Google sign-in (optional but recommended)

1. Go to **console.cloud.google.com** and create a project called
   "Poppylo".
2. Under **APIs & Services → OAuth consent screen**, choose External, set the
   app name "Poppylo", add your support email and publish it.
3. Under **Credentials → Create credentials → OAuth client ID**:
   - **Web application** (name "Supabase"). Copy its **Client ID** and
     **Client secret**.
   - **Android**, once per signing key, all with package name
     **`com.poppylo.app`**:

     | Key | SHA-1 |
     |---|---|
     | Upload key (release builds, APKs) | `14:6B:BD:99:FF:BE:0D:9F:A4:83:BF:B1:D0:EF:87:D3:DE:82:93:B1` |
     | Debug key (this laptop, `flutter run`) | `F5:2A:32:28:F9:67:91:34:CE:71:6A:B6:4B:68:48:CF:99:1A:50:3B` |
     | Play App Signing key | copy it from **Play Console → Setup → App signing** after the first upload |

4. In Supabase, go to **Authentication → Sign In / Providers → Google**:
   - turn it ON;
   - paste the **Web** client ID and secret;
   - in **Client IDs** (authorized client IDs), paste the Web client ID too.
5. **Authentication → Sign In / Providers →** turn on **Allow manual
   linking**. This lets a guest attach Google to their existing account.

## 6. Connect the app

Copy `env.example.json` to **`env.json`** in the project root (git ignores it)
and fill it in:

```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_...",
  "GOOGLE_WEB_CLIENT_ID": "1234-abc.apps.googleusercontent.com"
}
```

Then always build with it:

```bash
flutter run --dart-define-from-file=env.json
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json
```

Leave `GOOGLE_WEB_CLIENT_ID` empty to hide the Google button. Email sign-in
still works.

## 7. Check it works

1. Run the app, finish onboarding and do one lesson.
2. In Supabase, **Authentication → Users** shows a new **Anonymous** user.
3. In **Table Editor**, `answer_events` has your answers (within a few seconds).
4. In the app, go to **Profile → Save your progress → Continue with email**,
   enter the code, and the same user now shows your email.
5. Use **SQL Editor** with `supabase/admin_queries.sql` to see every learner,
   the words each one learned, daily activity and the hardest words.

## How the tracking works

| Table | What's in it |
|---|---|
| `auth.users` | Every learner. `is_anonymous = true` for guests. |
| `profiles` | Name, level, daily goal, reasons for learning |
| `word_progress` | One row per learner per word: learned date, level (box 1–5), next review, times seen / correct / again |
| `daily_activity` | Per learner per day: new words, reviews, misses |
| `answer_events` | Every single answer with a timestamp (full history) |

- The app saves on the phone first and uploads a few seconds later. Offline
  answers wait in a queue, which survives restarts.
- Row level security means each learner can only ever read their own rows.
- The `admin.*` views (all learners, learned words, hardest words) are not
  reachable from the app, only from the dashboard.
- **Profile → Delete account** removes the learner and all their rows
  (required by Google Play).

## Before the Play Store release

- Host the updated `docs/privacy-policy.html`. It now covers the server data.
- Update the **Data safety** form; see `docs/RELEASE.md`.
- Play also needs an **account deletion web link**. A simple page saying
  "Open the app → Profile → Delete account, or email us" is enough.
- Consider turning on **CAPTCHA** (Authentication → Attack Protection) if
  bots start creating guest accounts.
