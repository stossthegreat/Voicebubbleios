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
    _initStore();
  }

  Future<void> _initStore() async {
    try {
      await _subscriptionService.initialize();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing) return;
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final success = await _subscriptionService
          .purchaseSubscription(SubscriptionService.monthlyProductId);

      if (!success) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'Purchase not completed.';
        });
        return;
      }

      // Wait for confirmation
      for (int i = 0; i < 6; i++) {
        final active = await _subscriptionService.hasActiveSubscription();
        if (active) {
          widget.onSubscribe();
          widget.onClose();
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      setState(() {
        _isPurchasing = false;
        _errorMessage =
            'Processing… If it succeeded, tap “Restore Purchase”.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Something went wrong.';
      });
    }
  }

  Future<void> _handleRestore() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    try {
      await _subscriptionService.restorePurchases();
      final active = await _subscriptionService.hasActiveSubscription();
      if (active) {
        widget.onRestore();
        widget.onClose();
        return;
      }
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'No purchases found.';
      });
    } catch (_) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Restore failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _subscriptionService.monthlyProduct;
    final price = monthly?.price ?? "\$4.99";

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.70),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
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
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),

                // TITLE
                const Text(
                  'Unlock Premium',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Full access to everything VoiceBubble offers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // PRICE
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Monthly Plan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free for 1 day, cancel anytime',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // FEATURES
                _feature(Icons.timer_rounded, '90 mins speech-to-text'),
                _feature(Icons.auto_awesome_rounded, 'Premium rewrite quality'),
                _feature(Icons.palette_rounded, 'Unlimited custom presets'),
                _feature(Icons.cloud_sync_rounded, 'Cloud sync'),
                _feature(Icons.workspace_premium_rounded, 'Priority support'),
                const SizedBox(height: 18),

                // ERROR
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // SUBSCRIBE
                _button(
                  label: _isPurchasing ? 'Processing…' : 'Subscribe',
                  filled: true,
                  onTap: _isLoading || _isPurchasing ? null : _handlePurchase,
                ),
                const SizedBox(height: 10),

                // CONTINUE FREE
                _button(
                  label: 'Continue Free for 1 Day',
                  filled: false,
                  onTap: _isPurchasing ? null : widget.onClose,
                ),
                const SizedBox(height: 10),

                // RESTORE
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
    );
  }

  Widget _feature(IconData icon, String text) {
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
            child: Icon(icon, size: 18, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(width: 10),
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

  Widget _button({
    required String label,
    required bool filled,
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
          border: Border.all(color: Colors.white, width: filled ? 0 : 2),
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
