import 'package:flutter/material.dart';
import 'usage_service.dart';
import 'subscription_service.dart';
import '../widgets/upgrade_dialog.dart';
import '../widgets/review_dialog.dart';
import '../screens/paywall_screen.dart';

/// Central place to check feature access and show appropriate dialogs
class FeatureGate {
  static final UsageService _usageService = UsageService();
  static final SubscriptionService _subService = SubscriptionService();

  /// Check if user can use STT/AI recording
  /// Returns true if allowed, false if blocked (and shows dialog)
  static Future<bool> canUseSTT(BuildContext context) async {
    final isPro = await _subService.isPro();
    final canUse = await _usageService.canUseSTT(isPro: isPro);

    if (!canUse) {
      // Check if should show review prompt first (free users)
      final shouldShowReview = await _usageService.shouldShowReviewPrompt(isPro: isPro);
      
      if (shouldShowReview && context.mounted) {
        // Show review dialog with bonus offer
        final didReview = await ReviewDialog.showForFreeUser(context);
        
        if (didReview == true) {
          // User reviewed, check again if they have time now
          return await _usageService.canUseSTT(isPro: isPro);
        }
      }

      // Show upgrade dialog
      if (context.mounted) {
        final shouldUpgrade = await UpgradeDialog.show(
          context,
          reason: isPro 
              ? 'You\'ve used all 90 minutes this month.' 
              : 'You\'ve used all ${await _usageService.hasClaimedReviewBonus() ? '6' : '5'} minutes of free STT & AI.',
        );

        if (shouldUpgrade == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
        }
      }
      return false;
    }

    return true;
  }

  /// Check if user can use Highlight AI (Pro only)
  /// Returns true if allowed, false if blocked (and shows dialog)
  static Future<bool> canUseHighlightAI(BuildContext context) async {
    final isPro = await _subService.isPro();

    if (!isPro) {
      if (context.mounted) {
        final shouldUpgrade = await UpgradeDialog.show(
          context,
          title: 'Pro Feature',
          reason: 'Highlight AI is a Pro feature. Upgrade to select text and transform it with AI.',
        );

        if (shouldUpgrade == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
        }
      }
      return false;
    }

    return true;
  }

  /// Check if user can export audio (counts against STT limit)
  /// Returns true if allowed, false if blocked
  static Future<bool> canExportAudio(BuildContext context, int durationSeconds) async {
    final isPro = await _subService.isPro();
    final remaining = await _usageService.getRemainingSeconds(isPro: isPro);

    if (remaining < durationSeconds) {
      if (context.mounted) {
        final shouldUpgrade = await UpgradeDialog.show(
          context,
          reason: 'Not enough time remaining to export this audio. You need ${_usageService.formatTime(durationSeconds)} but only have ${_usageService.formatTime(remaining)} left.',
        );

        if (shouldUpgrade == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
        }
      }
      return false;
    }

    return true;
  }

  /// Track STT usage after recording
  static Future<void> trackSTTUsage(int seconds) async {
    await _usageService.addUsage(seconds);
  }

  /// Track audio export usage
  static Future<void> trackAudioExport(int seconds) async {
    await _usageService.addUsage(seconds);
  }

  /// Get current subscription status
  static Future<bool> isPro() async {
    return await _subService.isPro();
  }

  /// Get remaining seconds
  static Future<int> getRemainingSeconds() async {
    final isPro = await _subService.isPro();
    return await _usageService.getRemainingSeconds(isPro: isPro);
  }

  /// Show review dialog if appropriate (call after successful actions)
  static Future<void> maybeShowReviewDialog(BuildContext context) async {
    await checkAndShowReviewDialog(context);
  }
}

// ============================================================
// INTEGRATION EXAMPLES - Copy these into your existing files
// ============================================================

/*
// ═══════════════════════════════════════════════════════════
// 1. RECORDING SCREEN - Before starting recording
// ═══════════════════════════════════════════════════════════

// In recording_screen.dart, in _startRecording():

Future<void> _startRecording() async {
  // CHECK ACCESS FIRST
  final canUse = await FeatureGate.canUseSTT(context);
  if (!canUse) return; // Dialog already shown
  
  // ... existing recording logic ...
}


// ═══════════════════════════════════════════════════════════
// 2. RECORDING SCREEN - After stopping recording
// ═══════════════════════════════════════════════════════════

// In recording_screen.dart, in _stopRecording():

Future<void> _stopRecording() async {
  // ... existing stop logic ...
  
  // TRACK USAGE
  final durationSeconds = _recordingDuration.inSeconds;
  await FeatureGate.trackSTTUsage(durationSeconds);
  
  // ... continue to transcription ...
}


// ═══════════════════════════════════════════════════════════
// 3. RICH TEXT EDITOR - Before showing AI menu
// ═══════════════════════════════════════════════════════════

// In rich_text_editor.dart, in _showAIMenu():

Future<void> _showAIMenu() async {
  // CHECK PRO ACCESS FIRST
  final canUse = await FeatureGate.canUseHighlightAI(context);
  if (!canUse) return; // Dialog already shown
  
  // ... existing AI menu logic ...
}


// ═══════════════════════════════════════════════════════════
// 4. EXPORT - Before exporting audio
// ═══════════════════════════════════════════════════════════

// In export logic:

Future<void> _exportAudio(int audioDurationSeconds) async {
  // CHECK ACCESS FIRST
  final canExport = await FeatureGate.canExportAudio(context, audioDurationSeconds);
  if (!canExport) return; // Dialog already shown
  
  // TRACK USAGE
  await FeatureGate.trackAudioExport(audioDurationSeconds);
  
  // ... existing export logic ...
}


// ═══════════════════════════════════════════════════════════
// 5. SETTINGS SCREEN - Add usage widget
// ═══════════════════════════════════════════════════════════

// In settings_screen.dart:

import '../widgets/usage_display_widget.dart';

// In build(), add this widget:
const UsageDisplayWidget(),


// ═══════════════════════════════════════════════════════════
// 6. HOME/RECORD SCREEN - Show compact usage
// ═══════════════════════════════════════════════════════════

// In recording_screen.dart header:

import '../widgets/usage_display_widget.dart';

// Add to app bar or header:
UsageDisplayCompact(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    );
  },
),

*/
