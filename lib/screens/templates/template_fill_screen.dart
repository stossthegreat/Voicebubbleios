import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_templates.dart';
import '../../services/ai_service.dart';
import 'result_screen.dart';

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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _isExpanded = {};
  final Map<String, bool> _isRecording = {};
  int _currentSectionIndex = 0;
  bool _isGenerating = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    for (final section in widget.template.sections) {
      _controllers[section.id] = TextEditingController();
      _isExpanded[section.id] = false;
      _isRecording[section.id] = false;
    }
    // First section expanded by default
    if (widget.template.sections.isNotEmpty) {
      _isExpanded[widget.template.sections.first.id] = true;
    }
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _progressController.dispose();
    super.dispose();
  }

  double get _completionProgress {
    if (widget.template.sections.isEmpty) return 0;
    int filled = 0;
    for (final section in widget.template.sections) {
      if (_controllers[section.id]?.text.trim().isNotEmpty == true) {
        filled++;
      }
    }
    return filled / widget.template.sections.length;
  }

  bool get _canGenerate {
    for (final section in widget.template.sections) {
      if (section.isRequired && 
          _controllers[section.id]?.text.trim().isEmpty == true) {
        return false;
      }
    }
    return true;
  }

  Future<void> _generateDocument() async {
    if (!_canGenerate || _isGenerating) return;

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      // Build the prompt from all sections
      final buffer = StringBuffer();
      buffer.writeln('Create a ${widget.template.name} using this information:\n');
      
      for (final section in widget.template.sections) {
        final value = _controllers[section.id]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          buffer.writeln('${section.title}: $value');
          buffer.writeln('(AI guidance: ${section.aiPrompt})\n');
        }
      }
      
      buffer.writeln('\nGenerate a polished, professional ${widget.template.name} that incorporates all the above. Write in a natural, human voice.');

      // Navigate to result screen with the combined prompt
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              presetId: 'magic',
              presetName: widget.template.name,
              customPrompt: buffer.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _expandSection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      // Collapse all
      for (final section in widget.template.sections) {
        _isExpanded[section.id] = false;
      }
      // Expand selected
      _isExpanded[widget.template.sections[index].id] = true;
      _currentSectionIndex = index;
    });
  }

  void _nextSection() {
    if (_currentSectionIndex < widget.template.sections.length - 1) {
      _expandSection(_currentSectionIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    final templateColor = widget.template.color;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.template.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Template icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: templateColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.template.icon,
                      color: templateColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_completionProgress * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${widget.template.sections.length} sections',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completionProgress,
                      backgroundColor: surfaceColor,
                      valueColor: AlwaysStoppedAnimation(templateColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sections List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.template.sections.length,
                itemBuilder: (context, index) {
                  final section = widget.template.sections[index];
                  final isExpanded = _isExpanded[section.id] ?? false;
                  final hasContent = _controllers[section.id]?.text.trim().isNotEmpty == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SectionCard(
                      section: section,
                      controller: _controllers[section.id]!,
                      isExpanded: isExpanded,
                      hasContent: hasContent,
                      templateColor: templateColor,
                      onTap: () => _expandSection(index),
                      onNext: _nextSection,
                      isLast: index == widget.template.sections.length - 1,
                    ),
                  );
                },
              ),
            ),

            // Generate Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canGenerate && !_isGenerating ? _generateDocument : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canGenerate ? templateColor : surfaceColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: surfaceColor,
                    disabledForegroundColor: secondaryTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _canGenerate ? 4 : 0,
                    shadowColor: templateColor.withOpacity(0.4),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _canGenerate ? Icons.auto_awesome : Icons.lock_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _canGenerate ? 'Generate ${widget.template.name}' : 'Fill required sections',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final TemplateSection section;
  final TextEditingController controller;
  final bool isExpanded;
  final bool hasContent;
  final Color templateColor;
  final VoidCallback onTap;
  final VoidCallback onNext;
  final bool isLast;

  const _SectionCard({
    required this.section,
    required this.controller,
    required this.isExpanded,
    required this.hasContent,
    required this.templateColor,
    required this.onTap,
    required this.onNext,
    required this.isLast,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    if (widget.isExpanded) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: widget.isExpanded ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isExpanded
                ? widget.templateColor.withOpacity(0.5)
                : widget.hasContent
                    ? const Color(0xFF10B981).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
            width: widget.isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header (always visible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.hasContent
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : widget.isExpanded
                              ? widget.templateColor.withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.hasContent
                          ? Icons.check
                          : widget.section.icon,
                      color: widget.hasContent
                          ? const Color(0xFF10B981)
                          : widget.isExpanded
                              ? widget.templateColor
                              : secondaryTextColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.section.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!widget.section.isRequired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Optional',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (!widget.isExpanded && widget.hasContent)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.controller.text,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ),

            // Expanded Content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.templateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: widget.templateColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.section.hint,
                              style: TextStyle(
                                color: widget.templateColor,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        maxLines: widget.section.maxLines,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type or tap mic to speak...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        // Voice Input Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Implement voice input
                              HapticFeedback.mediumImpact();
                              setState(() => _isRecording = !_isRecording);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? const Color(0xFFEF4444).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isRecording
                                      ? const Color(0xFFEF4444)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRecording ? Icons.stop : Icons.mic,
                                    color: _isRecording
                                        ? const Color(0xFFEF4444)
                                        : textColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isRecording ? 'Recording...' : 'Voice Input',
                                    style: TextStyle(
                                      color: _isRecording
                                          ? const Color(0xFFEF4444)
                                          : textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Next Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onNext();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: widget.templateColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.isLast ? 'Done' : 'Next',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    widget.isLast
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
