import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/usage_service.dart';
import '../services/subscription_service.dart';

/// Dialog to ask for app review
/// - Free users: Shown when 5 min exhausted, offers 1 min bonus
/// - Pro users: Shown after upgrade to say thanks
class ReviewDialog extends StatelessWidget {
  final bool isFreeUser;
  final VoidCallback? onReviewComplete;

  const ReviewDialog({
    super.key,
    required this.isFreeUser,
    this.onReviewComplete,
  });

  /// Show review dialog for free user (with bonus)
  static Future<bool?> showForFreeUser(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReviewDialog(isFreeUser: true),
    );
  }

  /// Show review dialog for pro user (thank you)
  static Future<bool?> showForProUser(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const ReviewDialog(isFreeUser: false),
    );
  }

  Future<void> _openReview() async {
    // Replace with your actual app store URLs
    const androidUrl = 'https://play.google.com/store/apps/details?id=com.voicebubble.app';
    const iosUrl = 'https://apps.apple.com/app/voicebubble/id123456789';
    
    // Try to open the appropriate store
    try {
      // You can use Platform.isAndroid / Platform.isIOS to pick the right one
      final uri = Uri.parse(androidUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);
    const accentColor = Color(0xFFF59E0B);
    const greenColor = Color(0xFF10B981);

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
        children: [
          // Stars animation placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star,
                  color: accentColor,
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            isFreeUser ? 'Enjoying VoiceBubble?' : 'Thank You! 🎉',
            style: const TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFreeUser) ...[
            // Free user - offer bonus
            const Text(
              'You\'ve used your 5 minutes of free STT & AI.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    greenColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greenColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: greenColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: greenColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get 1 extra minute FREE!',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Leave a review and we\'ll add 1 minute to your account.',
                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Pro user - thank you message
            const Text(
              'Thanks for upgrading to Pro! We\'d love to hear your feedback.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you mind leaving us a review? It helps us grow and improve the app for everyone.',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (isFreeUser)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No Thanks',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        if (!isFreeUser)
          TextButton(
            onPressed: () async {
              await SubscriptionService().markAskedForReviewAfterUpgrade();
              if (context.mounted) Navigator.pop(context, false);
            },
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        ElevatedButton(
          onPressed: () async {
            // Open review
            await _openReview();
            
            if (isFreeUser) {
              // Claim the bonus
              final claimed = await UsageService().claimReviewBonus();
              if (claimed) {
                debugPrint('✅ Review bonus claimed - 1 minute added');
              }
            } else {
              // Mark that pro user left review
              await SubscriptionService().markLeftReview();
              await SubscriptionService().markAskedForReviewAfterUpgrade();
            }
            
            if (context.mounted) {
              Navigator.pop(context, true);
              
              // Show confirmation for free users
              if (isFreeUser) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('🎉 1 extra minute added to your account!'),
                      ],
                    ),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
            
            onReviewComplete?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFreeUser ? greenColor : primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rate_review, size: 18),
              const SizedBox(width: 8),
              Text(
                isFreeUser ? 'Leave Review & Get Bonus' : 'Leave a Review',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Check and show review dialog if appropriate
Future<void> checkAndShowReviewDialog(BuildContext context) async {
  final usageService = UsageService();
  final subService = SubscriptionService();
  
  final isPro = await subService.isPro();
  
  if (isPro) {
    // Pro user - check if we should ask for review after upgrade
    final hasAsked = await subService.hasAskedForReviewAfterUpgrade();
    if (!hasAsked && context.mounted) {
      await ReviewDialog.showForProUser(context);
    }
  } else {
    // Free user - check if they've hit limit and haven't claimed bonus
    final shouldShow = await usageService.shouldShowReviewPrompt(isPro: false);
    if (shouldShow && context.mounted) {
      await ReviewDialog.showForFreeUser(context);
    }
  }
}
