// ============================================================================
// ELITE PROJECT CREATION WIZARD
// ============================================================================
// ZERO learning curve - Beautiful guided flow that makes starting EASY
// This is how we destroy Scrivener's "learning cliff"
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_templates.dart';

class EliteProjectCreationWizard extends StatefulWidget {
  final EliteProjectService projectService;
  final Function(EliteProject) onProjectCreated;
  final EliteProjectType? preselectedType;

  const EliteProjectCreationWizard({
    super.key,
    required this.projectService,
    required this.onProjectCreated,
    this.preselectedType,
  });

  @override
  State<EliteProjectCreationWizard> createState() => _EliteProjectCreationWizardState();
}

class _EliteProjectCreationWizardState extends State<EliteProjectCreationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1: Type selection
  EliteProjectType? _selectedType;
  
  // Step 2: Template selection
  ProjectTemplate? _selectedTemplate;
  
  // Step 3: Project details
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  int _selectedColorIndex = 0;
  
  // Step 4: Goals (optional)
  int? _targetWordCount;
  DateTime? _deadline;
  int? _dailyWordGoal;

  final List<Color> _projectColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType;
      _currentStep = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(1);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createProject();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedType != null;
      case 1:
        return true; // Template is optional
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 3:
        return true; // Goals are optional
      default:
        return false;
    }
  }

  Future<void> _createProject() async {
    HapticFeedback.mediumImpact();
    
    final project = await widget.projectService.createProject(
      name: _nameController.text.trim(),
      type: _selectedType!,
      subtitle: _subtitleController.text.trim().isEmpty
          ? null
          : _subtitleController.text.trim(),
      templateId: _selectedTemplate?.id,
      colorIndex: _selectedColorIndex,
    );
    
    // Update goals if set
    if (_targetWordCount != null || _deadline != null || _dailyWordGoal != null) {
      await widget.projectService.updateProjectGoals(
        project.id,
        ProjectGoals(
          targetWordCount: _targetWordCount,
          deadline: _deadline,
          dailyWordGoal: _dailyWordGoal,
        ),
      );
    }
    
    widget.onProjectCreated(project);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: _previousStep,
        ),
        title: Text(
          'Create Project',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _currentStep == 3 ? _createProject : null,
              child: Text(
                _currentStep == 3 ? 'Create' : 'Skip',
                style: TextStyle(
                  color: _currentStep == 3
                      ? (_selectedType?.accentColor ?? const Color(0xFF6366F1))
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(isDark),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTypeSelection(isDark),
                _buildTemplateSelection(isDark),
                _buildProjectDetails(isDark),
                _buildGoalsSetup(isDark),
              ],
            ),
          ),
          
          // Bottom button
          _buildBottomButton(isDark),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isComplete = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (_selectedType?.accentColor ?? const Color(0xFF6366F1))
                          : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ============================================================================
  // STEP 1: TYPE SELECTION
  // ============================================================================

  Widget _buildTypeSelection(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you creating?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the type of project that best fits your goal',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Type grid
          ...EliteProjectType.values.map((type) => _buildTypeOption(type, isDark)),
        ],
      ),
    );
  }

  Widget _buildTypeOption(EliteProjectType type, bool isDark) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? type.accentColor.withOpacity(0.1)
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? type.accentColor
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: type.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(type.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? type.accentColor
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTypeDescription(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: type.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeDescription(EliteProjectType type) {
    switch (type) {
      case EliteProjectType.novel:
        return 'Write fiction, chapters, and stories';
      case EliteProjectType.course:
        return 'Create educational content and lessons';
      case EliteProjectType.podcast:
        return 'Plan episodes, interviews, and show notes';
      case EliteProjectType.youtube:
        return 'Script videos, descriptions, and content';
      case EliteProjectType.blog:
        return 'Write articles, posts, and newsletters';
      case EliteProjectType.research:
        return 'Academic papers, thesis, and studies';
      case EliteProjectType.business:
        return 'Business plans, pitches, and proposals';
      case EliteProjectType.memoir:
        return 'Personal stories and life experiences';
      case EliteProjectType.freeform:
        return 'Flexible structure for any project';
    }
  }

  // ============================================================================
  // STEP 2: TEMPLATE SELECTION
  // ============================================================================

  Widget _buildTemplateSelection(bool isDark) {
    if (_selectedType == null) return const SizedBox();
    
    final templates = EliteProjectTemplateRegistry.getTemplatesForType(_selectedType!);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedType!.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_selectedType!.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Template',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Or start from scratch',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Blank option
          _buildTemplateOption(
            name: 'Start Blank',
            description: 'Create your own structure from scratch',
            isSelected: _selectedTemplate == null,
            icon: Icons.add_box_outlined,
            isDark: isDark,
            onTap: () => setState(() => _selectedTemplate = null),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Or use a template:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          
          // Templates
          ...templates.map((template) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTemplateOption(
              name: template.name,
              description: template.description,
              isSelected: _selectedTemplate?.id == template.id,
              sections: template.sections.length,
              isDark: isDark,
              onTap: () => setState(() => _selectedTemplate = template),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTemplateOption({
    required String name,
    required String description,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
    int? sections,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedType!.accentColor.withOpacity(0.1)
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _selectedType!.accentColor
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? _selectedType!.accentColor.withOpacity(0.2)
                    : (isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon ?? Icons.description_outlined,
                color: isSelected
                    ? _selectedType!.accentColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? _selectedType!.accentColor
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sections != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$sections sections included',
                      style: TextStyle(
                        fontSize: 11,
                        color: _selectedType!.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedType!.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // STEP 3: PROJECT DETAILS
  // ============================================================================

  Widget _buildProjectDetails(bool isDark) {
    if (_selectedType == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name Your Project',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Give it a title that inspires you',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: _getNameHint(),
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _selectedType!.accentColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 20),
          
          // Subtitle field
          TextField(
            controller: _subtitleController,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: _getSubtitleHint(),
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _selectedType!.accentColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
              labelText: 'Subtitle (optional)',
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Color selection
          Text(
            'Choose a color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_projectColors.length, (index) {
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColorIndex = index);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _projectColors[index],
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _projectColors[index].withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getNameHint() {
    switch (_selectedType) {
      case EliteProjectType.novel:
        return 'e.g., "The Last Starship"';
      case EliteProjectType.course:
        return 'e.g., "Master Python in 30 Days"';
      case EliteProjectType.podcast:
        return 'e.g., "The Creative Hour"';
      case EliteProjectType.youtube:
        return 'e.g., "Tech Deep Dives"';
      case EliteProjectType.blog:
        return 'e.g., "Startup Journey"';
      case EliteProjectType.research:
        return 'e.g., "AI Impact Study"';
      case EliteProjectType.business:
        return 'e.g., "Series A Pitch"';
      case EliteProjectType.memoir:
        return 'e.g., "My Story"';
      case EliteProjectType.freeform:
        return 'e.g., "Ideas & Notes"';
      default:
        return 'Enter project name';
    }
  }

  String _getSubtitleHint() {
    switch (_selectedType) {
      case EliteProjectType.novel:
        return 'e.g., "A Sci-Fi Thriller"';
      case EliteProjectType.course:
        return 'e.g., "For Complete Beginners"';
      case EliteProjectType.podcast:
        return 'e.g., "Creativity & Innovation"';
      case EliteProjectType.youtube:
        return 'e.g., "Weekly Reviews"';
      case EliteProjectType.blog:
        return 'e.g., "Weekly Newsletter"';
      case EliteProjectType.research:
        return 'e.g., "Masters Thesis"';
      case EliteProjectType.business:
        return 'e.g., "Q1 2025"';
      case EliteProjectType.memoir:
        return 'e.g., "1990-2020"';
      case EliteProjectType.freeform:
        return 'e.g., "Brainstorming"';
      default:
        return 'Optional subtitle';
    }
  }

  // ============================================================================
  // STEP 4: GOALS SETUP
  // ============================================================================

  Widget _buildGoalsSetup(bool isDark) {
    if (_selectedType == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Your Goals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - you can always change these later',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Target word count
          _buildGoalCard(
            title: 'Target Word Count',
            subtitle: 'How many words is your goal?',
            icon: Icons.article_outlined,
            isDark: isDark,
            child: _buildWordCountSelector(isDark),
          ),
          
          const SizedBox(height: 16),
          
          // Daily goal
          _buildGoalCard(
            title: 'Daily Writing Goal',
            subtitle: 'Words per day to stay on track',
            icon: Icons.today_outlined,
            isDark: isDark,
            child: _buildDailyGoalSelector(isDark),
          ),
          
          const SizedBox(height: 16),
          
          // Deadline
          _buildGoalCard(
            title: 'Target Deadline',
            subtitle: 'When do you want to finish?',
            icon: Icons.flag_outlined,
            isDark: isDark,
            child: _buildDeadlineSelector(isDark),
          ),
          
          const SizedBox(height: 32),
          
          // Motivation message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedType!.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Goals help you stay motivated. We\'ll track your progress and celebrate milestones!',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
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

  Widget _buildGoalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _selectedType!.accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildWordCountSelector(bool isDark) {
    final presets = [10000, 25000, 50000, 75000, 100000];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...presets.map((count) => _buildChip(
          label: '${count ~/ 1000}K',
          isSelected: _targetWordCount == count,
          isDark: isDark,
          onTap: () => setState(() {
            _targetWordCount = _targetWordCount == count ? null : count;
          }),
        )),
        _buildChip(
          label: 'Custom',
          isSelected: _targetWordCount != null && !presets.contains(_targetWordCount),
          isDark: isDark,
          onTap: () => _showCustomWordCountDialog(),
        ),
      ],
    );
  }

  Widget _buildDailyGoalSelector(bool isDark) {
    final presets = [250, 500, 1000, 1500, 2000];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((count) => _buildChip(
        label: '$count',
        isSelected: _dailyWordGoal == count,
        isDark: isDark,
        onTap: () => setState(() {
          _dailyWordGoal = _dailyWordGoal == count ? null : count;
        }),
      )).toList(),
    );
  }

  Widget _buildDeadlineSelector(bool isDark) {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: _deadline != null
                  ? _selectedType!.accentColor
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Text(
              _deadline != null
                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                  : 'Select a date',
              style: TextStyle(
                fontSize: 14,
                color: _deadline != null
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
            const Spacer(),
            if (_deadline != null)
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedType!.accentColor
              : (isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  void _showCustomWordCountDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Word Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter word count',
            suffix: const Text('words'),
            filled: true,
            fillColor: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                setState(() => _targetWordCount = count);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType!.accentColor,
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedType!.accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  // ============================================================================
  // BOTTOM BUTTON
  // ============================================================================

  Widget _buildBottomButton(bool isDark) {
    final buttonText = _currentStep == 3
        ? 'Create Project'
        : (_currentStep == 0 ? 'Continue' : 'Next');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceed ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed
                  ? (_selectedType?.accentColor ?? const Color(0xFF6366F1))
                  : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
              foregroundColor: Colors.white,
              disabledForegroundColor: isDark ? Colors.grey[600] : Colors.grey[500],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _canProceed ? 4 : 0,
              shadowColor: _canProceed
                  ? (_selectedType?.accentColor.withOpacity(0.4) ?? Colors.transparent)
                  : Colors.transparent,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
