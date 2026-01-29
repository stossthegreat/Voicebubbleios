// ============================================================================
// ELITE PROJECTS - LIBRARY TAB
// ============================================================================
// This is the Projects section that lives INSIDE your Library screen
// Beautiful, integrated, ELITE
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';

class LibraryProjectsTab extends StatefulWidget {
  final EliteProjectService projectService;
  final Function(EliteProject) onProjectTap;
  final Function() onCreateProject;
  final Function(EliteProject)? onQuickRecord;

  const LibraryProjectsTab({
    super.key,
    required this.projectService,
    required this.onProjectTap,
    required this.onCreateProject,
    this.onQuickRecord,
  });

  @override
  State<LibraryProjectsTab> createState() => _LibraryProjectsTabState();
}

class _LibraryProjectsTabState extends State<LibraryProjectsTab> {
  String _searchQuery = '';
  EliteProjectType? _filterType;
  String _sortBy = 'recent'; // recent, name, progress

  List<EliteProject> get _filteredProjects {
    var projects = widget.projectService.projects
        .where((p) => !p.isArchived)
        .toList();

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      projects = projects.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.subtitle?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Filter by type
    if (_filterType != null) {
      projects = projects.where((p) => p.type == _filterType).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        projects.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'progress':
        projects.sort((a, b) => b.progress.percentComplete.compareTo(a.progress.percentComplete));
        break;
      case 'recent':
      default:
        projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return projects;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.projectService,
      builder: (context, _) {
        final projects = _filteredProjects;

        return CustomScrollView(
          slivers: [
            // Header with search and filters
            SliverToBoxAdapter(
              child: _buildHeader(isDark),
            ),

            // Quick stats bar
            if (widget.projectService.projects.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildQuickStats(isDark),
              ),

            // Active project card (if any)
            if (widget.projectService.activeProject != null)
              SliverToBoxAdapter(
                child: _buildActiveProjectCard(isDark),
              ),

            // Projects grid or empty state
            if (projects.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(isDark),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProjectCard(projects[index], isDark),
                    childCount: projects.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search projects...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All filter
                _buildFilterChip(
                  label: 'All',
                  isSelected: _filterType == null,
                  onTap: () => setState(() => _filterType = null),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                // Type filters
                ...EliteProjectType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: type.emoji,
                    isSelected: _filterType == type,
                    onTap: () => setState(() => 
                      _filterType = _filterType == type ? null : type
                    ),
                    isDark: isDark,
                    color: type.accentColor,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? const Color(0xFF6366F1))
              : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (color ?? const Color(0xFF6366F1))
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final stats = ProjectStatistics.fromProjects(widget.projectService.projects);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.15),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: stats.totalProjects.toString(),
            label: 'Projects',
            icon: Icons.folder_outlined,
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          _buildStatItem(
            value: _formatWordCount(stats.totalWords),
            label: 'Words',
            icon: Icons.text_fields,
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          _buildStatItem(
            value: stats.currentStreak > 0 ? '🔥 ${stats.currentStreak}' : '—',
            label: 'Streak',
            icon: null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    IconData? icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: const Color(0xFF6366F1), size: 18),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProjectCard(bool isDark) {
    final project = widget.projectService.activeProject!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => widget.onProjectTap(project),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                project.type.accentColor,
                project.type.accentColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: project.type.accentColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Project emoji
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    project.type.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (project.progress.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🔥 ${project.progress.currentStreak}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(project.progress.percentComplete * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${project.progress.totalWordCount} words',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick record button
              if (widget.onQuickRecord != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onQuickRecord!(project);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.mic,
                      color: project.type.accentColor,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(EliteProject project, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onProjectTap(project);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showProjectOptions(project);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    project.type.accentColor.withOpacity(0.2),
                    project.type.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Stack(
                children: [
                  // Type emoji
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3) 
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          project.type.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  
                  // Progress ring
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: project.progress.percentComplete,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation(
                              project.type.accentColor,
                            ),
                            strokeWidth: 3,
                          ),
                          Center(
                            child: Text(
                              '${(project.progress.percentComplete * 100).toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          _formatWordCount(project.progress.totalWordCount),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (project.progress.currentStreak > 0) ...[
                          const Spacer(),
                          Text(
                            '🔥 ${project.progress.currentStreak}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? 'No projects found'
                  : 'Start Your First Project',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? 'Try a different search or filter'
                  : 'Create a project to organize your\nvoice recordings into something amazing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (_searchQuery.isEmpty && _filterType == null)
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onCreateProject();
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProjectOptions(EliteProject project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Project info
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: project.type.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(project.type.emoji, style: const TextStyle(fontSize: 24)),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          project.type.displayName,
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
              
              const SizedBox(height: 24),
              
              // Options
              _buildOptionTile(
                icon: Icons.play_arrow,
                label: 'Continue Working',
                onTap: () {
                  Navigator.pop(context);
                  widget.onProjectTap(project);
                },
                isDark: isDark,
              ),
              _buildOptionTile(
                icon: Icons.mic,
                label: 'Quick Record',
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onQuickRecord != null) {
                    widget.onQuickRecord!(project);
                  }
                },
                isDark: isDark,
              ),
              _buildOptionTile(
                icon: Icons.star_outline,
                label: widget.projectService.activeProject?.id == project.id
                    ? 'Remove from Active'
                    : 'Set as Active Project',
                onTap: () async {
                  if (widget.projectService.activeProject?.id == project.id) {
                    await widget.projectService.setActiveProject(null);
                  } else {
                    await widget.projectService.setActiveProject(project.id);
                  }
                  Navigator.pop(context);
                },
                isDark: isDark,
              ),
              _buildOptionTile(
                icon: Icons.archive_outlined,
                label: 'Archive Project',
                onTap: () async {
                  await widget.projectService.archiveProject(project.id);
                  Navigator.pop(context);
                },
                isDark: isDark,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k words';
    }
    return '$count words';
  }
}

// ============================================================================
// FLOATING CREATE BUTTON - Add to your Library screen
// ============================================================================

class ProjectsFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProjectsFloatingButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text(
        'New Project',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
