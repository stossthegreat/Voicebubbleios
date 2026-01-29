// ============================================================================
// PROJECT BRIDGE - CONNECTS OLD PROJECT SYSTEM TO ELITE PROJECTS
// ============================================================================
// Handles migration and compatibility between existing Project model
// and new EliteProject system
// ============================================================================

import '../../models/project.dart';
import '../../models/recording_item.dart';
import 'elite_project_models.dart';

class ProjectBridge {
  
  /// Convert old Project to EliteProject
  static EliteProject fromLegacyProject(Project legacyProject, List<RecordingItem> items) {
    return EliteProject(
      id: legacyProject.id,
      name: legacyProject.name,
      type: EliteProjectType.freeform, // Default to freeform for existing projects
      description: legacyProject.description ?? 'Migrated from legacy project',
      createdAt: legacyProject.createdAt,
      updatedAt: DateTime.now(),
      structure: ProjectStructure(
        sections: _createSectionsFromItems(items),
        totalSections: items.length,
        completedSections: items.where((item) => item.enhancedText?.isNotEmpty ?? false).length,
      ),
      progress: ProjectProgress(
        wordCount: _calculateWordCount(items),
        targetWordCount: 10000, // Default target
        sessionsCount: items.length,
        totalTimeMinutes: items.length * 5, // Estimate 5 minutes per recording
        lastSessionAt: items.isNotEmpty ? items.last.createdAt : DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        dailyProgress: {},
      ),
      goals: ProjectGoals(
        dailyWordTarget: 500,
        weeklySessionTarget: 5,
        completionDeadline: DateTime.now().add(const Duration(days: 90)),
        isActive: true,
      ),
      aiMemory: ProjectAIMemory(
        characters: [],
        locations: [],
        topics: [],
        facts: [],
        plotPoints: [],
        style: StyleMemory(
          tone: 'conversational',
          pointOfView: 'first_person',
          tense: 'present',
          customInstructions: 'Continue in the same style and voice.',
        ),
      ),
      settings: ProjectSettings(
        isPrivate: false,
        allowCollaboration: false,
        autoSave: true,
        backupEnabled: true,
        exportFormats: ['text', 'markdown'],
        aiAssistanceLevel: AIAssistanceLevel.balanced,
      ),
    );
  }
  
  /// Convert EliteProject back to legacy Project (for compatibility)
  static Project toLegacyProject(EliteProject eliteProject) {
    return Project(
      id: eliteProject.id,
      name: eliteProject.name,
      description: eliteProject.description,
      createdAt: eliteProject.createdAt,
      tags: [], // Legacy projects don't have tags in elite system
    );
  }
  
  /// Create sections from recording items
  static List<ProjectSection> _createSectionsFromItems(List<RecordingItem> items) {
    return items.map((item) => ProjectSection(
      id: item.id,
      title: _extractTitle(item.enhancedText ?? item.rawTranscript ?? 'Untitled'),
      content: item.enhancedText ?? item.rawTranscript ?? '',
      status: (item.enhancedText?.isNotEmpty ?? false) 
          ? SectionStatus.completed 
          : SectionStatus.draft,
      wordCount: _countWords(item.enhancedText ?? item.rawTranscript ?? ''),
      createdAt: item.createdAt,
      updatedAt: item.createdAt,
      recordingIds: [item.id],
      aiContext: '',
      tags: item.tags?.map((tag) => tag.name).toList() ?? [],
      isLocked: false,
      order: items.indexOf(item),
    )).toList();
  }
  
  /// Extract title from content (first line or first few words)
  static String _extractTitle(String content) {
    if (content.isEmpty) return 'Untitled Section';
    
    final lines = content.split('\n');
    final firstLine = lines.first.trim();
    
    if (firstLine.length <= 50) {
      return firstLine;
    }
    
    final words = firstLine.split(' ');
    if (words.length <= 8) {
      return firstLine;
    }
    
    return '${words.take(8).join(' ')}...';
  }
  
  /// Calculate total word count from items
  static int _calculateWordCount(List<RecordingItem> items) {
    return items.fold(0, (total, item) {
      final text = item.enhancedText ?? item.rawTranscript ?? '';
      return total + _countWords(text);
    });
  }
  
  /// Count words in text
  static int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
  
  /// Check if a legacy project should be migrated
  static bool shouldMigrate(Project legacyProject) {
    // Migrate all legacy projects to elite system
    return true;
  }
  
  /// Get appropriate EliteProjectType based on project content
  static EliteProjectType inferProjectType(Project legacyProject, List<RecordingItem> items) {
    final allText = items
        .map((item) => (item.enhancedText ?? item.rawTranscript ?? '').toLowerCase())
        .join(' ');
    
    // Simple keyword-based inference
    if (allText.contains('chapter') || allText.contains('character') || allText.contains('plot')) {
      return EliteProjectType.novel;
    }
    
    if (allText.contains('lesson') || allText.contains('course') || allText.contains('tutorial')) {
      return EliteProjectType.course;
    }
    
    if (allText.contains('episode') || allText.contains('podcast') || allText.contains('interview')) {
      return EliteProjectType.podcast;
    }
    
    if (allText.contains('video') || allText.contains('youtube') || allText.contains('script')) {
      return EliteProjectType.youtube;
    }
    
    if (allText.contains('article') || allText.contains('blog') || allText.contains('post')) {
      return EliteProjectType.blog;
    }
    
    if (allText.contains('research') || allText.contains('thesis') || allText.contains('study')) {
      return EliteProjectType.research;
    }
    
    if (allText.contains('business') || allText.contains('plan') || allText.contains('strategy')) {
      return EliteProjectType.business;
    }
    
    if (allText.contains('memoir') || allText.contains('life') || allText.contains('story')) {
      return EliteProjectType.memoir;
    }
    
    // Default to freeform
    return EliteProjectType.freeform;
  }
}