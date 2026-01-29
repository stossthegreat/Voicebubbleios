import 'package:flutter/material.dart';

// ============================================================
//        AI ACTIONS MENU - THE VIRAL FEATURE
// ============================================================
//
// The popup menu that appears when user selects text.
// This is the feature that will make users film TikToks.
//
// ============================================================

enum AIAction {
  rewrite,
  expand,
  shorten,
  professional,
  casual,
  translate,
  delete,
}

class AIActionsMenu extends StatefulWidget {
  final String selectedText;
  final Function(AIAction action) onActionSelected;
  final VoidCallback onDismiss;
  final Animation<double> animation;

  const AIActionsMenu({
    super.key,
    required this.selectedText,
    required this.onActionSelected,
    required this.onDismiss,
    required this.animation,
  });

  @override
  State<AIActionsMenu> createState() => _AIActionsMenuState();
}

class _AIActionsMenuState extends State<AIActionsMenu> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animation.value,
          child: Opacity(
            opacity: widget.animation.value,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with selected text preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_fix_high,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${widget.selectedText.length > 30 ? '${widget.selectedText.substring(0, 30)}...' : widget.selectedText}"',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onDismiss,
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.refresh,
                                  label: 'Rewrite',
                                  color: const Color(0xFF3B82F6),
                                  action: AIAction.rewrite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.expand_more,
                                  label: 'Expand',
                                  color: const Color(0xFF10B981),
                                  action: AIAction.expand,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.compress,
                                  label: 'Shorten',
                                  color: const Color(0xFFF59E0B),
                                  action: AIAction.shorten,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.business_center,
                                  label: 'Professional',
                                  color: const Color(0xFF8B5CF6),
                                  action: AIAction.professional,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.sentiment_satisfied,
                                  label: 'Casual',
                                  color: const Color(0xFFEC4899),
                                  action: AIAction.casual,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.translate,
                                  label: 'Translate',
                                  color: const Color(0xFF06B6D4),
                                  action: AIAction.translate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: const Color(0xFFEF4444),
                              action: AIAction.delete,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required AIAction action,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onActionSelected(action),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}