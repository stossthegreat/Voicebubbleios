// ============================================================================
// MOVE RECORDING TO PROJECT
// ============================================================================
// Feature for LIBRARY screen to move existing recordings into projects
// Long-press a recording → "Move to Project"
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';

/// Shows as an action when user long-presses a recording in Library
class MoveToProjectAction {
  final EliteProjectService projectService;
  
  MoveToProjectAction({required this.projectService});
  
  /// Call this to show the move dialog
  /// Returns true if moved successfully
  Future<bool> show(
    BuildContext context, {
    required String recordingId,
    required String recordingContent,
    String? recordingTitle,
  }) async {
    final result = await showModalBottomSheet<MoveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveToProjectSheet(
        projectService: projectService,
        recordingId: recordingId,
        recordingContent: recordingContent,
        recordingTitle: recordingTitle,
      ),
    );
    
    return result?.success ?? false;
  }
}

class MoveResult {
  final bool success;
  final String? projectId;
  final String? sectionId;
  
  MoveResult({
    required this.success,
    this.projectId,
    this.sectionId,
  });
}

class MoveToProjectSheet extends StatefulWidget {
  final EliteProjectService projectService;
  final String recordingId;
  final String recordingContent;
  final String? recordingTitle;

  const MoveToProjectSheet({
    super.key,
    required this.projectService,
    required this.recordingId,
    required this.recordingContent,
    this.recordingTitle,
  });

  @override
  State<MoveToProjectSheet> createState() => _MoveToProjectSheetState();
}

class _MoveToProjectSheetState extends State<MoveToProjectSheet> {
  EliteProject? _selectedProject;
  ProjectSection? _selectedSection;
  bool _createNewSection = false;
  final _newSectionController = TextEditingController();
  bool _isMoving = false;
  bool _appendContent = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill new section name with recording title if available
    if (widget.recordingTitle != null) {
      _newSectionController.text = widget.recordingTitle!;
    }
    
