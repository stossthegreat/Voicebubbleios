// ============================================================================
// ELITE PROJECTS INTEGRATION ROUTER
// ============================================================================
// The glue that connects everything together
// Drop this into your app and everything works
// ============================================================================

import 'package:flutter/material.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_voice_service.dart';
import 'elite_project_selection_screen.dart';
import 'elite_project_workspace_screen.dart';
import 'elite_project_section_editor.dart';
import 'elite_project_creation_wizard.dart';
import 'elite_project_statistics_screen.dart';
import 'elite_project_memory_editor.dart';

/// Main entry point for the Elite Projects system
/// 
/// Usage:
/// ```dart
/// // Initialize once in main.dart
/// final eliteProjects = EliteProjectsRouter();
/// await eliteProjects.initialize();
/// 
/// // Navigate to projects
/// Navigator.push(context, eliteProjects.projectsScreen(context));
/// ```
class EliteProjectsRouter {
  late final EliteProjectService _projectService;
  late final EliteProjectVoiceService _voiceService;
  
  bool _isInitialized = false;

  // Callback for when user wants to record
  Function(BuildContext context, EliteProject project, String sectionId)? onRecordRequested;
  
  // Callback for AI preset execution
  Function(BuildContext context, String presetId, String aiContext, EliteProject project)? onAIPresetRequested;

  /// Initialize the Elite Projects system
  /// Call this once when your app starts
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _projectService = EliteProjectService();
    await _projectService.initialize();
    
    _voiceService = EliteProjectVoiceService(projectService: _projectService);
    
