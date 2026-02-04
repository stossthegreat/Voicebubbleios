import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/ai_service.dart';
import '../../services/feature_gate.dart';
import '../../widgets/usage_display_widget.dart';
import 'preset_selection_screen.dart';
import 'result_screen.dart';

class RecordingScreen extends StatefulWidget {
  final bool isInstructionsMode;
  
  const RecordingScreen({
    super.key,
    this.isInstructionsMode = false,
  });
  
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  // Audio recorder for high-quality Whisper transcription
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AIService _aiService = AIService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  String? _audioPath;
  late AnimationController _pulseController;
  
  // Timer
  Timer? _timer;
  Timer? _waveTimer;
  int _recordingSeconds = 0;
  int _recordingMilliseconds = 0;
  
  // Sound wave animation - more bars for the waveform effect
  final int _waveBarCount = 50;
  List<double> _waveHeights = [];
  double _currentSoundLevel = 0.0;
  double _targetSoundLevel = 0.3;
  final Random _random = Random();
  
  // App colors
  final Color _primaryBlue = const Color(0xFF3B82F6);
  final Color _darkBlue = const Color(0xFF2563EB);
  
  @override
  void initState() {
    super.initState();
    _waveHeights = List.generate(_waveBarCount, (index) => 0.1 + _random.nextDouble() * 0.2);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startRecording();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _waveTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPaused) {
        setState(() {
          _recordingMilliseconds += 100;
          if (_recordingMilliseconds >= 1000) {
            _recordingMilliseconds = 0;
            _recordingSeconds++;
          }
        });
      }
    });
  }
  
  void _startWaveAnimation() {
    _waveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          // Smoothly interpolate toward target sound level
          _currentSoundLevel = _currentSoundLevel * 0.7 + _targetSoundLevel * 0.3;
          
          // Shift all bars to the left
          for (int i = 0; i < _waveHeights.length - 1; i++) {
            _waveHeights[i] = _waveHeights[i + 1];
          }
          
          // Generate new bar on the right with variation based on sound level
          final baseHeight = _currentSoundLevel * 0.6 + 0.1;
          final variation = _random.nextDouble() * 0.3 * _currentSoundLevel;
          _waveHeights[_waveHeights.length - 1] = (baseHeight + variation).clamp(0.08, 1.0);
        });
      }
    });
  }
  
  String _formatTime() {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    final millis = (_recordingMilliseconds ~/ 100).toString();
    return '$minutes:$seconds.$millis';
  }
  
  void _updateWaveHeights(double soundLevel) {
    // Normalize sound level (typically -2 to 10, we want 0.1 to 1.0)
    final normalizedLevel = ((soundLevel.clamp(-2, 8) + 2) / 10).clamp(0.1, 1.0);
    
    // Shift existing waves to the left and add new one at the end
    setState(() {
      for (int i = 0; i < _waveHeights.length - 1; i++) {
        _waveHeights[i] = _waveHeights[i + 1];
      }
      // Add some randomness to make it look more natural
      _waveHeights[_waveHeights.length - 1] = 
          (normalizedLevel * 0.6 + 0.1 + _random.nextDouble() * 0.3).clamp(0.1, 1.0);
    });
  }
  
  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        print('No microphone permission');
        if (mounted) Navigator.pop(context);
        return;
      }

      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _audioPath!,
      );

      // Use AudioRecorder's amplitude for waveform (no speech_to_text conflict)
      _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
        if (!_isPaused && mounted) {
          // Normalize amplitude: amp.current is typically -40 to 0 dB
          final normalized = ((amp.current + 40) / 40).clamp(0.1, 1.0);
          _targetSoundLevel = normalized;
        }
      });

      setState(() => _isRecording = true);
      _startTimer();
      _startWaveAnimation();
      print('Recording started: $_audioPath');
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) Navigator.pop(context);
    }
  }
  
  Future<void> _pauseRecording() async {
    if (_isPaused) {
      // Resume
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
    } else {
      // Pause
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }
  
  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _waveTimer?.cancel();
    await _audioRecorder.stop();

    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  Future<void> _stopRecording() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _timer?.cancel();
    _waveTimer?.cancel();

    try {
      // Stop audio recording
      final path = await _audioRecorder.stop();

      if (path != null && path.isNotEmpty) {
        print('Recording stopped: $path');
        
        // Use Whisper API for final accurate transcription
        final audioFile = File(path);
        
        if (!await audioFile.exists()) {
          throw Exception('Audio file not found');
        }
        
        print('Transcribing audio file (${await audioFile.length()} bytes)...');
        final transcription = await _aiService.transcribeAudio(audioFile);
        
        if (transcription.isEmpty) {
          throw Exception('No transcription received from server');
        }
        
        // Update app state with Whisper result
        if (!mounted) return;
        context.read<AppStateProvider>().setTranscription(transcription);

        // Track STT usage for free/pro limits
        await FeatureGate.trackSTTUsage(_recordingSeconds);

        print('Final transcription: $transcription');
        
        // If in instructions mode, return transcription directly
        if (widget.isInstructionsMode) {
          if (mounted) {
            Navigator.pop(context, transcription);
          }
          return;
        }
        
        // Navigate directly to preset selection (skip showing transcription)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PresetSelectionScreen(fromRecording: true),
            ),
          );
        }
      } else {
        throw Exception('No audio recorded');
      }
    } catch (e) {
      print('Error stopping/transcribing: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
      });
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transcription Failed'),
          content: Text(
            'Could not transcribe your audio:\n\n$e\n\nPlease check:\n'
            '• Backend server is running\n'
            '• OPENAI_API_KEY is configured\n'
            '• You have internet connection',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Try Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // STT Time Remaining Display
            UsageDisplayCompact(),
            
            const SizedBox(height: 20),
            
            // Instructions mode banner (if applicable)
            if (widget.isInstructionsMode) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Speak your instructions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // Waveform visualization
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_waveBarCount, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 3,
                    height: (_isPaused ? 0.15 : _waveHeights[index]) * 100,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _primaryBlue,
                    ),
                  );
                }),
              ),
            ),
            
            const Spacer(),
            
            // Recording label
            Text(
              _isPaused ? 'Paused' : (_isProcessing ? 'Processing...' : 'Recording'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Timer
            Text(
              _formatTime(),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Control buttons
            if (_isProcessing)
              // Processing indicator
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(_primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Getting perfect transcription',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _cancelRecording,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2A2A2A),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  
                  // Stop button (blue circle with white square)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _stopRecording,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _primaryBlue,
                          ),
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 14), // Match spacing with other labels
                    ],
                  ),
                  const SizedBox(width: 32),
                  
                  // Pause button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _pauseRecording,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2A2A2A),
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: _isPaused ? _primaryBlue : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
            const Spacer(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
