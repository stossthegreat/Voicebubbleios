import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_template.dart';
import '../../models/recording_item.dart';
import '../../services/template_service.dart';
import '../../providers/app_state_provider.dart';
import '../main/recording_detail_screen.dart';
import '../main/recording_screen.dart';

// ============================================================
//        TEMPLATE FILL SCREEN
// ============================================================
//
// Elite voice-powered template filling experience.
// Users speak their responses and AI creates perfect documents.
//
// ============================================================

class TemplateFillScreen extends StatefulWidget {
  final DocumentTemplate template;

  const TemplateFillScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplateFillScreen> createState() => _TemplateFillScreenState();
}

class _TemplateFillScreenState extends State<TemplateFillScreen>
    with TickerProviderStateMixin {
  final _templateService = TemplateService();
  final PageController _pageController = PageController();
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentPromptIndex = 0;
  Map<String, String> _responses = {};
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
    _updateProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentPromptIndex + 1) / widget.template.voicePrompts.length;
    _progressController.animateTo(progress);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top bar
                  Row(
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
                          onPressed: () => _showExitDialog(),
                          icon: Icon(Icons.close, color: textColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.template.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.template.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Step ${_currentPromptIndex + 1} of ${widget.template.voicePrompts.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_currentPromptIndex > 0)
                        TextButton(
                          onPressed: _previousPrompt,
                          child: Text(
                            'Back',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Current prompt
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.template.voicePrompts.length,
                itemBuilder: (context, index) {
                  return _buildPromptPage(widget.template.voicePrompts[index]);
                },
              ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Voice recording button
                  GestureDetector(
                    onTap: _isProcessing ? null : _startVoiceRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecording 
                            ? const Color(0xFFEF4444)
                            : _isProcessing
                                ? surfaceColor
                                : primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording 
                                ? const Color(0xFFEF4444)
                                : primaryColor).withValues(alpha: 0.3),
                            blurRadius: _isRecording ? 20 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    _isProcessing
                        ? 'Processing your response...'
                        : _isRecording
                            ? 'Tap to stop recording'
                            : 'Tap to record your response',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Skip and continue buttons
                  Row(
                    children: [
                      if (!widget.template.voicePrompts[_currentPromptIndex].isRequired)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipPrompt,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: textColor.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      
                      if (!widget.template.voicePrompts[_currentPromptIndex].isRequired)
                        const SizedBox(width: 16),
                      
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canContinue() ? _nextPrompt : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isLastPrompt() ? 'Create Document' : 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptPage(VoicePrompt prompt) {
    final textColor = Colors.white;
    final surfaceColor = const Color(0xFF1A1A1A);
    final response = _responses[prompt.id] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt title
          Text(
            prompt.placeholder,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Prompt description
          Text(
            prompt.prompt,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          
          if (prompt.example != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prompt.example!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Response preview
          if (response.isNotEmpty) ...[
            Text(
              'Your Response:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                response,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Word count and requirements
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: textColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Max ${prompt.maxWords} words • ${prompt.isRequired ? 'Required' : 'Optional'}',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              if (response.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${response.split(' ').length} words',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    final currentPrompt = widget.template.voicePrompts[_currentPromptIndex];
    final response = _responses[currentPrompt.id] ?? '';
    
    return !currentPrompt.isRequired || response.isNotEmpty;
  }

  bool _isLastPrompt() {
    return _currentPromptIndex == widget.template.voicePrompts.length - 1;
  }

  void _startVoiceRecording() {
    // Navigate to recording screen with template context
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(
          isTemplateMode: true,
          templatePrompt: widget.template.voicePrompts[_currentPromptIndex].prompt,
          onRecordingComplete: (response) {
            _handleVoiceResponse(response);
          },
        ),
      ),
    );
  }

  void _handleVoiceResponse(String response) {
    setState(() {
      _responses[widget.template.voicePrompts[_currentPromptIndex].id] = response;
    });
  }

  void _skipPrompt() {
    if (_isLastPrompt()) {
      _createDocument();
    } else {
      _nextPrompt();
    }
  }

  void _nextPrompt() {
    if (_isLastPrompt()) {
      _createDocument();
    } else {
      setState(() {
        _currentPromptIndex++;
      });
      _updateProgress();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPrompt() {
    if (_currentPromptIndex > 0) {
      setState(() {
        _currentPromptIndex--;
      });
      _updateProgress();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createDocument() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Create document from template
      final documentContent = _templateService.createDocumentFromTemplate(
        widget.template,
        _responses,
      );

      // Create recording item
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final recordingItem = RecordingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rawTranscript: 'Template: ${widget.template.name}',
        finalText: documentContent,
        presetId: 'template',
        createdAt: DateTime.now(),
        outcomes: [],
        editHistory: [],
      );

      // Save the document
      await appState.saveRecording(recordingItem);

      if (mounted) {
        // Navigate to document editor
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecordingDetailScreen(
              recordingId: recordingItem.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating document: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Exit Template?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will be lost if you exit now.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit template
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}