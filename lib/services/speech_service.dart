// ============================================================
//        SPEECH SERVICE - VOICE RECORDING
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize();
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    VoidCallback? onComplete,
  }) async {
    if (!_isInitialized || _isListening) return;

    _isListening = true;
    
    await _speech.listen(
      onResult: (result) {
        if (result.hasConfidenceRating && result.confidence > 0.5) {
          onResult(result.recognizedWords);
        }
        if (result.finalResult) {
          _isListening = false;
          onComplete?.call();
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speech.stop();
    _isListening = false;
  }

  Future<void> cancel() async {
    if (!_isListening) return;
    
    await _speech.cancel();
    _isListening = false;
  }
}