    // Pre-select active project
    if (widget.projectService.activeProject != null) {
      _selectedProject = widget.projectService.activeProject;
    }
  }

  @override
  void dispose() {
    _newSectionController.dispose();
    super.dispose();
  }

  Future<void> _moveToProject() async {
    if (_selectedProject == null) return;
    if (!_createNewSection && _selectedSection == null) return;
    if (_createNewSection && _newSectionController.text.trim().isEmpty) return;
    
    setState(() => _isMoving = true);
    
    try {
      String sectionId;
      
      if (_createNewSection) {
        // Create new section first
        final newSection = await widget.projectService.addSection(
          _selectedProject!.id,
          _newSectionController.text.trim(),
        );
        sectionId = newSection.id;
      } else {
        sectionId = _selectedSection!.id;
        
        // Handle existing content
        final existingContent = _selectedSection!.content ?? '';
        String newContent;
        
        if (_appendContent && existingContent.isNotEmpty) {
          newContent = '$existingContent\n\n${widget.recordingContent}';
        } else {
          newContent = widget.recordingContent;
        }
        
        await widget.projectService.updateSectionContent(
          _selectedProject!.id,
          sectionId,
          newContent,
        );
      }
      
      // Add recording reference
      await widget.projectService.addRecordingToSection(
        _selectedProject!.id,
        sectionId,
        widget.recordingId,
      );
      
      // Update progress
      final wordCount = widget.recordingContent.trim().split(RegExp(r'\s+')).length;
      await widget.projectService.updateProgress(
        _selectedProject!.id,
        wordsAdded: wordCount,
        minutesWorked: 1,
      );
      
      // If creating new section, add the content
      if (_createNewSection) {
        await widget.projectService.updateSectionContent(
          _selectedProject!.id,
          sectionId,
          widget.recordingContent,
        );
      }
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        Navigator.pop(context, MoveResult(
          success: true,
          projectId: _selectedProject!.id,
          sectionId: sectionId,
        ));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _createNewSection
                        ? 'Created "${_newSectionController.text}" in ${_selectedProject!.name}'
                        : 'Moved to "${_selectedSection!.title}"',
                  ),
                ),
              ],
            ),
            backgroundColor: _selectedProject!.type.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to project workspace
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isMoving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to move: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = widget.projectService.projects.where((p) => !p.isArchived).toList();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              _buildHeader(isDark),
              
              // Preview of content being moved
              _buildContentPreview(isDark),
              
              // Main content
              Expanded(
                child: projects.isEmpty
                    ? _buildNoProjects(isDark)
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Project selector
                          _buildSectionTitle('SELECT PROJECT', isDark),
                          const SizedBox(height: 12),
                          ..._buildProjectList(projects, isDark),
                          
                          // Section selector (if project selected)
                          if (_selectedProject != null) ...[
                            const SizedBox(height: 24),
                            _buildSectionTitle('SELECT OR CREATE SECTION', isDark),
                            const SizedBox(height: 12),
                            _buildCreateNewSectionOption(isDark),
                            if (!_createNewSection) ...[
                              const SizedBox(height: 8),
                              ..._buildSectionList(
                                _selectedProject!.structure.sections,
                                0,
                                isDark,
                              ),
                            ],
                            
                            // Append toggle (if existing section selected)
                            if (!_createNewSection && 
                                _selectedSection != null &&
                                _selectedSection!.content != null &&
                                _selectedSection!.content!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildAppendToggle(isDark),
                            ],
                          ],
                          
                          const SizedBox(height: 100),
                        ],
                      ),
              ),
              
              // Bottom action
              _buildBottomAction(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedProject?.type.accentColor ?? const Color(0xFF6366F1),
                  (_selectedProject?.type.accentColor ?? const Color(0xFF6366F1)).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.drive_file_move, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move to Project',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${widget.recordingContent.split(RegExp(r'\s+')).length} words',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(bool isDark) {
    final preview = widget.recordingContent.length > 150
        ? '${widget.recordingContent.substring(0, 150)}...'
        : widget.recordingContent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.content_copy, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Content to move:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[500] : Colors.grey[600],
        letterSpacing: 1,
      ),
    );
  }

  List<Widget> _buildProjectList(List<EliteProject> projects, bool isDark) {
    return projects.map((project) {
      final isSelected = _selectedProject?.id == project.id;
      
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedProject = project;
            _selectedSection = null;
            _createNewSection = false;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? project.type.accentColor.withOpacity(0.15)
                : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? project.type.accentColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: project.type.accentColor.withOpacity(isSelected ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(project.type.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? project.type.accentColor
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      '${project.structure.sections.length} sections • ${project.progress.totalWordCount} words',
                      style: TextStyle(
                        fontSize: 12,
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
                    color: project.type.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildCreateNewSectionOption(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _createNewSection = true;
              _selectedSection = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _createNewSection
                  ? _selectedProject!.type.accentColor.withOpacity(0.15)
                  : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _createNewSection
                    ? _selectedProject!.type.accentColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedProject!.type.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _selectedProject!.type.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create New Section',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _createNewSection ? FontWeight.w700 : FontWeight.w500,
                      color: _createNewSection
                          ? _selectedProject!.type.accentColor
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                if (_createNewSection)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedProject!.type.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
              ],
            ),
          ),
        ),
        
        // New section name input
        if (_createNewSection) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _newSectionController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Section name',
              filled: true,
              fillColor: isDark ? const Color(0xFF252525) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _selectedProject!.type.accentColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _selectedProject!.type.accentColor,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSectionList(List<ProjectSection> sections, int depth, bool isDark) {
    final widgets = <Widget>[];
    
    for (final section in sections) {
      final isSelected = _selectedSection?.id == section.id;
      
      widgets.add(
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedSection = section;
              _createNewSection = false;
            });
          },
          child: Container(
            margin: EdgeInsets.only(
              left: depth * 16.0,
              bottom: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedProject!.type.accentColor.withOpacity(0.15)
                  : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _selectedProject!.type.accentColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: section.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? _selectedProject!.type.accentColor
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: _selectedProject!.type.accentColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
      
      widgets.addAll(_buildSectionList(section.children, depth + 1, isDark));
    }
    
    return widgets;
  }

  Widget _buildAppendToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Section has existing content',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appendContent = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _appendContent
                          ? _selectedProject!.type.accentColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _appendContent
                            ? _selectedProject!.type.accentColor
                            : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_to_photos,
                          size: 20,
                          color: _appendContent
                              ? _selectedProject!.type.accentColor
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Append',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _appendContent
                                ? _selectedProject!.type.accentColor
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appendContent = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_appendContent
                          ? Colors.red.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_appendContent
                            ? Colors.red
                            : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.find_replace,
                          size: 20,
                          color: !_appendContent
                              ? Colors.red
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Replace',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_appendContent
                                ? Colors.red
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
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
    );
  }

  Widget _buildNoProjects(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open, size: 40, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          Text(
            'No Projects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a project first',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    final canMove = _selectedProject != null &&
        (_createNewSection ? _newSectionController.text.trim().isNotEmpty : _selectedSection != null);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: canMove && !_isMoving ? _moveToProject : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedProject?.type.accentColor ?? const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[300],
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isMoving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.drive_file_move, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _createNewSection
                        ? 'Create Section & Move'
                        : (_selectedSection != null ? 'Move to "${_selectedSection!.title}"' : 'Select destination'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
