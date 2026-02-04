import 'package:hive_flutter/hive_flutter.dart';

/// Manages subscription/pro status
class SubscriptionService {
  static const String _boxName = 'subscription';

  // Singleton
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Check if user is pro (and not expired)
  Future<bool> isPro() async {
    final box = await Hive.openBox(_boxName);
    final isPro = box.get('is_pro', defaultValue: false);
    
    if (!isPro) return false;
    
    final expiryString = box.get('expiry_date');
    if (expiryString == null) return false;
    
    try {
      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Set pro status with expiry date
  Future<void> setPro(bool value, {DateTime? expiryDate}) async {
    final box = await Hive.openBox(_boxName);
    await box.put('is_pro', value);
    
    if (expiryDate != null) {
      await box.put('expiry_date', expiryDate.toIso8601String());
    }
    
    if (value) {
      await box.put('upgraded_at', DateTime.now().toIso8601String());
    }
  }

  /// Get expiry date
  Future<DateTime?> getExpiryDate() async {
    final box = await Hive.openBox(_boxName);
    final expiryString = box.get('expiry_date');
    
    if (expiryString == null) return null;
    
    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  /// Get days remaining in subscription
  Future<int> getDaysRemaining() async {
    final expiry = await getExpiryDate();
    if (expiry == null) return 0;
    
    final now = DateTime.now();
    if (now.isAfter(expiry)) return 0;
    
    return expiry.difference(now).inDays;
  }

  /// Check if user has asked for review after upgrading
  Future<bool> hasAskedForReviewAfterUpgrade() async {
    final box = await Hive.openBox(_boxName);
    return box.get('asked_review_after_upgrade', defaultValue: false);
  }

  /// Mark that we asked for review after upgrade
  Future<void> markAskedForReviewAfterUpgrade() async {
    final box = await Hive.openBox(_boxName);
    await box.put('asked_review_after_upgrade', true);
  }

  /// Check if user left a review
  Future<bool> hasLeftReview() async {
    final box = await Hive.openBox(_boxName);
    return box.get('has_left_review', defaultValue: false);
  }

  /// Mark that user left a review
  Future<void> markLeftReview() async {
    final box = await Hive.openBox(_boxName);
    await box.put('has_left_review', true);
    await box.put('review_left_at', DateTime.now().toIso8601String());
  }

  /// Activate monthly subscription
  Future<void> activateMonthly() async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await setPro(true, expiryDate: expiry);
  }

  /// Activate yearly subscription
  Future<void> activateYearly() async {
    final expiry = DateTime.now().add(const Duration(days: 365));
    await setPro(true, expiryDate: expiry);
  }

  /// Activate lifetime subscription
  Future<void> activateLifetime() async {
    // Set expiry far in the future (100 years)
    final expiry = DateTime.now().add(const Duration(days: 36500));
    await setPro(true, expiryDate: expiry);
  }

  /// Cancel subscription (for testing/admin)
  Future<void> cancelSubscription() async {
    final box = await Hive.openBox(_boxName);
    await box.put('is_pro', false);
    await box.delete('expiry_date');
  }

  /// Get subscription status for display
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final isPro = await this.isPro();
    final expiry = await getExpiryDate();
    final daysRemaining = await getDaysRemaining();
    
    return {
      'isPro': isPro,
      'expiryDate': expiry,
      'daysRemaining': daysRemaining,
      'statusText': isPro 
          ? (daysRemaining > 365 ? 'Lifetime' : '$daysRemaining days remaining')
          : 'Free',
    };
  }
}
