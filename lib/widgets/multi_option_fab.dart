import 'package:flutter/material.dart';

class MultiOptionFab extends StatefulWidget {
  final VoidCallback? onVoicePressed;
  final VoidCallback? onTextPressed;
  final VoidCallback? onImagePressed;
  final VoidCallback? onProjectPressed;
  final VoidCallback? onTodoPressed;
  final bool showProjectOption;

  const MultiOptionFab({
    super.key,
    this.onVoicePressed,
    this.onTextPressed,
    this.onImagePressed,
    this.onProjectPressed,
    this.onNotePressed,
    this.showProjectOption = false,
  });

  @override
  State<MultiOptionFab> createState() => _MultiOptionFabState();
}

class _MultiOptionFabState extends State<MultiOptionFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onOptionPressed(VoidCallback? callback) {
    if (_isExpanded) {
      _toggle(); // Close the menu
      Future.delayed(const Duration(milliseconds: 200), () {
        callback?.call();
      });
    }
  }

  double _getDelay(int index) {
    // Calculate delay based on visible options
    final visibleOptions = [
      widget.onImagePressed,
      widget.onTodoPressed, 
      widget.onTextPressed,
      widget.onVoicePressed,
    ].where((callback) => callback != null).length;
    
    int visibleIndex = 0;
    final callbacks = [
      widget.onImagePressed,
      widget.onTodoPressed,
      widget.onTextPressed, 
      widget.onVoicePressed,
    ];
    
    for (int i = 0; i <= index; i++) {
      if (callbacks[i] != null) {
        if (i == index) break;
        visibleIndex++;
      }
    }
    
    final baseDelay = widget.showProjectOption ? 0.1 : 0.0;
    return baseDelay + (visibleIndex * 0.1);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B82F6);
    const surfaceColor = Color(0xFF1A1A1A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // Options
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                // Project option (if enabled)
                if (widget.showProjectOption)
                  _buildOption(
                    icon: Icons.folder_outlined,
                    label: 'Project',
                    color: const Color(0xFF9333EA),
                    onPressed: () => _onOptionPressed(widget.onProjectPressed),
                    delay: 0.0,
                  ),

                // Image option
                _buildOption(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  color: const Color(0xFF10B981),
                  onPressed: () => _onOptionPressed(widget.onImagePressed),
                  delay: widget.showProjectOption ? 0.1 : 0.0,
                ),

                // Todo option
                _buildOption(
                  icon: Icons.checklist,
                  label: 'Todo',
                  color: const Color(0xFF8B5CF6),
                  onPressed: () => _onOptionPressed(widget.onTodoPressed),
                  delay: widget.showProjectOption ? 0.2 : 0.1,
                ),

                // Text option (full document)
                _buildOption(
                  icon: Icons.article_outlined,
                  label: 'Document',
                  color: const Color(0xFFF59E0B),
                  onPressed: () => _onOptionPressed(widget.onTextPressed),
                  delay: widget.showProjectOption ? 0.3 : 0.2,
                ),

                // Voice option
                _buildOption(
                  icon: Icons.mic_outlined,
                  label: 'Voice',
                  color: const Color(0xFFEF4444),
                  onPressed: () => _onOptionPressed(widget.onVoicePressed),
                  delay: widget.showProjectOption ? 0.4 : 0.3,
                ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: primaryColor,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0, // 45 degree rotation
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // FAB
              FloatingActionButton.small(
                onPressed: onPressed,
                backgroundColor: color,
                heroTag: label, // Unique hero tag for each FAB
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}