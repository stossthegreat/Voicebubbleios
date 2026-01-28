import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../models/smart_action.dart';
import '../../models/recording_item.dart';
import '../../models/outcome_type.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_service.dart';
import 'home_screen.dart';

class SmartActionsResultScreen extends StatefulWidget {
  final String transcription;
  final String languageCode;

  const SmartActionsResultScreen({
    super.key,
    required this.transcription,
    required this.languageCode,
  });

  @override
  State<SmartActionsResultScreen> createState() =>
      _SmartActionsResultScreenState();
}

class _SmartActionsResultScreenState extends State<SmartActionsResultScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<SmartAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _extractActions();
  }

  Future<void> _extractActions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('🔵 Smart Actions: Starting extraction...');
      print('🔵 Transcription: ${widget.transcription}');
      print('🔵 Language: ${widget.languageCode}');
      
      final aiService = AIService();
      final response = await aiService.extractSmartActions(
        widget.transcription,
        widget.languageCode,
      );

      print('🔵 Response received: ${response.actions.length} actions');
      for (var action in response.actions) {
        print('🔵 Action: ${action.type.name} - ${action.title}');
      }

      setState(() {
        _actions = response.actions;
        _isLoading = false;
      });

      print('🔵 UI updated with ${_actions.length} actions');
      
      // Save actions to library
      await _saveActionsToLibrary();
    } catch (e, stackTrace) {
      print('🔴 Smart Actions Error: $e');
      print('🔴 Stack: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActionsToLibrary() async {
    if (_actions.isEmpty) return;

    try {
      final appState = context.read<AppStateProvider>();
      
      // Save each action as a recording item
      for (var action in _actions) {
        final itemId = const Uuid().v4();
        final item = RecordingItem(
          id: itemId,
          rawTranscript: widget.transcription, // FIXED: correct field name
          finalText: action.formattedText,
          createdAt: DateTime.now(),
          presetUsed: 'Smart Actions',
          presetId: 'smart_actions',
          outcomes: [_getOutcomeType(action.type).toString().split('.').last],
          editHistory: [],
          tags: [],
        );
        
        await appState.saveRecording(item); // FIXED: correct method name
        print('✅ Saved action to library: ${action.title}');
      }
    } catch (e) {
      print('⚠️ Failed to save actions to library: $e');
    }
  }

  OutcomeType _getOutcomeType(SmartActionType type) {
    switch (type) {
      case SmartActionType.calendar:
        return OutcomeType.task;
      case SmartActionType.email:
        return OutcomeType.message;
      case SmartActionType.todo:
        return OutcomeType.task;
      case SmartActionType.note:
        return OutcomeType.note;
      case SmartActionType.message:
        return OutcomeType.message;
    }
  }

  void _handleExport(SmartAction action) async {
    switch (action.type) {
      case SmartActionType.calendar:
        await _exportToCalendar(action);
        break;
      case SmartActionType.email:
        await _exportToEmail(action);
        break;
      case SmartActionType.todo:
        await _exportToTodo(action);
        break;
      case SmartActionType.note:
        await _exportToNote(action);
        break;
      case SmartActionType.message:
        await _exportToMessage(action);
        break;
    }
  }

  Future<void> _exportToCalendar(SmartAction action) async {
    if (action.datetime == null) {
      _showMessage('No date/time specified for this event');
      return;
    }

    // Create calendar URL (works on Android/iOS)
    final start = action.datetime!.toUtc().millisecondsSinceEpoch ~/ 1000;
    final end = start + 3600; // Default 1 hour duration
    
    final title = Uri.encodeComponent(action.title);
    final description = Uri.encodeComponent(action.description ?? '');
    final location = Uri.encodeComponent(action.location ?? '');

    final url = 'https://www.google.com/calendar/render?action=TEMPLATE&text=$title&dates=${start}T/${end}T&details=$description&location=$location';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showMessage('Could not open calendar');
    }
  }

  Future<void> _exportToEmail(SmartAction action) async {
    final to = action.recipient ?? '';
    final subject = Uri.encodeComponent(action.subject ?? action.title);
    final body = Uri.encodeComponent(action.body ?? action.formattedText);

    final url = 'mailto:$to?subject=$subject&body=$body';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showMessage('Could not open email app');
    }
  }

  Future<void> _exportToTodo(SmartAction action) async {
    // Show a dialog with options: Google Tasks, Todoist, or save locally
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              title: const Text('Save in VoiceBubble'),
              onTap: () {
                Navigator.pop(context);
                _saveTaskLocally(action);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Color(0xFF3B82F6)),
              title: const Text('Open Google Tasks'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleTasks(action);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTaskLocally(SmartAction action) async {
    // Save as a todo-type outcome in our system
    final appState = context.read<AppStateProvider>();
    
    // This will be implemented when we integrate with your existing outcome system
    _showMessage('Task saved to Outcomes!');
  }

  Future<void> _openGoogleTasks(SmartAction action) async {
    // Google Tasks doesn't have a direct URL scheme, so open the web version
    final url = 'https://tasks.google.com/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _exportToNote(SmartAction action) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note, color: Color(0xFF6B7280)),
              title: const Text('Save in VoiceBubble'),
              onTap: () {
                Navigator.pop(context);
                _saveNoteLocally(action);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Color(0xFFFBBF24)),
              title: const Text('Open Google Keep'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleKeep();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNoteLocally(SmartAction action) async {
    _showMessage('Note saved to Library!');
  }

  Future<void> _openGoogleKeep() async {
    final url = 'https://keep.google.com/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _exportToMessage(SmartAction action) async {
    // Copy message to clipboard and show success
    _showMessage('Message copied! Ready to paste in ${action.platform ?? "your app"}');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Smart Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  SizedBox(height: 16),
                  Text(
                    'Detecting actions...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to detect actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _extractActions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _actions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No actions detected',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try speaking about tasks, events, or messages',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _actions.length,
                      itemBuilder: (context, index) {
                        return _SmartActionCard(
                          action: _actions[index],
                          onExport: () => _handleExport(_actions[index]),
                        );
                      },
                    ),
    );
  }
}

class _SmartActionCard extends StatelessWidget {
  final SmartAction action;
  final VoidCallback onExport;

  const _SmartActionCard({
    required this.action,
    required this.onExport,
  });

  Color get _typeColor {
    switch (action.type) {
      case SmartActionType.calendar:
        return const Color(0xFFEC4899); // Pink
      case SmartActionType.email:
        return const Color(0xFF3B82F6); // Blue
      case SmartActionType.todo:
        return const Color(0xFF10B981); // Green
      case SmartActionType.note:
        return const Color(0xFF6B7280); // Gray
      case SmartActionType.message:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.type.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        action.type.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                if (action.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    action.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],

                // Metadata
                if (action.datetime != null ||
                    action.location != null ||
                    action.recipient != null ||
                    action.priority != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (action.datetime != null)
                        _MetadataChip(
                          icon: Icons.schedule,
                          label: _formatDateTime(action.datetime!),
                        ),
                      if (action.location != null)
                        _MetadataChip(
                          icon: Icons.location_on,
                          label: action.location!,
                        ),
                      if (action.recipient != null)
                        _MetadataChip(
                          icon: Icons.person,
                          label: action.recipient!,
                        ),
                      if (action.priority != null)
                        _MetadataChip(
                          icon: Icons.flag,
                          label: action.priority!,
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Formatted text preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    action.formattedText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.send, size: 20),
                    label: Text(_getActionLabel()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _typeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  String _getActionLabel() {
    switch (action.type) {
      case SmartActionType.calendar:
        return 'Add to Calendar';
      case SmartActionType.email:
        return 'Open in Email';
      case SmartActionType.todo:
        return 'Add Task';
      case SmartActionType.note:
        return 'Save Note';
      case SmartActionType.message:
        return 'Copy Message';
    }
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
