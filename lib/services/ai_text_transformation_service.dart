import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============================================================
//        AI TEXT TRANSFORMATION SERVICE
// ============================================================
//
// Deadly precise AI text transformations.
// Elite prompts that deliver stunning results.
//
// ============================================================

class AITextTransformationService {
  static final AITextTransformationService _instance = AITextTransformationService._internal();
  factory AITextTransformationService() => _instance;
  AITextTransformationService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  /// Transform text with deadly precision
  Future<String> transformText(
    String text,
    String action, {
    String? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transform-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'action': action,
          'context': context ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transformedText'] ?? text;
      } else {
        throw Exception('Failed to transform text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Translate text to target language
  Future<String> translateText(String text, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/translate-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'targetLanguage': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] ?? text;
      } else {
        throw Exception('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get available languages for translation
  Future<List<String>> getAvailableLanguages() async {
    return [
      'Spanish', 'French', 'German', 'Italian', 'Portuguese',
      'Chinese', 'Japanese', 'Korean', 'Arabic', 'Russian',
      'Dutch', 'Swedish', 'Norwegian', 'Danish', 'Finnish'
    ];
  }
}