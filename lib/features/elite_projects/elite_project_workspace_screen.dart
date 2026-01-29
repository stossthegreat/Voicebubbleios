// ============================================================================
// ELITE PROJECT WORKSPACE SCREEN
// ============================================================================
// The main creative environment - spacious, clean, distraction-free
// This is where Scrivener users will CRY with joy
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

class EliteProjectWorkspaceScreen extends StatefulWidget {
  final EliteProject project;
  final EliteProjectService projectService;
  final Function(String sectionId)? onRecordForSection;
  final VoidCallback? onBack;

  const EliteProjectWorkspaceScreen({
    super.key,
    required this.project,
    required this.projectService,
    this.onRecordForSection,
    this.onBack,
  });

  @override
  State<EliteProjectWorkspaceScreen> createState() => _EliteProjectWorkspaceScreenState();
}

class _EliteProjectWorkspaceScreenState extends State<EliteProjectWorkspaceScreen> {
  String? _selectedSectionId;
  bool _showSidebar = true;
  bool _isFullscreen = false;
  bool _showMemoryPanel = false;

  EliteProject get _project => widget.projectService.getProject(widget.project.id) ?? widget.project;

  @override
  void initState() {
    super.initState();
    // Select first section by default
    if (_project.structure.sections.isNotEmpty) {
      _selectedSectionId = _project.structure.sections.first.id;
    }
  }

  ProjectSection? get _selectedSection {
    if (_selectedSectionId == null) return null;
    return _findSection(_project.structure.sections, _selectedSectionId!);
  }

  ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            if (!_isFullscreen) _buildTopBar(isDark),
            
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  if (_showSidebar && !_isFullscreen)
                    _buildSidebar(isDark),
                  
                  // Main editor area
                  Expanded(
                    child: _buildEditorArea(isDark),
                  ),
                  
