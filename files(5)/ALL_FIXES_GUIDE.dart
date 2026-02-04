// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║                        ALL FIXES - COPY/PASTE GUIDE                          ║
// ║                                                                              ║
// ║  This file contains ALL the fixes you need to apply to existing files.       ║
// ║  Search for the "FIND:" text in each file and replace with "REPLACE WITH:"   ║
// ╚══════════════════════════════════════════════════════════════════════════════╝


// ════════════════════════════════════════════════════════════════════════════════
// FIX 1: CONTINUE FEATURE BROKEN
// File: lib/screens/main/recording_detail_screen.dart
// Problem: FAB uses recordingItems (filtered) instead of allRecordingItems
// ════════════════════════════════════════════════════════════════════════════════

// FIND:
/*
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final item = appState.recordingItems.firstWhere(
            (r) => r.id == widget.recordingId,
            orElse: () => throw Exception('Recording not found'),
          );
*/

// REPLACE WITH:
/*
      floatingActionButton: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final item = appState.allRecordingItems.firstWhere(
            (r) => r.id == widget.recordingId,
            orElse: () => throw Exception('Recording not found'),
          );
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 2: BATCH TAG DIALOG NOT REFRESHING
// File: lib/screens/batch_operations_screen.dart
// Problem: After creating tag, list doesn't refresh
// ════════════════════════════════════════════════════════════════════════════════

// ADD THIS IMPORT AT TOP:
/*
import '../widgets/create_tag_dialog.dart';
*/

// FIND the entire _showTagSelection() method and REPLACE WITH:
/*
  void _showTagSelection() async {
    final appState = context.read<AppStateProvider>();
    
    // Always refresh tags first to get latest
    await appState.refreshTags();
    
    var availableTags = appState.tags;

    // If no tags, offer to create one
    if (availableTags.isEmpty) {
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('No Tags Available', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You don\'t have any tags yet. Would you like to create one now?',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create Tag', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
          ],
        ),
      );

      if (shouldCreate == true && mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const CreateTagDialog(),
        );
        if (result == true) {
          await appState.refreshTags();
          // Call again to show the tag list now
          if (mounted) _showTagSelection();
        }
      }
      return;
    }

    // Show tag selection dialog
    final selectedTagId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Add Tag to Notes',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableTags.length,
            itemBuilder: (context, index) {
              final tag = availableTags[index];
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(tag.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  tag.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, tag.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Create new tag
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => const CreateTagDialog(),
              );
              if (result == true) {
                await appState.refreshTags();
                if (mounted) _showTagSelection();
              }
            },
            child: const Text('Create New', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );

    if (selectedTagId != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adding tag to ${_selectedNotes.length} notes...'),
            backgroundColor: const Color(0xFF3B82F6),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _batchService.addTagToNotes(_selectedNotes, selectedTagId, appState);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag added to ${_selectedNotes.length} notes!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        setState(() => _selectedIds.clear());
      }
    }
  }
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 3: WORD COUNT OVERLAPPING MIC BUTTON
// File: lib/widgets/rich_text_editor.dart
// Problem: Bottom status bar doesn't leave room for FAB
// ════════════════════════════════════════════════════════════════════════════════

// FIND:
/*
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
*/

// REPLACE WITH:
/*
                Container(
                  padding: const EdgeInsets.only(left: 8, right: 80, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 4: OUTCOME CHIPS NOT SENDING TO OUTCOMES TAB
// File: lib/screens/main/result_screen.dart
// Problem: hiddenInLibrary not set when outcomes selected
// ════════════════════════════════════════════════════════════════════════════════

// FIX 4A: In _saveRecording() method, find where RecordingItem is created:

// FIND:
/*
        final item = RecordingItem(
          id: itemId,
          rawTranscript: appState.transcription,
          finalText: _rewrittenText,
          presetUsed: appState.selectedPreset?.name ?? 'Unknown',
          outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
          projectId: continueContext?.projectId,
          createdAt: DateTime.now(),
          editHistory: List.from(_textHistory),
          presetId: appState.selectedPreset?.id ?? '',
          continuedFromId: continueContext?.singleItemId,
          contentType: 'voice',
        );
*/

// REPLACE WITH:
/*
        final item = RecordingItem(
          id: itemId,
          rawTranscript: appState.transcription,
          finalText: _rewrittenText,
          presetUsed: appState.selectedPreset?.name ?? 'Unknown',
          outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
          projectId: continueContext?.projectId,
          createdAt: DateTime.now(),
          editHistory: List.from(_textHistory),
          presetId: appState.selectedPreset?.id ?? '',
          continuedFromId: continueContext?.singleItemId,
          contentType: 'voice',
          hiddenInLibrary: _selectedOutcomes.isNotEmpty,  // ← ADD THIS LINE
        );
*/


// FIX 4B: In _updateExistingItem() method:

// FIND:
/*
      final updatedItem = existingItem.copyWith(
        outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
        finalText: _rewrittenText,
        editHistory: List.from(_textHistory),
      );
*/

