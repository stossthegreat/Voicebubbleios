import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum RefinementType {
  shorten,
  expand,
  casual,
  professional,
  fixGrammar,
  translate,
}

class RefinementService {
  // Backend URL - same as AIService
  static const String _backendUrl = 'https://voicebubble-production.up.railway.app';
  
  final Dio _dio = Dio();
  
  RefinementService() {
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }
  
  /// Refine text with user-initiated action
  /// IMPORTANT: User must click button to trigger this
  Future<String> refineText(String text, RefinementType type, {String? targetLanguage}) async {
    try {
      // Map refinement type to special preset ID
      String presetId;
      switch (type) {
        case RefinementType.shorten:
          presetId = '_refine_shorten';
          break;
        case RefinementType.expand:
          presetId = '_refine_expand';
          break;
        case RefinementType.casual:
          presetId = '_refine_casual';
          break;
        case RefinementType.professional:
          presetId = '_refine_professional';
          break;
        case RefinementType.fixGrammar:
          presetId = '_refine_grammar';
          break;
        case RefinementType.translate:
          presetId = '_refine_translate_${targetLanguage ?? 'en'}';
          break;
      }
      
      debugPrint('🎨 Refining text with type: $presetId');
      
      final response = await _dio.post(
        '$_backendUrl/api/rewrite/batch',
        data: {
          'text': text,
          'presetId': presetId,
          'language': targetLanguage ?? 'en',
        },
      );
      
      final refined = response.data['text'] ?? text;
      debugPrint('✅ Refinement complete');
      return refined;
    } catch (e) {
      debugPrint('❌ Refinement error: $e');
      throw Exception('Failed to refine text: $e');
    }
  }
  
  /// Shorten text - cuts by ~50%, keeps core message
  Future<String> shorten(String text) async {
    return await refineText(text, RefinementType.shorten);
  }
  
  /// Expand text - adds more detail and depth
  Future<String> expand(String text) async {
    return await refineText(text, RefinementType.expand);
  }
  
  /// Make casual - friendlier tone
  Future<String> makeCasual(String text) async {
    return await refineText(text, RefinementType.casual);
  }
  
  /// Make professional - formal tone
  Future<String> makeProfessional(String text) async {
    return await refineText(text, RefinementType.professional);
  }
  
  /// Fix grammar - keeps exact wording, only fixes mistakes
  Future<String> fixGrammar(String text) async {
    return await refineText(text, RefinementType.fixGrammar);
  }
  
  /// Translate to target language
  Future<String> translate(String text, String targetLanguage) async {
    return await refineText(text, RefinementType.translate, targetLanguage: targetLanguage);
  }
  
  /// Custom refinement with user instruction
  Future<String> customRefine(String text, String instruction) async {
    try {
      debugPrint('🎨 Custom refining with instruction: $instruction');
      
      final response = await _dio.post(
        '$_backendUrl/api/rewrite/batch',
        data: {
          'text': text,
          'presetId': 'magic', // Use magic preset for flexible refinement
          'language': 'auto',
          'customInstruction': instruction,
        },
      );
      
      final refined = response.data['text'] ?? text;
      debugPrint('✅ Custom refinement complete');
      return refined;
    } catch (e) {
      debugPrint('❌ Custom refinement error: $e');
      throw Exception('Failed to refine text: $e');
    }
  }
}
