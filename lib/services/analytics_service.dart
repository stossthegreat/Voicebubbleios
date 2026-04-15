// ============================================================
//        ANALYTICS SERVICE - Firebase Analytics
// ============================================================
//
// Centralized analytics tracking for user events.
// Tracks all important user actions for insights.
//
// ============================================================

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================================
  // USER PROPERTIES
  // ============================================================

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({required String name, required String value}) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // ============================================================
  // RECORDING EVENTS
  // ============================================================

  Future<void> logRecordingStarted() async {
    await _analytics.logEvent(
      name: 'recording_started',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecordingCompleted({
    required int durationSeconds,
    required String presetId,
    required String language,
  }) async {
    await _analytics.logEvent(
      name: 'recording_completed',
      parameters: {
        'duration_seconds': durationSeconds,
        'preset_id': presetId,
        'language': language,
      },
    );
  }

  Future<void> logAudioFileUploaded({
    required int durationSeconds,
    required String fileType,
  }) async {
    await _analytics.logEvent(
      name: 'audio_file_uploaded',
      parameters: {
        'duration_seconds': durationSeconds,
        'file_type': fileType,
      },
    );
  }

  // ============================================================
  // AI PRESET EVENTS
  // ============================================================

  Future<void> logPresetSelected({
    required String presetId,
    required String presetName,
  }) async {
    await _analytics.logEvent(
      name: 'preset_selected',
      parameters: {
        'preset_id': presetId,
        'preset_name': presetName,
      },
    );
  }

  Future<void> logPresetFavorited({
    required String presetId,
    required bool isFavorited,
  }) async {
    await _analytics.logEvent(
      name: 'preset_favorited',
      parameters: {
        'preset_id': presetId,
        'is_favorited': isFavorited,
      },
    );
  }

  // ============================================================
  // AI OUTPUT EVENTS
  // ============================================================

  Future<void> logOutputGenerated({
    required String presetId,
    required int outputLength,
    required int generationTimeMs,
    required bool wasEnhanced,
    required int qualityScore,
  }) async {
    await _analytics.logEvent(
      name: 'output_generated',
      parameters: {
        'preset_id': presetId,
        'output_length': outputLength,
        'generation_time_ms': generationTimeMs,
        'was_enhanced': wasEnhanced,
        'quality_score': qualityScore,
      },
    );
  }

  Future<void> logOutputEdited({
    required String presetId,
  }) async {
    await _analytics.logEvent(
      name: 'output_edited',
      parameters: {
        'preset_id': presetId,
      },
    );
  }

  Future<void> logOutputShared({
    required String presetId,
    required String shareMethod,
  }) async {
    await _analytics.logEvent(
      name: 'output_shared',
      parameters: {
        'preset_id': presetId,
        'share_method': shareMethod,
      },
    );
  }

  Future<void> logRefinementUsed({
    required String refinementType,
    required String presetId,
  }) async {
    await _analytics.logEvent(
      name: 'refinement_used',
      parameters: {
        'refinement_type': refinementType,
        'preset_id': presetId,
      },
    );
  }

  Future<void> logInstructionsAdded({
    required String presetId,
    required int instructionLength,
  }) async {
    await _analytics.logEvent(
      name: 'instructions_added',
      parameters: {
        'preset_id': presetId,
        'instruction_length': instructionLength,
      },
    );
  }

  Future<void> logOutputRegenerated({
    required String presetId,
  }) async {
    await _analytics.logEvent(
      name: 'output_regenerated',
      parameters: {
        'preset_id': presetId,
      },
    );
  }

  // ============================================================
  // IMAGE TO TEXT / OCR EVENTS
  // ============================================================

  Future<void> logImageToTextUsed({
    required int characterCount,
    required bool success,
    String? source,
  }) async {
    await _analytics.logEvent(
      name: 'image_to_text_used',
      parameters: {
        'character_count': characterCount,
        'success': success,
        if (source != null) 'source': source,
      },
    );
  }

  // ============================================================
  // OUTCOME EVENTS
  // ============================================================

  Future<void> logOutcomeAssigned({
    required String outcomeType,
    required String presetId,
  }) async {
    await _analytics.logEvent(
      name: 'outcome_assigned',
      parameters: {
        'outcome_type': outcomeType,
        'preset_id': presetId,
      },
    );
  }

  Future<void> logOutcomeCompleted({
    required String outcomeType,
  }) async {
    await _analytics.logEvent(
      name: 'outcome_completed',
      parameters: {
        'outcome_type': outcomeType,
      },
    );
  }

  Future<void> logReminderSet({
    required String outcomeType,
    required int hoursFromNow,
  }) async {
    await _analytics.logEvent(
      name: 'reminder_set',
      parameters: {
        'outcome_type': outcomeType,
        'hours_from_now': hoursFromNow,
      },
    );
  }

  // ============================================================
  // PROJECT EVENTS
  // ============================================================

  Future<void> logProjectCreated() async {
    await _analytics.logEvent(name: 'project_created');
  }

  Future<void> logProjectOpened({
    required int itemCount,
  }) async {
    await _analytics.logEvent(
      name: 'project_opened',
      parameters: {
        'item_count': itemCount,
      },
    );
  }

  Future<void> logItemAddedToProject() async {
    await _analytics.logEvent(name: 'item_added_to_project');
  }

  Future<void> logContinueFromProject() async {
    await _analytics.logEvent(name: 'continue_from_project');
  }

  Future<void> logContinueFromItem() async {
    await _analytics.logEvent(name: 'continue_from_item');
  }

  // ============================================================
  // Smart actions analytics removed

  // ============================================================
  // SUBSCRIPTION EVENTS
  // ============================================================

  Future<void> logPaywallViewed() async {
    await _analytics.logEvent(name: 'paywall_viewed');
  }

  Future<void> logSubscriptionPurchased({
    required String productId,
    required String priceString,
  }) async {
    await _analytics.logEvent(
      name: 'subscription_purchased',
      parameters: {
        'product_id': productId,
        'price': priceString,
      },
    );
  }

  Future<void> logSubscriptionCancelled() async {
    await _analytics.logEvent(name: 'subscription_cancelled');
  }

  Future<void> logUsageLimitHit({
    required int secondsUsed,
    required int monthlyLimit,
  }) async {
    await _analytics.logEvent(
      name: 'usage_limit_hit',
      parameters: {
        'seconds_used': secondsUsed,
        'monthly_limit': monthlyLimit,
      },
    );
  }

  // ============================================================
  // NAVIGATION EVENTS
  // ============================================================

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  Future<void> logTabSelected({
    required String tabName,
  }) async {
    await _analytics.logEvent(
      name: 'tab_selected',
      parameters: {
        'tab_name': tabName,
      },
    );
  }

  // ============================================================
  // LANGUAGE & SETTINGS
  // ============================================================

  Future<void> logLanguageChanged({
    required String languageCode,
    required String languageName,
  }) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {
        'language_code': languageCode,
        'language_name': languageName,
      },
    );
  }

  Future<void> logLanguageFavorited({
    required String languageCode,
    required bool isFavorited,
  }) async {
    await _analytics.logEvent(
      name: 'language_favorited',
      parameters: {
        'language_code': languageCode,
        'is_favorited': isFavorited,
      },
    );
  }

  Future<void> logOverlayActivated({
    required bool isEnabled,
  }) async {
    await _analytics.logEvent(
      name: 'overlay_activated',
      parameters: {
        'is_enabled': isEnabled,
      },
    );
  }

  // ============================================================
  // ERROR TRACKING
  // ============================================================

  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? context,
  }) async {
    await _analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (context != null) 'context': context,
      },
    );
  }

  // ============================================================
  // CUSTOM EVENTS
  // ============================================================

  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters?.cast<String, Object>(),
    );
  }
}
