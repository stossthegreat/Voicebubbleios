// ============================================================================
// ELITE PROJECT VOICE INTEGRATION
// ============================================================================
// Connects the Elite Projects system to your voice recording workflow
// This is what makes it VOICE-FIRST unlike all competitors
// ============================================================================

import 'package:flutter/material.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

/// Handles voice recording integration for Elite Projects
/// This service bridges your existing recording system with the project structure
class EliteProjectVoiceService {
  final EliteProjectService projectService;

  EliteProjectVoiceService({required this.projectService});

  // ============================================================================
  // RECORDING CONTEXT GENERATION
  // ============================================================================

  /// Generates context for a new recording within a project section
  /// This context helps AI understand what the user is working on
  RecordingContext generateRecordingContext({
    required EliteProject project,
    required String sectionId,
  }) {
    final section = _findSection(project.structure.sections, sectionId);
    if (section == null) {
      return RecordingContext(
        projectName: project.name,
        projectType: project.type,
        sectionTitle: 'Unknown Section',
        aiContext: EliteProjectAIContextService.generateFullContext(project),
      );
    }

    // Get the section's position in hierarchy
    final breadcrumb = _getSectionBreadcrumb(project.structure.sections, sectionId);
    
    // Get surrounding content for better context
    final previousContent = _getPreviousSectionContent(project, sectionId);
    final nextSectionHint = _getNextSectionHint(project, sectionId);

    return RecordingContext(
      projectName: project.name,
      projectType: project.type,
      sectionId: sectionId,
      sectionTitle: section.title,
      sectionDescription: section.description,
      sectionBreadcrumb: breadcrumb,
      existingContent: section.content,
      previousContent: previousContent,
      nextSectionHint: nextSectionHint,
      aiContext: EliteProjectAIContextService.generateFullContext(
        project,
        currentSectionId: sectionId,
        currentSectionContent: section.content,
      ),
      suggestedPresets: _getSuggestedPresetsForSection(project, section),
    );
  }

  /// Get AI presets relevant to this section
  List<AIPreset> _getSuggestedPresetsForSection(
    EliteProject project,
    ProjectSection section,
  ) {
    final allPresets = EliteProjectAIContextService.getPresetsForType(project.type);
    
    // Prioritize based on section status
    if (section.content == null || section.content!.isEmpty) {
      // Empty section - prioritize creation presets
      return allPresets.where((p) => 
        p.id.contains('continue') || 
        p.id.contains('write') ||
        p.id.contains('create')
      ).toList();
    } else {
      // Has content - prioritize editing presets
      return allPresets.where((p) =>
        p.id.contains('expand') ||
        p.id.contains('polish') ||
        p.id.contains('describe')
      ).toList();
    }
  }

  // ============================================================================
  // RECORDING COMPLETION HANDLING
  // ============================================================================

  /// Process a completed recording and add it to the project
  Future<ProcessedRecording> processRecordingForProject({
    required String projectId,
    required String sectionId,
    required String recordingId,
    required String transcribedText,
    String? enhancedText,
    Duration? recordingDuration,
  }) async {
    // Add recording reference to section
    await projectService.addRecordingToSection(projectId, sectionId, recordingId);
    
    // Get the project for context
    final project = projectService.getProject(projectId);
    if (project == null) {
      throw Exception('Project not found');
    }

    // Update section content if enhanced text provided
    if (enhancedText != null && enhancedText.isNotEmpty) {
      final section = _findSection(project.structure.sections, sectionId);
      if (section != null) {
        final existingContent = section.content ?? '';
        final newContent = existingContent.isEmpty
            ? enhancedText
            : '$existingContent\n\n$enhancedText';
        
        await projectService.updateSectionContent(projectId, sectionId, newContent);
      }
    }

    // Update progress
    await projectService.updateProgress(
      projectId,
      wordsAdded: _countWords(enhancedText ?? transcribedText),
      minutesWorked: recordingDuration?.inMinutes ?? 1,
    );

    // Extract any new memory items from the content
    final memoryUpdates = await _extractMemoryFromContent(
      project,
      enhancedText ?? transcribedText,
    );

    return ProcessedRecording(
      recordingId: recordingId,
      sectionId: sectionId,
      transcribedText: transcribedText,
      enhancedText: enhancedText,
      wordsAdded: _countWords(enhancedText ?? transcribedText),
      memoryItemsExtracted: memoryUpdates,
    );
  }

  /// Extract memory items (characters, facts, etc.) from new content
  Future<List<String>> _extractMemoryFromContent(
    EliteProject project,
    String content,
  ) async {
    // This would call your AI service to extract entities
    // For now, return empty list - implement based on your AI backend
    final extractionPrompt = EliteProjectAIContextService.generateMemoryExtractionPrompt(
      project,
      content,
    );
    
    // TODO: Call AI service with extractionPrompt
    // Parse response and add to project memory
    
    return [];
  }

