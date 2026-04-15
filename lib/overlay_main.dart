import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🎯 Overlay entry point called!');
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: const Color(0xFF3B82F6),
      ),
      home: const OverlayWidget(),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> with SingleTickerProviderStateMixin {
  String _currentView = 'mic'; // 'mic', 'presets', or 'result'
  String _transcription = '';
  String _selectedPreset = '';
  late AnimationController _pulseController;
  
  final List<Map<String, dynamic>> _presets = [
    {'id': 'magic', 'name': 'Magic', 'icon': Icons.auto_awesome},
    {'id': 'email_professional', 'name': 'Professional', 'icon': Icons.mail},
    {'id': 'email_casual', 'name': 'Casual', 'icon': Icons.chat_bubble},
    {'id': 'quick_reply', 'name': 'Quick Reply', 'icon': Icons.flash_on},
    {'id': 'social_viral_caption', 'name': 'Viral Content', 'icon': Icons.local_fire_department},
    {'id': 'rewrite_enhance', 'name': 'Enhance', 'icon': Icons.edit_note},
  ];
  
  @override
  void initState() {
    super.initState();
    debugPrint('🎨 Overlay widget initialized!');
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _close() {
    FlutterOverlayWindow.closeOverlay();
  }

  void _showPresets() {
    setState(() {
      _currentView = 'presets';
      _transcription = 'Test transcription'; // Mock for now
    });
  }

  void _selectPreset(String presetId, String presetName) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = presetName;
      _currentView = 'result';
    });
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    // For now, just show presets after a delay (simulating recording)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showPresets();
      }
    });
    // TODO: Integrate with actual recording
  }
  
  void _copyResult() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(const ClipboardData(text: 'AI output will go here'));
    _close();
  }
  
  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000); // Pure black
    const surfaceColor = Color(0xFF1A1A1A); // Dark gray
    const primaryBlue = Color(0xFF3B82F6); // Blue accent

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: primaryBlue.withOpacity(0.3), width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentView == 'mic'
                              ? 'Voice to AI'
                              : _currentView == 'presets'
                                  ? 'Choose Preset'
                                  : 'AI Result',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: _buildContent(surfaceColor, primaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent(Color surfaceColor, Color primaryBlue) {
    switch (_currentView) {
      case 'mic':
        return _buildMicView(surfaceColor, primaryBlue);
      case 'presets':
        return _buildPresetsView(surfaceColor, primaryBlue);
      case 'result':
        return _buildResultView(surfaceColor, primaryBlue);
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildMicView(Color surfaceColor, Color primaryBlue) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic button
          GestureDetector(
            onTap: _startRecording,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tap to speak',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voice to AI-powered text',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresetsView(Color surfaceColor, Color primaryBlue) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return GestureDetector(
            onTap: () => _selectPreset(preset['id'], preset['name']),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      preset['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    preset['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildResultView(Color surfaceColor, Color primaryBlue) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Selected preset
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withOpacity(0.3)),
            ),
            child: Text(
              'Preset: $_selectedPreset',
              style: TextStyle(
                fontSize: 14,
                color: primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Result
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  'AI output will appear here',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Copy button
          GestureDetector(
            onTap: _copyResult,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Copy & Close',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
