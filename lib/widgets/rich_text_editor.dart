import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../services/rich_text_service.dart';
import '../services/text_transformation_service.dart';
import 'ai_actions_menu.dart';

// ============================================================
//        RICH TEXT EDITOR WIDGET
// ============================================================
//
// Professional rich text editor matching Samsung Notes quality.
// Full formatting toolbar, auto-save, dark theme.
//
// ============================================================

// KEYBOARD SHORTCUTS INTENTS
class SaveIntent extends Intent {}
class BoldIntent extends Intent {}
class ItalicIntent extends Intent {}
class UnderlineIntent extends Intent {}
class UndoIntent extends Intent {}
class RedoIntent extends Intent {}
class InsertDateTimeIntent extends Intent {}
class InsertDividerIntent extends Intent {}
class DuplicateLineIntent extends Intent {}

class RichTextEditor extends StatefulWidget {
  final String? initialFormattedContent;
  final String? initialPlainText;
  final Function(String plainText, String deltaJson) onSave;
  final bool readOnly;

  const RichTextEditor({
    super.key,
    this.initialFormattedContent,
    this.initialPlainText,
    required this.onSave,
    this.readOnly = false,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> with TickerProviderStateMixin {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _saveTimer;
  bool _showSaved = false;
  bool _hasUnsavedChanges = false;
  final _richTextService = RichTextService();
  final _transformationService = TextTransformationService();
  late AnimationController _saveIndicatorController;
  late Animation<double> _saveIndicatorAnimation;
  int _wordCount = 0;
  int _characterCount = 0;
  
  // AI Actions Menu State
  bool _showAIActions = false;
  TextSelection? _currentSelection;
  Offset? _selectionPosition;
  String _selectedText = '';
  late AnimationController _aiMenuController;
  late Animation<double> _aiMenuAnimation;
  bool _isTransforming = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _controller.addListener(_onTextChanged);
    
    // Initialize animations
    _saveIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _saveIndicatorController,
      curve: Curves.easeInOut,
    ));
    
    // AI Actions Menu Animation
    _aiMenuController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _aiMenuAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _aiMenuController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializeController() {
    final doc = _richTextService.createDocument(
      formattedContent: widget.initialFormattedContent,
      plainText: widget.initialPlainText ?? '',
    );

    _controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    // Listen for selection changes
    _controller.addListener(_onSelectionChanged);
  }
  
  void _onSelectionChanged() {
    final selection = _controller.selection;
    
    // Hide AI menu if no selection or collapsed selection
    if (!selection.isValid || selection.isCollapsed) {
      if (_showAIActions) {
        _hideAIActionsMenu();
      }
      return;
    }
    
    // Show AI menu for text selection
    final selectedText = _controller.document.toPlainText().substring(
      selection.start,
      selection.end,
    ).trim();
    
    if (selectedText.isNotEmpty && selectedText.length > 2) {
      _showAIActionsMenu(selection, selectedText);
    }
  }
  
  void _showAIActionsMenu(TextSelection selection, String selectedText) {
    setState(() {
      _currentSelection = selection;
      _selectedText = selectedText;
      _showAIActions = true;
    });
    
    _aiMenuController.forward();
  }
  
  void _hideAIActionsMenu() {
    _aiMenuController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showAIActions = false;
          _currentSelection = null;
          _selectedText = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _saveIndicatorController.dispose();
    _aiMenuController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.readOnly) return;

    final plainText = _controller.document.toPlainText();
    final words = plainText.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final characters = plainText.length;

    setState(() {
      _hasUnsavedChanges = true;
      _showSaved = false;
      _wordCount = words;
      _characterCount = characters;
    });

    // Debounce auto-save
    if (_saveTimer?.isActive ?? false) _saveTimer!.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveContent();
    });
  }

  Future<void> _saveContent() async {
    try {
      final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
      final plainText = _controller.document.toPlainText().trim();

      await widget.onSave(plainText, deltaJson);

      // Animate save indicator
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _showSaved = true;
        });
        
        _saveIndicatorController.forward().then((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _saveIndicatorController.reverse().then((_) {
                if (mounted) setState(() => _showSaved = false);
              });
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error saving content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final primaryColor = const Color(0xFF3B82F6);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU): UnderlineIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _saveContent()),
          BoldIntent: CallbackAction<BoldIntent>(onInvoke: (_) => _controller.formatSelection(quill.Attribute.bold)),
          ItalicIntent: CallbackAction<ItalicIntent>(onInvoke: (_) => _controller.formatSelection(quill.Attribute.italic)),
          UnderlineIntent: CallbackAction<UnderlineIntent>(onInvoke: (_) => _controller.formatSelection(quill.Attribute.underline)),
          UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _controller.undo()),
          RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _controller.redo()),
        },
        child: Stack(
          children: [
            Column(
              children: [
                // Formatting Toolbar
                if (!widget.readOnly)
                  Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: quill.QuillToolbar.simple(
                      controller: _controller,
                      configurations: quill.QuillSimpleToolbarConfigurations(
                        multiRowsDisplay: false,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showColorButton: true,
                        showBackgroundColorButton: true,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: true,
                        showCodeBlock: false,
                        showQuote: true,
                        showIndent: true,
                        showLink: false,
                        showUndo: true,
                        showRedo: true,
                        showDirection: false,
                        showSearchButton: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showSmallButton: false,
                        showInlineCode: true,
                        showClearFormat: true,
                        showHeaderStyle: true,
                        showAlignmentButtons: true,
                      ),
                    ),
                  ),

                // Editor
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: quill.QuillEditor.basic(
                      controller: _controller,
                      focusNode: _focusNode,
                      configurations: quill.QuillEditorConfigurations(
                        padding: EdgeInsets.zero,
                        autoFocus: !widget.readOnly,
                        expands: true,
                        placeholder: widget.readOnly ? 'No content yet...' : 'Start typing your masterpiece...',
                        readOnly: widget.readOnly,
                      ),
                    ),
                  ),
                ),

                // Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_wordCount words • $_characterCount characters',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (_hasUnsavedChanges)
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Unsaved changes',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (_showSaved)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Saved',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Animated Save Indicator (top-right)
            if (_showSaved)
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _saveIndicatorAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _saveIndicatorAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Saved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // AI Actions Menu Overlay
            if (_showAIActions && _currentSelection != null)
              Positioned(
                top: 100, // Position above selected text (we'll improve this)
                left: 50,
                right: 50,
                child: AIActionsMenu(
                  selectedText: _selectedText,
                  animation: _aiMenuAnimation,
                  onActionSelected: _handleAIAction,
                  onDismiss: _hideAIActionsMenu,
                ),
              ),
              
            // Loading overlay for AI transformations
            if (_isTransforming)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'AI is working its magic...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _handleAIAction(AIAction action) async {
    if (_currentSelection == null) return;
    
    _hideAIActionsMenu();
    
    // Show loading state
    // TODO: Implement AI transformation
    
    switch (action) {
      case AIAction.rewrite:
        await _transformText('rewrite');
        break;
      case AIAction.expand:
        await _transformText('expand');
        break;
      case AIAction.shorten:
        await _transformText('shorten');
        break;
      case AIAction.professional:
        await _transformText('professional');
        break;
      case AIAction.casual:
        await _transformText('casual');
        break;
      case AIAction.translate:
        await _transformText('translate');
        break;
      case AIAction.delete:
        _deleteSelectedText();
        break;
    }
  }
  
  Future<void> _transformText(String action) async {
    if (_isTransforming || _currentSelection == null) return;
    
    setState(() {
      _isTransforming = true;
    });
    
    try {
      // Get context (surrounding text for better AI understanding)
      final fullText = _controller.document.toPlainText();
      final contextStart = (_currentSelection!.start - 100).clamp(0, fullText.length);
      final contextEnd = (_currentSelection!.end + 100).clamp(0, fullText.length);
      final context = fullText.substring(contextStart, contextEnd);
      
      String transformedText;
      
      switch (action) {
        case 'rewrite':
          transformedText = await _transformationService.rewriteText(_selectedText, context: context);
          break;
        case 'expand':
          transformedText = await _transformationService.expandText(_selectedText, context: context);
          break;
        case 'shorten':
          transformedText = await _transformationService.shortenText(_selectedText, context: context);
          break;
        case 'professional':
          transformedText = await _transformationService.makeProfessional(_selectedText, context: context);
          break;
        case 'casual':
          transformedText = await _transformationService.makeCasual(_selectedText, context: context);
          break;
        case 'translate':
          // For now, translate to Spanish. Later we'll add language selection
          transformedText = await _transformationService.translateText(_selectedText, 'es', context: context);
          break;
        default:
          transformedText = _selectedText;
      }
      
      _replaceSelectedText(transformedText);
      
    } catch (e) {
      debugPrint('❌ Text transformation error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transform text: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransforming = false;
        });
      }
    }
  }
  
  void _deleteSelectedText() {
    if (_currentSelection == null) return;
    
    _controller.document.delete(_currentSelection!.start, _currentSelection!.length);
    _controller.updateSelection(
      TextSelection.collapsed(offset: _currentSelection!.start),
      quill.ChangeSource.local,
    );
  }
  
  void _replaceSelectedText(String newText) {
    if (_currentSelection == null) return;
    
    _controller.document.delete(_currentSelection!.start, _currentSelection!.length);
    _controller.document.insert(_currentSelection!.start, newText);
    _controller.updateSelection(
      TextSelection.collapsed(offset: _currentSelection!.start + newText.length),
      quill.ChangeSource.local,
    );
  }
  }
}