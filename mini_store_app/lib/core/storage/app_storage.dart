import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] so features depend on a small,
/// app-owned API instead of the plugin directly.
///
/// No feature keys belong here; callers own their key names and values.
class AppStorage {
  AppStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<AppStorage> create() async {
    return AppStorage(await SharedPreferences.getInstance());
  }

  T? read<T>(String key) {
    final value = _preferences.get(key);
    return value is T ? value : null;
  }

  Future<bool> write<T extends Object>(String key, T value) {
    return switch (value) {
      String stringValue => _preferences.setString(key, stringValue),
      bool boolValue => _preferences.setBool(key, boolValue),
      int intValue => _preferences.setInt(key, intValue),
      double doubleValue => _preferences.setDouble(key, doubleValue),
      List<String> listValue => _preferences.setStringList(key, listValue),
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unsupported storage value type: ${value.runtimeType}',
      ),
    };
  }

  bool containsKey(String key) => _preferences.containsKey(key);

  Future<bool> remove(String key) => _preferences.remove(key);

  Future<bool> clear() => _preferences.clear();

  Set<String> get keys => _preferences.getKeys();
}
