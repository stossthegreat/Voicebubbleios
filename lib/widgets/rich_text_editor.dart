import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../services/refinement_service.dart';
import '../models/outcome_type.dart';
import './outcome_chip.dart';

// ============================================================
//        RICH TEXT EDITOR WIDGET — WITH AI SELECTION MENU
// ============================================================

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
  
  // Context-aware features
  final bool showOutcomeChips;
  final OutcomeType? initialOutcomeType;
  final Function(OutcomeType)? onOutcomeChanged;
  
  final bool showReminderButton;
  final DateTime? initialReminder;
  final Function(DateTime?)? onReminderChanged;
  
  final bool showCompletionCheckbox;
  final bool initialCompletion;
  final Function(bool)? onCompletionChanged;
  
  final bool showImageSection;
  final String? initialImagePath;
  final Function(String?)? onImageChanged;
  
  // Top toolbar actions (Google Keep style)
  final bool showTopToolbar;
  final bool isPinned;
  final Function(bool)? onPinChanged;
  final Function(String)? onVoiceNoteAdded;

  const RichTextEditor({
    super.key,
    this.initialFormattedContent,
    this.initialPlainText,
    required this.onSave,
    this.readOnly = false,
    this.showOutcomeChips = false,
    this.initialOutcomeType,
    this.onOutcomeChanged,
    this.showReminderButton = false,
    this.initialReminder,
    this.onReminderChanged,
    this.showCompletionCheckbox = false,
    this.initialCompletion = false,
    this.onCompletionChanged,
    this.showImageSection = false,
    this.initialImagePath,
    this.onImageChanged,
    this.showTopToolbar = true,
    this.isPinned = false,
    this.onPinChanged,
    this.onVoiceNoteAdded,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> with TickerProviderStateMixin {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _saveTimer;
  Timer? _selectionTimer;
  bool _showSaved = false;
  bool _hasUnsavedChanges = false;
  late AnimationController _saveIndicatorController;
  late Animation<double> _saveIndicatorAnimation;
  int _wordCount = 0;
  int _characterCount = 0;
  
  // Selection tracking
  bool _hasSelection = false;
  String _selectedText = '';
  int _selectionStart = 0;
  int _selectionEnd = 0;
  
  // Context-aware state
  OutcomeType? _selectedOutcomeType;
  DateTime? _reminderDateTime;
  bool _isCompleted = false;
  File? _selectedImage;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _controller.addListener(_onControllerChanged);
    
    // Initialize context-aware state
    _selectedOutcomeType = widget.initialOutcomeType;
    _reminderDateTime = widget.initialReminder;
    _isCompleted = widget.initialCompletion;
    _imagePath = widget.initialImagePath;
    _isPinned = widget.isPinned;
    
    _saveIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _saveIndicatorController, curve: Curves.easeInOut),
    );
  }

  void _initializeController() {
    quill.Document doc;
    
    if (widget.initialFormattedContent != null && widget.initialFormattedContent!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.initialFormattedContent!);
        doc = quill.Document.fromJson(deltaJson);
      } catch (e) {
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
    _selectionTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    _saveIndicatorController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.readOnly) return;
    
    // Update word/character count
    final plainText = _controller.document.toPlainText();
    final words = plainText.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    setState(() {
      _hasUnsavedChanges = true;
      _showSaved = false;
      _wordCount = words;
      _characterCount = plainText.length;
    });

    // Check selection with debounce
    _selectionTimer?.cancel();
    _selectionTimer = Timer(const Duration(milliseconds: 200), _checkSelection);

    // Auto-save with debounce
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveContent);
  }

  void _checkSelection() {
    if (!mounted) return;
    
    final selection = _controller.selection;
    final plainText = _controller.document.toPlainText();
    
    if (selection.baseOffset != selection.extentOffset) {
      final start = selection.start;
      final end = selection.end;
      
      if (end <= plainText.length) {
        final text = plainText.substring(start, end);
        if (text.trim().length > 1) {
          setState(() {
            _hasSelection = true;
            _selectedText = text;
            _selectionStart = start;
            _selectionEnd = end;
          });
          return;
        }
      }
    }
    
    if (_hasSelection) {
      setState(() {
        _hasSelection = false;
        _selectedText = '';
      });
    }
  }

  Future<void> _saveContent() async {
    if (!mounted) return;
    
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
      debugPrint('Save error: $e');
    }
  }

  void _showAIMenu() {
    if (_selectedText.isEmpty) return;
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AIMenuSheet(
        selectedText: _selectedText,
        onResult: (newText) {
          Navigator.pop(ctx);
          _replaceSelection(newText);
        },
      ),
    );
  }

  void _replaceSelection(String newText) {
    _controller.replaceText(
      _selectionStart,
      _selectionEnd - _selectionStart,
      newText,
      null,
    );
    
    setState(() {
      _hasSelection = false;
      _selectedText = '';
    });
    
    HapticFeedback.mediumImpact();
  }

  // Context-aware helper methods
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(path.join(appDir.path, 'images'));
        
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        
        final fileName = '${const Uuid().v4()}.jpg';
        final savedImage = File(path.join(imagesDir.path, fileName));
        await File(image.path).copy(savedImage.path);
        
        setState(() {
          _selectedImage = savedImage;
          _imagePath = savedImage.path;
        });
        
        widget.onImageChanged?.call(savedImage.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(path.join(appDir.path, 'images'));
        
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        
        final fileName = '${const Uuid().v4()}.jpg';
        final savedImage = File(path.join(imagesDir.path, fileName));
        await File(image.path).copy(savedImage.path);
        
        setState(() {
          _selectedImage = savedImage;
          _imagePath = savedImage.path;
        });
        
        widget.onImageChanged?.call(savedImage.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _imagePath = null;
                    });
                    widget.onImageChanged?.call(null);
                  },
                ),
            ],
          ),
        );
      },
    );
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

    if (selectedDateTime != null && mounted) {
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

      if (selectedTime != null && mounted) {
        final newReminder = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          _reminderDateTime = newReminder;
        });
        widget.onReminderChanged?.call(newReminder);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF1A1A1A);

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
                // Top toolbar (Google Keep style) - Row 1
                if (widget.showTopToolbar && !widget.readOnly)
                  Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Pin button
                        IconButton(
                          icon: Icon(
                            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: _isPinned ? const Color(0xFFF59E0B) : Colors.white70,
                            size: 20,
                          ),
                          onPressed: _togglePin,
                          tooltip: 'Pin',
                        ),
                        // Add image button
                        IconButton(
                          icon: const Icon(Icons.image_outlined, color: Colors.white70, size: 20),
                          onPressed: _insertImageAtCursor,
                          tooltip: 'Add image',
                        ),
                        // Take photo button
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 20),
                          onPressed: _takePhotoAtCursor,
                          tooltip: 'Take photo',
                        ),
                        // Voice note button
                        IconButton(
                          icon: Icon(
                            _isRecordingVoiceNote ? Icons.stop_circle : Icons.mic_outlined,
                            color: _isRecordingVoiceNote ? const Color(0xFFEF4444) : Colors.white70,
                            size: 20,
                          ),
                          onPressed: _toggleVoiceNoteRecording,
                          tooltip: _isRecordingVoiceNote ? 'Stop recording' : 'Record voice note',
                        ),
                        // Add checkbox button
                        IconButton(
                          icon: const Icon(Icons.check_box_outlined, color: Colors.white70, size: 20),
                          onPressed: _insertCheckboxAtCursor,
                          tooltip: 'Add checkbox',
                        ),
                        const Spacer(),
                        // More options menu
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                          onPressed: () {
                            // TODO: Show more options menu
                          },
                          tooltip: 'More options',
                        ),
                      ],
                    ),
                  ),
                
                // Context-aware header sections (for outcomes only)
                
                // Outcome chips section (for outcomes tab)
                if (widget.showOutcomeChips)
                  Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Outcome Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: OutcomeType.values.map((outcomeType) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: OutcomeChip(
                                  outcomeType: outcomeType,
                                  isSelected: _selectedOutcomeType == outcomeType,
                                  onTap: () {
                                    setState(() {
                                      _selectedOutcomeType = outcomeType;
                                    });
                                    widget.onOutcomeChanged?.call(outcomeType);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Reminder and completion controls (for outcomes/todos)
                if (widget.showReminderButton || widget.showCompletionCheckbox)
                  Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Completion checkbox
                        if (widget.showCompletionCheckbox)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCompleted = !_isCompleted;
                              });
                              widget.onCompletionChanged?.call(_isCompleted);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              child: _isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        if (widget.showCompletionCheckbox)
                          const SizedBox(width: 8),
                        if (widget.showCompletionCheckbox)
                          const Text(
                            'Completed',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        
                        const Spacer(),
                        
                        // Reminder button
                        if (widget.showReminderButton)
                          GestureDetector(
                            onTap: _showReminderPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _reminderDateTime != null 
                                    ? const Color(0xFF3B82F6).withOpacity(0.2)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                                border: _reminderDateTime != null
                                    ? Border.all(color: const Color(0xFF3B82F6))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _reminderDateTime != null ? Icons.alarm : Icons.alarm_add,
                                    size: 16,
                                    color: _reminderDateTime != null 
                                        ? const Color(0xFF3B82F6)
                                        : Colors.white.withOpacity(0.7),
                                  ),
                                  if (_reminderDateTime != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_reminderDateTime!.day}/${_reminderDateTime!.month} ${_reminderDateTime!.hour.toString().padLeft(2, '0')}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _reminderDateTime = null;
                                        });
                                        widget.onReminderChanged?.call(null);
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Image section (for image content types)
                if (widget.showImageSection)
                  Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _imagePath != null ? Icons.edit : Icons.add_photo_alternate,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _imagePath != null ? 'Change' : 'Add',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_imagePath != null && File(_imagePath!).existsSync()) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Quill formatting toolbar (Row 2) - scrollable
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
                        showStrikeThrough: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: true,
                        showCodeBlock: false,
                        showQuote: false,
                        showIndent: false,
                        showLink: false,
                        showUndo: true,
                        showRedo: true,
                        showDirection: false,
                        showSearchButton: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showSmallButton: false,
                        showInlineCode: false,
                        showClearFormat: false,
                        showHeaderStyle: true,
                        showAlignmentButtons: false,
                      ),
                    ),
                  ),

                // Editor content (Row 3+)
                Expanded(
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: quill.QuillEditor.basic(
                      focusNode: _focusNode,
                      configurations: quill.QuillEditorConfigurations(
                        controller: _controller,
                        padding: EdgeInsets.zero,
                        autoFocus: !widget.readOnly,
                        expands: true,
                        placeholder: 'Start typing...',
                        readOnly: widget.readOnly,
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null,
                          ),
                          placeHolder: quill.DefaultTextBlockStyle(
                            TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Status bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_wordCount words • $_characterCount characters',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      const Spacer(),
                      if (_hasUnsavedChanges)
                        const Row(
                          children: [
                            Icon(Icons.circle, color: Color(0xFFF59E0B), size: 6),
                            SizedBox(width: 6),
                            Text('Unsaved', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                          ],
                        ),
                      if (_showSaved)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('Saved', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // AI BUTTON - shows when text selected
            if (_hasSelection)
              Positioned(
                right: 16,
                bottom: 60,
                child: FloatingActionButton.small(
                  onPressed: _showAIMenu,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: const Icon(Icons.auto_awesome, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// AI MENU BOTTOM SHEET
// ============================================================

class _AIMenuSheet extends StatefulWidget {
  final String selectedText;
  final Function(String) onResult;

  const _AIMenuSheet({required this.selectedText, required this.onResult});

  @override
  State<_AIMenuSheet> createState() => _AIMenuSheetState();
}

class _AIMenuSheetState extends State<_AIMenuSheet> {
  bool _loading = false;
  String? _active;
  final _service = RefinementService();

  Future<void> _run(String id) async {
    if (_loading) return;
    setState(() { _loading = true; _active = id; });

    try {
      String result;
      switch (id) {
        case 'magic': result = await _service.refineText(widget.selectedText, RefinementType.professional); break;
        case 'shorten': result = await _service.shorten(widget.selectedText); break;
        case 'expand': result = await _service.expand(widget.selectedText); break;
        case 'pro': result = await _service.makeProfessional(widget.selectedText); break;
        case 'casual': result = await _service.makeCasual(widget.selectedText); break;
        case 'grammar': result = await _service.fixGrammar(widget.selectedText); break;
        default: result = widget.selectedText;
      }
      widget.onResult(result);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
              SizedBox(width: 8),
              Text('AI Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          // Magic button - full width
          _btn('magic', '✨ Magic', Icons.auto_awesome, const Color(0xFF8B5CF6)),
          const SizedBox(height: 8),
          // Buttons
          Row(children: [
            _btn('shorten', 'Shorten', Icons.compress, const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _btn('expand', 'Expand', Icons.expand, const Color(0xFF3B82F6)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _btn('pro', 'Professional', Icons.work, const Color(0xFF0891B2)),
            const SizedBox(width: 8),
            _btn('casual', 'Casual', Icons.mood, const Color(0xFF10B981)),
          ]),
          const SizedBox(height: 8),
          _btn('grammar', 'Fix Grammar', Icons.check, const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _btn(String id, String label, IconData icon, Color color) {
    final isActive = _active == id && _loading;
    return Expanded(
      child: GestureDetector(
        onTap: () => _run(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TOP TOOLBAR HELPER METHODS (Google Keep style)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _insertImageAtCursor() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Save image permanently
        final appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${const Uuid().v4()}.jpg';
        final String permanentPath = '${appDir.path}/images/$fileName';
        
        await Directory('${appDir.path}/images').create(recursive: true);
        await File(image.path).copy(permanentPath);
        
        // Insert image reference at cursor position
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n[Image: $permanentPath]\n');
        _controller.updateSelection(
          TextSelection.collapsed(offset: index + permanentPath.length + 12),
          ChangeSource.local,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  Future<void> _takePhotoAtCursor() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        // Save image permanently
        final appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${const Uuid().v4()}.jpg';
        final String permanentPath = '${appDir.path}/images/$fileName';
        
        await Directory('${appDir.path}/images').create(recursive: true);
        await File(image.path).copy(permanentPath);
        
        // Insert image reference at cursor position
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n[Image: $permanentPath]\n');
        _controller.updateSelection(
          TextSelection.collapsed(offset: index + permanentPath.length + 12),
          ChangeSource.local,
        );
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  Future<void> _toggleVoiceNoteRecording() async {
    if (_isRecordingVoiceNote) {
      // Stop recording
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        // Insert voice note reference at cursor
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, '\n🎤 [Voice Note: $path]\n');
        _controller.updateSelection(
          TextSelection.collapsed(offset: index + path.length + 18),
          ChangeSource.local,
        );
        widget.onVoiceNoteAdded?.call(path);
      }
      setState(() {
        _isRecordingVoiceNote = false;
        _currentRecordingPath = null;
      });
    } else {
      // Start recording
      if (await _audioRecorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${const Uuid().v4()}.m4a';
        final String recordPath = '${appDir.path}/voice_notes/$fileName';
        
        await Directory('${appDir.path}/voice_notes').create(recursive: true);
        
        await _audioRecorder.start(const RecordConfig(), path: recordPath);
        setState(() {
          _isRecordingVoiceNote = true;
          _currentRecordingPath = recordPath;
        });
      }
    }
  }
  
  void _insertCheckboxAtCursor() {
    final index = _controller.selection.baseOffset;
    // Use Quill's built-in checkbox attribute
    _controller.document.insert(index, '\n');
    _controller.formatText(index, 1, quill.Attribute.unchecked);
    _controller.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      ChangeSource.local,
    );
  }
  
  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned;
    });
    widget.onPinChanged?.call(_isPinned);
  }
}

