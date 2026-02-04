// ═══════════════════════════════════════════════════════════════════════════════
// ⚠️⚠️⚠️ CRITICAL WARNING: DO NOT MODIFY THIS FILE ⚠️⚠️⚠️
// ═══════════════════════════════════════════════════════════════════════════════
// 
// This is the DEDICATED OUTCOMES CREATION SCREEN with its OWN SPECIFIC UI
// 
// OUTCOMES HAS DIFFERENT FEATURES THAN LIBRARY:
// - Outcome type chips (Message, Content, Task, Idea, Note)
// - Reminder picker for setting alarms
// - Completion checkbox for tasks
// - hiddenInLibrary: true (only shows in outcomes tab)
// 
// ⛔ DO NOT:
// - Consolidate this with RichTextEditor
// - Remove any features from this screen
// - Touch this file unless specifically asked by the user
// - Apply library changes to outcomes
// 
// 🔒 OUTCOMES IS COMPLETELY SEPARATE FROM LIBRARY
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../models/outcome_type.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_selection_dialog.dart';
import '../../services/reminder_manager.dart';
import '../../widgets/rich_text_editor.dart';

class OutcomeCreationScreen extends StatefulWidget {
  final String contentType; // 'text', 'image', 'voice'
  final String? initialText;
  final String? itemId; // For editing existing items

  const OutcomeCreationScreen({
    super.key,
    required this.contentType,
    this.initialText,
    this.itemId,
  });

  @override
  State<OutcomeCreationScreen> createState() => _OutcomeCreationScreenState();
}

