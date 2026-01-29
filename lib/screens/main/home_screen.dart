import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform, File;
import 'package:file_picker/file_picker.dart';
import '../../providers/app_state_provider.dart';
import '../../constants/presets.dart';
import '../../constants/languages.dart';
import '../../models/preset.dart';
import '../../services/native_overlay_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/continue_banner.dart';
import '../../widgets/language_selector_popup.dart';
import '../main/recording_screen.dart';
import '../main/preset_selection_screen.dart';
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
  
  /// Pick and upload audio file
  Future<void> _pickAudioFile() async {
    try {
      // Show file picker for audio files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        if (!mounted) return;
        
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Transcribing audio...'),
                  ],
                ),
              ),
            ),
          ),
        );
        
        try {
          // Transcribe the audio file
          final aiService = AIService();
          final transcription = await aiService.transcribeAudio(file);
          
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          
          if (transcription.isEmpty) {
            throw Exception('No speech detected in audio file');
          }
          
          // Set transcription in app state
          final appState = context.read<AppStateProvider>();
          appState.setTranscription(transcription);
          
          // Navigate to preset selection
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PresetSelectionScreen(fromRecording: true),
            ),
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Transcribed: ${transcription.substring(0, transcription.length > 50 ? 50 : transcription.length)}...'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to transcribe audio: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
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
        child: Column(
          children: [
            // Continue Banner (if context exists)
            const ContinueBanner(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header (stays at top)
              Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and VoiceBubble text (BIGGER LOGO)
                  Row(
                    children: [
                      Image.asset(
                        'assets/app_logo.png',
                        width: 48, // Increased from 32
                        height: 48, // Increased from 32
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'VoiceBubble',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  // Settings Button (moved left, more accessible)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(Icons.settings, color: textColor, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Activate Voice Bubble Button (under settings)
            if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _toggleOverlay();
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _checkOverlayStatus();
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _overlayEnabled ? const Color(0xFF10B981) : surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _overlayEnabled ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bubble_chart,
                              color: _overlayEnabled ? Colors.white : const Color(0xFF3B82F6),
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Activate\nVoice\nBubble',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: _overlayEnabled ? Colors.white : const Color(0xFF3B82F6),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Add spacing before main content
            const SizedBox(height: 32),
            
            // Main content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                    // Language Selector and Record Button
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 32),
                    
                    // Language Selector Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Consumer<AppStateProvider>(
                        builder: (context, appState, _) {
                          final language = appState.selectedLanguage;
                          final primaryColor = const Color(0xFF3B82F6);
                          return GestureDetector(
                            onTap: () async {
                              await showDialog(
                                context: context,
                                builder: (context) => const LanguageSelectorPopup(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    language.flagEmoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Output Language',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          language.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Upload Audio Button (bottom left)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Tooltip(
          message: 'Upload Audio',
          child: FloatingActionButton(
            onPressed: _pickAudioFile,
            backgroundColor: const Color(0xFF10B981),
            child: const Icon(
              Icons.upload_file,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
  
  Widget _buildPresetCard(
    BuildContext context,
    Preset preset,
    Color surfaceColor,
    Color textColor,
  ) {
    final gradients = {
      'magic': [const Color(0xFF9333EA), const Color(0xFFEC4899)],
      'email_professional': [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      'email_casual': [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      'quick_reply': [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      'dating_opener': [const Color(0xFFEC4899), const Color(0xFFEF4444)],
      'dating_reply': [const Color(0xFFF472B6), const Color(0xFFEC4899)],
      'social_viral_caption': [const Color(0xFFEF4444), const Color(0xFFF97316)],
      'social_viral_video': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      'rewrite_enhance': [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
      'shorten': [const Color(0xFF10B981), const Color(0xFF059669)],
      'expand': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'formal_business': [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
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
