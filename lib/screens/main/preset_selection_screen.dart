import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../constants/presets.dart';
import '../../models/preset.dart';
import '../../services/preset_favorites_service.dart';
import 'recording_screen.dart';
import 'result_screen.dart';

class PresetSelectionScreen extends StatefulWidget {
  final bool fromRecording;
  final String? continueFromItemId;

  const PresetSelectionScreen({
    super.key,
    this.fromRecording = false,
    this.continueFromItemId,
  });

  @override
  State<PresetSelectionScreen> createState() => _PresetSelectionScreenState();
}

class _PresetSelectionScreenState extends State<PresetSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Animation<double>> _cardAnimations = [];
  final PresetFavoritesService _favoritesService = PresetFavoritesService();
  Set<String> _favoritePresetIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoritePresetIds = favorites.toSet();
    });
  }

  Future<void> _toggleFavorite(String presetId) async {
    await _favoritesService.toggleFavorite(presetId);
    await _loadFavorites();
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
    final backgroundColor = const Color(0xFF000000); // Always black
    final surfaceColor = const Color(0xFF1A1A1A); // Dark gray for cards
    final textColor = Colors.white; // Always white text
    final secondaryTextColor = const Color(0xFF94A3B8); // Light gray
    final primaryColor = const Color(0xFF3B82F6); // Blue accent
    
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
  ) {
    final isFavorite = _favoritePresetIds.contains(preset.id);
    
    return _AnimatedPresetCard(
      preset: preset,
      surfaceColor: surfaceColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      primaryColor: primaryColor,
      isFavorite: isFavorite,
      onTap: () => _handlePresetSelection(context, preset),
      onToggleFavorite: () => _toggleFavorite(preset.id),
    );
  }
}

class _AnimatedPresetCard extends StatefulWidget {
  final Preset preset;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color primaryColor;
  final VoidCallback onTap;

  const _AnimatedPresetCard({
    required this.preset,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_AnimatedPresetCard> createState() => _AnimatedPresetCardState();
}

class _AnimatedPresetCardState extends State<_AnimatedPresetCard>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;
  late AnimationController _iconPopController;
  late AnimationController _glowController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Shimmer animation (repeating every 2.5 seconds)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    // Icon pop animation on entrance
    _iconPopController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_iconPopController);
    
    // Glow pulsing animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Trigger icon pop after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _iconPopController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _iconPopController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  // Get preset-specific colors
  List<Color> _getPresetColors(String presetId) {
    switch (presetId) {
      case 'magic':
        return [const Color(0xFF9333EA), const Color(0xFFEC4899)]; // Purple to Pink
      case 'email_professional':
        return [const Color(0xFF3B82F6), const Color(0xFF06B6D4)]; // Blue to Cyan
      case 'email_casual':
        return [const Color(0xFF10B981), const Color(0xFF14B8A6)]; // Green to Teal
      case 'quick_reply':
        return [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]; // Yellow to Amber
      case 'dating_opener':
        return [const Color(0xFFEF4444), const Color(0xFFF87171)]; // Red to Light Red
      case 'dating_reply':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Pink to Light Pink
      case 'social_viral_caption':
        return [const Color(0xFFF97316), const Color(0xFFEF4444)]; // Orange to Red
      case 'social_viral_video':
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)]; // Purple to Light Purple
      case 'rewrite_enhance':
        return [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)]; // Cyan to Sky
      case 'shorten':
        return [const Color(0xFF10B981), const Color(0xFF059669)]; // Emerald
      case 'expand':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // Amber
      case 'formal_business':
        return [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]; // Dark Blue to Blue
      default:
        return [const Color(0xFF9333EA), const Color(0xFFEC4899)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = widget.preset.color ?? widget.primaryColor;
    final presetColors = [mainColor, mainColor.withOpacity(0.7)];
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: Listenable.merge([_shimmerController, _glowController]),
          builder: (context, child) {
            return Stack(
              children: [
                // Main card content
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: presetColors[0].withOpacity(0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: presetColors[0].withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon with animated gradient background and pop animation
                      AnimatedBuilder(
                        animation: _iconScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    presetColors[0].withOpacity(0.85),
                                    presetColors[1].withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: presetColors[0].withOpacity(_glowAnimation.value),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.preset.icon,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
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
                      // Star icon
                      GestureDetector(
                        onTap: widget.onToggleFavorite,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            widget.isFavorite ? Icons.star : Icons.star_border,
                            size: 24,
                            color: widget.isFavorite 
                                ? const Color(0xFFFBBF24) // Golden yellow
                                : widget.secondaryTextColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: widget.secondaryTextColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                // Shimmer overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.transparent,
                            presetColors[0].withOpacity(0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.3, 0.5, 0.7],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          transform: _SlidingGradientTransform(
                            percent: _shimmerController.value,
                          ),
                        ).createShader(bounds);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              presetColors[1].withOpacity(0.05),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Custom gradient transform for shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  final double percent;

  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (percent - 0.5) * 2,
      bounds.height * (percent - 0.5) * 2,
      0,
    );
  }
}

