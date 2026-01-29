// ============================================================================
// PROJECT RECORDING CONTEXT WIDGETS
// ============================================================================
// These widgets integrate with your EXISTING recording screen
// Shows project context while user records
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

/// Shows project + section context at top of recording screen
/// Drop this into your existing recording UI
class ProjectRecordingContext extends StatelessWidget {
  final EliteProject project;
  final ProjectSection section;
  final VoidCallback? onChangeSection;
  final bool compact;

  const ProjectRecordingContext({
    super.key,
    required this.project,
    required this.section,
    this.onChangeSection,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (compact) {
      return _buildCompact(context, isDark);
    }
    
    return _buildFull(context, isDark);
  }

  Widget _buildCompact(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: project.type.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(project.type.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: project.type.accentColor,
                  ),
                ),
              ],
            ),
          ),
          if (onChangeSection != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 18),
              onPressed: onChangeSection,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, bool isDark) {
    final hasContent = section.content != null && section.content!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: project.type.accentColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: project.type.accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  project.type.accentColor.withOpacity(0.15),
                  project.type.accentColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: project.type.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(project.type.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recording for',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: project.type.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onChangeSection != null)
                  TextButton(
                    onPressed: onChangeSection,
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: project.type.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Section info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: section.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      section.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: section.status.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (section.description != null && section.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    section.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                
                // Existing content preview
                if (hasContent) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Continue from:',
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
                          _getLastContent(section.content!, 100),
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
                  ),
                ],
                
                // Tips
                const SizedBox(height: 16),
                _buildRecordingTip(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingTip(bool isDark) {
    String tip;
    IconData icon;
    
    switch (project.type) {
      case EliteProjectType.novel:
        tip = 'Speak naturally - describe the scene as if telling a friend';
        icon = Icons.auto_stories;
        break;
      case EliteProjectType.course:
        tip = 'Explain as if teaching a student one-on-one';
        icon = Icons.school;
        break;
      case EliteProjectType.podcast:
        tip = 'Talk like you\'re having a conversation';
        icon = Icons.podcasts;
        break;
      case EliteProjectType.youtube:
        tip = 'Start with energy - hook them in the first 5 seconds';
        icon = Icons.play_circle;
        break;
      case EliteProjectType.blog:
        tip = 'Share your insights naturally - we\'ll polish it later';
        icon = Icons.article;
        break;
      default:
        tip = 'Just speak naturally - AI will format it perfectly';
        icon = Icons.mic;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: project.type.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: project.type.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLastContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    
    // Get last portion
    final lastPart = content.substring(content.length - maxLength);
    final firstSpace = lastPart.indexOf(' ');
    
    if (firstSpace > 0) {
      return '...${lastPart.substring(firstSpace + 1)}';
    }
    return '...$lastPart';
  }
}

// ============================================================================
// SECTION SELECTOR - Pick which section to record for
// ============================================================================

class ProjectSectionSelector extends StatelessWidget {
  final EliteProject project;
  final String? selectedSectionId;
  final Function(ProjectSection) onSectionSelected;
  final Function()? onCreateSection;

  const ProjectSectionSelector({
    super.key,
    required this.project,
    this.selectedSectionId,
    required this.onSectionSelected,
    this.onCreateSection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: project.type.accentColor.withOpacity(0.15),
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
                        'Select Section',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: project.type.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Sections list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._buildSectionItems(project.structure.sections, 0, isDark),
                
                // Add section option
                if (onCreateSection != null) ...[
                  const SizedBox(height: 8),
                  _buildAddSectionItem(isDark),
                ],
              ],
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  List<Widget> _buildSectionItems(List<ProjectSection> sections, int depth, bool isDark) {
    final widgets = <Widget>[];
    
    for (final section in sections) {
      final isSelected = selectedSectionId == section.id;
      final hasContent = section.content != null && section.content!.isNotEmpty;
      final wordCount = hasContent ? section.content!.split(RegExp(r'\s+')).length : 0;
      
      widgets.add(
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSectionSelected(section);
          },
          child: Container(
            margin: EdgeInsets.only(
              left: depth * 20.0,
              bottom: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: section.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Title and stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? project.type.accentColor
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      if (hasContent)
                        Text(
                          '$wordCount words',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        )
                      else
                        Text(
                          'Empty - ready to start',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: project.type.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      );
      
      // Recursively add children
      widgets.addAll(_buildSectionItems(section.children, depth + 1, isDark));
    }
    
    return widgets;
  }

  Widget _buildAddSectionItem(bool isDark) {
    return GestureDetector(
      onTap: onCreateSection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: project.type.accentColor.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: project.type.accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Add New Section',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: project.type.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK PROJECT PICKER - For selecting project before recording
// ============================================================================

class QuickProjectPicker extends StatelessWidget {
  final EliteProjectService projectService;
  final Function(EliteProject, ProjectSection) onSelected;
  final VoidCallback? onCreateProject;

  const QuickProjectPicker({
    super.key,
    required this.projectService,
    required this.onSelected,
    this.onCreateProject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = projectService.projects.where((p) => !p.isArchived).toList();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                      child: const Icon(Icons.mic, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record to Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Select where to save your recording',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Projects
              Expanded(
                child: projects.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          return _buildProjectItem(
                            context,
                            projects[index],
                            isDark,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectItem(BuildContext context, EliteProject project, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 20, right: 16, bottom: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: project.type.accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(project.type.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          project.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          '${project.structure.sections.length} sections',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
        collapsedBackgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
        children: [
          ...project.structure.sections.map((section) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: section.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                section.title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelected(project, section);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
              'Create a project to start recording',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            if (onCreateProject != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onCreateProject!();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER - Show quick project picker
// ============================================================================

Future<void> showProjectPicker(
  BuildContext context, {
  required EliteProjectService projectService,
  required Function(EliteProject, ProjectSection) onSelected,
  VoidCallback? onCreateProject,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickProjectPicker(
      projectService: projectService,
      onSelected: onSelected,
      onCreateProject: onCreateProject,
    ),
  );
}
