# Releasing Poppylo

## App identity (do not change after the first upload)

| | Value |
|---|---|
| Android application ID | `com.poppylo.app` |
| iOS bundle ID | `com.poppylo.app` |
| Version | set `version:` in `pubspec.yaml`, e.g. `1.0.0+1` → name 1.0.0, code 1 |

**Every new upload needs a higher build number**: `1.0.0+1` → `1.0.1+2` → `1.1.0+3`…

## Signing key ⚠️ back this up

Release builds are signed with an **upload key**:

- `android/upload-keystore.jks`: the key
- `android/key.properties`: its password and alias

Both files are **git-ignored on purpose**. Never commit them or share them in chat.

**Back up both files now** to a password manager or a private, encrypted drive,
and keep a copy somewhere outside this laptop. When you enrol in
**Play App Signing** (the default), Google holds the real app-signing key, so a
lost upload key can be reset through Play support. That reset takes days, so
the backup still matters.

On a new machine, copy both files back into `android/`. Without them, release
builds fall back to the debug key, which Play Console rejects.

## Build

```bash
flutter test                        # all tests green
flutter build appbundle --release --dart-define-from-file=env.json
# → build/app/outputs/bundle/release/app-release.aab
```

Upload `app-release.aab` in Play Console.

## Icon and splash

The source PNGs are drawn in code:

```bash
flutter test tool/icon/generate_icon_test.dart   # → assets/brand/*.png
dart run flutter_launcher_icons                  # Android, iOS and web icons
dart run flutter_native_splash:create            # launch screens
```

## Play Console checklist

- **Backend:** set up Supabase first; see `docs/BACKEND_SETUP.md`.
- **Privacy policy URL:** host `docs/privacy-policy.html` (GitHub Pages,
  Netlify or your own site) and paste the URL. First fill in
  `[CONTACT EMAIL]`, `[DEVELOPER OR COMPANY NAME]`, `[DATA REGION]` and
  `[EMAIL PROVIDER]`.
- **Data safety form** (with the Supabase backend switched on):
  - Data collected:
    - **Personal info**: name (optional, from setup) and email address
      (only if the learner saves progress with email or Google);
    - **App activity**: in-app actions (learning answers and progress);
    - **App info and performance**: none;
    - **Device or other IDs**: none (the guest ID is a random account ID).
  - Purposes: **App functionality** and **Analytics**. Not shared with third
    parties, not used for ads.
  - Encrypted in transit: **Yes** (HTTPS).
  - Users can request deletion: **Yes**, in the app (Profile → Delete
    account) and by email. Play also asks for a **web link** for deletion
    requests.
  - Building *without* `env.json` makes the app offline-only again, and then
    "No data collected" applies.
- **Ads:** No.
- **Content rating:** an educational / reference app with no user-generated
  content and no violence or sexual content.
- **Target audience:** 13+ (not designed for children). This avoids the
  Families policy requirements.
- **App access:** no login is needed, so all features are available.
- **Store listing:** add this line to the full description:
  > Word data from Wiktionary, Tatoeba and FrequencyWords (CC BY-SA 4.0 /
  > CC BY 2.0 FR).
- **Testing:** new *personal* developer accounts must run a closed test
  (currently at least 12 testers for 14 days) before production access.
  Organization accounts are exempt. Check Play Console for the current rule.

## Before each release

- [ ] Bump `version:` in `pubspec.yaml`
- [ ] Update the version shown in the Profile footer
      (`lib/features/profile/profile_tab.dart`)
- [ ] `flutter test` passes
- [ ] Try the release build on a real phone: `flutter run --release`
