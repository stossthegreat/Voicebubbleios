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
import '../../services/continue_service.dart';
import '../../constants/presets.dart';
import 'recording_screen.dart';

class RecordingDetailScreen extends StatelessWidget {
  final String recordingId;

  const RecordingDetailScreen({
    super.key,
    required this.recordingId,
  });

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
              (r) => r.id == recordingId,
              orElse: () => throw Exception('Recording not found'),
            );

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Recording Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Delete button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showDeleteOptions(context, appState, item.id),
                          icon: Icon(Icons.more_vert, color: textColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips: Preset chip (large) + Outcome chips (smaller)
                        Consumer<AppStateProvider>(
                          builder: (context, appState, _) {
                            final tags = appState.tags;
                            final itemTags = item.tags
                                .map((tagId) => tags.where((t) => t.id == tagId).firstOrNull)
                                .where((t) => t != null)
                                .cast<Tag>()
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Preset chip - FIRST and prominent
                                    if (AppPresets.findById(item.presetId) != null)
                                      PresetChip(
                                        preset: AppPresets.findById(item.presetId)!,
                                        isLarge: true,
                                      ),
                                    
                                    // Outcome chips - SECOND and smaller
                                    if (item.outcomes.isNotEmpty)
                                      ...item.outcomeTypes.map((outcome) {
                                        return OutcomeChip(
                                          outcomeType: outcome,
                                          isSelected: true,
                                          onTap: () {}, // Read-only
                                        );
                                      }).toList(),
                                  ],
                                ),
                                
                                // Tags section - separate row below preset/outcome
                                if (itemTags.isNotEmpty || true) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // Existing tag chips
                                      ...itemTags.map((tag) {
                                        return TagChip(
                                          tag: tag,
                                          size: 'small',
                                          showRemove: true,
                                          onRemove: () async {
                                            await appState.removeTagFromRecording(item.id, tag.id);
                                          },
                                        );
                                      }).toList(),
                                      
                                      // Add Tag button
                                      GestureDetector(
                                        onTap: () async {
                                          final result = await showModalBottomSheet<bool>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => AddTagBottomSheet(
                                              recordingId: item.id,
                                              currentTags: item.tags,
                                            ),
                                          );
                                          // UI will update automatically via Provider
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFF3B82F6).withOpacity(0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                size: 12,
                                                color: const Color(0xFF3B82F6),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Add Tag',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Date
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Full text (not truncated)
                        Container(
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
                          child: SelectableText(
                            item.finalText,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            // Copy button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item.finalText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard'),
                                      backgroundColor: Color(0xFF10B981),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: surfaceColor,
                                  foregroundColor: textColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Share button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(item.finalText);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: surfaceColor,
                                  foregroundColor: textColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleContinue(context, appState, item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Add to Project button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => AddToProjectDialog(
                                  recordingItemId: item.id,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.folder_outlined, size: 20, color: primaryColor),
                            label: Text(
                              'Add to Project',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
  
  void _showDeleteOptions(BuildContext context, AppStateProvider appState, String itemId) {
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
                leading: const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                title: const Text('Delete Permanently', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _showDeleteConfirmation(context, appState, itemId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
