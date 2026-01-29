// ============================================================================
// ELITE PROJECT WORKSPACE - THE BEAUTIFUL BEAST
// ============================================================================
// Integrates with your existing:
// - flutter_quill editor
// - Recording flow (VoiceBubble → AI presets → output)
// - Library tab (add recordings to projects)
// - AI presets system
// 
// This is NOT separate - this IS your workspace
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_quill/flutter_quill.dart'; // Your existing quill
import 'dart:convert';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

class EliteWorkspace extends StatefulWidget {
  final EliteProject project;
  final EliteProjectService projectService;
  
  // YOUR EXISTING CALLBACKS - connects to your app
  final Function()? onRecordPressed; // Opens YOUR recording screen
  final Function(String presetId, String systemPrompt)? onAIPresetPressed;
  final Function(String content)? onExportPressed;
  
  const EliteWorkspace({
    super.key,
    required this.project,
    required this.projectService,
    this.onRecordPressed,
    this.onAIPresetPressed,
    this.onExportPressed,
  });

  @override
  State<EliteWorkspace> createState() => _EliteWorkspaceState();
}

class _EliteWorkspaceState extends State<EliteWorkspace> with TickerProviderStateMixin {
  // Quill controller - uses your existing flutter_quill
  // late QuillController _quillController;
  late TextEditingController _textController; // Fallback for now
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  
  String? _selectedSectionId;
  ProjectSection? _selectedSection;
  bool _showSidebar = true;
  bool _showAIPanel = false;
  bool _isZenMode = false; // Distraction-free
  bool _hasUnsavedChanges = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Select first section by default
    if (widget.project.structure.sections.isNotEmpty) {
      _selectSection(widget.project.structure.sections.first);
    }
  }

  void _selectSection(ProjectSection section) {
    // Save current before switching
    if (_hasUnsavedChanges && _selectedSectionId != null) {
      _saveCurrentSection();
    }
    
    setState(() {
      _selectedSectionId = section.id;
      _selectedSection = section;
      _textController.text = section.content ?? '';
      _hasUnsavedChanges = false;
      _updateWordCount();
    });
  }

  void _updateWordCount() {
    final text = _textController.text;
    setState(() {
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _saveCurrentSection() async {
    if (_selectedSectionId == null) return;
    
    await widget.projectService.updateSectionContent(
      widget.project.id,
      _selectedSectionId!,
      _textController.text,
    );
    
    setState(() => _hasUnsavedChanges = false);
  }

  @override
  void dispose() {
    if (_hasUnsavedChanges) _saveCurrentSection();
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isZenMode) {
      return _buildZenMode(isDark);
    }
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(isDark),
            
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Sidebar - Section navigator
                  if (_showSidebar) _buildSidebar(isDark),
                  
                  // Editor area
                  Expanded(child: _buildEditorArea(isDark)),
                  
                  // AI Panel
                  if (_showAIPanel) _buildAIPanel(isDark),
                ],
              ),
            ),
            
            // Bottom action bar
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TOP BAR - Project info + actions
  // ============================================================================

  Widget _buildTopBar(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, 
              size: 18,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          
          // Sidebar toggle
          IconButton(
            icon: Icon(
              _showSidebar ? Icons.menu_open : Icons.menu,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
          
          const SizedBox(width: 12),
          
          // Project info
          Expanded(
            child: Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.project.type.accentColor,
                        widget.project.type.accentColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.project.type.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        widget.project.type.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Project name
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedSection != null)
                        Text(
                          _selectedSection!.title,
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
          ),
          
          // Progress indicator
          _buildProgressBadge(isDark),
          
          const SizedBox(width: 16),
          
          // AI Panel toggle
          _buildGlowingButton(
            icon: Icons.auto_awesome,
            label: 'AI',
            isActive: _showAIPanel,
            color: const Color(0xFF8B5CF6),
            onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
          ),
          
          const SizedBox(width: 8),
          
          // Zen mode
          IconButton(
            icon: Icon(
              Icons.fullscreen,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: () => setState(() => _isZenMode = true),
            tooltip: 'Zen Mode',
          ),
          
          // More options
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black87),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'stats', child: Text('📊 Statistics')),
              const PopupMenuItem(value: 'memory', child: Text('🧠 AI Memory')),
              const PopupMenuItem(value: 'export', child: Text('📤 Export')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'settings', child: Text('⚙️ Settings')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(bool isDark) {
    final progress = widget.project.progress;
    final percent = (progress.percentComplete * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.project.type.accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress.percentComplete,
              strokeWidth: 2,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(widget.project.type.accentColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.project.type.accentColor,
            ),
          ),
          if (progress.currentStreak > 0) ...[
            const SizedBox(width: 8),
            Text('🔥${progress.currentStreak}', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildGlowingButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: isActive ? BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3 + (_pulseController.value * 0.2)),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ) : null,
          child: Material(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // SIDEBAR - Section navigator with beautiful hierarchy
  // ============================================================================

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : const Color(0xFFFCFCFC),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: Column(
        children: [
          // Quick actions
          _buildSidebarHeader(isDark),
          
          // Sections list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: widget.project.structure.sections
                  .map((s) => _buildSectionItem(s, 0, isDark))
                  .toList(),
            ),
          ),
          
          // Add section button
          _buildAddSectionButton(isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sections',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Quick filter/search
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              ),
            ),
            child: TextField(
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search sections...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(ProjectSection section, int depth, bool isDark) {
    final isSelected = _selectedSectionId == section.id;
    final hasContent = section.content != null && section.content!.isNotEmpty;
    final wordCount = hasContent ? section.content!.split(RegExp(r'\s+')).length : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _selectSection(section),
          child: Container(
            margin: EdgeInsets.only(
              left: 8 + (depth * 16.0),
              right: 8,
              bottom: 2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.project.type.accentColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: widget.project.type.accentColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
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
                              ? widget.project.type.accentColor
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasContent)
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
                
                // Recording indicator
                if (section.recordingIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.mic,
                      size: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Children
        ...section.children.map((child) => _buildSectionItem(child, depth + 1, isDark)),
      ],
    );
  }

  Widget _buildAddSectionButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showAddSectionDialog,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Section'),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.project.type.accentColor,
          side: BorderSide(color: widget.project.type.accentColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  // ============================================================================
  // EDITOR AREA - The beautiful writing space
  // ============================================================================

  Widget _buildEditorArea(bool isDark) {
    if (_selectedSection == null) {
      return _buildNoSectionSelected(isDark);
    }
    
    return Container(
      color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Section header
          _buildSectionHeader(isDark),
          
          // Editor
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title (editable)
                  _buildEditableTitle(isDark),
                  
                  const SizedBox(height: 24),
                  
                  // Main editor
                  // TODO: Replace with your flutter_quill editor
                  _buildTextEditor(isDark),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
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
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a section to start writing',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSectionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Section'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.project.type.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status dropdown
          _buildStatusDropdown(isDark),
          
          const Spacer(),
          
          // Word count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '$_wordCount words',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Save indicator
          if (_hasUnsavedChanges)
            TextButton.icon(
              onPressed: _saveCurrentSection,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: widget.project.type.accentColor,
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green[400]),
                const SizedBox(width: 4),
                Text(
                  'Saved',
                  style: TextStyle(fontSize: 12, color: Colors.green[400]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return PopupMenuButton<SectionStatus>(
      onSelected: (status) async {
        await widget.projectService.updateSectionStatus(
          widget.project.id,
          _selectedSectionId!,
          status,
        );
        setState(() {
          _selectedSection = _selectedSection!.copyWith(status: status);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedSection!.status.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedSection!.status.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              _selectedSection!.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedSection!.status.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: _selectedSection!.status.color),
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

  Widget _buildEditableTitle(bool isDark) {
    return TextField(
      controller: TextEditingController(text: _selectedSection!.title),
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Section Title',
      ),
      onChanged: (value) async {
        await widget.projectService.updateSectionTitle(
          widget.project.id,
          _selectedSectionId!,
          value,
        );
      },
    );
  }

  Widget _buildTextEditor(bool isDark) {
    // TODO: Replace this with your flutter_quill editor
    // QuillEditor(
    //   controller: _quillController,
    //   scrollController: _scrollController,
    //   focusNode: _focusNode,
    //   configurations: QuillEditorConfigurations(
    //     // your config
    //   ),
    // )
    
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 20,
      style: TextStyle(
        fontSize: 17,
        height: 1.8,
        color: isDark ? Colors.grey[200] : Colors.grey[800],
        fontFamily: 'Georgia', // Nice serif for writing
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: _getPlaceholderForType(),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[700] : Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
      ),
      onChanged: (value) {
        setState(() => _hasUnsavedChanges = true);
        _updateWordCount();
        
        // Auto-save after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_hasUnsavedChanges && mounted) {
            _saveCurrentSection();
          }
        });
      },
    );
  }

  String _getPlaceholderForType() {
    switch (widget.project.type) {
      case EliteProjectType.novel:
        return 'Begin your scene...\n\nTip: Press the record button to dictate!';
      case EliteProjectType.course:
        return 'Write your lesson content...\n\nTip: Explain concepts as if speaking to a student.';
      case EliteProjectType.podcast:
        return 'Write your episode notes...\n\nTip: Dictate your talking points naturally.';
      case EliteProjectType.youtube:
        return 'Write your video script...\n\nTip: Start with a strong hook!';
      case EliteProjectType.blog:
        return 'Start your article...\n\nTip: Lead with value.';
      default:
        return 'Start writing...\n\nTip: Press the microphone to record!';
    }
  }

  // ============================================================================
  // AI PANEL - Presets and magic
  // ============================================================================

  Widget _buildAIPanel(bool isDark) {
    final presets = EliteProjectAIContextService.getPresetsForType(widget.project.type);
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E8E8),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Presets
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildAIPanelSection(
                  'Quick Actions',
                  presets.take(6).toList(),
                  isDark,
                ),
                
                const SizedBox(height: 16),
                
                // Memory summary
                _buildMemorySummary(isDark),
              ],
            ),
          ),
          
          // Bottom record button
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildRecordButton(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPanelSection(String title, List<AIPreset> presets, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...presets.map((preset) => _buildPresetCard(preset, isDark)),
      ],
    );
  }

  Widget _buildPresetCard(AIPreset preset, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (widget.onAIPresetPressed != null) {
          final context = EliteProjectAIContextService.generateFullContext(
            widget.project,
            currentSectionId: _selectedSectionId,
            currentSectionContent: _textController.text,
          );
          widget.onAIPresetPressed!(preset.id, context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
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
                    widget.project.type.accentColor.withOpacity(0.2),
                    widget.project.type.accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPresetIcon(preset.id),
                color: widget.project.type.accentColor,
                size: 16,
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
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresetIcon(String presetId) {
    if (presetId.contains('continue')) return Icons.play_arrow;
    if (presetId.contains('dialogue')) return Icons.chat_bubble;
    if (presetId.contains('describe')) return Icons.visibility;
    if (presetId.contains('action')) return Icons.flash_on;
    if (presetId.contains('emotion')) return Icons.favorite;
    if (presetId.contains('polish')) return Icons.auto_fix_high;
    if (presetId.contains('expand')) return Icons.unfold_more;
    if (presetId.contains('example')) return Icons.lightbulb;
    if (presetId.contains('quiz')) return Icons.quiz;
    return Icons.auto_awesome;
  }

  Widget _buildMemorySummary(bool isDark) {
    final memory = widget.project.memory;
    final hasMemory = memory.characters.isNotEmpty ||
        memory.facts.isNotEmpty ||
        memory.locations.isNotEmpty;
    
    if (!hasMemory) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.psychology_outlined, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'No AI Memory Yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add characters, facts, and style to help AI stay consistent',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleMenuAction('memory'),
              child: const Text('Setup Memory'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI MEMORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (memory.characters.isNotEmpty)
              _buildMemoryChip('${memory.characters.length} characters', Icons.person, isDark),
            if (memory.locations.isNotEmpty)
              _buildMemoryChip('${memory.locations.length} locations', Icons.place, isDark),
            if (memory.facts.isNotEmpty)
              _buildMemoryChip('${memory.facts.length} facts', Icons.lightbulb, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoryChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: widget.project.type.accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM BAR - Record button and quick actions
  // ============================================================================

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE8E8E8),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quick stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.project.progress.totalWordCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.project.type.accentColor,
                  ),
                ),
                Text(
                  ' total words',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Continue with AI button
          OutlinedButton.icon(
            onPressed: () {
              if (widget.onAIPresetPressed != null) {
                final context = EliteProjectAIContextService.generateFullContext(
                  widget.project,
                  currentSectionId: _selectedSectionId,
                  currentSectionContent: _textController.text,
                );
                widget.onAIPresetPressed!('${widget.project.type.name}_continue', context);
              }
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Continue with AI'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Main record button
          _buildRecordButton(isDark),
        ],
      ),
    );
  }

  Widget _buildRecordButton(bool isDark) {
    return GestureDetector(
      onTap: widget.onRecordPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.project.type.accentColor,
              widget.project.type.accentColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: widget.project.type.accentColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Record',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ZEN MODE - Distraction-free writing
  // ============================================================================

  Widget _buildZenMode(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFDF8),
      body: GestureDetector(
        onDoubleTap: () => setState(() => _isZenMode = false),
        child: Stack(
          children: [
            // Editor
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      
                      // Title
                      Text(
                        _selectedSection?.title ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Editor
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 20,
                          height: 2,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          fontFamily: 'Georgia',
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[700] : Colors.grey[400],
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _hasUnsavedChanges = true);
                          _updateWordCount();
                        },
                      ),
                      
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),
            
            // Top bar (minimal)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.fullscreen_exit,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      onPressed: () => setState(() => _isZenMode = false),
                    ),
                    const Spacer(),
                    Text(
                      '$_wordCount words',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_hasUnsavedChanges)
                      Text(
                        'Saving...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                      )
                    else
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[400],
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom record button
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
                onPressed: widget.onRecordPressed,
                backgroundColor: widget.project.type.accentColor,
                child: const Icon(Icons.mic, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOGS & ACTIONS
  // ============================================================================

  void _showAddSectionDialog() {
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
              'Add Section',
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
                        widget.project.id,
                        controller.text.trim(),
                      );
                      
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.project.type.accentColor,
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'stats':
        // Navigate to stats screen
        break;
      case 'memory':
        // Navigate to memory editor
        break;
      case 'export':
        if (widget.onExportPressed != null) {
          widget.onExportPressed!(_textController.text);
        }
        break;
      case 'settings':
        // Open settings
        break;
    }
  }
}

// Helper extension for Section copyWith
extension ProjectSectionCopyWith on ProjectSection {
  ProjectSection copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    SectionStatus? status,
    List<ProjectSection>? children,
    List<String>? recordingIds,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectSection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      status: status ?? this.status,
      children: children ?? this.children,
      recordingIds: recordingIds ?? this.recordingIds,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
