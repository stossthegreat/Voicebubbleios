import 'package:hive_flutter/hive_flutter.dart';

/// Tracks STT and AI usage for free/pro limits
/// FREE: 5 minutes (300 seconds) + 1 minute bonus for review
/// PRO: 90 minutes (5400 seconds)
class UsageService {
  static const String _boxName = 'usage_data';
  static const int freeSecondsLimit = 300;      // 5 minutes
  static const int proSecondsLimit = 5400;      // 90 minutes
  static const int reviewBonusSeconds = 60;     // 1 minute bonus for review

  // Singleton
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  /// Get total seconds used this month
  Future<int> getSecondsUsed() async {
    final box = await Hive.openBox(_boxName);
    final monthKey = _getCurrentMonthKey();
    return box.get('stt_seconds_$monthKey', defaultValue: 0);
  }

  /// Add seconds to usage (call after recording/export)
  Future<void> addUsage(int seconds) async {
    final box = await Hive.openBox(_boxName);
    final monthKey = _getCurrentMonthKey();
    final current = box.get('stt_seconds_$monthKey', defaultValue: 0);
    await box.put('stt_seconds_$monthKey', current + seconds);
  }

  /// Check if user can use STT/AI
  Future<bool> canUseSTT({required bool isPro}) async {
    final used = await getSecondsUsed();
    final limit = await getTotalLimit(isPro: isPro);
    return used < limit;
  }

  /// Get remaining seconds
  Future<int> getRemainingSeconds({required bool isPro}) async {
    final used = await getSecondsUsed();
    final limit = await getTotalLimit(isPro: isPro);
    return (limit - used).clamp(0, limit);
  }

  /// Get total limit including review bonus
  Future<int> getTotalLimit({required bool isPro}) async {
    if (isPro) return proSecondsLimit;

    final hasReviewBonus = await hasClaimedReviewBonus();
    return freeSecondsLimit + (hasReviewBonus ? reviewBonusSeconds : 0);
  }

  /// Check if user has claimed review bonus
  Future<bool> hasClaimedReviewBonus() async {
    final box = await Hive.openBox(_boxName);
    return box.get('review_bonus_claimed', defaultValue: false);
  }

  /// Claim review bonus (only works once, only for free users)
  Future<bool> claimReviewBonus() async {
    final box = await Hive.openBox(_boxName);
    final alreadyClaimed = box.get('review_bonus_claimed', defaultValue: false);

    if (alreadyClaimed) return false;

    await box.put('review_bonus_claimed', true);
    await box.put('review_bonus_claimed_at', DateTime.now().toIso8601String());
    return true;
  }

  /// Check if user has exhausted free limit (to show review prompt)
  Future<bool> shouldShowReviewPrompt({required bool isPro}) async {
    if (isPro) return false;

    final hasBonus = await hasClaimedReviewBonus();
    if (hasBonus) return false; // Already claimed

    final used = await getSecondsUsed();
    return used >= freeSecondsLimit; // Show when 5 min exhausted
  }

  /// Format seconds to MM:SS display
  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Format for display like "4:30 / 5:00"
  Future<String> getUsageDisplayString({required bool isPro}) async {
    final used = await getSecondsUsed();
    final limit = await getTotalLimit(isPro: isPro);
    return '${formatTime(used)} / ${formatTime(limit)}';
  }

  /// Get percentage used (0.0 to 1.0)
  Future<double> getUsagePercentage({required bool isPro}) async {
    final used = await getSecondsUsed();
    final limit = await getTotalLimit(isPro: isPro);
    return (used / limit).clamp(0.0, 1.0);
  }

  /// Reset usage (for testing or admin)
  Future<void> resetUsage() async {
    final box = await Hive.openBox(_boxName);
    final monthKey = _getCurrentMonthKey();
    await box.put('stt_seconds_$monthKey', 0);
  }

  /// Reset review bonus (for testing)
  Future<void> resetReviewBonus() async {
    final box = await Hive.openBox(_boxName);
    await box.put('review_bonus_claimed', false);
    await box.delete('review_bonus_claimed_at');
  }

  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}_${now.month}';
  }
}
