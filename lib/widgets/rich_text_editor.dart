import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'ai_actions_menu.dart';

// ============================================================
//        RICH TEXT EDITOR WIDGET
// ============================================================

// KEYBOARD SHORTCUTS INTENTS
class SaveIntent extends Intent {}
class BoldIntent extends Intent {}
class ItalicIntent extends Intent {}
class UnderlineIntent extends Intent {}
class UndoIntent extends Intent {}
class RedoIntent extends Intent {}

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
  late AnimationController _saveIndicatorController;
  late Animation<double> _saveIndicatorAnimation;
  int _wordCount = 0;
  int _characterCount = 0;
  
  // AI Menu state
  bool _showAIMenu = false;
  String _selectedText = '';
  TextSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _controller.addListener(_onTextChanged);
    _controller.addListener(_onSelectionChanged);
    
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
  }

  void _initializeController() {
    quill.Document doc;
    
    // Try to load from formatted content (Delta JSON)
    if (widget.initialFormattedContent != null && widget.initialFormattedContent!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.initialFormattedContent!);
        doc = quill.Document.fromJson(deltaJson);
      } catch (e) {
        // Fallback to plain text
        doc = quill.Document()..insert(0, widget.initialPlainText ?? '');
      }
    } else if (widget.initialPlainText != null && widget.initialPlainText!.isNotEmpty) {
      doc = quill.Document()..insert(0, widget.initialPlainText!);
    } else {
      doc = quill.Document();
    }

    _controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _saveIndicatorController.dispose();
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

    if (_saveTimer?.isActive ?? false) _saveTimer!.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveContent();
    });
  }

  void _onSelectionChanged() {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed && !widget.readOnly) {
      final plainText = _controller.document.toPlainText();
      if (selection.start < plainText.length && selection.end <= plainText.length) {
        final selectedText = plainText.substring(selection.start, selection.end).trim();
        
        if (selectedText.isNotEmpty) {
          setState(() {
            _currentSelection = selection;
            _selectedText = selectedText;
            _showAIMenu = true;
          });
          return;
        }
      }
    }
    
    setState(() {
      _showAIMenu = false;
      _currentSelection = null;
      _selectedText = '';
    });
  }

  void _replaceSelectedText(String newText) {
    if (_currentSelection == null) return;

    final selection = _currentSelection!;
    _controller.replaceText(
      selection.start,
      selection.end - selection.start,
      newText,
      TextSelection.collapsed(offset: selection.start + newText.length),
    );
    
    setState(() {
      _showAIMenu = false;
      _currentSelection = null;
      _selectedText = '';
    });
  }

  void _dismissAIMenu() {
    setState(() {
      _showAIMenu = false;
      _currentSelection = null;
      _selectedText = '';
    });
  }

  Future<void> _saveContent() async {
    try {
      final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
      final plainText = _controller.document.toPlainText().trim();

      await widget.onSave(plainText, deltaJson);

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
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;

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
                    child: quill.QuillSimpleToolbar(
                      configurations: quill.QuillSimpleToolbarConfigurations(
                        controller: _controller,
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
                      focusNode: _focusNode,
                      configurations: quill.QuillEditorConfigurations(
                        controller: _controller,
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
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_wordCount words • $_characterCount characters',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
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
            
            // AI Actions Menu
            if (_showAIMenu && _currentSelection != null)
              Positioned(
                top: 100,
                left: 20,
                child: AIActionsMenu(
                  selectedText: _selectedText,
                  selection: _currentSelection!,
                  onTextReplaced: _replaceSelectedText,
                  onDismiss: _dismissAIMenu,
                ),
              ),

            // Animated Save Indicator
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
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
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
            
          ],
        ),
      ),
    );
  }
}
