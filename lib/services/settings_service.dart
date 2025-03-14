import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  SharedPreferences? _prefs;

  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _themeModeKey = 'theme_mode';

  // Factory constructor to return the singleton instance
  factory SettingsService() {
    return _instance;
  }

  // Private constructor
  SettingsService._internal();

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getGeminiApiKey() async {
    await init();
    return _prefs?.getString(_geminiApiKeyKey);
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    await init();
    await _prefs?.setString(_geminiApiKeyKey, apiKey);
    notifyListeners();
  }

  Future<ThemeMode> getThemeMode() async {
    await init();
    final value = _prefs?.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await init();
    await _prefs?.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }
}
