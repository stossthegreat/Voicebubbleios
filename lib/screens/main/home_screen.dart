import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../../providers/app_state_provider.dart';
import '../../constants/presets.dart';
import '../../constants/languages.dart';
import '../../models/preset.dart';
import '../../services/native_overlay_service.dart';
import '../main/recording_screen.dart';
import '../main/preset_selection_screen.dart';
import '../main/vault_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _overlayEnabled = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOverlayStatus();
    _initializeOverlay();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      // App resumed (user came back from settings)
      debugPrint('📱 App resumed, checking overlay status...');
      
      final isActive = await NativeOverlayService.isActive();
      final hasPermission = await NativeOverlayService.checkPermission();
      
      debugPrint('Service active: $isActive, Permission granted: $hasPermission');
      
      // If we have permission but service isn't running, start it
      if (hasPermission && !isActive) {
        debugPrint('🚀 Auto-starting service after permission grant...');
        final started = await NativeOverlayService.showOverlay();
        if (started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Bubble activated! Look on the left side'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      await _checkOverlayStatus();
    }
  }
  
  Future<void> _checkOverlayStatus() async {
    if (Platform.isAndroid) {
      // Check whether overlay permission itself is granted
      final hasPermission = await NativeOverlayService.checkPermission();
      debugPrint('📊 Overlay permission granted: $hasPermission');
      setState(() {
        _overlayEnabled = hasPermission;
      });
    }
  }
  
  Future<void> _initializeOverlay() async {
    if (Platform.isAndroid) {
      // Initial check uses permission state, not service state
      final hasPermission = await NativeOverlayService.checkPermission();
      debugPrint('📊 Initial overlay check - permission granted: $hasPermission');
      setState(() {
        _overlayEnabled = hasPermission;
      });
    }
  }
  
  Future<void> _toggleOverlay() async {
    if (!Platform.isAndroid) return;
    
    if (_overlayEnabled) {
      // Stop the overlay service
      debugPrint('🛑 Stopping overlay service...');
      await NativeOverlayService.hideOverlay();
      setState(() {
        _overlayEnabled = false;
      });
      debugPrint('✅ Overlay service stopped');
    } else {
      // Check if we have overlay permission
      debugPrint('🔍 Checking overlay permission...');
      final hasPermission = await NativeOverlayService.checkPermission();
      debugPrint('Permission status: $hasPermission');
      
      if (!hasPermission) {
        // Request overlay permission
        debugPrint('📱 Requesting overlay permission...');
        
        // Show instruction dialog FIRST
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Enable Overlay Permission'),
              content: const Text(
                'To use the floating bubble:\n\n'
                '1. Find "VoiceBubble" in the list\n'
                '2. Turn ON "Allow display over other apps"\n'
                '3. Press back to return here\n\n'
                'Tap OK to open settings now.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        
        await NativeOverlayService.requestPermission();
        
        // Give user time to enable permission
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if permission was granted
        final permissionGranted = await NativeOverlayService.checkPermission();
        debugPrint('Permission granted: $permissionGranted');
        
        if (permissionGranted && mounted) {
          // Start the overlay service
          debugPrint('🚀 Starting overlay service...');
          final started = await NativeOverlayService.showOverlay();
          debugPrint('Service started: $started');
          
          setState(() {
            _overlayEnabled = started;
          });
          
          if (started && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Bubble activated! Close and reopen app to refresh status.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // We have permission, start the overlay service
        debugPrint('🚀 Starting overlay service (permission already granted)...');
        final started = await NativeOverlayService.showOverlay();
        debugPrint('Service started: $started');
        
        setState(() {
          _overlayEnabled = started;
        });
        
        if (started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Bubble activated! Close and reopen app to refresh status.'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 4),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to start bubble service'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = const Color(0xFF000000); // Always black
    final surfaceColor = const Color(0xFF1A1A1A); // Dark gray for cards
    final textColor = Colors.white; // Always white text
    final secondaryTextColor = const Color(0xFF94A3B8); // Light gray
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header
              Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VoiceBubble',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Tap to speak',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                          if (Platform.isAndroid && _overlayEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Overlay Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Vault Button
                      Consumer<AppStateProvider>(
                        builder: (context, appState, _) {
                          return Stack(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(48),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const VaultScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.archive_outlined,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              if (appState.archivedItems.isNotEmpty)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9333EA),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Text(
                                        appState.archivedItems.length > 9
                                            ? '9+'
                                            : appState.archivedItems.length.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Settings Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.settings_outlined,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Android Overlay Toggle Banner
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _overlayEnabled
                          ? [const Color(0xFF10B981), const Color(0xFF14B8A6)]
                          : [const Color(0xFF9333EA), const Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _overlayEnabled ? Icons.check_circle : Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _overlayEnabled
                              ? 'Bubble active! Close and reopen app to refresh status'
                              : 'Tap Setup to enable the floating bubble',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _toggleOverlay();
                          // Refresh status after toggle
                          await Future.delayed(const Duration(milliseconds: 500));
                          await _checkOverlayStatus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _overlayEnabled
                              ? const Color(0xFF10B981)
                              : const Color(0xFF9333EA),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _overlayEnabled ? 'Stop' : 'Setup',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Main Record Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                    
                    // Record Button
                    GestureDetector(
                      onTap: () {
                        context.read<AppStateProvider>().reset();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap to speak',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voice to AI-powered text',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Card 1: Speak to rewrite (BELOW the mic)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _AnimatedFeatureCard(
                        icon: Icons.edit_note_rounded,
                        text: 'Speak to rewrite or ask anything',
                        gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card 2: Language support (BELOW card 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _AnimatedFeatureCard(
                        icon: Icons.language_rounded,
                        text: 'Speak in your language, most major languages supported',
                        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPresetCard(
    BuildContext context,
    Preset preset,
    Color surfaceColor,
    Color textColor,
  ) {
    final gradients = {
      'formal-email': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      'casual': [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      'list': [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      'magic': [const Color(0xFF9333EA), const Color(0xFFEC4899)],
    };
    
    final gradient = gradients[preset.id] ?? [const Color(0xFF9333EA), const Color(0xFFEC4899)];
    
    return GestureDetector(
      onTap: () {
        context.read<AppStateProvider>().setSelectedPreset(preset);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecordingScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                preset.icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Feature Card with classy pulsing glow effect
class _AnimatedFeatureCard extends StatefulWidget {
  final IconData icon;
  final String text;
  final List<Color> gradientColors;

  const _AnimatedFeatureCard({
    required this.icon,
    required this.text,
    required this.gradientColors,
  });

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.gradientColors[0].withOpacity(0.15),
                widget.gradientColors[1].withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.gradientColors[0].withOpacity(0.3 * _pulseAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withOpacity(0.15 * _pulseAnimation.value),
                blurRadius: 20 * _pulseAnimation.value,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated icon container with glow
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors[0].withOpacity(0.4 * _pulseAnimation.value),
                      blurRadius: 12 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
