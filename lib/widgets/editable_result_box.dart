import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_selection_ai_menu.dart';

class EditableResultBox extends StatefulWidget {
  final String initialText;
  final Function(String) onTextChanged;
  final bool isLoading;

  const EditableResultBox({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    this.isLoading = false,
  });

  @override
  State<EditableResultBox> createState() => _EditableResultBoxState();
}

class _EditableResultBoxState extends State<EditableResultBox> {
  late TextEditingController _controller;
  Timer? _debounce;
  
  // Selection tracking
  bool _hasSelection = false;
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  Offset _selectionPosition = Offset.zero;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(EditableResultBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText && 
        widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSelectionChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final selection = _controller.selection;
    
    if (selection.baseOffset != selection.extentOffset) {
      // Text is selected
      final start = selection.start;
      final end = selection.end;
      final text = _controller.text.substring(start, end);
      
      if (text.trim().isNotEmpty) {
        setState(() {
          _hasSelection = true;
          _selectedText = text;
          _selectionStart = start;
          _selectionEnd = end;
        });
        
        // Get position for menu
        _updateSelectionPosition();
      }
    } else {
      // No selection
      if (_hasSelection) {
        setState(() {
          _hasSelection = false;
          _selectedText = '';
        });
      }
    }
  }

  void _updateSelectionPosition() {
    // Get the approximate position of selection
    final RenderBox? renderBox = 
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _selectionPosition = Offset(
          offset.dx + renderBox.size.width / 2,
          offset.dy + 60, // Position below the text
        );
      });
    }
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onTextChanged(value);
    });
  }

  void _showAIMenu() {
    if (_selectedText.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    showTextSelectionAIMenu(
      context: context,
      selectedText: _selectedText,
      globalPosition: _selectionPosition,
      onReplace: (newText) {
        // Replace the selected text with AI result
        final beforeSelection = _controller.text.substring(0, _selectionStart);
        final afterSelection = _controller.text.substring(_selectionEnd);
        final newFullText = beforeSelection + newText + afterSelection;
        
        _controller.text = newFullText;
        _controller.selection = TextSelection.collapsed(
          offset: _selectionStart + newText.length,
        );
        
        widget.onTextChanged(newFullText);
        
        setState(() {
          _hasSelection = false;
          _selectedText = '';
        });
        
        HapticFeedback.mediumImpact();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3B82F6);
    final textColor = Colors.white;

    return Stack(
      children: [
        Container(
          key: _textFieldKey,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                const Color(0xFF2563EB).withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: widget.isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Refining...',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onTextChanged,
                  maxLines: null,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Your text will appear here...',
                    hintStyle: TextStyle(
                      color: textColor.withOpacity(0.3),
                    ),
                  ),
                  // Enable text selection toolbar
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) {
                    // Custom context menu with AI option
                    return AdaptiveTextSelectionToolbar(
                      anchors: editableTextState.contextMenuAnchors,
                      children: [
                        // AI Actions button
                        TextSelectionToolbarTextButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            editableTextState.hideToolbar();
                            _showAIMenu();
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 18, color: Color(0xFF8B5CF6)),
                              SizedBox(width: 6),
                              Text('AI Actions', style: TextStyle(color: Color(0xFF8B5CF6))),
                            ],
                          ),
                        ),
                        // Standard Cut
                        TextSelectionToolbarTextButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            editableTextState.cutSelection(SelectionChangedCause.toolbar);
                          },
                          child: const Text('Cut'),
                        ),
                        // Standard Copy
                        TextSelectionToolbarTextButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            editableTextState.copySelection(SelectionChangedCause.toolbar);
                          },
                          child: const Text('Copy'),
                        ),
                        // Standard Paste
                        TextSelectionToolbarTextButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            editableTextState.pasteText(SelectionChangedCause.toolbar);
                          },
                          child: const Text('Paste'),
                        ),
                        // Standard Select All
                        TextSelectionToolbarTextButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            editableTextState.selectAll(SelectionChangedCause.toolbar);
                          },
                          child: const Text('Select All'),
                        ),
                      ],
                    );
                  },
                ),
        ),
        
        // Floating AI Button when text is selected
        if (_hasSelection && _selectedText.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _showAIMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