    _isInitialized = true;
  }

  /// Get the project service for direct access
  EliteProjectService get projectService {
    _checkInitialized();
    return _projectService;
  }

  /// Get the voice service for recording integration
  EliteProjectVoiceService get voiceService {
    _checkInitialized();
    return _voiceService;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('EliteProjectsRouter not initialized. Call initialize() first.');
    }
  }

  // ============================================================================
  // NAVIGATION - Route builders for each screen
  // ============================================================================

  /// Main projects screen - shows all projects
  MaterialPageRoute projectsScreen(BuildContext context) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectSelectionScreen(
        projectService: _projectService,
        onProjectSelected: (project) {
          Navigator.push(context, workspaceScreen(context, project));
        },
      ),
    );
  }

  /// Project workspace - main editing environment
  MaterialPageRoute workspaceScreen(BuildContext context, EliteProject project) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectWorkspaceScreen(
        project: project,
        projectService: _projectService,
        onRecordForSection: (sectionId) {
          if (onRecordRequested != null) {
            onRecordRequested!(context, project, sectionId);
          } else {
            _showDefaultRecordDialog(context, project, sectionId);
          }
        },
        onOpenSection: (sectionId) {
          Navigator.push(context, sectionEditorScreen(context, project, sectionId));
        },
      ),
    );
  }

  /// Section editor - focused writing for a single section
  MaterialPageRoute sectionEditorScreen(
    BuildContext context,
    EliteProject project,
    String sectionId,
  ) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectSectionEditor(
        project: project,
        sectionId: sectionId,
        projectService: _projectService,
        onRecordPressed: (sectionId) {
          if (onRecordRequested != null) {
            onRecordRequested!(context, project, sectionId);
          } else {
            _showDefaultRecordDialog(context, project, sectionId);
          }
        },
        onAIPresetSelected: (presetId, aiContext) {
          if (onAIPresetRequested != null) {
            onAIPresetRequested!(context, presetId, aiContext, project);
          } else {
            _showDefaultAIDialog(context, presetId);
          }
        },
      ),
    );
  }

  /// Project creation wizard
  MaterialPageRoute creationWizardScreen(
    BuildContext context, {
    EliteProjectType? preselectedType,
  }) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectCreationWizard(
        projectService: _projectService,
        preselectedType: preselectedType,
        onProjectCreated: (project) {
          Navigator.pop(context);
          Navigator.push(context, workspaceScreen(context, project));
        },
      ),
    );
  }

  /// Statistics screen - progress visualization
  MaterialPageRoute statisticsScreen(BuildContext context, {EliteProject? project}) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectStatisticsScreen(
        projectService: _projectService,
        project: project,
      ),
    );
  }

  /// Memory editor - manage AI memory for a project
  MaterialPageRoute memoryEditorScreen(BuildContext context, EliteProject project) {
    _checkInitialized();
    
    return MaterialPageRoute(
      builder: (_) => EliteProjectMemoryEditor(
        project: project,
        projectService: _projectService,
      ),
    );
  }

  // ============================================================================
  // QUICK ACCESS WIDGETS
  // ============================================================================

  /// Widget showing recent/active projects for home screen
  Widget recentProjectsWidget({
    int maxProjects = 3,
    Function(EliteProject)? onProjectTap,
  }) {
    _checkInitialized();
    
    return ListenableBuilder(
      listenable: _projectService,
      builder: (context, _) {
        final projects = _projectService.projects
            .where((p) => !p.isArchived)
            .take(maxProjects)
            .toList();
        
        if (projects.isEmpty) {
          return _buildEmptyRecentProjects(context);
        }
        
        return Column(
          children: projects.map((project) => 
            _buildRecentProjectCard(context, project, onProjectTap)
          ).toList(),
        );
      },
    );
  }

  Widget _buildEmptyRecentProjects(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first project to get started',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, creationWizardScreen(context));
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
    );
  }

  Widget _buildRecentProjectCard(
    BuildContext context,
    EliteProject project,
    Function(EliteProject)? onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap(project);
        } else {
          Navigator.push(context, workspaceScreen(context, project));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            // Type badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: project.type.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  project.type.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${project.progress.totalWordCount} words',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
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
                ],
              ),
            ),
            
            // Progress
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: project.progress.percentComplete,
                    backgroundColor: isDark 
                        ? const Color(0xFF333333) 
                        : const Color(0xFFE5E5E5),
                    valueColor: AlwaysStoppedAnimation(project.type.accentColor),
                    strokeWidth: 4,
                  ),
                  Center(
                    child: Text(
                      '${(project.progress.percentComplete * 100).toInt()}%',
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
          ],
        ),
      ),
    );
  }

  /// Quick record button for home screen
  Widget quickRecordButton(BuildContext context) {
    _checkInitialized();
    
    return ListenableBuilder(
      listenable: _projectService,
      builder: (context, _) {
        final activeProject = _projectService.activeProject;
        
        if (activeProject == null) {
          return const SizedBox.shrink();
        }
        
        final continuation = _voiceService.getContinuationContext(activeProject);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: () {
            if (onRecordRequested != null && continuation.suggestedSectionId != null) {
              onRecordRequested!(context, activeProject, continuation.suggestedSectionId!);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeProject.type.accentColor,
                  activeProject.type.accentColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: activeProject.type.accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue Recording',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        continuation.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // DEFAULT DIALOGS (when callbacks not set)
  // ============================================================================

  void _showDefaultRecordDialog(
    BuildContext context,
    EliteProject project,
    String sectionId,
  ) {
    final recordingContext = _voiceService.generateRecordingContext(
      project: project,
      sectionId: sectionId,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Not Configured'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the onRecordRequested callback to handle recording.',
            ),
            const SizedBox(height: 16),
            Text(
              'Project: ${recordingContext.projectName}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Section: ${recordingContext.sectionTitle}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDefaultAIDialog(BuildContext context, String presetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Not Configured'),
        content: Text(
          'Set the onAIPresetRequested callback to handle AI preset: $presetId',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GLOBAL INSTANCE (optional singleton pattern)
// ============================================================================

/// Global instance for easy access throughout the app
/// Initialize with: await eliteProjects.initialize();
final eliteProjects = EliteProjectsRouter();

// ============================================================================
// INTEGRATION HELPERS
// ============================================================================

/// Extension to add Elite Projects to your existing recording flow
extension EliteProjectRecordingIntegration on EliteProjectsRouter {
  /// Call this when a recording is completed to add it to a project
  Future<void> onRecordingCompleted({
    required String projectId,
    required String sectionId,
    required String recordingId,
    required String transcribedText,
    String? enhancedText,
    Duration? recordingDuration,
  }) async {
    await voiceService.processRecordingForProject(
      projectId: projectId,
      sectionId: sectionId,
      recordingId: recordingId,
      transcribedText: transcribedText,
      enhancedText: enhancedText,
      recordingDuration: recordingDuration,
    );
  }

  /// Get recording context for a section
  RecordingContext getRecordingContext({
    required String projectId,
    required String sectionId,
  }) {
    final project = projectService.getProject(projectId);
    if (project == null) {
      throw Exception('Project not found');
    }
    
    return voiceService.generateRecordingContext(
      project: project,
      sectionId: sectionId,
    );
  }
}
