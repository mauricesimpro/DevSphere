import 'package:shared_preferences/shared_preferences.dart';

/// Persists the small amount of configuration DevSphere needs between runs.
///
/// Right now that is just the user's display name, captured by the first-run
/// setup form and cleared again when the user signs out.
class AppConfig {
  AppConfig._(this._prefs);

  static const _nameKey = 'config.name';

  final SharedPreferences _prefs;

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig._(prefs);
  }

  /// The configured display name, or null if the app has never been set up.
  String? get name {
    final value = _prefs.getString(_nameKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Whether first-run setup has been completed.
  bool get isConfigured => name != null;

  Future<void> setName(String name) async {
    await _prefs.setString(_nameKey, name.trim());
  }

  /// Clears all stored configuration (used by "Sign out").
  Future<void> reset() async {
    await _prefs.remove(_nameKey);
  }
}
