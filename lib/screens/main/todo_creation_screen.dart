import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_selection_dialog.dart';

class TodoItem {
  String id;
  String text;
  bool isCompleted;
  
  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
    };
  }
  
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class TodoCreationScreen extends StatefulWidget {
  final String? projectId;
  final String? itemId; // For editing existing todos

  const TodoCreationScreen({
    super.key,
    this.projectId,
    this.itemId,
  });

  @override
  State<TodoCreationScreen> createState() => _TodoCreationScreenState();
}

class _TodoCreationScreenState extends State<TodoCreationScreen> {
  late TextEditingController _titleController;
  final List<TodoItem> _todoItems = [];
  final List<TextEditingController> _todoControllers = [];
  final List<FocusNode> _todoFocusNodes = [];
  
  List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleController.addListener(_onTextChanged);
    
    // Add first todo item
    _addTodoItem();
    
    // Load existing item if editing
    if (widget.itemId != null) {
      _loadExistingItem();
    } else {
      // Auto-focus title for new todos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleController.text.isEmpty 
          ? _titleController.selection = TextSelection.fromPosition(TextPosition(offset: 0))
          : _todoFocusNodes.first.requestFocus();
      });
    }
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _addTodoItem({String? text, bool isCompleted = false}) {
    final todoItem = TodoItem(
      id: const Uuid().v4(),
      text: text ?? '',
      isCompleted: isCompleted,
    );
    
    final controller = TextEditingController(text: text ?? '');
    final focusNode = FocusNode();
    
    controller.addListener(_onTextChanged);
    
    setState(() {
      _todoItems.add(todoItem);
      _todoControllers.add(controller);
      _todoFocusNodes.add(focusNode);
    });
    
    // Focus on the new item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void _removeTodoItem(int index) {
    if (_todoItems.length <= 1) return; // Keep at least one item
    
    setState(() {
      _todoControllers[index].dispose();
      _todoFocusNodes[index].dispose();
      _todoItems.removeAt(index);
      _todoControllers.removeAt(index);
      _todoFocusNodes.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoItems[index].isCompleted = !_todoItems[index].isCompleted;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _loadExistingItem() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final item = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
    
    if (item != null) {
      setState(() {
        _titleController.text = item.customTitle ?? '';
        _selectedTags = List.from(item.tags);
      });
      
      // Parse todo items from finalText (JSON format)
      try {
        if (item.finalText.isNotEmpty) {
          final List<dynamic> todoData = [];
          // Simple parsing - in real app you'd use proper JSON
          final lines = item.finalText.split('\n');
          for (String line in lines) {
            if (line.trim().isNotEmpty) {
              final isCompleted = line.startsWith('☑');
              final text = line.replaceFirst(RegExp(r'^[☐☑]\s*'), '');
              todoData.add({
                'id': const Uuid().v4(),
                'text': text,
                'isCompleted': isCompleted,
              });
            }
          }
          
          // Clear existing items and add loaded ones
          _todoItems.clear();
          _todoControllers.forEach((c) => c.dispose());
          _todoFocusNodes.forEach((f) => f.dispose());
          _todoControllers.clear();
          _todoFocusNodes.clear();
          
          for (var data in todoData) {
            _addTodoItem(text: data['text'], isCompleted: data['isCompleted']);
          }
          
          if (_todoItems.isEmpty) {
            _addTodoItem();
          }
        }
      } catch (e) {
        // If parsing fails, just add one empty item
        _addTodoItem();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _todoControllers.forEach((controller) => controller.dispose());
    _todoFocusNodes.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Discard changes?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  String _generateTodoText() {
    final buffer = StringBuffer();
    for (int i = 0; i < _todoItems.length; i++) {
      final item = _todoItems[i];
      final text = _todoControllers[i].text.trim();
      if (text.isNotEmpty) {
        final checkbox = item.isCompleted ? '☑' : '☐';
        buffer.writeln('$checkbox $text');
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _saveTodo() async {
    // Update todo items with current text
    for (int i = 0; i < _todoItems.length; i++) {
      _todoItems[i].text = _todoControllers[i].text.trim();
    }
    
    // Remove empty items
    final nonEmptyItems = _todoItems.where((item) => item.text.isNotEmpty).toList();
    
    if (nonEmptyItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one todo item'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final todoText = _generateTodoText();
      
      if (widget.itemId != null) {
        // Update existing item
        final existingItem = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
        if (existingItem != null) {
          final updatedItem = existingItem.copyWith(
            finalText: todoText,
            customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            tags: _selectedTags,
          );
          await appState.updateRecording(updatedItem);
        }
      } else {
        // Create new item
        final newItem = RecordingItem(
          id: const Uuid().v4(),
          rawTranscript: todoText,
          finalText: todoText,
          presetUsed: 'Todo List',
          outcomes: ['task'], // Add to task outcomes for alarm/completion system
          projectId: widget.projectId,
          createdAt: DateTime.now(),
          editHistory: [],
          presetId: 'todo_list',
          tags: _selectedTags,
          customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          contentType: 'todo',
          isCompleted: false, // Initialize as not completed
        );

        await appState.saveRecording(newItem);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemId != null ? 'Todo updated' : 'Todo created'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTagSelectionDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TagSelectionDialog(
        selectedTagIds: _selectedTags,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            widget.itemId != null ? 'Edit Todo' : 'New Todo',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            // Tag button
            IconButton(
              onPressed: _showTagSelectionDialog,
              icon: Icon(
                Icons.label_outline,
                color: _selectedTags.isNotEmpty ? primaryColor : secondaryTextColor,
              ),
            ),
            // Save button
            TextButton(
              onPressed: _isLoading ? null : _saveTodo,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tags display
                if (_selectedTags.isNotEmpty)
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      final tags = appState.tags;
                      final selectedTagObjects = _selectedTags
                          .map((tagId) => tags.where((t) => t.id == tagId).firstOrNull)
                          .where((t) => t != null)
                          .toList();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedTagObjects.map((tag) {
                            return TagChip(
                              tag: tag!,
                              isSelected: true,
                              onTap: () {
                                setState(() {
                                  _selectedTags.remove(tag.id);
                                  _hasUnsavedChanges = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                // Title field
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Todo title (optional)',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                
                const SizedBox(height: 16),

                // Todo items list
                Container(
                  constraints: BoxConstraints(
                    minHeight: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _todoItems.length,
                          itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    GestureDetector(
                                      onTap: () => _toggleTodoItem(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _todoItems[index].isCompleted 
                                              ? primaryColor 
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: _todoItems[index].isCompleted 
                                                ? primaryColor 
                                                : secondaryTextColor,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: _todoItems[index].isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Text field
                                    Expanded(
                                      child: TextField(
                                        controller: _todoControllers[index],
                                        focusNode: _todoFocusNodes[index],
                                        style: TextStyle(
                                          color: _todoItems[index].isCompleted 
                                              ? secondaryTextColor 
                                              : textColor,
                                          fontSize: 16,
                                          decoration: _todoItems[index].isCompleted 
                                              ? TextDecoration.lineThrough 
                                              : null,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Add todo item...',
                                          hintStyle: TextStyle(color: secondaryTextColor),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        textCapitalization: TextCapitalization.sentences,
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty && index == _todoItems.length - 1) {
                                            _addTodoItem();
                                          }
                                        },
                                      ),
                                    ),
                                    
                                    // Delete button (only show if more than 1 item)
                                    if (_todoItems.length > 1)
                                      IconButton(
                                        onPressed: () => _removeTodoItem(index),
                                        icon: Icon(
                                          Icons.close,
                                          color: secondaryTextColor,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Add button
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _addTodoItem,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add item',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_todoItems.where((item) => item.isCompleted).length}/${_todoItems.length} completed',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    if (_hasUnsavedChanges)
                      const Text(
                        'Unsaved changes',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}