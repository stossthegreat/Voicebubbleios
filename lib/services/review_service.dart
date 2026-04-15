import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'analytics_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const String _keyCompletionCount = 'outcome_completion_count';
  static const String _keyReviewRequested = 'review_requested';
  static const String _keyLastRequestDate = 'last_review_request_date';

  static const int _completionsForReview = 5;
  static const int _daysBetweenRequests = 90;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Track an outcome completion and potentially trigger review
  Future<void> trackOutcomeCompletion() async {
    final prefs = await SharedPreferences.getInstance();

    final currentCount = prefs.getInt(_keyCompletionCount) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_keyCompletionCount, newCount);

    debugPrint('ReviewService: Outcome completions: $newCount');

    if (newCount == _completionsForReview) {
      await _maybeRequestReview(prefs);
    }
  }

  /// Request review if conditions are met
  Future<void> _maybeRequestReview(SharedPreferences prefs) async {
    final hasRequested = prefs.getBool(_keyReviewRequested) ?? false;

    if (hasRequested) {
      final lastRequestMillis = prefs.getInt(_keyLastRequestDate) ?? 0;
      final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestMillis);
      final daysSince = DateTime.now().difference(lastRequest).inDays;

      if (daysSince < _daysBetweenRequests) {
        debugPrint('ReviewService: Too soon to request review ($daysSince days)');
        return;
      }
    }

    if (await _inAppReview.isAvailable()) {
      debugPrint('ReviewService: Triggering review request');

      AnalyticsService().logCustomEvent(
        eventName: 'review_prompt_shown',
        parameters: {
          'trigger': 'fifth_completion',
        },
      );

      await _inAppReview.requestReview();

      await prefs.setBool(_keyReviewRequested, true);
      await prefs.setInt(_keyLastRequestDate, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_keyCompletionCount, 0);
    } else {
      debugPrint('ReviewService: In-app review not available');
    }
  }

  /// Get current completion count (for debugging)
  Future<int> getCompletionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletionCount) ?? 0;
  }
}
