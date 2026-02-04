import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../widgets/review_dialog.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1; // 0 = monthly, 1 = yearly, 2 = lifetime
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Monthly',
      'price': '\$4.99',
      'period': '/month',
      'savings': null,
      'popular': false,
    },
    {
      'name': 'Yearly',
      'price': '\$29.99',
      'period': '/year',
      'savings': 'Save 50%',
      'popular': true,
    },
    {
      'name': 'Lifetime',
      'price': '\$79.99',
      'period': 'one-time',
      'savings': 'Best Value',
      'popular': false,
    },
  ];

  Future<void> _purchase() async {
    setState(() => _isLoading = true);

    try {
      final subService = SubscriptionService();
      
      // TODO: Replace with actual in-app purchase logic
      // For now, simulate purchase
      await Future.delayed(const Duration(seconds: 1));

      switch (_selectedPlan) {
        case 0:
          await subService.activateMonthly();
          break;
        case 1:
          await subService.activateYearly();
          break;
        case 2:
          await subService.activateLifetime();
          break;
      }

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('🎉 Welcome to VoiceBubble Pro!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );

        // Ask for review after small delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          await ReviewDialog.showForProUser(context);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);
    const accentColor = Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: secondaryTextColor),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Restore purchases
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Restoring purchases...'),
                          backgroundColor: primaryColor,
                        ),
                      );
                    },
                    child: const Text(
                      'Restore',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Pro badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'VoiceBubble Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Headline
                    const Text(
                      'Unlock Your Full\nVoice Potential',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Features
                    _buildFeature(
                      icon: Icons.timer,
                      title: '90 Minutes STT & AI',
                      subtitle: 'vs 5 minutes on free',
                      color: primaryColor,
                    ),
                    _buildFeature(
                      icon: Icons.auto_awesome,
                      title: 'Unlimited Highlight AI',
                      subtitle: 'Select text → AI magic',
                      color: const Color(0xFF8B5CF6),
                    ),
                    _buildFeature(
                      icon: Icons.support_agent,
                      title: 'Priority Support',
                      subtitle: 'Get help when you need it',
                      color: const Color(0xFF10B981),
                    ),
                    _buildFeature(
                      icon: Icons.rocket_launch,
                      title: 'Early Access',
                      subtitle: 'New features first',
                      color: accentColor,
                    ),

                    const SizedBox(height: 32),

                    // Plans
                    ...List.generate(_plans.length, (index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPlan == index;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPlan = index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.15) : surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Radio
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? primaryColor : secondaryTextColor,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              
                              // Plan details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          plan['name'],
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (plan['popular']) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'POPULAR',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (plan['savings'] != null)
                                      Text(
                                        plan['savings'],
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    plan['price'],
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    plan['period'],
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _purchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms
                    Text(
                      'Cancel anytime. Recurring billing. Terms apply.',
                      style: TextStyle(
                        color: secondaryTextColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 20,
          ),
        ],
      ),
    );
  }
}
