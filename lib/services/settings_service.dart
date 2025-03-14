import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String? getGeminiApiKey() {
    return _prefs.getString(_geminiApiKeyKey);
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    await _prefs.setString(_geminiApiKeyKey, apiKey);
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }
}
