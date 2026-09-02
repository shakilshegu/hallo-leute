/// Build-time configuration.
///
/// The default targets the deployed coffee-meet-api on Cloud Run, so a plain
/// `flutter build apk` produces a shareable build. Override for local work
/// with a dart-define:
///
/// ```
/// # Android emulator against a local API on port 3001
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api/v1
/// # iOS simulator / desktop
/// flutter run --dart-define=API_BASE_URL=http://localhost:3001/api/v1
/// # physical device on the same wifi as your Mac
/// flutter run --dart-define=API_BASE_URL=http://<your-mac-lan-ip>:3001/api/v1
/// ```
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://coffee-meet-api-967267012189.asia-south1.run.app/api/v1',
  );
}
