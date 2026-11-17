/// Backend settings, passed at build time so no secrets live in the code:
///
///   flutter run --dart-define-from-file=env.json
///   flutter build apk --release --dart-define-from-file=env.json
///
/// See `env.example.json`. Without them the app runs fully offline
/// (local progress only, no accounts), exactly as before.
abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The project's public "publishable" key (formerly "anon" key). Safe in
  /// the app: row level security protects each learner's data.
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Google Cloud OAuth client id of type "Web application". Android uses
  /// it as `serverClientId` so Supabase can verify the Google ID token.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get googleConfigured => googleWebClientId.isNotEmpty;
}
