import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_service.dart';
import '../../services/refinement_service.dart';
import '../../models/recording_item.dart';
import '../../models/outcome_type.dart';
import '../../widgets/editable_result_box.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/refinement_buttons.dart';
import '../../widgets/add_to_project_dialog.dart';
import 'preset_selection_screen.dart';
import 'recording_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _generateRewrite();
  }

  Future<void> _generateRewrite() async {
    final appState = context.read<AppStateProvider>();
    final transcription = appState.transcription;
    final preset = appState.selectedPreset;
    final language = appState.selectedLanguage;

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
      final rewrittenText = await aiService.rewriteText(
        transcription,
        preset,
        language.code,
      );

      setState(() {
        _rewrittenText = rewrittenText;
        _isLoading = false;
      });

      // Initialize history with first result
      _saveToHistory(rewrittenText);

      // Auto-assign outcome based on preset
      _autoAssignOutcome(preset.id);

      appState.setRewrittenText(rewrittenText);
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
  }

  Future<void> _saveRecording() async {
    final appState = context.read<AppStateProvider>();

    // Create new RecordingItem
    final item = RecordingItem(
      id: const Uuid().v4(),
      rawTranscript: appState.transcription,
      finalText: _rewrittenText,
      presetUsed: appState.selectedPreset?.name ?? 'Unknown',
      outcomes: _selectedOutcomes.map((o) => o.toStorageString()).toList(),
      projectId: null,
      createdAt: DateTime.now(),
      editHistory: List.from(_textHistory),
      presetId: appState.selectedPreset?.id ?? '',
    );

    await appState.saveRecording(item);
    debugPrint('💾 Recording saved: ${item.id}');
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _rewrittenText));

    // Save recording
    await _saveRecording();

    setState(() {
      _showCopied = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);
    final primaryColor = const Color(0xFF3B82F6);

    final appState = context.watch<AppStateProvider>();
    final canUndo = _historyIndex > 0;
    final canRedo = _historyIndex < _textHistory.length - 1;

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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PresetSelectionScreen(
                                  fromRecording: true,
                                ),
                              ),
                            );
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
                                    onTap: () {
                                      _toggleOutcome(outcome);
                                      // Auto-save when outcome is toggled
                                      _saveRecording();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _copyToClipboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Copy to Clipboard',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

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
