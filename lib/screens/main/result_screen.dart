import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_service.dart';
import '../../services/refinement_service.dart';
import '../../services/continue_service.dart';
import '../../services/reminder_manager.dart';
import '../../models/recording_item.dart';
import '../../models/outcome_type.dart';
import '../../widgets/editable_result_box.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/refinement_buttons.dart';
import '../../widgets/add_to_project_dialog.dart';
import '../../widgets/reminder_button.dart';
import 'preset_selection_screen.dart';
import 'recording_screen.dart';
import 'outcomes_result_screen.dart';
import 'unstuck_result_screen.dart';
import 'smart_actions_result_screen.dart';

class ResultScreen extends StatefulWidget {
  final String? continueFromItemId;
  
  const ResultScreen({
    super.key,
    this.continueFromItemId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  bool _showCopied = false;
  String _rewrittenText = '';
  String? _error;

  // Undo/redo functionality
  final List<String> _textHistory = [];
  int _historyIndex = -1;

  // Outcomes (multiple selections allowed)
  Set<OutcomeType> _selectedOutcomes = {};

  // Active refinement tracking
  RefinementType? _activeRefinement;
  
  // Track saved item ID to prevent duplicates
  String? _savedItemId;

  @override
  void initState() {
    super.initState();
    // Don't initialize _savedItemId from continueFromItemId anymore
    // Continue should always create NEW items, not update existing ones
    _generateRewrite();
  }

  Future<void> _generateRewrite() async {
    final appState = context.read<AppStateProvider>();
    final transcription = appState.transcription;
    final preset = appState.selectedPreset;
    final language = appState.selectedLanguage;
    final continueContext = appState.continueContext;

    if (transcription.isEmpty || preset == null) {
      setState(() {
        _error = 'No transcription or preset available';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _rewrittenText = '';
      _error = null;
    });

    try {
      final aiService = AIService();
      String rewrittenText;
      
      // Check if we're continuing from an existing item
      if (continueContext != null && continueContext.contextTexts.isNotEmpty) {
        // Use context-aware rewriting
        print('🔄 Using context-aware rewriting with ${continueContext.contextTexts.length} context items');
        rewrittenText = await aiService.rewriteWithContext(
          text: transcription,
          preset: preset,
          languageCode: language.code,
          contextTexts: continueContext.contextTexts,
        );
      } else {
        // Normal rewriting
        rewrittenText = await aiService.rewriteText(
          transcription,
          preset,
          language.code,
        );
      }

      setState(() {
        _rewrittenText = rewrittenText;
        _isLoading = false;
      });

      // Initialize history with first result
      _saveToHistory(rewrittenText);

      // Don't auto-assign outcome - let user choose
      // _autoAssignOutcome(preset.id);

      appState.setRewrittenText(rewrittenText);
      
      // Save or update the recording
      if (_savedItemId != null) {
        // Only update if we already saved this result (within the same session)
        await _updateExistingItem();
      } else if (continueContext != null && continueContext.singleItemId != null) {
        // 🔥 CONTINUING FROM A SINGLE CARD — UPDATE THE ORIGINAL CARD
        await _updateOriginalCard(continueContext.singleItemId!);
        appState.clearContinueContext();
      } else if (continueContext != null && continueContext.projectId != null) {
        // Continuing from PROJECT — create new card in project
        await _saveRecording();
        if (_savedItemId != null) {
          await appState.addItemToProject(continueContext.projectId!, _savedItemId!);
        }
        appState.clearContinueContext();
      } else {
        // Normal new recording
        await _saveRecording();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _autoAssignOutcome(String presetId) {
    // Auto-assign outcome based on preset
    final outcome = _getOutcomeFromPreset(presetId);
    setState(() {
      _selectedOutcomes.add(outcome);
    });
  }

  OutcomeType _getOutcomeFromPreset(String presetId) {
    // Map preset IDs to outcomes
    if (presetId.contains('email') || presetId.contains('reply') || presetId.contains('message')) {
      return OutcomeType.message;
    } else if (presetId.contains('social') || presetId.contains('instagram') || presetId.contains('twitter') || presetId.contains('linkedin') || presetId.contains('viral')) {
      return OutcomeType.content;
    } else if (presetId.contains('task') || presetId.contains('todo')) {
      return OutcomeType.task;
    } else if (presetId.contains('brain') || presetId.contains('idea') || presetId.contains('story') || presetId.contains('creative')) {
      return OutcomeType.idea;
    } else {
      return OutcomeType.note;
    }
  }

  void _saveToHistory(String text) {
    // Clear forward history if we're in the middle
    if (_historyIndex < _textHistory.length - 1) {
      _textHistory.removeRange(_historyIndex + 1, _textHistory.length);
    }
    _textHistory.add(text);
    _historyIndex++;
    debugPrint('📝 Saved to history: index $_historyIndex, total ${_textHistory.length}');
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _rewrittenText = _textHistory[_historyIndex];
      });
      debugPrint('↩️ Undo: index $_historyIndex');
    }
  }

  void _redo() {
    if (_historyIndex < _textHistory.length - 1) {
      setState(() {
        _historyIndex++;
        _rewrittenText = _textHistory[_historyIndex];
      });
      debugPrint('↪️ Redo: index $_historyIndex');
    }
  }

  void _onTextEdited(String newText) {
    // User manually edited text
    setState(() {
      _rewrittenText = newText;
    });
    _saveToHistory(newText);
    debugPrint('✏️ User edited text');
  }

  Future<void> _handleRefinement(RefinementType type) async {
    setState(() {
      _activeRefinement = type;
    });

    try {
      final service = RefinementService();
      String refined;

      switch (type) {
        case RefinementType.shorten:
          refined = await service.shorten(_rewrittenText);
          break;
        case RefinementType.expand:
          refined = await service.expand(_rewrittenText);
          break;
        case RefinementType.casual:
          refined = await service.makeCasual(_rewrittenText);
          break;
        case RefinementType.professional:
          refined = await service.makeProfessional(_rewrittenText);
          break;
        case RefinementType.fixGrammar:
          refined = await service.fixGrammar(_rewrittenText);
          break;
        case RefinementType.translate:
          refined = await service.translate(_rewrittenText, 'en');
          break;
      }

      setState(() {
        _rewrittenText = refined;
        _activeRefinement = null;
      });

      _saveToHistory(refined);
      debugPrint('🎨 Refinement complete: $type');
    } catch (e) {
      setState(() {
        _activeRefinement = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refine: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _toggleOutcome(OutcomeType outcome) {
    setState(() {
      if (_selectedOutcomes.contains(outcome)) {
        _selectedOutcomes.remove(outcome);
      } else {
        _selectedOutcomes.add(outcome);
      }
    });
    debugPrint('🏷️ Outcomes: $_selectedOutcomes');
    // Update existing item instead of saving new one
    if (_savedItemId != null) {
      _updateExistingItem();
    }
  }

  Future<void> _saveRecording() async {
    // Only save if we haven't saved yet (prevent duplicates)
    if (_savedItemId != null) {
      debugPrint('⚠️ Item already saved with ID: $_savedItemId');
      return;
    }
    
    try {
      final appState = context.read<AppStateProvider>();

      debugPrint('🔍 Starting _saveRecording...');
      debugPrint('🔍 Transcription: ${appState.transcription}');
      debugPrint('🔍 Rewritten text: $_rewrittenText');
      debugPrint('🔍 Selected outcomes: $_selectedOutcomes');

      // Get continue context if exists
      final continueContext = appState.continueContext;

      // Create new RecordingItem with generated ID
      final itemId = const Uuid().v4();
      final item = RecordingItem(
        id: itemId,
        rawTranscript: appState.transcription,
        finalText: _rewrittenText,
        presetUsed: appState.selectedPreset?.name ?? 'Unknown',
        outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
        projectId: continueContext?.projectId, // Link to project if continuing from project
        createdAt: DateTime.now(),
        editHistory: List.from(_textHistory),
        presetId: appState.selectedPreset?.id ?? '',
        continuedFromId: continueContext?.singleItemId, // 🔥 LINK TO ORIGINAL CARD
      );

      debugPrint('💾 Created item: ${item.id}');
      debugPrint('💾 Item outcomes: ${item.outcomes}');
      debugPrint('💾 Continued from: ${item.continuedFromId}');
      
      await appState.saveRecording(item);
      
      // 🔥 Link the continuation chain
      if (continueContext?.singleItemId != null) {
        final continueService = ContinueService();
        await continueService.linkContinuationChain(
          newItemId: itemId,
          continuedFromId: continueContext!.singleItemId,
        );
        debugPrint('🔗 Linked: ${continueContext.singleItemId} → $itemId');
      }
      
      // Store the ID to prevent duplicate saves
      _savedItemId = itemId;
      
      debugPrint('✅ Recording saved successfully!');
      debugPrint('✅ Total recordings now: ${appState.recordingItems.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _saveRecording: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  Future<void> _updateExistingItem() async {
    if (_savedItemId == null) return;
    
    try {
      final appState = context.read<AppStateProvider>();
      
      // Find the existing item
      final existingItem = appState.recordingItems.firstWhere(
        (item) => item.id == _savedItemId,
        orElse: () => throw Exception('Item not found'),
      );
      
      // Create updated item with new outcomes
      final updatedItem = existingItem.copyWith(
        outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
        finalText: _rewrittenText, // In case text was edited
        editHistory: List.from(_textHistory),
      );
      
      await appState.updateRecording(updatedItem);
      
      debugPrint('✅ Updated item: $_savedItemId with outcomes: $_selectedOutcomes');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating item: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Update the original card with combined content (for Continue feature)
  Future<void> _updateOriginalCard(String originalItemId) async {
    try {
      final appState = context.read<AppStateProvider>();
      
      // Find the original item
      final originalItem = appState.recordingItems.firstWhere(
        (item) => item.id == originalItemId,
        orElse: () => throw Exception('Original item not found'),
      );
      
      // Combine the old text with new text
      // The AI was given the original text as context, so _rewrittenText 
      // should already be a coherent continuation/combination
      final combinedText = '${originalItem.finalText}\n\n$_rewrittenText';
      
      // Create updated item
      final updatedItem = originalItem.copyWith(
        finalText: combinedText,
        rawTranscript: '${originalItem.rawTranscript}\n\n${appState.transcription}',
        editHistory: [...originalItem.editHistory, combinedText],
      );
      
      // Save the update
      await appState.updateRecording(updatedItem);
      
      // Set savedItemId to the original so further edits update it
      _savedItemId = originalItemId;
      
      debugPrint('✅ Updated original card: $originalItemId with continued content');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR updating original card: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Fallback: save as new item if update fails
      await _saveRecording();
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _rewrittenText));

    // Don't save again - already saved in _generateRewrite()
    // Just update if outcomes changed
    if (_savedItemId != null) {
      await _updateExistingItem();
    }

    setState(() {
      _showCopied = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
  
  /// Show voice recording for instructions
  Future<void> _showInstructionsVoiceRecording(BuildContext context) async {
    // Navigate to recording screen for instructions
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordingScreen(isInstructionsMode: true),
      ),
    ).then((instructionsText) async {
      // When they come back with voice instructions
      if (instructionsText != null && instructionsText is String && instructionsText.isNotEmpty) {
        await _addMoreAndRewrite(instructionsText);
      }
    });
  }
  
  /// Add user text and regenerate with AI
  Future<void> _addMoreAndRewrite(String additionalText) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final appState = context.read<AppStateProvider>();
      final refinementService = RefinementService();
      
      // Combine current text with additional instruction
      final combinedPrompt = '$_rewrittenText\n\n[User adds: $additionalText]';
      
      // Use the refinement service to regenerate
      final refined = await refinementService.customRefine(
        combinedPrompt,
        'Rewrite the entire text incorporating the user\'s addition or instruction. Maintain the original style unless the user asks to change it.',
      );
      
      // Update history and text
      setState(() {
        _saveToHistory(_rewrittenText);
        _rewrittenText = refined;
        _isLoading = false;
      });
      
      // Auto-save the update
      if (_savedItemId != null) {
        await _updateExistingItem();
      } else {
        await _saveRecording();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Rewritten with your additions!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rewrite: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
  
  /// Regenerate the output from scratch
  Future<void> _regenerateOutput() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Just call _generateRewrite again - it will regenerate from original transcription
      await _generateRewrite();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Regenerated!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showReminderPicker() async {
    if (_savedItemId == null) return;
    
    final appState = context.read<AppStateProvider>();
    final item = appState.recordingItems.firstWhere(
      (i) => i.id == _savedItemId,
      orElse: () => appState.recordingItems.first,
    );
    
    await ReminderManager().showReminderPicker(
      context: context,
      item: item,
      appState: appState,
    );
    
    // Refresh to show updated reminder
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final preset = appState.selectedPreset;
    
    // Route to custom result screens for special presets
    if (preset?.id == 'outcomes') {
      return OutcomesResultScreen(
        continueFromItemId: widget.continueFromItemId,
      );
    }
    
    if (preset?.id == 'unstuck') {
      return UnstuckResultScreen(
        continueFromItemId: widget.continueFromItemId,
      );
    }
    
    if (preset?.id == 'smart_actions') {
      return SmartActionsResultScreen(
        transcription: appState.transcription,
        languageCode: appState.selectedLanguage.code,
      );
    }
    
    // Default behavior for all other presets
    return _buildNormalResultScreen(context);
  }

  Widget _buildNormalResultScreen(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final canUndo = _historyIndex > 0;
    final canRedo = _historyIndex < _textHistory.length - 1;
    
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: Icon(Icons.close, color: textColor, size: 20),
                        ),
                      ),
                      Row(
                        children: [
                          // Undo button
                          IconButton(
                            onPressed: canUndo ? _undo : null,
                            icon: Icon(
                              Icons.undo,
                              color: canUndo ? textColor : secondaryTextColor.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                          // Redo button
                          IconButton(
                            onPressed: canRedo ? _redo : null,
                            icon: Icon(
                              Icons.redo,
                              color: canRedo ? textColor : secondaryTextColor.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          appState.reset();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecordingScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Re-record',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor,
                          ),
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
                        // Original
                        Text(
                          'Original',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"${appState.transcription}"',
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Preset label
                        Row(
                          children: [
                            Text(
                              appState.selectedPreset?.name ?? 'Rewritten',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Editable Result Box
                        if (_isLoading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
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
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          )
                        else if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Error: $_error',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          )
                        else
                          EditableResultBox(
                            initialText: _rewrittenText,
                            onTextChanged: _onTextEdited,
                            isLoading: _activeRefinement != null,
                          ),

                        const SizedBox(height: 16),

                        // Add More and Rewrite buttons (right under output box)
                        Row(
                          children: [
                            // Instructions Button (voice-based)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showInstructionsVoiceRecording(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Instructions',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Rewrite Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _regenerateOutput,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF10B981),
                                  side: BorderSide(color: _isLoading ? Colors.grey : const Color(0xFF10B981), width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Rewrite',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Refinement Buttons
                        if (!_isLoading && _error == null) ...[
                          RefinementButtons(
                            currentText: _rewrittenText,
                            onRefinementComplete: (refined) {
                              setState(() {
                                _rewrittenText = refined;
                              });
                              _saveToHistory(refined);
                            },
                            activeRefinement: _activeRefinement,
                          ),
                          const SizedBox(height: 24),

                          // Outcomes Section
                          Text(
                            'Select outcomes',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: OutcomeType.values.map((outcome) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: OutcomeChip(
                                    outcomeType: outcome,
                                    isSelected: _selectedOutcomes.contains(outcome),
                                    onTap: () => _toggleOutcome(outcome),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Reminder button (only show after item is saved)
                          if (_savedItemId != null)
                            Consumer<AppStateProvider>(
                              builder: (context, appState, _) {
                                final item = appState.recordingItems.firstWhere(
                                  (i) => i.id == _savedItemId,
                                  orElse: () => appState.recordingItems.first,
                                );
                                return ReminderButton(
                                  reminderDateTime: item.reminderDateTime,
                                  onPressed: _showReminderPicker,
                                );
                              },
                            ),
                          const SizedBox(height: 24),

                          // Add to Project Button
                          GestureDetector(
                            onTap: () async {
                              // Save first if not saved yet
                              await _saveRecording();
                              
                              // Get the item ID
                              final appState = context.read<AppStateProvider>();
                              final items = appState.recordingItems;
                              if (items.isNotEmpty) {
                                final latestItem = items.first;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => AddToProjectDialog(
                                    recordingItemId: latestItem.id,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add to Project',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Share and Different Style buttons side by side
                          Row(
                            children: [
                              // Share Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Share.share(_rewrittenText);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.share, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Different Style Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PresetSelectionScreen(
                                          fromRecording: true,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Different Style',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Copied notification
            if (_showCopied)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Copied! Paste anywhere',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
}
