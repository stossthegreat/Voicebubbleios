import 'package:flutter/material.dart';
import 'dart:async';
import '../services/usage_service.dart';
import '../services/subscription_service.dart';
import '../screens/paywall_screen.dart';

/// Countdown timer showing remaining STT time
/// Place this at the top of the recording screen, above the waveform
class STTCountdownTimer extends StatefulWidget {
  final bool isRecording;
  final VoidCallback? onLimitReached;

  const STTCountdownTimer({
    super.key,
    this.isRecording = false,
    this.onLimitReached,
  });

  @override
  State<STTCountdownTimer> createState() => _STTCountdownTimerState();
}

class _STTCountdownTimerState extends State<STTCountdownTimer> {
  final UsageService _usageService = UsageService();
  final SubscriptionService _subService = SubscriptionService();

  int _remainingSeconds = 300; // Default 5 min
  int _totalLimit = 300;
  bool _isPro = false;
  bool _isLoading = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(STTCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start/stop countdown based on recording state
    if (widget.isRecording && !oldWidget.isRecording) {
      _startCountdown();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final isPro = await _subService.isPro();
    final remaining = await _usageService.getRemainingSeconds(isPro: isPro);
    final total = await _usageService.getTotalLimit(isPro: isPro);

    setState(() {
      _isPro = isPro;
      _remainingSeconds = remaining;
      _totalLimit = total;
      _isLoading = false;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // Limit reached!
        timer.cancel();
        widget.onLimitReached?.call();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 40);
    }

    final percentage = _remainingSeconds / _totalLimit;
    final isLow = percentage < 0.2;
    final isCritical = percentage < 0.1;

    // Colors
    Color timerColor;
    if (isCritical) {
      timerColor = const Color(0xFFEF4444); // Red
    } else if (isLow) {
      timerColor = const Color(0xFFF59E0B); // Orange
    } else {
      timerColor = _isPro ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6); // Gold for pro, blue for free
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaywallScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer icon with animation when recording
            if (widget.isRecording)
              _buildPulsingIcon(timerColor)
            else
              Icon(Icons.timer, color: timerColor, size: 18),

            const SizedBox(width: 8),

            // Time remaining
            Text(
              _formatTime(_remainingSeconds),
              style: TextStyle(
                color: timerColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(width: 8),

            // Label
            Text(
              'remaining',
              style: TextStyle(
                color: timerColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),

            // Pro badge
            if (_isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Upgrade hint for free users
            if (!_isPro) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: timerColor.withOpacity(0.5),
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 500),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.timer, color: color, size: 18),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted && widget.isRecording) {
          setState(() {});
        }
      },
    );
  }
}

/// Compact version - just the time
class STTCountdownCompact extends StatefulWidget {
  final bool isRecording;

  const STTCountdownCompact({
    super.key,
    this.isRecording = false,
  });

  @override
  State<STTCountdownCompact> createState() => _STTCountdownCompactState();
}

class _STTCountdownCompactState extends State<STTCountdownCompact> {
  final UsageService _usageService = UsageService();
  final SubscriptionService _subService = SubscriptionService();

  int _remainingSeconds = 300;
  bool _isPro = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(STTCountdownCompact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startCountdown();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isPro = await _subService.isPro();
    final remaining = await _usageService.getRemainingSeconds(isPro: isPro);
    setState(() {
      _isPro = isPro;
      _remainingSeconds = remaining;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _remainingSeconds < 60;
    final color = isLow 
        ? const Color(0xFFEF4444) 
        : (_isPro ? const Color(0xFFF59E0B) : Colors.white70);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
