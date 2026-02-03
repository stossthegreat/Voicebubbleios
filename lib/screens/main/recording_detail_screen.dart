import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../models/tag.dart';
import '../../models/outcome_type.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/preset_chip.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/add_tag_bottom_sheet.dart';
import '../../widgets/add_to_project_dialog.dart';
import '../../widgets/rich_text_editor.dart';
import '../../services/continue_service.dart';
import '../../services/reminder_manager.dart';
import '../../constants/presets.dart';
import 'recording_screen.dart';
// ✨ NEW IMPORTS ✨
import '../version_history_screen.dart';
import '../../widgets/export_dialogs.dart';
import '../../widgets/background_picker.dart';
import '../../services/version_history_service.dart';
import '../../constants/visual_constants.dart';
// ✨ END NEW IMPORTS ✨

class RecordingDetailScreen extends StatefulWidget {
  final String recordingId;

  const RecordingDetailScreen({
    super.key,
    required this.recordingId,
  });

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            // Search in ALL items, not just recordingItems (which filters out outcome items)
            final item = appState.allRecordingItems.firstWhere(
              (r) => r.id == widget.recordingId,
              orElse: () => RecordingItem(
                id: widget.recordingId,
                rawTranscript: '',
                finalText: '',
                presetUsed: '',
                outcomes: [],
                projectId: null,
                createdAt: DateTime.now(),
                editHistory: [],
                presetId: '',
                tags: [],
                contentType: 'text',
              ),
            );

            // If item wasn't found in state yet, show loading
            if (!appState.allRecordingItems.any((r) => r.id == widget.recordingId)) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✨ BUILD BACKGROUND IF SET ✨
            Widget? backgroundWidget;
            if (item.background != null) {
              final bg = VisualConstants.findById(item.background!);
              if (bg != null) {
                backgroundWidget = Opacity(
                  opacity: 0.15, // Subtle so text is readable
                  child: bg.buildBackground(context),
                );
              }
            }
            // ✨ END BACKGROUND BUILD ✨

