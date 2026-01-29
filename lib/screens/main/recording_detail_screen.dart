import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../models/tag.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/preset_chip.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/add_tag_bottom_sheet.dart';
import '../../widgets/add_to_project_dialog.dart';
import '../../widgets/rich_text_editor.dart';
import '../../services/continue_service.dart';
import '../../constants/presets.dart';
import 'recording_screen.dart';

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
            final item = appState.recordingItems.firstWhere(
              (r) => r.id == widget.recordingId,
              orElse: () => throw Exception('Recording not found'),
            );

            return Column(
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
                        child: Text(
                          _getTitleFromContent(item.finalText),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

                // Rich Text Editor (FULL SCREEN)
                Expanded(
                  child: RichTextEditor(
                    initialFormattedContent: item.formattedContent,
                    initialPlainText: item.finalText,
                    onSave: (plainText, deltaJson) => _saveContent(appState, item, plainText, deltaJson),
                    readOnly: false,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Floating Continue Button (bottom right)
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final item = appState.recordingItems.firstWhere(
            (r) => r.id == widget.recordingId,
            orElse: () => throw Exception('Recording not found'),
          );
          
          return FloatingActionButton(
            onPressed: () => _handleContinue(context, appState, item),
            backgroundColor: primaryColor,
            tooltip: 'Continue with AI',
            child: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getTitleFromContent(String content) {
    if (content.isEmpty) return 'Untitled';
    
    // Get first line or first 50 characters
    final firstLine = content.split('\n').first.trim();
    if (firstLine.length <= 50) return firstLine;
    
    return '${firstLine.substring(0, 47)}...';
  }

  Future<void> _saveContent(AppStateProvider appState, RecordingItem item, String plainText, String deltaJson) async {
    try {
      final updatedItem = item.copyWith(
        finalText: plainText,
        formattedContent: deltaJson,
      );
      
      await appState.updateRecording(updatedItem);
      debugPrint('✅ Saved formatted content for item: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error saving formatted content: $e');
    }
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
}