  // ============================================================================
  // QUICK RECORDING FEATURES
  // ============================================================================

  /// Get sections that are good candidates for recording
  List<SectionRecordingSuggestion> getRecordingSuggestions(EliteProject project) {
    final suggestions = <SectionRecordingSuggestion>[];
    
    void analyzeSections(List<ProjectSection> sections, int depth) {
      for (final section in sections) {
        final priority = _calculateRecordingPriority(section, project);
        
        if (priority > 0) {
          suggestions.add(SectionRecordingSuggestion(
            sectionId: section.id,
            sectionTitle: section.title,
            reason: _getRecordingReason(section),
            priority: priority,
            estimatedMinutes: _estimateRecordingTime(section, project),
          ));
        }
        
        analyzeSections(section.children, depth + 1);
      }
    }
    
    analyzeSections(project.structure.sections, 0);
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    
    return suggestions.take(5).toList();
  }

  int _calculateRecordingPriority(ProjectSection section, EliteProject project) {
    int priority = 0;
    
    // Empty sections get high priority
    if (section.content == null || section.content!.isEmpty) {
      priority += 10;
    }
    
    // Not started sections get medium-high priority
    if (section.status == SectionStatus.notStarted) {
      priority += 8;
    } else if (section.status == SectionStatus.inProgress) {
      priority += 5;
    }
    
    // First incomplete section in sequence gets bonus
    // (Continue where you left off)
    
    return priority;
  }

  String _getRecordingReason(ProjectSection section) {
    if (section.content == null || section.content!.isEmpty) {
      return 'Ready to start';
    }
    if (section.status == SectionStatus.inProgress) {
      return 'Continue working';
    }
    if (section.status == SectionStatus.needsRevision) {
      return 'Needs revision';
    }
    return 'Add more content';
  }

  int _estimateRecordingTime(ProjectSection section, EliteProject project) {
    // Rough estimate: 150 words per minute of speaking
    // Average section might need 300-500 words
    final targetWords = project.goals?.dailyWordGoal ?? 500;
    return (targetWords / 150).ceil();
  }

  // ============================================================================
  // CONTINUATION SUPPORT
  // ============================================================================

