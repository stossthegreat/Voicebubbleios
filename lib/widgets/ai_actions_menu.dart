import 'dart:ui';
// Force re-commit to sync to GitHub
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/text_transformation_service.dart';
import '../providers/app_state_provider.dart';

class AIActionsMenu extends StatefulWidget {
  final String selectedText;
  final TextSelection selection;
  final Function(String newText) onTextReplaced;
  final VoidCallback onDismiss;

  const AIActionsMenu({
    super.key,
    required this.selectedText,
    required this.selection,
    required this.onTextReplaced,
    required this.onDismiss,
  });

  @override
  State<AIActionsMenu> createState() => _AIActionsMenuState();
}

class _AIActionsMenuState extends State<AIActionsMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isProcessing = false;
  String? _processingAction;
  
  final _transformationService = TextTransformationService();

  final List<AIAction> _actions = [
    AIAction(id: 'rewrite', name: 'Rewrite', icon: '✨', description: 'Make it clearer & more impactful', color: Color(0xFF3B82F6)),
    AIAction(id: 'expand', name: 'Expand', icon: '📝', description: 'Add detail & examples', color: Color(0xFF10B981)),
    AIAction(id: 'shorten', name: 'Shorten', icon: '✂️', description: 'Make it concise & punchy', color: Color(0xFFF59E0B)),
    AIAction(id: 'professional', name: 'Professional', icon: '🎯', description: 'Business-ready & authoritative', color: Color(0xFF8B5CF6)),
    AIAction(id: 'casual', name: 'Casual', icon: '😎', description: 'Friendly & conversational', color: Color(0xFFEF4444)),
    AIAction(id: 'powerful', name: 'Make Powerful', icon: '🔥', description: 'Compelling & persuasive', color: Color(0xFFDC2626)),
    AIAction(id: 'explain', name: 'Explain Simply', icon: '💡', description: 'Easy to understand', color: Color(0xFF06B6D4)),
    AIAction(id: 'translate', name: 'Translate', icon: '🌍', description: 'Convert to another language', color: Color(0xFF84CC16)),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: _buildMenu()),
        );
      },
    );
  }

  Widget _buildMenu() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildHeader(), const SizedBox(height: 16), _buildActionsGrid(), if (_isProcessing) _buildProcessingIndicator()],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: Text('${widget.selectedText.length} chars selected', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        const Spacer(),
        IconButton(onPressed: widget.onDismiss, icon: const Icon(Icons.close, color: Colors.white, size: 20)),
      ],
    );
  }

  Widget _buildActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _actions.length,
      itemBuilder: (context, index) => _buildActionButton(_actions[index]),
    );
  }

  Widget _buildActionButton(AIAction action) {
    final isProcessing = _processingAction == action.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [action.color, action.color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: action.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : () => _handleAction(action),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcessing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else Text(action.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(action.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('AI is working its magic...', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _handleAction(AIAction action) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; _processingAction = action.id; });

    try {
      String transformedText;
      if (action.id == 'translate') {
        final language = await _showLanguageDialog();
        if (language == null) { setState(() { _isProcessing = false; _processingAction = null; }); return; }
        transformedText = await _transformationService.translateText(widget.selectedText, language);
      } else {
        transformedText = await _transformationService.transformText(widget.selectedText, action.id, context: 'Rich text editor selection');
      }
      widget.onTextReplaced(transformedText);
      widget.onDismiss();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ${action.name.toLowerCase()}: $e'), backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() { _isProcessing = false; _processingAction = null; });
    }
  }

  Future<String?> _showLanguageDialog() async {
    final languages = ['Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Chinese', 'Japanese', 'Korean', 'Arabic', 'Russian'];
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Translate to...', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) => ListTile(title: Text(languages[index], style: const TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context, languages[index])),
          ),
        ),
      ),
    );
  }
}

class AIAction {
  final String id;
  final String name;
  final String icon;
  final String description;
  final Color color;
  const AIAction({required this.id, required this.name, required this.icon, required this.description, required this.color});
}
