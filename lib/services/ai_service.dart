import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

import 'settings_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  GenerativeModel? _model;

  factory AiService() {
    return _instance;
  }

  AiService._internal();

  void _initializeModel(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: apiKey,
    );
  }

  Future<String> analyzePunchCard({
    required String title,
    required List<String> operations,
    required BuildContext context,
  }) async {
    try {
      final settingsService =
          Provider.of<SettingsService>(context, listen: false);
      final apiKey = settingsService.getGeminiApiKey();

      if (apiKey == null || apiKey.isEmpty) {
        return 'Please set your Gemini API key in the settings first.';
      }

      // Initialize or update model if API key changed
      _initializeModel(apiKey);

      final prompt = '''
Analyze this punch card program and explain what it does:

Card Title: $title
Operations:
${operations.join('\n')}

Context:
- Rows Y (0) and X (1) are used for coordinates
- Rows 2-11 represent numbers 0-9
- Multiple holes in a column can represent complex instructions
- Basic operations include LOAD, STORE, ADD, JMP, etc.

Please provide a detailed explanation of:
1. The overall purpose of this punch card program
2. The sequence of operations being performed
3. Any patterns or special instructions you notice
4. Potential output or results
''';

      final content = [Content.text(prompt)];
      final response = await _model?.generateContent(content);
      return response?.text ?? 'No analysis available';
    } catch (e) {
      return 'Error analyzing punch card: $e';
    }
  }
}
