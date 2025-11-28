import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../constants/presets.dart';
import '../../models/preset.dart';
import 'recording_screen.dart';
import 'result_screen.dart';

class PresetSelectionScreen extends StatefulWidget {
  final bool fromRecording;
  
  const PresetSelectionScreen({
    super.key,
    this.fromRecording = false,
  });

  @override
  State<PresetSelectionScreen> createState() => _PresetSelectionScreenState();
}

class _PresetSelectionScreenState extends State<PresetSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for each category
    for (int i = 0; i < AppPresets.categories.length; i++) {
      final start = i * 0.05;
      final end = start + 0.3;
      _cardAnimations.add(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handlePresetSelection(BuildContext context, Preset preset) {
    final appState = context.read<AppStateProvider>();
    appState.setSelectedPreset(preset);
    
    if (widget.fromRecording && appState.transcription.isNotEmpty) {
      // Coming from recording with transcription, go to result
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ResultScreen(),
        ),
      );
    } else {
      // Go to recording
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RecordingScreen(),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final primaryColor = isDark ? const Color(0xFFA855F7) : const Color(0xFF9333EA);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textColor, size: 20),
                    ),
                  ),
                  Text(
                    'Choose Style',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Custom preset creation
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Preset Categories List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: AppPresets.categories.length,
                itemBuilder: (context, categoryIndex) {
                  final category = AppPresets.categories[categoryIndex];
                  
                  return FadeTransition(
                    opacity: _cardAnimations[categoryIndex],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_cardAnimations[categoryIndex]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 16),
                            child: Text(
                              category.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          
                          // Presets in Category
                          ...category.presets.map((preset) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildPresetCard(
                                context,
                                preset,
                                surfaceColor,
                                textColor,
                                secondaryTextColor,
                                primaryColor,
                                isDark,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetCard(
    BuildContext context,
    Preset preset,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
    bool isDark,
  ) {
    return _AnimatedPresetCard(
      preset: preset,
      surfaceColor: surfaceColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      primaryColor: primaryColor,
      isDark: isDark,
      onTap: () => _handlePresetSelection(context, preset),
    );
  }
}

class _AnimatedPresetCard extends StatefulWidget {
  final Preset preset;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedPresetCard({
    required this.preset,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedPresetCard> createState() => _AnimatedPresetCardState();
}

class _AnimatedPresetCardState extends State<_AnimatedPresetCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDark
                  ? [
                      widget.surfaceColor,
                      widget.surfaceColor.withOpacity(0.8),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.2),
                      const Color(0xFFEC4899).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.preset.icon,
                  size: 24,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.preset.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.preset.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.secondaryTextColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: widget.secondaryTextColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

