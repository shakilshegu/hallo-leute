import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key-value storage on the device. No database, no network.
///
/// Values are JSON strings, so the same data could later be synced to a
/// server without changing its shape.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Device storage (SharedPreferences: NSUserDefaults on iOS, a private XML
/// file on Android). Removed when the app is uninstalled or its data cleared.
class PrefsStore implements KeyValueStore {
  PrefsStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static PrefsStore create() => PrefsStore(SharedPreferencesAsync());

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory store for tests and previews.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
