import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Tracks STT and AI usage for free/pro limits
/// FREE: 5 minutes (300 seconds) + 1 minute bonus for review
/// PRO: 90 minutes (5400 seconds)
///
/// Usage is stored locally in Hive AND backed up to Firestore.
/// Firestore sync is FIRE-AND-FORGET — it never blocks the main flow.
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
  /// Saves to Hive immediately, then syncs to Firestore in background
  Future<void> addUsage(int seconds) async {
    final box = await Hive.openBox(_boxName);
    final monthKey = _getCurrentMonthKey();
    final current = box.get('stt_seconds_$monthKey', defaultValue: 0);
    final newTotal = current + seconds;
    await box.put('stt_seconds_$monthKey', newTotal);

    // ✅ FIRE-AND-FORGET: Sync to Firestore in background — NEVER await this
    _syncUsageToFirestore(newTotal);
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

  /// Claim the review bonus (adds 1 minute)
  Future<bool> claimReviewBonus() async {
    final box = await Hive.openBox(_boxName);
    final alreadyClaimed = box.get('review_bonus_claimed', defaultValue: false);

    if (alreadyClaimed) return false;

    await box.put('review_bonus_claimed', true);
    await box.put('review_bonus_claimed_at', DateTime.now().toIso8601String());

    // ✅ FIRE-AND-FORGET: Sync to Firestore in background
    _syncReviewBonusToFirestore(true);
    return true;
  }

  /// Should we prompt for review? (after using 3+ minutes, and not yet claimed)
  Future<bool> shouldShowReviewPrompt({required bool isPro}) async {
    if (isPro) return false;
    final claimed = await hasClaimedReviewBonus();
    if (claimed) return false;
    final used = await getSecondsUsed();
    return used >= 180; // After 3 minutes of use
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

  /// Get the current month key (e.g., "2026_2" for February 2026)
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}_${now.month}';
  }

  // ══════════════════════════════════════════════════════════
  // FIRESTORE SYNC — ALL FIRE-AND-FORGET, NEVER BLOCKS
  // ══════════════════════════════════════════════════════════

  /// Get current Firebase user ID, or null if not logged in
  String? _getUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      debugPrint('⚠️ UsageService: Could not get user ID: $e');
      return null;
    }
  }

  /// Get the Firestore document reference for this user's usage
  DocumentReference? _getUserUsageDoc() {
    final uid = _getUserId();
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Sync usage seconds to Firestore (FIRE-AND-FORGET — never await this)
  void _syncUsageToFirestore(int totalSeconds) {
    try {
      final doc = _getUserUsageDoc();
      if (doc == null) return; // Not logged in, skip

      final monthKey = _getCurrentMonthKey();

      // Don't await — fire and forget
      doc.set({
        'usage': {
          'stt_seconds_$monthKey': totalSeconds,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('⚠️ UsageService: Firestore usage sync failed (non-critical): $e');
      });
    } catch (e) {
      debugPrint('⚠️ UsageService: Firestore usage sync error (non-critical): $e');
    }
  }

  /// Sync review bonus status to Firestore (FIRE-AND-FORGET)
  void _syncReviewBonusToFirestore(bool claimed) {
    try {
      final doc = _getUserUsageDoc();
      if (doc == null) return;

      doc.set({
        'usage': {
          'review_bonus_claimed': claimed,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('⚠️ UsageService: Firestore bonus sync failed (non-critical): $e');
      });
    } catch (e) {
      debugPrint('⚠️ UsageService: Firestore bonus sync error (non-critical): $e');
    }
  }

  /// Load usage from Firestore on app start (call once in main.dart)
  /// Takes the HIGHER of local vs server to prevent abuse
  Future<void> syncFromFirestore() async {
    try {
      final doc = _getUserUsageDoc();
      if (doc == null) return; // Not logged in, skip

      final snapshot = await doc.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Firestore timeout'),
      );

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || data['usage'] == null) return;

      final usage = data['usage'] as Map<String, dynamic>;
      final monthKey = _getCurrentMonthKey();
      final serverSeconds = usage['stt_seconds_$monthKey'] as int? ?? 0;
      final serverBonusClaimed = usage['review_bonus_claimed'] as bool? ?? false;

      // Take the HIGHER value to prevent abuse
      final box = await Hive.openBox(_boxName);
      final localSeconds = box.get('stt_seconds_$monthKey', defaultValue: 0) as int;

      if (serverSeconds > localSeconds) {
        await box.put('stt_seconds_$monthKey', serverSeconds);
        debugPrint('📊 UsageService: Synced from Firestore: $serverSeconds seconds (was $localSeconds locally)');
      }

      if (serverBonusClaimed) {
        final localClaimed = box.get('review_bonus_claimed', defaultValue: false) as bool;
        if (!localClaimed) {
          await box.put('review_bonus_claimed', true);
          debugPrint('📊 UsageService: Synced review bonus claimed from Firestore');
        }
      }
    } catch (e) {
      // NEVER crash on sync failure — local data is always the fallback
      debugPrint('⚠️ UsageService: syncFromFirestore failed (non-critical): $e');
    }
  }
}
