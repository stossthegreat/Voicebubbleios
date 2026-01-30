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
    final now = DateTime.now();
    
    return EliteProject(
      id: legacyProject.id,
      name: legacyProject.name,
      type: EliteProjectType.freeform,
      description: legacyProject.description ?? 'Migrated from legacy project',
      createdAt: legacyProject.createdAt,
      updatedAt: now,
      structure: ProjectStructure(
        sections: _createSectionsFromItems(items),
        totalSections: items.length,
        completedSections: items.where((item) => item.finalText.isNotEmpty).length,
      ),
      progress: ProjectProgress(
        wordCount: _calculateWordCount(items),
        targetWordCount: 10000,
        sessionsCount: items.length,
        totalTimeMinutes: items.length * 5,
        lastSessionAt: items.isNotEmpty ? items.last.createdAt : now,
        currentStreak: 1,
        longestStreak: 1,
        dailyProgress: {},
      ),
      projectGoals: const ProjectGoals(
        dailyWordTarget: 500,
        weeklySessionTarget: 5,
        isActive: true,
      ),
      aiMemory: const ProjectAIMemory(
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
      itemIds: items.map((i) => i.id).toList(),
      tags: [],
    );
  }

  /// Create sections from recording items
  static List<ProjectSection> _createSectionsFromItems(List<RecordingItem> items) {
    return items.map((item) => ProjectSection(
      id: item.id,
      title: _getTitleFromContent(item.finalText, item.createdAt),
      content: item.finalText,
      status: item.finalText.isNotEmpty
          ? SectionStatus.completed
          : SectionStatus.notStarted,
      createdAt: item.createdAt,
      updatedAt: item.createdAt,
      recordingIds: [item.id],
    )).toList();
  }

  /// Get title from content or date
  static String _getTitleFromContent(String content, DateTime createdAt) {
    if (content.isEmpty) {
      return 'Recording ${createdAt.toString().substring(0, 10)}';
    }
    final firstLine = content.split('\n').first.trim();
    if (firstLine.length <= 50) return firstLine;
    return '${firstLine.substring(0, 47)}...';
  }

  /// Calculate total word count from items
  static int _calculateWordCount(List<RecordingItem> items) {
    int total = 0;
    for (final item in items) {
      final text = item.finalText;
      total = total + text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }
    return total;
  }

  /// Extract common topics from items
  static List<TopicMemory> _extractTopics(List<RecordingItem> items) {
    final wordCounts = <String, int>{};
    
    for (final item in items) {
      final text = item.finalText.toLowerCase();
      final words = text.split(RegExp(r'\s+'))
          .where((w) => w.length > 5)
          .toList();
      
      for (final word in words) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(5).map((entry) => TopicMemory(
      id: 'topic_${entry.key}',
      name: entry.key,
      description: 'Mentioned ${entry.value} times',
    )).toList();
  }
}