class _OutcomeCreationScreenState extends State<OutcomeCreationScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late quill.QuillController _quillController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  OutcomeType? _selectedOutcomeType;
  List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  DateTime? _reminderDateTime;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController(text: widget.initialText ?? '');
    _quillController = quill.QuillController.basic();

    // Add listeners to track changes
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    // Load existing item if editing
    if (widget.itemId != null) {
      _loadExistingItem();
    } else {
      // Auto-focus content for new items
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentFocusNode.requestFocus();
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

  Future<void> _loadExistingItem() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final item = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
    
    if (item != null) {
      setState(() {
        _titleController.text = item.customTitle ?? '';
        // Load content
        _contentController.text = item.finalText;
        _selectedTags = List.from(item.tags);
        _reminderDateTime = item.reminderDateTime;
        _isCompleted = item.isCompleted;
        // Set outcome type from first outcome
        if (item.outcomes.isNotEmpty) {
          _selectedOutcomeType = OutcomeTypeExtension.fromString(item.outcomes.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
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

  Future<void> _showReminderPicker() async {
    final selectedDateTime = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDateTime != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _reminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6),
                onPrimary: Colors.white,
                surface: Color(0xFF1A1A1A),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          _reminderDateTime = DateTime(
            selectedDateTime.year,
            selectedDateTime.month,
            selectedDateTime.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          _hasUnsavedChanges = true;
        });
      }
    }
  }

  Future<void> _saveOutcome() async {
    if (_selectedOutcomeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an outcome type'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final plainText = _quillController.document.toPlainText().trim();
    // Fixed: Better empty check - Quill can have just newlines
    if (plainText.isEmpty || plainText.replaceAll('\n', '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content'),
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
      
      if (widget.itemId != null) {
        // Update existing item
        final existingItem = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
        if (existingItem != null) {
          final updatedItem = existingItem.copyWith(
            finalText: plainText,
            formattedContent: jsonEncode(_quillController.document.toDelta().toJson()),
            customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            tags: _selectedTags,
            outcomes: [_selectedOutcomeType!.toStorageString()],
            reminderDateTime: _reminderDateTime,
            isCompleted: _isCompleted,
          );
          await appState.updateRecording(updatedItem);
        }
      } else {
        // Create new item
        final newItem = RecordingItem(
          id: const Uuid().v4(),
          rawTranscript: widget.contentType == 'voice' ? '' : plainText,
          finalText: plainText,
          formattedContent: jsonEncode(_quillController.document.toDelta().toJson()),
          presetUsed: '${_selectedOutcomeType!.displayName} (${widget.contentType})',
          outcomes: [_selectedOutcomeType!.toStorageString()],
          projectId: null, // Outcomes don't belong to projects
          createdAt: DateTime.now(),
          editHistory: [plainText],
          presetId: '${_selectedOutcomeType!.toStorageString()}_${widget.contentType}',
          tags: _selectedTags,
          customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          contentType: widget.contentType,
          reminderDateTime: _reminderDateTime,
          isCompleted: _isCompleted,
          hiddenInLibrary: true, // Hide from library, show only in outcomes
        );

        await appState.saveRecording(newItem);

        // Schedule reminder if set
        if (_reminderDateTime != null) {
          await ReminderManager().scheduleReminder(newItem);
        }
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemId != null ? 'Outcome updated' : 'Outcome created'),
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

  List<Color> _getOutcomeColors(OutcomeType type) {
    switch (type) {
      case OutcomeType.message:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case OutcomeType.content:
        return [const Color(0xFF9333EA), const Color(0xFFEC4899)];
      case OutcomeType.task:
        return [const Color(0xFF10B981), const Color(0xFF14B8A6)];
      case OutcomeType.idea:
        return [const Color(0xFFF59E0B), const Color(0xFFF97316)];
      case OutcomeType.note:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF22D3EE); // Outcomes color

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Scrollable even when empty
          slivers: [
            // Collapsible app bar (header disappears on scroll)
            SliverAppBar(
              backgroundColor: backgroundColor,
              pinned: false,
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () async {
                  if (await _onWillPop()) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              title: Text(
                widget.itemId != null ? 'Edit Outcome' : 'Create Outcome',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              actions: [
                // Reminder button
                IconButton(
                  onPressed: _showReminderPicker,
                  icon: Icon(
                    _reminderDateTime != null ? Icons.alarm : Icons.alarm_add,
                    color: _reminderDateTime != null ? primaryColor : secondaryTextColor,
                  ),
                ),
                // Save button
                TextButton(
                  onPressed: _isLoading ? null : _saveOutcome,
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
            
            // Scrollable content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Outcome Type Selection (Required)
                  Text(
                    'Select Outcome Type *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Outcome Type Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: OutcomeType.values.map((outcomeType) {
                      return OutcomeChip(
                        outcomeType: outcomeType,
                        isSelected: _selectedOutcomeType == outcomeType,
                        onTap: () {
                          setState(() {
                            _selectedOutcomeType = outcomeType;
                            _hasUnsavedChanges = true;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),

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

                  // Reminder display
                  if (_reminderDateTime != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alarm, color: primaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Reminder: ${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year} at ${_reminderDateTime!.hour.toString().padLeft(2, '0')}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: primaryColor, fontSize: 12),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _reminderDateTime = null;
                                _hasUnsavedChanges = true;
                              });
                            },
                            child: Icon(Icons.close, color: primaryColor, size: 16),
                          ),
                        ],
                      ),
                    ),

                  // Completion checkbox
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCompleted = !_isCompleted;
                            _hasUnsavedChanges = true;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCompleted ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          child: _isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mark as completed',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title field
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: _selectedOutcomeType != null 
                            ? '${_selectedOutcomeType!.displayName} title (optional)'
                            : 'Title (optional)',
                        hintStyle: const TextStyle(color: secondaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // ══════════════════════════════════════════
                  // QUILL TOOLBAR (Between title and content)
                  // ══════════════════════════════════════════
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: quill.QuillToolbar.simple(
                      configurations: quill.QuillSimpleToolbarConfigurations(
                        controller: _quillController,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showColorButton: true,
                        showBackgroundColorButton: true,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: true,
                        showCodeBlock: true,
                        showQuote: true,
                        showIndent: true,
                        showLink: true,
                        showUndo: true,
                        showRedo: true,
                        multiRowsDisplay: false,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Content field with Quill editor
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5, // Half screen minimum
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scaffoldBackgroundColor: Colors.transparent,
                        canvasColor: Colors.transparent,
                      ),
                      child: quill.QuillEditor.basic(
                        configurations: quill.QuillEditorConfigurations(
                          controller: _quillController,
                          padding: const EdgeInsets.all(16),
                          placeholder: _selectedOutcomeType != null 
                              ? 'Write your ${_selectedOutcomeType!.displayName.toLowerCase()}...'
                              : 'Start writing...',
                          scrollPhysics: const ClampingScrollPhysics(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status row
                  if (_hasUnsavedChanges)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Unsaved changes',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  // Extra space at bottom for scrolling
                  const SizedBox(height: 200),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}