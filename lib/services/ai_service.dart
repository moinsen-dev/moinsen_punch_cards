import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'settings_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  GenerativeModel? _model;

  factory AiService() {
    return _instance;
  }

  AiService._internal();

  Future<void> _initModel() async {
    if (_model != null) return;

    final apiKey = await SettingsService().getGeminiApiKey();
    if (apiKey == null) throw Exception('Gemini API key not found');

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> analyzePunchCard({
    required String title,
    required List<String> operations,
    required BuildContext context,
  }) async {
    await _initModel();
    if (_model == null) throw Exception('Failed to initialize Gemini AI model');

    final prompt = '''
Analyze this punch card program:

Title: $title
Operations: ${operations.join(', ')}

Please provide:
1. A description of what the program does
2. Any potential issues or inefficiencies
3. Suggestions for improvement

Format your response in markdown.
''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    return response.text ?? 'Failed to analyze the program';
  }

  Future<Map<String, dynamic>> validateChallengeSolution({
    required String challengeTitle,
    required String challengeDescription,
    required List<String> requiredOperations,
    required List<String> programOperations,
    required BuildContext context,
  }) async {
    await _initModel();
    if (_model == null) throw Exception('Failed to initialize Gemini AI model');

    final prompt = '''
Evaluate this punch card program solution for the following challenge:

Challenge Title: $challengeTitle
Description: $challengeDescription
Required Operations: ${requiredOperations.join(', ')}

Student's Solution Operations: ${programOperations.join(', ')}

Please analyze:
1. Does the solution correctly solve the challenge? (yes/no)
2. Score the solution from 0-100
3. List what was done correctly
4. List what could be improved
5. Provide specific advice for improvement

Format your response in JSON with the following structure:
{
  "correct": true/false,
  "score": number,
  "correctPoints": ["list", "of", "correct", "things"],
  "improvementPoints": ["list", "of", "improvements"],
  "advice": "detailed advice"
}
''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);

    if (response.text == null) {
      throw Exception('Failed to validate the solution');
    }

    try {
      // Parse the JSON response
      final Map<String, dynamic> result = json.decode(response.text!);

      // Validate the required fields
      if (!result.containsKey('correct') ||
          !result.containsKey('score') ||
          !result.containsKey('correctPoints') ||
          !result.containsKey('improvementPoints') ||
          !result.containsKey('advice')) {
        throw Exception('Invalid response format from AI');
      }

      return result;
    } catch (e) {
      throw Exception('Failed to parse validation response: $e');
    }
  }
}
