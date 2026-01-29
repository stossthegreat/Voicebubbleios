// ============================================================================
// ELITE PROJECT WORKSPACE - THE BEAUTIFUL BEAST
// ============================================================================
// Integrates with your existing flutter_quill editor
// Voice-first with prominent recording
// AI features everywhere
// ELITE feel throughout
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_quill/flutter_quill.dart'; // Uncomment when integrating
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

class EliteWorkspaceScreen extends StatefulWidget {
  final EliteProject project;
  final EliteProjectService projectService;
  
  // YOUR EXISTING CALLBACKS - connect to your app
  final Function(String projectId, String sectionId)? onStartRecording;
  final Function(String presetId, String aiContext, String sectionId)? onUseAIPreset;
  final Function(EliteProject project)? onOpenMemory;
  final Function(EliteProject project)? onOpenStats;
  final Function(EliteProject project)? onExport;

  const EliteWorkspaceScreen({
    super.key,
    required this.project,
    required this.projectService,
    this.onStartRecording,
    this.onUseAIPreset,
    this.onOpenMemory,
    this.onOpenStats,
    this.onExport,
  });

  @override
  State<EliteWorkspaceScreen> createState() => _EliteWorkspaceScreenState();
}

class _EliteWorkspaceScreenState extends State<EliteWorkspaceScreen>
    with TickerProviderStateMixin {
  
  // State
  String? _selectedSectionId;
  bool _showSidebar = true;
  bool _showAIPanel = false;
  bool _isFullscreen = false;
  bool _isSaving = false;
  
  // For flutter_quill - uncomment when integrating
  // late QuillController _quillController;
  late TextEditingController _textController; // Temporary until quill connected
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  
  int _wordCount = 0;
  DateTime? _lastSaved;

  EliteProject get _project =>
      widget.projectService.getProject(widget.project.id) ?? widget.project;

  ProjectSection? get _selectedSection {
    if (_selectedSectionId == null) return null;
    return _findSection(_project.structure.sections, _selectedSectionId!);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();
    
    // Select first section by default
    if (_project.structure.sections.isNotEmpty) {
      _selectedSectionId = _project.structure.sections.first.id;
      _loadSectionContent();
    }
  }

  void _loadSectionContent() {
    if (_selectedSection != null) {
      _textController.text = _selectedSection!.content ?? '';
      _updateWordCount();
    }
  }

  void _updateWordCount() {
    final text = _textController.text;
    setState(() {
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _saveContent() async {
    if (_selectedSectionId == null || _isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      await widget.projectService.updateSectionContent(
        _project.id,
        _selectedSectionId!,
        _textController.text,
      );
      
      setState(() {
        _lastSaved = DateTime.now();
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _saveContent();
    _scrollController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (hidden in fullscreen)
            if (!_isFullscreen) _buildTopBar(isDark),
            
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Sidebar - Section tree
                  if (_showSidebar && !_isFullscreen)
                    _buildSidebar(isDark),
                  
                  // Editor area
                  Expanded(
                    child: _buildEditorArea(isDark),
                  ),
                  
                  // AI Panel
                  if (_showAIPanel && !_isFullscreen)
                    _buildAIPanel(isDark),
                ],
              ),
            ),
            
            // Bottom action bar
            if (!_isFullscreen) _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TOP BAR - Project info, toggles, actions
  // ============================================================================

  Widget _buildTopBar(bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, 
              color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          
          // Sidebar toggle
          IconButton(
            icon: Icon(
              _showSidebar ? Icons.menu_open : Icons.menu,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
          
          const SizedBox(width: 8),
          
          // Project badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _project.type.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_project.type.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  _project.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _project.type.accentColor,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Progress indicator
          _buildProgressPill(isDark),
          
          const SizedBox(width: 16),
          
          // Save status
          _buildSaveStatus(isDark),
          
          const SizedBox(width: 8),
          
          // AI Panel toggle
          _buildIconButton(
            icon: Icons.psychology,
            isActive: _showAIPanel,
            activeColor: _project.type.accentColor,
            isDark: isDark,
            onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
            tooltip: 'AI Assistant',
          ),
          
          // Memory
          _buildIconButton(
            icon: Icons.memory,
            isDark: isDark,
            onPressed: () => widget.onOpenMemory?.call(_project),
            tooltip: 'AI Memory',
          ),
          
          // Stats
          _buildIconButton(
            icon: Icons.bar_chart,
            isDark: isDark,
            onPressed: () => widget.onOpenStats?.call(_project),
            tooltip: 'Statistics',
          ),
          
          // Fullscreen
          _buildIconButton(
            icon: Icons.fullscreen,
            isDark: isDark,
            onPressed: () => setState(() => _isFullscreen = true),
            tooltip: 'Focus Mode',
          ),
          
          // More options
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, 
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export')),
              const PopupMenuItem(value: 'settings', child: Text('Project Settings')),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill(bool isDark) {
    final progress = _project.progress.percentComplete;
    final streak = _project.progress.currentStreak;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(_project.type.accentColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(width: 8),
            Text('🔥 $streak', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveStatus(bool isDark) {
    if (_isSaving) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(
            isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }
    
    if (_lastSaved != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done, size: 16, color: Colors.green[400]),
          const SizedBox(width: 4),
          Text(
            'Saved',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green[400],
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? activeColor,
    String? tooltip,
  }) {
    final button = IconButton(
      icon: Icon(
        icon,
        color: isActive
            ? (activeColor ?? _project.type.accentColor)
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
        size: 22,
      ),
      onPressed: onPressed,
    );
    
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  // ============================================================================
  // SIDEBAR - Section tree with status indicators
  // ============================================================================

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Sections',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, 
                    color: _project.type.accentColor, size: 20),
                  onPressed: _showAddSectionDialog,
                  tooltip: 'Add Section',
                ),
              ],
            ),
          ),
          
          // Section list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _buildSectionTree(_project.structure.sections, 0, isDark),
            ),
          ),
          
          // Quick stats at bottom
          _buildSidebarFooter(isDark),
        ],
      ),
    );
  }

  List<Widget> _buildSectionTree(
    List<ProjectSection> sections,
    int depth,
    bool isDark,
  ) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      widgets.add(_buildSectionItem(section, depth, isDark));
      
      if (section.children.isNotEmpty) {
        widgets.addAll(_buildSectionTree(section.children, depth + 1, isDark));
      }
    }
    
    return widgets;
  }

  Widget _buildSectionItem(ProjectSection section, int depth, bool isDark) {
    final isSelected = _selectedSectionId == section.id;
    final wordCount = _countSectionWords(section);
    
    return GestureDetector(
      onTap: () {
        // Save current before switching
        _saveContent();
        setState(() => _selectedSectionId = section.id);
        _loadSectionContent();
      },
      onLongPress: () => _showSectionOptions(section),
      child: Container(
        margin: EdgeInsets.only(
          left: depth * 16.0,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _project.type.accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: _project.type.accentColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: section.status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? _project.type.accentColor
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (wordCount > 0)
                    Text(
                      '$wordCount words',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            
            // Expand indicator if has children
            if (section.children.isNotEmpty)
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(bool isDark) {
    final totalWords = _project.progress.totalWordCount;
    final totalSections = _project.progress.totalSections;
    final complete = _project.progress.sectionsComplete;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Words', _formatNumber(totalWords), isDark),
          _buildStatItem('Sections', '$complete/$totalSections', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // EDITOR AREA - The beautiful writing space
  // ============================================================================

  Widget _buildEditorArea(bool isDark) {
    if (_selectedSection == null) {
      return _buildNoSectionSelected(isDark);
    }
    
    return GestureDetector(
      onTap: () {
        // Exit fullscreen on tap outside
        if (_isFullscreen) {
          // Could show a floating toolbar instead
        }
      },
      child: Container(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        child: Column(
          children: [
            // Fullscreen header (minimal)
            if (_isFullscreen) _buildFullscreenHeader(isDark),
            
            // Editor
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: _isFullscreen ? 120 : 40,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    if (!_isFullscreen) _buildSectionHeader(isDark),
                    
                    const SizedBox(height: 24),
                    
                    // THE EDITOR
                    // Replace this TextField with your flutter_quill editor
                    _buildTextEditor(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSectionSelected(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a section to start',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Or create a new one',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSectionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _project.type.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => setState(() => _isFullscreen = false),
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Text(
            _selectedSection!.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            '$_wordCount words',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedSection!.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -1,
                ),
              ),
            ),
            
            // Status dropdown
            _buildStatusDropdown(isDark),
          ],
        ),
        
        // Description if any
        if (_selectedSection!.description != null &&
            _selectedSection!.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _selectedSection!.description!,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Quick actions
        _buildQuickActions(isDark),
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return PopupMenuButton<SectionStatus>(
      onSelected: (status) async {
        await widget.projectService.updateSectionStatus(
          _project.id,
          _selectedSectionId!,
          status,
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedSection!.status.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedSection!.status.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedSection!.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedSection!.status.color,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: _selectedSection!.status.color,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => SectionStatus.values.map((status) {
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              Text(status.emoji),
              const SizedBox(width: 8),
              Text(status.displayName),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // RECORD - Primary action
        _buildActionChip(
          icon: Icons.mic,
          label: 'Record',
          isPrimary: true,
          isDark: isDark,
          onTap: () {
            if (widget.onStartRecording != null && _selectedSectionId != null) {
              widget.onStartRecording!(_project.id, _selectedSectionId!);
            }
          },
        ),
        
        // Continue with AI
        _buildActionChip(
          icon: Icons.auto_awesome,
          label: 'Continue',
          isDark: isDark,
          onTap: () => _triggerAIPreset('continue'),
        ),
        
        // Add subsection
        _buildActionChip(
          icon: Icons.add,
          label: 'Subsection',
          isDark: isDark,
          onTap: () => _showAddSectionDialog(parentId: _selectedSectionId),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? _project.type.accentColor
              : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark 
                      ? const Color(0xFF333333) 
                      : const Color(0xFFE0E0E0),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor(bool isDark) {
    // TODO: Replace with flutter_quill integration
    // 
    // return QuillEditor(
    //   controller: _quillController,
    //   scrollController: _scrollController,
    //   focusNode: FocusNode(),
    //   configurations: QuillEditorConfigurations(
    //     readOnly: false,
    //     placeholder: _getPlaceholder(),
    //     padding: EdgeInsets.zero,
    //     customStyles: DefaultStyles(
    //       paragraph: DefaultTextBlockStyle(
    //         TextStyle(
    //           fontSize: 18,
    //           height: 1.8,
    //           color: isDark ? Colors.grey[200] : Colors.grey[800],
    //         ),
    //         // ... more styling
    //       ),
    //     ),
    //   ),
    // );
    
    // Temporary: Plain TextField until quill connected
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 20,
      style: TextStyle(
        fontSize: 18,
        height: 1.8,
        color: isDark ? Colors.grey[200] : Colors.grey[800],
        fontFamily: 'Georgia',
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: _getPlaceholder(),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[700] : Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
      ),
      onChanged: (value) {
        _updateWordCount();
        
        // Auto-save after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _saveContent();
        });
      },
    );
  }

  String _getPlaceholder() {
    switch (_project.type) {
      case EliteProjectType.novel:
        return 'Start writing your scene...\n\nTip: Use the microphone to dictate and let words flow naturally.';
      case EliteProjectType.course:
        return 'Write your lesson content here...\n\nTip: Explain concepts out loud - voice often captures ideas better than typing.';
      case EliteProjectType.podcast:
        return 'Write your episode notes or script...\n\nTip: Record your talking points to capture your natural speaking style.';
      case EliteProjectType.youtube:
        return 'Write your video script...\n\nTip: Speak your script out loud first to find your authentic voice.';
      default:
        return 'Start writing...\n\nTip: Press the microphone button to dictate your thoughts.';
    }
  }

  // ============================================================================
  // AI PANEL - Format-specific presets
  // ============================================================================

  Widget _buildAIPanel(bool isDark) {
    final presets = EliteProjectAIContextService.getPresetsForType(_project.type);
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _project.type.accentColor,
                        _project.type.accentColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${_project.type.displayName} Mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: _project.type.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Presets list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Quick actions section
                _buildAISectionHeader('Quick Actions', isDark),
                ...presets.take(4).map((p) => _buildPresetCard(p, isDark)),
                
                const SizedBox(height: 16),
                
                // More presets
                _buildAISectionHeader('More Options', isDark),
                ...presets.skip(4).map((p) => _buildPresetCard(p, isDark)),
              ],
            ),
          ),
          
          // Bottom: Record button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Column(
              children: [
                // Voice record button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onStartRecording != null && _selectedSectionId != null) {
                        widget.onStartRecording!(_project.id, _selectedSectionId!);
                      }
                    },
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('Record Voice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _project.type.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Memory status
                _buildMemoryStatus(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPresetCard(AIPreset preset, bool isDark) {
    return GestureDetector(
      onTap: () => _triggerAIPreset(preset.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _project.type.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPresetIcon(preset.id),
                color: _project.type.accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryStatus(bool isDark) {
    final memory = _project.memory;
    final hasMemory = memory.characters.isNotEmpty ||
        memory.locations.isNotEmpty ||
        memory.facts.isNotEmpty ||
        memory.topics.isNotEmpty;
    
    return GestureDetector(
      onTap: () => widget.onOpenMemory?.call(_project),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 14,
              color: hasMemory 
                  ? _project.type.accentColor 
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              hasMemory
                  ? 'AI Memory Active'
                  : 'Add AI Memory',
              style: TextStyle(
                fontSize: 11,
                color: hasMemory
                    ? _project.type.accentColor
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresetIcon(String presetId) {
    if (presetId.contains('continue')) return Icons.play_arrow;
    if (presetId.contains('dialogue')) return Icons.chat_bubble_outline;
    if (presetId.contains('describe')) return Icons.visibility;
    if (presetId.contains('action')) return Icons.flash_on;
    if (presetId.contains('emotion')) return Icons.favorite_outline;
    if (presetId.contains('polish')) return Icons.auto_fix_high;
    if (presetId.contains('expand')) return Icons.unfold_more;
    if (presetId.contains('example')) return Icons.lightbulb_outline;
    if (presetId.contains('quiz')) return Icons.quiz;
    if (presetId.contains('intro')) return Icons.start;
    if (presetId.contains('outro')) return Icons.stop;
    if (presetId.contains('hook')) return Icons.catching_pokemon;
    if (presetId.contains('seo')) return Icons.search;
    if (presetId.contains('question')) return Icons.help_outline;
    if (presetId.contains('show')) return Icons.description;
    return Icons.auto_awesome;
  }

  // ============================================================================
  // BOTTOM BAR - Word count, quick record
  // ============================================================================

  Widget _buildBottomBar(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Word count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '$_wordCount words',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Streak indicator
          if (_project.progress.currentStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '${_project.progress.currentStreak} day streak',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // MAIN RECORD BUTTON
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onStartRecording != null && _selectedSectionId != null) {
                widget.onStartRecording!(_project.id, _selectedSectionId!);
              }
            },
            icon: const Icon(Icons.mic, size: 20),
            label: const Text('Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _project.type.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
              shadowColor: _project.type.accentColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS & ACTIONS
  // ============================================================================

  void _triggerAIPreset(String presetId) {
    if (widget.onUseAIPreset != null && _selectedSectionId != null) {
      final context = EliteProjectAIContextService.generateFullContext(
        _project,
        currentSectionId: _selectedSectionId,
        currentSectionContent: _textController.text,
      );
      widget.onUseAIPreset!(presetId, context, _selectedSectionId!);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        widget.onExport?.call(_project);
        break;
      case 'settings':
        // Show project settings
        break;
      case 'archive':
        _showArchiveConfirmation();
        break;
    }
  }

  void _showAddSectionDialog({String? parentId}) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parentId != null ? 'Add Subsection' : 'Add Section',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Section title',
                filled: true,
                fillColor: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      
                      await widget.projectService.addSection(
                        _project.id,
                        controller.text.trim(),
                        parentId: parentId,
                      );
                      
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _project.type.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSectionOptions(ProjectSection section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameSectionDialog(section);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Subsection'),
              onTap: () {
                Navigator.pop(context);
                _showAddSectionDialog(parentId: section.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(section);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameSectionDialog(ProjectSection section) {
    final controller = TextEditingController(text: section.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: const Text('Rename Section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Section title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await widget.projectService.updateSectionTitle(
                _project.id,
                section.id,
                controller.text.trim(),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ProjectSection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${section.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.projectService.deleteSection(_project.id, section.id);
              Navigator.pop(context);
              if (_selectedSectionId == section.id) {
                _selectedSectionId = null;
              }
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Project'),
        content: const Text('Archive this project? You can unarchive it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.projectService.archiveProject(_project.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }

  int _countSectionWords(ProjectSection section) {
    final content = section.content ?? '';
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
