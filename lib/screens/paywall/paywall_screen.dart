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

    try {
      final success = await _subscriptionService.purchaseSubscription(
        SubscriptionService.monthlyProductId,
      );

      if (!success) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'Purchase cancelled or failed.';
        });
        return;
      }

      // Wait for backend confirming subscription
      for (int i = 0; i < 8; i++) {
        final has = await _subscriptionService.hasActiveSubscription();
        if (has) {
          widget.onSubscribe();
          widget.onClose();
          return;
        }
        await Future.delayed(const Duration(milliseconds: 700));
      }

      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Purchase delayed. If charged, tap Restore Purchase.';
      });

    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Error. Try again.';
      });
    }
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
        widget.onRestore();
        widget.onClose();
      } else {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'No purchases found.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Failed to restore.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _subscriptionService.monthlyProduct;
    final price = monthly?.price ?? '\$4.99';

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.65),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                      Color(0xFF1E88E5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      spreadRadius: 2,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// TITLE
                    const Text(
                      'Unlock Premium',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// PRICE CARD
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Monthly',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// FEATURES
                    _feature('90 minutes speech-to-text included'),
                    _feature('Premium rewrite quality'),
                    _feature('Unlimited custom presets'),
                    _feature('Cloud sync'),
                    _feature('Priority support'),

                    const SizedBox(height: 12),

                    /// DESCRIPTION
                    Text(
                      'Free for 1 day, then $price/month.\nCancel anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    /// SUBSCRIBE
                    _button(
                      label: _isPurchasing ? 'Processing...' : 'Subscribe',
                      onTap: _isPurchasing ? null : _handlePurchase,
                      filled: true,
                    ),
                    const SizedBox(height: 8),

                    /// FREE
                    _button(
                      label: 'Continue Free for 1 Day',
                      onTap: _isPurchasing ? null : widget.onClose,
                      filled: false,
                    ),
                    const SizedBox(height: 6),

                    /// RESTORE
                    TextButton(
                      onPressed: _isPurchasing ? null : _handleRestore,
                      child: Text(
                        'Restore Purchase',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required bool filled,
    required String label,
    required VoidCallback? onTap,
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
              fontWeight: FontWeight.w800,
              color: filled ? const Color(0xFF0D47A1) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
