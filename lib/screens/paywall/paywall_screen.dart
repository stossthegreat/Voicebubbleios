import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback onClose;
  
  const PaywallScreen({
    super.key,
    required this.onSubscribe,
    required this.onRestore,
    required this.onClose,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await _subscriptionService.initialize();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    final productId = SubscriptionService.monthlyProductId;

    try {
      final success = await _subscriptionService.purchaseSubscription(productId);

      if (!success) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;  // FIX processing stuck
          _errorMessage = 'Purchase failed or cancelled. Please try again.';
        });
        return;
      }

      await _waitForSubscriptionConfirmation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;  // FIX processing stuck
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _waitForSubscriptionConfirmation() async {
    for (int i = 0; i < 10; i++) {
      final hasSubscription = await _subscriptionService.hasActiveSubscription();
      if (hasSubscription) {
        if (!mounted) return;
        widget.onSubscribe();
        widget.onClose();
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() {
      _isPurchasing = false;  // FIX processing stuck
      _errorMessage =
          'Purchase taking longer than expected. If charged, tap "Restore Purchase".';
    });
  }

  Future<void> _handleRestore() async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      await _subscriptionService.restorePurchases();
      final hasSubscription = await _subscriptionService.hasActiveSubscription();

      if (hasSubscription) {
        if (!mounted) return;
        widget.onRestore();
        widget.onClose();
      } else {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'No purchases found to restore.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Failed to restore purchases. Please try again.';
      });
    }
  }

  String _pricingLine() {
    if (_isLoading) return 'Loading pricing...';

    final product = _subscriptionService.monthlyProduct;
    if (product == null) return 'Free for 1 day, then subscribe. Cancel anytime.';

    return 'Free for 1 day, then ${product.price} per month. Cancel anytime.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.75),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1565C0),
                        Color(0xFF1E88E5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Unlock Premium',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Get unlimited access to all VoiceBubble power.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 22),

                      /// Single Monthly Card (Yearly removed)
                      _buildMonthlyCard(),
                      const SizedBox(height: 18),

                      _buildFeatureRow(
                        icon: Icons.timer_rounded,
                        text: '90 minutes speech-to-text included',
                      ),
                      _buildFeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Premium AI models for better rewrites',
                      ),
                      _buildFeatureRow(
                        icon: Icons.palette_rounded,
                        text: 'Unlimited custom presets',
                      ),
                      _buildFeatureRow(
                        icon: Icons.cloud_sync_rounded,
                        text: 'Cloud sync between devices',
                      ),
                      _buildFeatureRow(
                        icon: Icons.workspace_premium_rounded,
                        text: 'Priority support',
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _pricingLine(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_errorMessage != null)
                        _buildErrorBox(),

                      _buildPrimaryButton(
                        label: _isPurchasing ? 'Processing...' : 'Subscribe',
                        onTap: _isLoading || _isPurchasing ? null : _handlePurchase,
                        filled: true,
                      ),
                      const SizedBox(height: 8),

                      _buildPrimaryButton(
                        label: 'Continue Free for 1 Day',
                        onTap: _isPurchasing ? null : widget.onClose,
                        filled: false,
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _isLoading || _isPurchasing ? null : _handleRestore,
                        child: Text(
                          'Restore Purchase',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard() {
    final monthly = _subscriptionService.monthlyProduct;
    final price = monthly?.price ?? '\$4.99';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Monthly',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
    required bool filled,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white,
            width: filled ? 0 : 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: filled ? const Color(0xFF0D47A1) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
