import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _geminiApiKeyKey = 'gemini_api_key';

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
  }
}