            return Stack(
              children: [
                // Background layer
                if (backgroundWidget != null)
                  Positioned.fill(child: backgroundWidget),
                
                // Content layer
                Column(
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: textColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isEditingTitle
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _titleController,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryColor),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        isDense: true,
                                      ),
                                      autofocus: true,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _saveTitle(appState, item),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.check, color: Colors.white, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _cancelEditingTitle,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.close, color: textColor, size: 16),
                                    ),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () => _startEditingTitle(item),
                                child: Text(
                                  _getDisplayTitle(item),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                      
                      // ✨ VERSION HISTORY BUTTON ✨
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VersionHistoryScreen(note: item),
                              ),
                            );
                          },
                          icon: Icon(Icons.history, color: primaryColor, size: 18),
                          tooltip: 'Version History',
                        ),
                      ),
                      // ✨ END VERSION HISTORY BUTTON ✨
                      
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert, color: textColor, size: 18),
                          color: surfaceColor,
                          onSelected: (value) => _handleMenuAction(context, appState, item, value),
                          itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'continue',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: primaryColor, size: 18),
                                const SizedBox(width: 12),
                                Text('Continue', style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, color: textColor, size: 18),
                                const SizedBox(width: 12),
                                Text('Share', style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'add_to_project',
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined, color: textColor, size: 18),
                                const SizedBox(width: 12),
                                Text('Add to Project', style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'manage_tags',
                            child: Row(
                              children: [
                                Icon(Icons.local_offer, color: textColor, size: 18),
                                const SizedBox(width: 12),
                                Text('Manage Tags', style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          // ✨ EXPORT MENU ITEM ✨
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download, color: textColor, size: 18),
                                const SizedBox(width: 12),
                                Text('Export', style: TextStyle(color: textColor)),
                              ],
                            ),
                          ),
                          // ✨ END NEW MENU ITEMS ✨
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content based on type
                Expanded(
                  child: _buildContentEditor(item, appState),
                ),
              ],
            ), // ← End of Column
              ], // ← End of Stack children
            ); // ← End of Stack
          },
        ),
      ),
      // Floating Continue Button (bottom right)
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final item = appState.allRecordingItems.firstWhere(
            (r) => r.id == widget.recordingId,
            orElse: () => appState.allRecordingItems.isNotEmpty
                ? appState.allRecordingItems.first
                : throw Exception('Recording not found'),
          );
          
          return FloatingActionButton.small(
            onPressed: () => _handleContinue(context, appState, item),
            backgroundColor: primaryColor,
            tooltip: 'Continue with AI',
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 20,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getDisplayTitle(RecordingItem item) {
    // Prioritize custom title over generated title
    if (item.customTitle != null && item.customTitle!.isNotEmpty) {
      return item.customTitle!;
    }
    return _getTitleFromContent(item.finalText);
  }
  
  String _getTitleFromContent(String content) {
    if (content.isEmpty) return 'Untitled';
    
    // Get first line or first 50 characters
    final firstLine = content.split('\n').first.trim();
    if (firstLine.length <= 50) return firstLine;
    
    return '${firstLine.substring(0, 47)}...';
  }
  
  void _startEditingTitle(RecordingItem item) {
    setState(() {
      _isEditingTitle = true;
      _titleController.text = item.customTitle ?? _getTitleFromContent(item.finalText);
    });
  }
  
  void _cancelEditingTitle() {
    setState(() {
      _isEditingTitle = false;
      _titleController.clear();
    });
  }
  
  Future<void> _saveTitle(AppStateProvider appState, RecordingItem item) async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty) {
      final updatedItem = item.copyWith(customTitle: newTitle);
      await appState.updateRecording(updatedItem);
    }
    setState(() {
      _isEditingTitle = false;
      _titleController.clear();
    });
  }

  Widget _buildContentEditor(RecordingItem item, AppStateProvider appState) {
    // ALWAYS use RichTextEditor with context-aware features
    return RichTextEditor(
      initialFormattedContent: item.formattedContent,
      initialPlainText: item.finalText,
      onSave: (plainText, deltaJson) => _saveContent(appState, item, plainText, deltaJson),
      readOnly: false,
      contentType: item.contentType, // Pass content type for auto-initialization
      // Context-aware features based on item type
      showImageSection: item.contentType == 'image',
      initialImagePath: item.contentType == 'image' ? item.rawTranscript : null,
      onImageChanged: (imagePath) => _updateItemImage(appState, item, imagePath),
      showOutcomeChips: item.outcomes.isNotEmpty,
      initialOutcomeType: item.outcomes.isNotEmpty ? OutcomeTypeExtension.fromString(item.outcomes.first) : null,
      onOutcomeChanged: (outcomeType) => _updateItemOutcome(appState, item, outcomeType),
      // Reminder button ONLY for outcomes (hiddenInLibrary = true)
      showReminderButton: item.hiddenInLibrary,
      initialReminder: item.reminderDateTime,
      onReminderChanged: (dateTime) => _updateItemReminder(appState, item, dateTime),
      showCompletionCheckbox: item.outcomes.isNotEmpty && item.hiddenInLibrary, // ONLY for outcomes, NOT library todos
      initialCompletion: item.isCompleted,
      onCompletionChanged: (completed) => _updateItemCompletion(appState, item, completed),
      // Top toolbar (Google Keep style) for library items
      showTopToolbar: !item.hiddenInLibrary, // Show for library, hide for outcomes
      isPinned: item.isPinned ?? false,
      onPinChanged: (pinned) => _updateItemPin(appState, item, pinned),
      onVoiceNoteAdded: (path) => _handleVoiceNoteAdded(appState, item, path),
      // Background support
      backgroundId: item.background,
      onBackgroundChanged: (backgroundId) => _updateItemBackground(appState, item, backgroundId),
    );
  }

  Future<void> _saveContent(AppStateProvider appState, RecordingItem item, String plainText, String deltaJson) async {
    try {
      final updatedItem = item.copyWith(
        finalText: plainText,
        formattedContent: deltaJson,
      );
      
      await appState.updateRecording(updatedItem);
      
      // ✨ AUTO-SAVE TO VERSION HISTORY ✨
      final versionService = VersionHistoryService();
      await versionService.saveVersion(updatedItem, 'Auto-save');
      // ✨ END AUTO-SAVE ✨
      
      debugPrint('✅ Saved formatted content for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error saving formatted content: $e');
    }
  }
  
  // Context-aware update methods
  
  Future<void> _updateItemImage(AppStateProvider appState, RecordingItem item, String? imagePath) async {
    try {
      final updatedItem = item.copyWith(
        rawTranscript: imagePath ?? '', // Store image path in rawTranscript
      );
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Updated image for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating image: $e');
    }
  }
  
  Future<void> _updateItemOutcome(AppStateProvider appState, RecordingItem item, OutcomeType outcomeType) async {
    try {
      final updatedItem = item.copyWith(
        outcomes: [outcomeType.toStorageString()],
      );
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Updated outcome for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating outcome: $e');
    }
  }
  
  Future<void> _updateItemReminder(AppStateProvider appState, RecordingItem item, DateTime? dateTime) async {
    try {
      final updatedItem = item.copyWith(
        reminderDateTime: dateTime,
      );
      await appState.updateRecording(updatedItem);
      
      // Schedule or cancel reminder
      if (dateTime != null) {
        await ReminderManager().scheduleReminder(updatedItem);
      } else {
        await ReminderManager().cancelReminder(updatedItem);
      }
      
      debugPrint('✅ Updated reminder for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating reminder: $e');
    }
  }
  
  Future<void> _updateItemCompletion(AppStateProvider appState, RecordingItem item, bool completed) async {
    try {
      final updatedItem = item.copyWith(
        isCompleted: completed,
      );
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Updated completion for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating completion: $e');
    }
  }
  
  Future<void> _updateItemPin(AppStateProvider appState, RecordingItem item, bool pinned) async {
    try {
      final updatedItem = item.copyWith(
        isPinned: pinned,
      );
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Updated pin status for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating pin: $e');
    }
  }
  
  Future<void> _handleVoiceNoteAdded(AppStateProvider appState, RecordingItem item, String voiceNotePath) async {
    debugPrint('🎤 Voice note added at: $voiceNotePath');
    // Voice note is already inserted into the document text by RichTextEditor
    // Just log it here for reference
  }

  void _handleMenuAction(BuildContext context, AppStateProvider appState, RecordingItem item, String action) {
    switch (action) {
      case 'continue':
        _handleContinue(context, appState, item);
        break;
      case 'share':
        Share.share(item.finalText);
        break;
      case 'add_to_project':
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => AddToProjectDialog(
            recordingItemId: item.id,
          ),
        );
        break;
      case 'manage_tags':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddTagBottomSheet(
            recordingId: item.id,
            currentTags: item.tags,
          ),
        );
        break;
      // ✨ EXPORT HANDLER ✨
      case 'export':
        showDialog(
          context: context,
          builder: (_) => ExportDialog(note: item),
        );
        break;
      // ✨ END NEW HANDLERS ✨
      case 'delete':
        _showDeleteConfirmation(context, appState, item.id);
        break;
    }
  }

  void _handleContinue(BuildContext context, AppStateProvider appState, RecordingItem item) async {
    try {
      // Build continue context from this single item
      final continueService = ContinueService();
      final continueContext = await continueService.buildContextFromItem(item.id);
      
      // Set the context
      appState.setContinueContext(continueContext);
      
      // Navigate to recording screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RecordingScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up continue: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, AppStateProvider appState, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Recording?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await appState.deleteRecording(itemId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to library
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recording deleted'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItemBackground(AppStateProvider appState, RecordingItem item, String? backgroundId) async {
    try {
      final updatedItem = item.copyWith(background: backgroundId);
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Updated background for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error updating background: $e');
    }
  }
}