                  // Memory panel
                  if (_showMemoryPanel && !_isFullscreen)
                    _buildMemoryPanel(isDark),
                ],
              ),
            ),
            
            // Bottom bar
            if (!_isFullscreen) _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
            tooltip: 'Back to Projects',
          ),
          const SizedBox(width: 8),
          
          // Toggle sidebar
          IconButton(
            icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
            tooltip: _showSidebar ? 'Hide Sidebar' : 'Show Sidebar',
          ),
          
          const SizedBox(width: 16),
          
          // Project info
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _project.type.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_project.type.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        _project.type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _project.type.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_project.subtitle != null)
                        Text(
                          _project.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: _project.progress.percentComplete,
                    strokeWidth: 2,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(_project.type.accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_project.progress.percentComplete * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatWordCount(_project.progress.totalWordCount)} words',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Memory toggle
          IconButton(
            icon: Icon(
              _showMemoryPanel ? Icons.psychology : Icons.psychology_outlined,
              color: _showMemoryPanel ? _project.type.accentColor : null,
            ),
            onPressed: () => setState(() => _showMemoryPanel = !_showMemoryPanel),
            tooltip: 'AI Memory',
          ),
          
          // Fullscreen toggle
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
          ),
          
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Project')),
              const PopupMenuItem(value: 'settings', child: Text('Project Settings')),
              const PopupMenuItem(value: 'stats', child: Text('View Statistics')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'help', child: Text('Help & Tips')),
            ],
          ),
        ],
      ),
    );
  }

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
                Icon(
                  Icons.list_alt,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Structure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _addSection,
                  tooltip: 'Add Section',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Sections list
          Expanded(
            child: _project.structure.sections.isEmpty
                ? _buildEmptySidebar(isDark)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: _project.structure.sections
                        .map((s) => _buildSectionItem(s, 0, isDark))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySidebar(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No sections yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first section to start organizing',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Section'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _project.type.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(ProjectSection section, int depth, bool isDark) {
    final isSelected = _selectedSectionId == section.id;
    final hasChildren = section.children.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedSectionId = section.id),
          onLongPress: () => _showSectionOptions(section),
          child: Container(
            margin: EdgeInsets.only(left: depth * 16.0, bottom: 4),
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
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: section.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                
                // Section title
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? _project.type.accentColor
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Word count
                if (section.wordCount > 0)
                  Text(
                    _formatWordCount(section.wordCount),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                
                // Expand indicator
                if (hasChildren)
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
              ],
            ),
          ),
        ),
        
        // Children
        if (hasChildren)
          ...section.children.map((c) => _buildSectionItem(c, depth + 1, isDark)),
      ],
    );
  }

  Widget _buildEditorArea(bool isDark) {
    if (_selectedSection == null) {
      return _buildNoSectionSelected(isDark);
    }
    
    final section = _selectedSection!;
    
    return Container(
      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFCFCFC),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (section.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              section.description!,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status dropdown
                    _buildStatusDropdown(section, isDark),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Wrap(
                  spacing: 12,
                  children: [
                    _buildActionButton(
                      icon: Icons.mic,
                      label: 'Record',
                      color: const Color(0xFFEF4444),
                      onTap: () => widget.onRecordForSection?.call(section.id),
                    ),
                    _buildActionButton(
                      icon: Icons.auto_awesome,
                      label: 'AI Continue',
                      color: const Color(0xFF6366F1),
                      onTap: () => _showAIOptions(section),
                    ),
                    _buildActionButton(
                      icon: Icons.add,
                      label: 'Add Subsection',
                      color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                      textColor: isDark ? Colors.white : Colors.black,
                      onTap: () => _addSubsection(section.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: _buildContentArea(section, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(ProjectSection section, bool isDark) {
    return PopupMenuButton<SectionStatus>(
      onSelected: (status) async {
        await widget.projectService.updateSection(
          _project.id,
          section.copyWith(status: status),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: section.status.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: section.status.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              section.status.emoji,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 6),
            Text(
              section.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: section.status.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: section.status.color,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final isLight = color.computeLuminance() > 0.5;
    final fgColor = textColor ?? (isLight ? Colors.black : Colors.white);
    
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(ProjectSection section, bool isDark) {
    // Show recordings/content in this section
    if (section.itemIds.isEmpty) {
      return _buildEmptyContent(section, isDark);
    }
    
    // TODO: Load and display recordings
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: section.itemIds.length,
      itemBuilder: (context, index) {
        return _buildContentItem(section.itemIds[index], isDark);
      },
    );
  }

  Widget _buildEmptyContent(ProjectSection section, bool isDark) {
    final placeholder = section.metadata['placeholder'] as String?;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _project.type.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note,
                size: 36,
                color: _project.type.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to create',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (placeholder != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  placeholder,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onRecordForSection?.call(section.id),
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAIOptions(section),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI Generate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(String recordingId, bool isDark) {
    // Placeholder for actual recording display
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Recording $recordingId',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 20),
                onPressed: () {},
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Content preview would appear here...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
            Icons.touch_app,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a section',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a section from the sidebar to start working',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryPanel(bool isDark) {
    return Container(
      width: 320,
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
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 20,
                  color: _project.type.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Memory',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _addMemoryItem,
                  tooltip: 'Add Memory',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Memory content
          Expanded(
            child: _buildMemoryContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryContent(bool isDark) {
    final memory = _project.memory;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Characters
        if (_project.type == EliteProjectType.novel ||
            _project.type == EliteProjectType.memoir) ...[
          _buildMemorySection(
            'Characters',
            Icons.person,
            memory.characters.map((c) => c.name).toList(),
            isDark,
            onAdd: _addCharacter,
          ),
          const SizedBox(height: 16),
        ],
        
        // Locations
        if (_project.type == EliteProjectType.novel) ...[
          _buildMemorySection(
            'Locations',
            Icons.place,
            memory.locations.map((l) => l.name).toList(),
            isDark,
            onAdd: _addLocation,
          ),
          const SizedBox(height: 16),
        ],
        
        // Topics (for courses, blogs)
        if (_project.type == EliteProjectType.course ||
            _project.type == EliteProjectType.blog ||
            _project.type == EliteProjectType.podcast) ...[
          _buildMemorySection(
            'Topics',
            Icons.topic,
            memory.topics.map((t) => t.name).toList(),
            isDark,
            onAdd: _addTopic,
          ),
          const SizedBox(height: 16),
        ],
        
        // Key Facts
        _buildMemorySection(
          'Key Facts',
          Icons.lightbulb_outline,
          memory.facts.map((f) => f.fact).toList(),
          isDark,
          onAdd: _addFact,
        ),
        const SizedBox(height: 16),
        
        // Style
        _buildStyleSection(isDark),
      ],
    );
  }

  Widget _buildMemorySection(
    String title,
    IconData icon,
    List<String> items,
    bool isDark, {
    VoidCallback? onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Spacer(),
            if (onAdd != null)
              GestureDetector(
                onTap: onAdd,
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'No ${title.toLowerCase()} yet',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildStyleSection(bool isDark) {
    final style = _project.memory.style;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.style, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Writing Style',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _editStyle,
              child: Icon(
                Icons.edit,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (style.tone != null) _buildStyleRow('Tone', style.tone!, isDark),
              if (style.pointOfView != null) _buildStyleRow('POV', style.pointOfView!, isDark),
              if (style.tense != null) _buildStyleRow('Tense', style.tense!, isDark),
              if (style.tone == null && style.pointOfView == null && style.tense == null)
                Text(
                  'No style preferences set',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Streak indicator
          if (_project.progress.currentStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
          
          // Quick stats
          Text(
            '${_project.progress.sectionsComplete}/${_project.progress.totalSections} sections',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Last saved indicator
          Text(
            'Saved',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.cloud_done,
            size: 16,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _addSection() {
    _showAddSectionDialog();
  }

  void _addSubsection(String parentId) {
    _showAddSectionDialog(parentId: parentId);
  }

  void _showAddSectionDialog({String? parentId}) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(parentId == null ? 'Add Section' : 'Add Subsection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Section name',
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
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              final section = ProjectSection(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: controller.text.trim(),
              );
              
              await widget.projectService.addSection(
                _project.id,
                section,
                parentSectionId: parentId,
              );
              
              Navigator.pop(context);
              setState(() => _selectedSectionId = section.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _project.type.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSectionOptions(ProjectSection section) {
    HapticFeedback.mediumImpact();
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameSection(section);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Subsection'),
              onTap: () {
                Navigator.pop(context);
                _addSubsection(section.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSection(section);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _renameSection(ProjectSection section) {
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
          decoration: InputDecoration(
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
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              await widget.projectService.updateSection(
                _project.id,
                section.copyWith(title: controller.text.trim()),
              );
              
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _project.type.accentColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(ProjectSection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section?'),
        content: Text('Are you sure you want to delete "${section.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.projectService.deleteSection(_project.id, section.id);
              Navigator.pop(context);
              setState(() {
                if (_selectedSectionId == section.id) {
                  _selectedSectionId = _project.structure.sections.isNotEmpty
                      ? _project.structure.sections.first.id
                      : null;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAIOptions(ProjectSection section) {
    // Show AI preset options for this section
    final presets = EliteProjectPresets.getPresetsForType(_project.type);
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  Text(
                    'AI Assistance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            ...presets.map((preset) => ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(preset.name),
              subtitle: Text(preset.description),
              onTap: () {
                Navigator.pop(context);
                // Trigger AI with this preset
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addMemoryItem() {
    // Show add memory dialog
  }

  void _addCharacter() {
    // Show add character dialog
  }

  void _addLocation() {
    // Show add location dialog
  }

  void _addTopic() {
    // Show add topic dialog
  }

  void _addFact() {
    // Show add fact dialog
  }

  void _editStyle() {
    // Show style editor
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        // Show export options
        break;
      case 'settings':
        // Show project settings
        break;
      case 'stats':
        // Show statistics
        break;
      case 'help':
        // Show help
        break;
    }
  }

  String _formatWordCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
