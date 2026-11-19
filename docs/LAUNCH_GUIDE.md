# Hallo Leute: launch guide (about 3 weeks)

Five jobs stand between the app and the Play Store. Do them in this order.
Steps 1–4 take about a week; step 5 includes Google's mandatory 14-day test.

| # | Job | Who | Time | Cost |
|---|---|---|---|---|
| 0 | ✅ Domain: `halloleute.app` | Done | – | – |
| 1 | Email sender (Resend, `mail.halloleute.app`) | You | 30 min | Free |
| 2 | Google sign-in | You (setup) + Claude (test) | 1 hour | Free |
| 3 | Crash reporting | You (account) + Claude (code) | 30 min | Free |
| 4 | Word list review | Anoop / a German speaker | 2–3 evenings | Free |
| 5 | Play Store closed beta → production | You | 1 day + 14 days testing | $25 one-time |

---

## 0. Domain ✅

`halloleute.app`: add DNS records at the registrar where it was bought.

---

## 1. Email sender (SMTP): switch to halloleute.app

Already working with the earlier domain (mail.poppylo.com, tested end to end on
18 Nov 2026). To switch: add `mail.halloleute.app` in Resend, verify its DNS,
then change the sender address and email subjects in Supabase. Steps below.

## 1. Email sender (SMTP), reference

**Why:** Supabase's built-in email only sends to your own team, so learners
who tap "Continue with email" never get their code.

**Use Resend** (free: 3,000 emails a month, 100 a day, easy setup).

1. Sign up at **resend.com**.
2. **Domains → Add domain** → enter your domain → add the DNS records it shows
   at your domain provider → wait for **Verified** (usually 5–30 minutes).
3. **API Keys → Create** → copy the key (`re_...`). Don't share it in chat.
4. In Supabase → **Authentication → Emails → SMTP Settings**, turn **Enable
   custom SMTP** on and fill in:

   | Field | Value |
   |---|---|
   | Sender email | `no-reply@mail.halloleute.app` |
   | Sender name | `Hallo Leute` |
   | Host | `smtp.resend.com` |
   | Port | `465` |
   | Username | `resend` |
   | Password | your Resend API key |

5. Still in **Authentication → Emails → Templates**, edit **Magic Link**,
   **Confirm signup** and **Change Email Address**. Replace the body with:
   ```html
   <h2>Your Hallo Leute code</h2>
   <p>Enter this code in the app:</p>
   <p style="font-size:28px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
   <p>If you didn't ask for this, you can ignore this email.</p>
   ```
   Subject: `Your Hallo Leute code`
6. **Authentication → Rate Limits**: raise *emails sent per hour* to about 100.
7. **Test:** in the app, go to Profile → Continue with email → your address.
   The code should arrive within a minute (check spam the first time).

**Done when:** a 6-digit code arrives and signing in works.

---

## 2. Google sign-in

**Why:** one tap, and almost every Android user in India already has a Google
account.

1. Go to **console.cloud.google.com**, create a project named `Hallo Leute`.
2. **APIs & Services → OAuth consent screen** (Google Auth Platform):
   - App name `Hallo Leute`, support email, logo optional;
   - **App domain:** your domain, plus the privacy policy URL (step 5.1);
   - **Audience:** External → **Publish app**;
   - Scopes: only the defaults (email, profile, openid). Keeping to these
     avoids Google's longer review.
3. **Clients → Create client**, three times:

   | Type | Name | Settings |
   |---|---|---|
   | Web application | Supabase | No URIs needed. Copy the **Client ID** and **Client secret** |
   | Android | Release (upload key) | Package `com.halloleute.app`, SHA-1 `14:6B:BD:99:FF:BE:0D:9F:A4:83:BF:B1:D0:EF:87:D3:DE:82:93:B1` |
   | Android | Debug | Package `com.halloleute.app`, SHA-1 `F5:2A:32:28:F9:67:91:34:CE:71:6A:B6:4B:68:48:CF:99:1A:50:3B` |

   After your first upload to Play (step 5), add a **fourth** Android client
   with the **Play App Signing** SHA-1 from Play Console → Test and release →
   App integrity. Without it, Google sign-in fails for Play Store installs.
4. In Supabase → **Authentication → Sign In / Providers → Google**:
   - turn it on and paste the Web **Client ID** and **Client secret**;
   - in **Client IDs** (authorized), paste the Web client ID.
   - Also check that **Allow manual linking** is on.
5. In `env.json`, set `"GOOGLE_WEB_CLIENT_ID": "<the Web client ID>"`.
6. **Test:** `flutter run --dart-define-from-file=env.json`, then Profile →
   Continue with Google.

**Done when:** Google sign-in works, and in Supabase → Authentication → Users
the same user now shows a Google identity.

---

## 3. Crash reporting

**Why:** if the app crashes on someone's phone, today you never find out.

**Use Sentry** (free plan: 5,000 errors a month, no Firebase needed).

1. Sign up at **sentry.io** → **Create project** → platform **Flutter** →
   name `hallo-leute`.