// REPLACE WITH:
/*
      final updatedItem = existingItem.copyWith(
        outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
        finalText: _rewrittenText,
        editHistory: List.from(_textHistory),
        hiddenInLibrary: _selectedOutcomes.isNotEmpty,  // ← ADD THIS LINE
      );
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 5: RECORDING SCREEN - ADD COUNTDOWN TIMER + USAGE TRACKING
// File: lib/screens/main/recording_screen.dart
// ════════════════════════════════════════════════════════════════════════════════

// ADD THESE IMPORTS AT TOP:
/*
import '../../widgets/stt_countdown_timer.dart';
import '../../services/feature_gate.dart';
*/

// ADD countdown timer state variable:
/*
  bool _isRecording = false;  // You probably already have this
*/

// ADD THIS WIDGET above your waveform in build():
/*
            // Countdown timer at top
            STTCountdownTimer(
              isRecording: _isRecording,
              onLimitReached: () {
                // Stop recording and show limit dialog
                _stopRecording();
                LimitReachedDialog.show(context);
              },
            ),
            
            const SizedBox(height: 16),
            
            // ... your existing waveform widget ...
*/

// MODIFY _startRecording() to check access:
/*
  Future<void> _startRecording() async {
    // CHECK ACCESS FIRST
    final canUse = await FeatureGate.canUseSTT(context);
    if (!canUse) return;
    
    // ... your existing recording start logic ...
    
    setState(() {
      _isRecording = true;
    });
  }
*/

// MODIFY _stopRecording() to track usage:
/*
  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
    });
    
    // ... your existing stop logic ...
    
    // TRACK USAGE (get actual duration from your recorder)
    final durationSeconds = _recordingDuration?.inSeconds ?? 0;
    await FeatureGate.trackSTTUsage(durationSeconds);
    
    // ... continue to transcription ...
  }
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 6: RICH TEXT EDITOR - BLOCK HIGHLIGHT AI FOR FREE USERS
// File: lib/widgets/rich_text_editor.dart
// ════════════════════════════════════════════════════════════════════════════════

// ADD IMPORT AT TOP:
/*
import '../services/feature_gate.dart';
*/

// FIND _showAIMenu() method and ADD check at the start:
/*
  Future<void> _showAIMenu() async {
    // CHECK PRO ACCESS FIRST
    final canUse = await FeatureGate.canUseHighlightAI(context);
    if (!canUse) return;
    
    // ... rest of existing AI menu logic ...
  }
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 7: SETTINGS SCREEN - ADD USAGE WIDGET
// File: lib/screens/settings_screen.dart (or wherever your settings are)
// ════════════════════════════════════════════════════════════════════════════════

// ADD IMPORT:
/*
import '../widgets/usage_display_widget.dart';
*/

// ADD THIS WIDGET in your settings list:
/*
            const SizedBox(height: 16),
            
            // STT & AI Usage
            const UsageDisplayWidget(),
            
            const SizedBox(height: 16),
*/


// ════════════════════════════════════════════════════════════════════════════════
// FIX 8: ADD PAYWALL ROUTE
// File: lib/main.dart (or your routes file)
// ════════════════════════════════════════════════════════════════════════════════

// ADD IMPORT:
/*
import 'screens/paywall_screen.dart';
*/

// ADD ROUTE in your MaterialApp routes:
/*
        '/paywall': (context) => const PaywallScreen(),
*/


// ════════════════════════════════════════════════════════════════════════════════
// SUMMARY OF ALL FILES TO MODIFY:
// ════════════════════════════════════════════════════════════════════════════════
/*

1. lib/screens/main/recording_detail_screen.dart
   - Change recordingItems → allRecordingItems in FAB

2. lib/screens/batch_operations_screen.dart
   - Add import for CreateTagDialog
   - Replace entire _showTagSelection() method

3. lib/widgets/rich_text_editor.dart
   - Change padding from symmetric to only (add right: 80)
   - Add FeatureGate import
   - Add canUseHighlightAI check in _showAIMenu()

4. lib/screens/main/result_screen.dart
   - Add hiddenInLibrary in _saveRecording()
   - Add hiddenInLibrary in _updateExistingItem()

5. lib/screens/main/recording_screen.dart
   - Add imports for timer and feature gate
   - Add STTCountdownTimer widget above waveform
   - Add canUseSTT check in _startRecording()
   - Add trackSTTUsage in _stopRecording()

6. lib/screens/settings_screen.dart
   - Add UsageDisplayWidget import
   - Add UsageDisplayWidget() in build

7. lib/main.dart
   - Add PaywallScreen import
   - Add '/paywall' route

NEW FILES TO ADD (already created):
- lib/services/usage_service.dart
- lib/services/subscription_service.dart
- lib/services/feature_gate.dart
- lib/widgets/upgrade_dialog.dart
- lib/widgets/review_dialog.dart
- lib/widgets/limit_reached_dialog.dart
- lib/widgets/usage_display_widget.dart
- lib/widgets/stt_countdown_timer.dart
- lib/screens/paywall_screen.dart

*/
