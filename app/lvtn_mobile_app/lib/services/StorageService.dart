import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  bool get isInitialized => _prefs != null;

  Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  Future<void> setString(String key, String value) async {
    await ensureInitialized();
    if (_prefs != null) {
      await _prefs!.setString(key, value);
    } else {
      throw Exception('StorageService chưa được khởi tạo');
    }
  }

  Future<String?> getString(String key) async {
    final value = _prefs?.getString(key);
    return value;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    return _prefs?.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return _prefs?.getBool(key);
  }

  Future<void> remove(String key) async {
    await ensureInitialized();
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }
}
