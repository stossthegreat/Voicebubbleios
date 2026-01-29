import 'dart:convert';
// Force re-commit to sync to GitHub
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============================================================
//        AI TEXT TRANSFORMATION SERVICE
// ============================================================
//
// Deadly precise AI text transformations for the viral
// Select Text → AI Actions feature.
//
// ============================================================

class AITextTransformationService {
  static final AITextTransformationService _instance = AITextTransformationService._internal();
  factory AITextTransformationService() => _instance;
  AITextTransformationService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://voicebubble-backend.onrender.com';

  Future<String> transformText({
    required String text,
    required String action,
    String? targetLanguage,
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
          'targetLanguage': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transformedText'] ?? text;
      } else {
        throw Exception('Failed to transform text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error transforming text: $e');
    }
  }

  Future<String> rewriteText(String text) async {
    return await transformText(text: text, action: 'rewrite');
  }

  Future<String> expandText(String text) async {
    return await transformText(text: text, action: 'expand');
  }

  Future<String> shortenText(String text) async {
    return await transformText(text: text, action: 'shorten');
  }

  Future<String> makeProfessional(String text) async {
    return await transformText(text: text, action: 'professional');
  }

  Future<String> makeCasual(String text) async {
    return await transformText(text: text, action: 'casual');
  }

  Future<String> makePowerful(String text) async {
    return await transformText(text: text, action: 'powerful');
  }

  Future<String> translateText(String text, String targetLanguage) async {
    return await transformText(text: text, action: 'translate', targetLanguage: targetLanguage);
  }
}