2. Copy the **DSN** (it looks like `https://abc123@o123.ingest.sentry.io/456`).
3. Add it to `env.json`: `"SENTRY_DSN": "<your DSN>"`.
4. **Claude:** adds the `sentry_flutter` package, reports crashes only (no
   personal data, no screenshots), and updates the privacy policy and Data
   safety answers ("Crash logs: collected, not shared, for app stability").

**Done when:** a test crash appears in the Sentry dashboard.

---

## 4. Word list review

**Why:** 3,000 words were generated from open data. A few odd meanings
("der Baum: tree, boom") hurt trust, and nurses will judge the Pflege pack
hardest.

1. **Claude:** exports a review sheet (`docs/word_review.csv`) with the top
   500 words plus both career packs. Columns:

   | word | article | meaning | example | example (English) | OK? | Fix / comment |
   |---|---|---|---|---|---|---|

2. **Reviewer** (Anoop, a German tutor, or a nurse already in Germany) opens it
   in Google Sheets and marks each row **OK**, **Fix** (with the correction) or
   **Remove**. About 2–3 evenings.
3. **Claude:** applies the fixes through the build script (overrides and
   blocklist, so they survive future rebuilds) and rebuilds `words.json`.

Priority: **Pflege pack → IT & Büro pack → top 200 → top 500.**

---

## 5. Play Store: closed beta, then production

### 5.1 Host the two web pages Play requires

1. **Claude:** fills in the privacy policy and creates a simple
   **delete-account** page (Play requires a deletion web link).
2. Easiest hosting: **app.netlify.com/drop**. Drag the folder with
   `privacy-policy.html` and `delete-account.html` onto the page, then connect
   your domain (e.g. `halloleute.app/privacy-policy.html`). Free.
   (GitHub Pages also works, but needs a paid plan for private repos.)

### 5.2 Play Console account

1. Go to **play.google.com/console** and pay **$25** once.
   - **Personal account:** quick, but requires the 14-day closed test below.
   - **Organization account:** needs a D-U-N-S number, skips the 14-day rule.
     Only worth it if you're registering a company anyway.
2. Complete identity verification. This can take a few days, so start early.

### 5.3 Create the app and fill in "Set up your app"

- **App name:** Hallo Leute · **Default language:** English · **App** ·
  **Free**.
- **Privacy policy:** your hosted URL.
- **App access:** "All functionality available without special access".
- **Ads:** No.
- **Content rating:** questionnaire → Education/Reference, no violence and no
  user-generated content.
- **Target audience:** 13+ (not designed for children).
- **Data safety:** use the answers in `docs/RELEASE.md`, plus crash logs after
  step 3, plus notifications.
- **Data deletion:** yes; link your delete-account page.
- **Store listing:**
  - short description (80 characters), e.g. *"Learn German words fast:
    flashcards, quizzes and job vocabulary for nurses & IT."*;
  - full description, including the attribution line from `docs/RELEASE.md`;
  - app icon (512×512, from `assets/brand/app_icon.png`) and a feature graphic
    (1024×500; Claude can design one);
  - at least 4 phone screenshots (see `docs/screenshots/`).

### 5.4 Closed test (14 days)

1. **Test and release → Testing → Closed testing → Create track**.
2. Build: `flutter build appbundle --release --dart-define-from-file=env.json`,
   then upload `build/app/outputs/bundle/release/app-release.aab`.
3. **Testers:** create a Google Group (e.g. `halloleute-beta`), add the group
   in Play Console, and recruit **at least 15 people** so you stay safely
   above 12. Good sources: nursing institutes, German classes, Kerala
   WhatsApp groups, friends.
4. Share the **opt-in link**. Each tester must accept and install it.
5. **Keep at least 12 testers opted in for 14 days in a row.** Ask them to
   actually use it; Google asks about tester engagement.
6. Collect feedback (a Google Form works well). Claude fixes bugs as they come
   in, and you upload new builds with a bumped version (`1.0.0+2`, `+3`…).
7. **Add the Play App Signing SHA-1 to Google Cloud** (step 2.3).

### 5.5 Production

1. After 14 days: **Dashboard → Apply for production**, then answer the
   questions about your testing and feedback.
2. Once approved, promote the tested build to **Production**. Start with a
   **20% staged rollout** and watch Sentry for 2–3 days, then go to 100%.

---

## Checklist

- [x] 0 · Domain: halloleute.app
- [ ] 1 · Resend switched to mail.halloleute.app, Supabase sender + templates updated, code arrives
- [ ] 2 · Google OAuth clients made, Supabase Google provider on, `env.json` updated, works
- [ ] 3 · Sentry project made, DSN in `env.json`, Claude integrated it
- [ ] 4 · Review sheet exported, reviewed, fixes applied
- [ ] 5.1 · Privacy policy and delete-account page live on your domain
- [ ] 5.2 · Play Console account verified
- [ ] 5.3 · App created, all "Set up your app" tasks done
- [ ] 5.4 · Closed test running with 12+ testers for 14 days
- [ ] 5.4 · Play App Signing SHA-1 added to Google Cloud
- [ ] 5.5 · Production approved, staged rollout started

**Never paste into chat:** API keys (Resend, Google client secret), the Sentry
auth token, passwords, or the keystore. Put them straight into the dashboards
or into `env.json`.