  /// Get context for "continue where I left off" feature
  ContinuationContext getContinuationContext(EliteProject project) {
    // Find the last worked-on section
    ProjectSection? lastSection;
    DateTime? lastModified;
    
    void findLastWorked(List<ProjectSection> sections) {
      for (final section in sections) {
        if (section.updatedAt != null) {
          if (lastModified == null || section.updatedAt!.isAfter(lastModified!)) {
            lastModified = section.updatedAt;
            lastSection = section;
          }
        }
        findLastWorked(section.children);
      }
    }
    
    findLastWorked(project.structure.sections);
    
    if (lastSection == null) {
      // No work done yet - suggest first section
      final firstSection = project.structure.sections.isNotEmpty
          ? project.structure.sections.first
          : null;
      
      return ContinuationContext(
        hasExistingWork: false,
        suggestedSectionId: firstSection?.id,
        suggestedSectionTitle: firstSection?.title ?? 'Get Started',
        message: 'Ready to begin your ${project.type.displayName.toLowerCase()}!',
      );
    }

    // Generate continuation prompt
    final continuationPrompt = EliteProjectAIContextService.generateContinuationContext(
      project,
      lastSection!.id,
    );

    return ContinuationContext(
      hasExistingWork: true,
      suggestedSectionId: lastSection!.id,
      suggestedSectionTitle: lastSection!.title,
      lastContent: lastSection!.content,
      lastModified: lastModified,
      message: 'Continue working on "${lastSection!.title}"',
      aiContinuationPrompt: continuationPrompt,
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }

  List<String> _getSectionBreadcrumb(List<ProjectSection> sections, String targetId) {
    List<String> breadcrumb = [];
    
    bool search(List<ProjectSection> sections, List<String> path) {
      for (final section in sections) {
        if (section.id == targetId) {
          breadcrumb = [...path, section.title];
          return true;
        }
        if (search(section.children, [...path, section.title])) {
          return true;
        }
      }
      return false;
    }
    
    search(sections, []);
    return breadcrumb;
  }

  String? _getPreviousSectionContent(EliteProject project, String sectionId) {
    final flatSections = _flattenSections(project.structure.sections);
    final index = flatSections.indexWhere((s) => s.id == sectionId);
    
    if (index > 0) {
      // Look back for a section with content
      for (int i = index - 1; i >= 0; i--) {
        if (flatSections[i].content != null && flatSections[i].content!.isNotEmpty) {
          // Return last ~200 words
          final content = flatSections[i].content!;
          final words = content.split(' ');
          if (words.length > 200) {
            return words.skip(words.length - 200).join(' ');
          }
          return content;
        }
      }
    }
    return null;
  }

  String? _getNextSectionHint(EliteProject project, String sectionId) {
    final flatSections = _flattenSections(project.structure.sections);
    final index = flatSections.indexWhere((s) => s.id == sectionId);
    
    if (index >= 0 && index < flatSections.length - 1) {
      final nextSection = flatSections[index + 1];
      return 'Next: ${nextSection.title}';
    }
    return null;
  }

  List<ProjectSection> _flattenSections(List<ProjectSection> sections) {
    final flat = <ProjectSection>[];
    void flatten(List<ProjectSection> sections) {
      for (final section in sections) {
        flat.add(section);
        flatten(section.children);
      }
    }
    flatten(sections);
    return flat;
  }

  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

class RecordingContext {
  final String projectName;
  final EliteProjectType projectType;
  final String? sectionId;
  final String sectionTitle;
  final String? sectionDescription;
  final List<String>? sectionBreadcrumb;
  final String? existingContent;
  final String? previousContent;
  final String? nextSectionHint;
  final String aiContext;
  final List<AIPreset>? suggestedPresets;

  RecordingContext({
    required this.projectName,
    required this.projectType,
    this.sectionId,
    required this.sectionTitle,
    this.sectionDescription,
    this.sectionBreadcrumb,
    this.existingContent,
    this.previousContent,
    this.nextSectionHint,
    required this.aiContext,
    this.suggestedPresets,
  });

  /// Format for display in recording UI
  String get displayTitle => '$projectName › $sectionTitle';

  /// Get a short context hint for the user
  String get contextHint {
    if (existingContent != null && existingContent!.isNotEmpty) {
      return 'Continue adding to this section';
    }
    return 'Start recording your thoughts for this section';
  }
}

class ProcessedRecording {
  final String recordingId;
  final String sectionId;
  final String transcribedText;
  final String? enhancedText;
  final int wordsAdded;
  final List<String> memoryItemsExtracted;

  ProcessedRecording({
    required this.recordingId,
    required this.sectionId,
    required this.transcribedText,
    this.enhancedText,
    required this.wordsAdded,
    required this.memoryItemsExtracted,
  });
}

class SectionRecordingSuggestion {
  final String sectionId;
  final String sectionTitle;
  final String reason;
  final int priority;
  final int estimatedMinutes;

  SectionRecordingSuggestion({
    required this.sectionId,
    required this.sectionTitle,
    required this.reason,
    required this.priority,
    required this.estimatedMinutes,
  });
}

class ContinuationContext {
  final bool hasExistingWork;
  final String? suggestedSectionId;
  final String suggestedSectionTitle;
  final String? lastContent;
  final DateTime? lastModified;
  final String message;
  final String? aiContinuationPrompt;

  ContinuationContext({
    required this.hasExistingWork,
    this.suggestedSectionId,
    required this.suggestedSectionTitle,
    this.lastContent,
    this.lastModified,
    required this.message,
    this.aiContinuationPrompt,
  });
}

// ============================================================================
// RECORDING SCREEN WIDGET - Drop-in component for your recording flow
// ============================================================================

class ProjectRecordingHeader extends StatelessWidget {
  final RecordingContext context;
  final VoidCallback? onChangeSection;

  const ProjectRecordingHeader({
    super.key,
    required this.context,
    this.onChangeSection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: this.context.projectType.accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: this.context.projectType.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      this.context.projectType.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      this.context.projectName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: this.context.projectType.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onChangeSection != null)
                TextButton.icon(
                  onPressed: onChangeSection,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Section title
          Text(
            this.context.sectionTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          
          // Breadcrumb
          if (this.context.sectionBreadcrumb != null && 
              this.context.sectionBreadcrumb!.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                this.context.sectionBreadcrumb!.join(' › '),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
          
          // Context hint
          const SizedBox(height: 8),
          Text(
            this.context.contextHint,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          
          // Existing content preview
          if (this.context.existingContent != null && 
              this.context.existingContent!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current content:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _truncateContent(this.context.existingContent!, 150),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          
          // Next section hint
          if (this.context.nextSectionHint != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  this.context.nextSectionHint!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }
}

// ============================================================================
// QUICK RECORD BUTTON - Add to your home screen
// ============================================================================

class QuickProjectRecordButton extends StatelessWidget {
  final EliteProject project;
  final VoidCallback onPressed;

  const QuickProjectRecordButton({
    super.key,
    required this.project,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              project.type.accentColor,
              project.type.accentColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: project.type.accentColor.withOpacity(0.3),
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
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue Recording',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
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
  }
}
