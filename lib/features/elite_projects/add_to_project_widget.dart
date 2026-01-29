// ============================================================================
// ADD TO PROJECT WIDGET
// ============================================================================
// This widget appears on your OUTPUT PAGE after recording
// Allows users to add their content directly to a project section
// Drop this into your existing output/result screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';

/// Drop-in widget for your output page
/// Shows "Add to Project" option after AI generates content
class AddToProjectButton extends StatelessWidget {
  final EliteProjectService projectService;
  final String content; // The transcribed/enhanced content to add
  final String? recordingId; // Optional recording reference
  final VoidCallback? onAdded;

  const AddToProjectButton({
    super.key,
    required this.projectService,
    required this.content,
    this.recordingId,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _showAddToProjectSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_to_photos_outlined,
                color: Color(0xFF6366F1),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Project',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Save to a section',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToProjectSheet(
        projectService: projectService,
        content: content,
        recordingId: recordingId,
        onAdded: onAdded,
      ),
    );
  }
}

/// Full-screen bottom sheet for selecting project and section
class AddToProjectSheet extends StatefulWidget {
  final EliteProjectService projectService;
  final String content;
  final String? recordingId;
  final VoidCallback? onAdded;

  const AddToProjectSheet({
    super.key,
    required this.projectService,
    required this.content,
    this.recordingId,
    this.onAdded,
  });

  @override
  State<AddToProjectSheet> createState() => _AddToProjectSheetState();
}

class _AddToProjectSheetState extends State<AddToProjectSheet> {
  EliteProject? _selectedProject;
  ProjectSection? _selectedSection;
  bool _appendMode = true; // true = append, false = replace
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Pre-select active project if any
    if (widget.projectService.activeProject != null) {
      _selectedProject = widget.projectService.activeProject;
    }
  }

  Future<void> _addToProject() async {
    if (_selectedProject == null || _selectedSection == null) return;
    
    setState(() => _isAdding = true);
    
    try {
      // Get existing content
      final existingContent = _selectedSection!.content ?? '';
      
      // Determine new content
      String newContent;
      if (_appendMode && existingContent.isNotEmpty) {
        newContent = '$existingContent\n\n${widget.content}';
      } else {
        newContent = widget.content;
      }
      
      // Update section content
      await widget.projectService.updateSectionContent(
        _selectedProject!.id,
        _selectedSection!.id,
        newContent,
      );
      
      // Add recording reference if provided
      if (widget.recordingId != null) {
        await widget.projectService.addRecordingToSection(
          _selectedProject!.id,
          _selectedSection!.id,
          widget.recordingId!,
        );
      }
      
      // Update progress
      final wordCount = widget.content.trim().split(RegExp(r'\s+')).length;
      await widget.projectService.updateProgress(
        _selectedProject!.id,
        wordsAdded: wordCount,
        minutesWorked: 1,
      );
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Added to "${_selectedSection!.title}" in ${_selectedProject!.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        widget.onAdded?.call();
      }
    } catch (e) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = widget.projectService.projects.where((p) => !p.isArchived).toList();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_to_photos, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${widget.content.split(RegExp(r'\s+')).length} words',
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
              ),
              
              // Content
              Expanded(
                child: projects.isEmpty
                    ? _buildNoProjects(isDark)
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Project selector
                          Text(
                            'SELECT PROJECT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Project cards (horizontal scroll)
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: projects.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                final isSelected = _selectedProject?.id == project.id;
                                
                                return _buildProjectCard(project, isSelected, isDark);
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Section selector
                          if (_selectedProject != null) ...[
                            Text(
                              'SELECT SECTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            ..._buildSectionList(_selectedProject!.structure.sections, 0, isDark),
                            
                            const SizedBox(height: 24),
                            
                            // Append/Replace toggle
                            if (_selectedSection != null && 
                                _selectedSection!.content != null &&
                                _selectedSection!.content!.isNotEmpty)
                              _buildAppendToggle(isDark),
                          ],
                          
                          const SizedBox(height: 100),
                        ],
                      ),
              ),
              
              // Bottom action
              Container(
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
                  onPressed: (_selectedProject != null && _selectedSection != null && !_isAdding)
                      ? _addToProject
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedProject?.type.accentColor ?? const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[300],
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isAdding
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
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedSection != null
                                  ? 'Add to "${_selectedSection!.title}"'
                                  : 'Select a section',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(EliteProject project, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedProject = project;
          _selectedSection = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? project.type.accentColor.withOpacity(0.15)
              : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? project.type.accentColor
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(project.type.emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: project.type.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              project.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? project.type.accentColor
                    : (isDark ? Colors.white : Colors.black),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSectionList(List<ProjectSection> sections, int depth, bool isDark) {
    final widgets = <Widget>[];
    
    for (final section in sections) {
      final isSelected = _selectedSection?.id == section.id;
      final hasContent = section.content != null && section.content!.isNotEmpty;
      
      widgets.add(
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedSection = section);
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
                    : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8)),
                width: isSelected ? 2 : 1,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? _selectedProject!.type.accentColor
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      if (hasContent)
                        Text(
                          '${section.content!.split(RegExp(r'\s+')).length} words',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                    ],
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
      
      // Add children
      widgets.addAll(_buildSectionList(section.children, depth + 1, isDark));
    }
    
    return widgets;
  }

  Widget _buildAppendToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This section already has content',
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
                child: _buildToggleOption(
                  label: 'Append',
                  subtitle: 'Add to end',
                  isSelected: _appendMode,
                  onTap: () => setState(() => _appendMode = true),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleOption(
                  label: 'Replace',
                  subtitle: 'Overwrite',
                  isSelected: !_appendMode,
                  onTap: () => setState(() => _appendMode = false),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedProject!.type.accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _selectedProject!.type.accentColor
                : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? _selectedProject!.type.accentColor
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProjects(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              child: const Icon(
                Icons.folder_open,
                size: 40,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Projects Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a project first to organize your recordings',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to create project
                // TODO: Call your creation wizard
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK ADD CHIP - Compact version for inline use
// ============================================================================

class QuickAddToProjectChip extends StatelessWidget {
  final EliteProjectService projectService;
  final String content;
  final String? recordingId;

  const QuickAddToProjectChip({
    super.key,
    required this.projectService,
    required this.content,
    this.recordingId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(width: 6),
            const Text(
              'Add to Project',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToProjectSheet(
        projectService: projectService,
        content: content,
        recordingId: recordingId,
      ),
    );
  }
}
