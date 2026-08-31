/// Build-time configuration.
///
/// The default targets a locally-running coffee-meet-api as seen from the
/// Android emulator (`10.0.2.2` is the host machine, `3001` is the API port).
/// Override for other setups with a dart-define:
///
/// ```
/// # iOS simulator / desktop
/// flutter run --dart-define=API_BASE_URL=http://localhost:3001/api/v1
/// # physical device on the same wifi
/// flutter run --dart-define=API_BASE_URL=http://<your-mac-lan-ip>:3001/api/v1
/// ```
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001/api/v1',
  );
}
