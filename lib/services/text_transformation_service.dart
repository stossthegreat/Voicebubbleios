import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// ============================================================
//        TEXT TRANSFORMATION SERVICE
// ============================================================
//
// Handles all AI text transformations for the select text menu.
// This is where the magic happens - turning selected text into gold.
//
// ============================================================

class TextTransformationService {
  static const String _baseUrl = 'https://voicebubble-backend.onrender.com';
  
  /// Transform selected text using AI
  Future<String> transformText({
    required String text,
    required String action,
    String? context,
    String? language,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transform/text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'action': action,
          'context': context ?? '',
          'language': language ?? 'auto',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transformedText'] ?? text;
      } else {
        debugPrint('❌ Transform API error: ${response.statusCode}');
        throw Exception('Failed to transform text: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Transform service error: $e');
      rethrow;
    }
  }

  /// Rewrite text to be clearer and more engaging
  Future<String> rewriteText(String text, {String? context}) async {
    return transformText(
      text: text,
      action: 'rewrite',
      context: context,
    );
  }

  /// Expand text with more details and examples
  Future<String> expandText(String text, {String? context}) async {
    return transformText(
      text: text,
      action: 'expand',
      context: context,
    );
  }

  /// Shorten text while keeping key points
  Future<String> shortenText(String text, {String? context}) async {
    return transformText(
      text: text,
      action: 'shorten',
      context: context,
    );
  }

  /// Make text more professional and formal
  Future<String> makeProfessional(String text, {String? context}) async {
    return transformText(
      text: text,
      action: 'professional',
      context: context,
    );
  }

  /// Make text more casual and friendly
  Future<String> makeCasual(String text, {String? context}) async {
    return transformText(
      text: text,
      action: 'casual',
      context: context,
    );
  }

  /// Translate text to specified language
  Future<String> translateText(String text, String targetLanguage, {String? context}) async {
    return transformText(
      text: text,
      action: 'translate',
      context: context,
      language: targetLanguage,
    );
  }

  /// Get available languages for translation
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'it', 'name': 'Italian'},
      {'code': 'pt', 'name': 'Portuguese'},
      {'code': 'ru', 'name': 'Russian'},
      {'code': 'ja', 'name': 'Japanese'},
      {'code': 'ko', 'name': 'Korean'},
      {'code': 'zh', 'name': 'Chinese'},
      {'code': 'ar', 'name': 'Arabic'},
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'nl', 'name': 'Dutch'},
      {'code': 'sv', 'name': 'Swedish'},
      {'code': 'no', 'name': 'Norwegian'},
      {'code': 'da', 'name': 'Danish'},
    ];
  }
}