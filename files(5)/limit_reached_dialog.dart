import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';
import 'review_dialog.dart';

/// Dialog shown when user reaches their STT/AI limit
class LimitReachedDialog extends StatelessWidget {
  final bool hasReviewBonus;
  final bool isPro;
  final int remainingSeconds;

  const LimitReachedDialog({
    super.key,
    required this.hasReviewBonus,
    required this.isPro,
    required this.remainingSeconds,
  });

  /// Show the limit reached dialog
  static Future<void> show(BuildContext context) async {
    final usageService = UsageService();
    final subService = SubscriptionService();
    
    final isPro = await subService.isPro();
    final hasReviewBonus = await usageService.hasClaimedReviewBonus();
    final remaining = await usageService.getRemainingSeconds(isPro: isPro);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LimitReachedDialog(
        hasReviewBonus: hasReviewBonus,
        isPro: isPro,
        remainingSeconds: remaining,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);
    const warningColor = Color(0xFFEF4444);
    const greenColor = Color(0xFF10B981);

    final canGetBonus = !isPro && !hasReviewBonus;

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_off,
              color: warningColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Time Limit Reached',
            style: TextStyle(
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
          Text(
            isPro
                ? 'You\'ve used all 90 minutes of STT & AI this month.'
                : 'You\'ve used all ${hasReviewBonus ? '6' : '5'} minutes of free STT & AI.',
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Options
          if (canGetBonus) ...[
            // Review bonus option
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await ReviewDialog.showForFreeUser(context);
              },
              child: Container(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Get 1 extra minute FREE',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Leave a review',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: greenColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Upgrade option
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '90 minutes + Unlimited Highlight AI',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Not Now',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      ],
    );
  }
}
