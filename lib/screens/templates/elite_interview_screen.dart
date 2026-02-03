// ============================================================
//        ELITE INTERVIEW SCREEN
// ============================================================
//
// The guided interview experience that makes users feel
// like they're working with a $500/hr consultant.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_service.dart';
import '../../services/template_ai_service.dart';
import 'template_models.dart';
import 'elite_interview_system.dart';
import 'elite_interview_flows.dart';

class EliteInterviewScreen extends StatefulWidget {
  final AppTemplate template;
  final List<InterviewQuestion> questions;
  final Function(Map<String, String>) onComplete;

  const EliteInterviewScreen({
    super.key,
    required this.template,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<EliteInterviewScreen> createState() => _EliteInterviewScreenState();
}

class _EliteInterviewScreenState extends State<EliteInterviewScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _showingTips = true;
  bool _hasRecorded = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String _currentTranscript = '';
  AnswerQuality? _lastQuality;
  Map<String, String> _answers = {};
  
  // Real STT components (from RecordingScreen)
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AIService _aiService = AIService();
  final TemplateAIService _templateAIService = TemplateAIService();
  String? _audioPath;
  bool _isProcessing = false;
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  InterviewQuestion get _currentQuestion => widget.questions[_currentIndex];
  double get _overallProgress => (_currentIndex + (_hasRecorded ? 1 : 0)) / widget.questions.length;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      print('Speech init error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _recordingTimer?.cancel();
    _speech.stop();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.template.gradientColors[0];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(primaryColor),
            Expanded(
              child: _showingTips && !_hasRecorded
                  ? _buildTipsView(primaryColor)
                  : _buildRecordingView(primaryColor),
            ),
            _buildBottomControls(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Row
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitConfirmation(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white54, size: 22),
                ),
              ),
              const Spacer(),
              // Question Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} of ${widget.questions.length}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar with segments
          Row(
            children: List.generate(widget.questions.length, (index) {
              final isCurrent = index == _currentIndex;
              final isComplete = index < _currentIndex || 
                  (index == _currentIndex && _hasRecorded);
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < widget.questions.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isComplete 
                        ? primaryColor 
                        : (isCurrent ? primaryColor.withOpacity(0.5) : const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsView(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            _currentQuestion.question,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          
          // Why It Matters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Why this matters',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion.whyItMatters,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Pro Tips
          if (_currentQuestion.proTips.isNotEmpty) ...[
            const Text(
              '💡 Pro Tips',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...(_currentQuestion.proTips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
          
          // Common Mistakes
          if (_currentQuestion.commonMistakes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              '⚠️ Avoid These',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...(_currentQuestion.commonMistakes.map((mistake) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mistake,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
          
          // Example Answer
          const SizedBox(height: 20),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              '📝 See Example Answer',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            iconColor: Colors.white54,
            collapsedIconColor: Colors.white54,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentQuestion.exampleAnswer,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRecordingView(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question (compact)
          Text(
            _currentQuestion.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          
          // EXAMPLE ALWAYS VISIBLE ABOVE VOICE BOX
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Perfect Example:',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion.exampleAnswer,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Recording/Transcript Area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording ? primaryColor : Colors.white.withOpacity(0.1),
                width: _isRecording ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isRecording) ...[
                  // Recording indicator
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recording... ${_recordingSeconds}s',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Aim for ${_currentQuestion.idealSeconds}s',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Timer progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_recordingSeconds / _currentQuestion.idealSeconds).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF2A2A2A),
                      valueColor: AlwaysStoppedAnimation(
                        _recordingSeconds >= _currentQuestion.minSeconds 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Transcript
                Text(
                  _currentTranscript.isEmpty && !_isRecording
                      ? 'Tap record to start speaking...'
                      : _currentTranscript.isEmpty
                          ? 'Listening...'
                          : _currentTranscript,
                  style: TextStyle(
                    fontSize: 16,
                    color: _currentTranscript.isEmpty 
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          
          // Quality Feedback
          if (_lastQuality != null && !_isRecording) ...[
            const SizedBox(height: 16),
            _buildQualityFeedback(primaryColor),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQualityFeedback(Color primaryColor) {
    final quality = _lastQuality!;
    final scoreColor = quality.score >= 85 
        ? Colors.green 
        : quality.score >= 70 
            ? Colors.orange 
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score & Feedback
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${quality.score}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quality.feedback,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          // Strengths
          if (quality.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...quality.strengths.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(s, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            )),
          ],
          
          // Missing
          if (quality.missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...quality.missing.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  ),
                ],
              ),
            )),
          ],
          
          // Push for more
          if (quality.needsMore && _currentQuestion.pushForMore.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentQuestion.pushForMore,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Tips/Back button
          if (!_showingTips && !_hasRecorded)
            GestureDetector(
              onTap: () => setState(() => _showingTips = true),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white54),
              ),
            )
          else if (_hasRecorded)
            GestureDetector(
              onTap: _reRecord,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white54, size: 20),
                    SizedBox(width: 8),
                    Text('Re-do', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 56),
          
          const Spacer(),
          
          // Main action button
          if (!_hasRecorded)
            // Record Button
            GestureDetector(
              onTap: _showingTips ? _startRecording : _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: _showingTips ? null : 72,
                      height: _showingTips ? null : 72,
                      padding: _showingTips 
                          ? const EdgeInsets.symmetric(horizontal: 32, vertical: 18)
                          : null,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isRecording 
                              ? [Colors.red, Colors.redAccent]
                              : widget.template.gradientColors,
                        ),
                        borderRadius: _showingTips 
                            ? BorderRadius.circular(16)
                            : BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : primaryColor).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _showingTips
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic, color: Colors.white, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  "I'm Ready",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  );
                },
              ),
            )
          else
            // Next/Finish Button
            GestureDetector(
              onTap: _nextQuestion,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.template.gradientColors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentIndex == widget.questions.length - 1 ? 'Finish' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentIndex == widget.questions.length - 1 
                          ? Icons.check 
                          : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          
          const Spacer(),
          
          // Skip button (for optional or frustrated users)
          if (!_currentQuestion.id.contains('required') && !_hasRecorded && !_showingTips)
            GestureDetector(
              onTap: _skipQuestion,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Skip', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }

  void _startRecording() async {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _showingTips = false;
      _isRecording = true;
      _recordingSeconds = 0;
      _currentTranscript = '';
    });
    
    // Get audio directory
    final dir = await getApplicationDocumentsDirectory();
    _audioPath = '${dir.path}/template_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    // Start audio recording for Whisper transcription
    try {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: _audioPath!,
      );
    } catch (e) {
      print('Audio recording error: $e');
    }
    
    // Start live STT for preview
    try {
      if (_speech.isAvailable) {
        _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _currentTranscript = result.recognizedWords;
              });
            }
          },
          listenFor: Duration(seconds: _currentQuestion.idealSeconds + 30),
        );
      }
    } catch (e) {
      print('STT error: $e');
    }
    
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _stopRecording() async {
    HapticFeedback.mediumImpact();
    _recordingTimer?.cancel();
    
    // Stop audio recording
    try {
      await _audioRecorder.stop();
      await _speech.stop();
    } catch (e) {
      print('Stop recording error: $e');
    }
    
    setState(() {
      _isRecording = false;
      _isProcessing = true; // Show loading while transcribing
    });
    
    // Transcribe with Whisper if we have audio
    String finalTranscript = _currentTranscript;
    if (_audioPath != null) {
      try {
        final audioFile = File(_audioPath!);
        if (await audioFile.exists()) {
          finalTranscript = await _aiService.transcribeAudio(audioFile);
          
          // Clean up grammar
          finalTranscript = await _templateAIService.cleanupAnswer(finalTranscript);
        }
      } catch (e) {
        print('Transcription error: $e');
        // Fall back to live STT transcript
      }
    }
    
    // Use example if no transcription
    if (finalTranscript.isEmpty || finalTranscript.contains('would appear')) {
      finalTranscript = _currentQuestion.exampleAnswer;
    }
    
    setState(() {
      _isProcessing = false;
      _hasRecorded = true;
      _currentTranscript = finalTranscript;
      
      // Score the answer
      _lastQuality = QualityScorer.scoreAnswer(
        question: _currentQuestion,
        answer: _currentTranscript,
        recordingSeconds: _recordingSeconds,
      );
    });
    
    // Save answer
    _answers[_currentQuestion.id] = _currentTranscript;
  }

  void _reRecord() {
    HapticFeedback.lightImpact();
    setState(() {
      _hasRecorded = false;
      _currentTranscript = '';
      _lastQuality = null;
      _recordingSeconds = 0;
    });
  }

  void _skipQuestion() {
    HapticFeedback.lightImpact();
    _nextQuestion();
  }

  void _nextQuestion() async {
    HapticFeedback.mediumImpact();
    
    if (_currentIndex == widget.questions.length - 1) {
      // Complete! Process with AI
      setState(() => _isProcessing = true);
      
      try {
        // Process answers with AI service
        final recordingItem = await _templateAIService.processTemplateAnswers(
          template: widget.template,
          answers: _answers,
        );
        
        // Save to app state
        if (mounted) {
          final appState = context.read<AppStateProvider>();
          await appState.saveRecording(recordingItem);
          
          // Call onComplete callback
          widget.onComplete(_answers);
        }
      } catch (e) {
        print('Error processing template: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } else {
      setState(() {
        _currentIndex++;
        _showingTips = true;
        _hasRecorded = false;
        _currentTranscript = '';
        _lastQuality = null;
        _recordingSeconds = 0;
      });
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave interview?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}