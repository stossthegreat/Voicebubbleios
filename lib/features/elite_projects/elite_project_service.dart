// ============================================================================
// ELITE PROJECT SERVICE - The Engine That Powers Everything
// ============================================================================
// CRUD operations, persistence, state management, progress tracking
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'elite_project_models.dart';
import 'elite_project_templates.dart';

const _uuid = Uuid();

// ============================================================================
// PROJECT SERVICE - Main service class
// ============================================================================

class EliteProjectService extends ChangeNotifier {
  static const String _boxName = 'elite_projects';
  static const String _settingsBoxName = 'elite_project_settings';
  
  Box<String>? _projectBox;
  Box<String>? _settingsBox;
  
  List<EliteProject> _projects = [];
  bool _isInitialized = false;
  String? _activeProjectId;

  // Getters
  List<EliteProject> get projects => List.unmodifiable(_projects);
  bool get isInitialized => _isInitialized;
  String? get activeProjectId => _activeProjectId;
  
  EliteProject? get activeProject {
    if (_activeProjectId == null) return null;
    return _projects.firstWhere(
      (p) => p.id == _activeProjectId,
      orElse: () => _projects.first,
    );
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _projectBox = await Hive.openBox<String>(_boxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
    
    // Load all projects
    await _loadProjects();
    
    // Load active project
    _activeProjectId = _settingsBox?.get('activeProjectId');
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadProjects() async {
    if (_projectBox == null) return;
    
    _projects = [];
    for (final key in _projectBox!.keys) {
      try {
        final json = _projectBox!.get(key);
        if (json != null) {
          final project = EliteProject.fromJson(jsonDecode(json));
          _projects.add(project);
        }
      } catch (e) {
        debugPrint('Error loading project $key: $e');
      }
    }
    
    // Sort by last updated
    _projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ============================================================================
  // CREATE PROJECT
  // ============================================================================

  /// Create a new project from a template
  Future<EliteProject> createProject({
    required String name,
    required EliteProjectType type,
    String? subtitle,
    String? templateId,
    int colorIndex = 0,
  }) async {
    final template = templateId != null 
        ? EliteProjectTemplateRegistry.getTemplate(templateId)
        : null;
    
    final project = EliteProject(
      id: _uuid.v4(),
      name: name,
      subtitle: subtitle,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      structure: template?.generateStructure() ?? ProjectStructure(sections: [
        ProjectSection(
          id: _uuid.v4(),
          title: 'Section 1',
          description: 'Your first section',
        ),
      ]),
      goals: template?.suggestedGoals ?? ProjectGoals(),
      progress: ProjectProgress(
        totalSections: template?.sections.length ?? 1,
      ),
      memory: ProjectMemory(
        style: template?.suggestedStyle ?? const StyleMemory(),
      ),
    );
    
    await _saveProject(project);
    _projects.insert(0, project);
    
    // Set as active if it's the first project
    if (_projects.length == 1) {
      await setActiveProject(project.id);
    }
    
    notifyListeners();
    return project;
  }

  /// Create a blank project with custom structure
  Future<EliteProject> createBlankProject({
    required String name,
    required EliteProjectType type,
    String? subtitle,
  }) async {
    return createProject(
      name: name,
      type: type,
      subtitle: subtitle,
    );
  }

  // ============================================================================
  // READ OPERATIONS
  // ============================================================================

  EliteProject? getProject(String id) {
    return _projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project not found: $id'),
    );
  }

  List<EliteProject> getProjectsByType(EliteProjectType type) {
    return _projects.where((p) => p.type == type).toList();
  }

  List<EliteProject> getRecentProjects({int limit = 5}) {
    return _projects.take(limit).toList();
  }

  List<EliteProject> searchProjects(String query) {
    final lowerQuery = query.toLowerCase();
    return _projects.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
             (p.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ============================================================================
  // UPDATE OPERATIONS
  // ============================================================================

  Future<void> updateProject(EliteProject project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    await _saveProject(updated);
    
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = updated;
    }
    
    notifyListeners();
  }

  Future<void> updateProjectName(String projectId, String name, {String? subtitle}) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    await updateProject(project.copyWith(
      name: name,
      subtitle: subtitle,
    ));
  }

  Future<void> updateProjectGoals(String projectId, ProjectGoals goals) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    await updateProject(project.copyWith(goals: goals));
  }

  Future<void> updateProjectMemory(String projectId, ProjectMemory memory) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    await updateProject(project.copyWith(memory: memory));
  }

  // ============================================================================
  // SECTION OPERATIONS
  // ============================================================================

  Future<void> addSection(
    String projectId,
    ProjectSection section, {
    String? parentSectionId,
  }) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _addSectionToStructure(
      project.structure,
      section,
      parentSectionId,
    );
    
    await updateProject(project.copyWith(
      structure: newStructure,
      progress: project.progress.copyWith(
        totalSections: _countSections(newStructure.sections),
      ),
    ));
  }

  Future<void> updateSection(
    String projectId,
    ProjectSection section,
  ) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _updateSectionInStructure(
      project.structure,
      section,
    );
    
    // Recalculate completed sections
    final completedCount = _countCompletedSections(newStructure.sections);
    
    await updateProject(project.copyWith(
      structure: newStructure,
      progress: project.progress.copyWith(
        sectionsComplete: completedCount,
      ),
    ));
  }

  Future<void> deleteSection(String projectId, String sectionId) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _deleteSectionFromStructure(
      project.structure,
      sectionId,
    );
    
    await updateProject(project.copyWith(
      structure: newStructure,
      progress: project.progress.copyWith(
        totalSections: _countSections(newStructure.sections),
        sectionsComplete: _countCompletedSections(newStructure.sections),
      ),
    ));
  }

  Future<void> reorderSections(
    String projectId,
    List<String> sectionIds, {
    String? parentSectionId,
  }) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _reorderSectionsInStructure(
      project.structure,
      sectionIds,
      parentSectionId,
    );
    
    await updateProject(project.copyWith(structure: newStructure));
  }

  // ============================================================================
  // PROGRESS TRACKING
  // ============================================================================

  Future<void> recordProgress(
    String projectId, {
    int wordsWritten = 0,
    int minutesWorked = 0,
    int sectionsCompleted = 0,
  }) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Update daily history
    final history = List<DailyProgress>.from(project.progress.dailyHistory);
    final todayIndex = history.indexWhere((d) => 
      d.date.year == todayDate.year &&
      d.date.month == todayDate.month &&
      d.date.day == todayDate.day
    );
    
    if (todayIndex >= 0) {
      history[todayIndex] = DailyProgress(
        date: todayDate,
        wordsWritten: history[todayIndex].wordsWritten + wordsWritten,
        minutesWorked: history[todayIndex].minutesWorked + minutesWorked,
        sectionsCompleted: history[todayIndex].sectionsCompleted + sectionsCompleted,
      );
    } else {
      history.add(DailyProgress(
        date: todayDate,
        wordsWritten: wordsWritten,
        minutesWorked: minutesWorked,
        sectionsCompleted: sectionsCompleted,
      ));
    }
    
    // Calculate streak
    final streak = _calculateStreak(history);
    
    await updateProject(project.copyWith(
      progress: project.progress.copyWith(
        totalWordCount: project.progress.totalWordCount + wordsWritten,
        sectionsComplete: project.progress.sectionsComplete + sectionsCompleted,
        lastWorkedOn: DateTime.now(),
        dailyHistory: history,
        currentStreak: streak,
        longestStreak: streak > project.progress.longestStreak 
            ? streak 
            : project.progress.longestStreak,
      ),
    ));
  }

  int _calculateStreak(List<DailyProgress> history) {
    if (history.isEmpty) return 0;
    
    // Sort by date descending
    final sorted = List<DailyProgress>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime? lastDate;
    
    for (final progress in sorted) {
      if (progress.wordsWritten > 0 || progress.minutesWorked > 0) {
        if (lastDate == null) {
          // First day with progress
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final progressDate = DateTime(
            progress.date.year,
            progress.date.month,
            progress.date.day,
          );
          
          // Only count if it's today or yesterday
          final diff = todayDate.difference(progressDate).inDays;
          if (diff > 1) break;
          
          streak = 1;
          lastDate = progressDate;
        } else {
          // Check if consecutive
          final progressDate = DateTime(
            progress.date.year,
            progress.date.month,
            progress.date.day,
          );
          final diff = lastDate.difference(progressDate).inDays;
          
          if (diff == 1) {
            streak++;
            lastDate = progressDate;
          } else {
            break;
          }
        }
      }
    }
    
    return streak;
  }

  // ============================================================================
  // MEMORY OPERATIONS
  // ============================================================================

  Future<void> addCharacter(String projectId, CharacterMemory character) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final characters = List<CharacterMemory>.from(project.memory.characters)
      ..add(character);
    
    await updateProject(project.copyWith(
      memory: project.memory.copyWith(characters: characters),
    ));
  }

  Future<void> updateCharacter(String projectId, CharacterMemory character) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final characters = List<CharacterMemory>.from(project.memory.characters);
    final index = characters.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      characters[index] = character;
      await updateProject(project.copyWith(
        memory: project.memory.copyWith(characters: characters),
      ));
    }
  }

  Future<void> deleteCharacter(String projectId, String characterId) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final characters = project.memory.characters
        .where((c) => c.id != characterId)
        .toList();
    
    await updateProject(project.copyWith(
      memory: project.memory.copyWith(characters: characters),
    ));
  }

  Future<void> addFact(String projectId, FactMemory fact) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final facts = List<FactMemory>.from(project.memory.facts)..add(fact);
    
    await updateProject(project.copyWith(
      memory: project.memory.copyWith(facts: facts),
    ));
  }

  Future<void> addPlotPoint(String projectId, PlotPoint plotPoint) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final plotPoints = List<PlotPoint>.from(project.memory.plotPoints)
      ..add(plotPoint);
    
    await updateProject(project.copyWith(
      memory: project.memory.copyWith(plotPoints: plotPoints),
    ));
  }

  Future<void> updateStyle(String projectId, StyleMemory style) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    await updateProject(project.copyWith(
      memory: project.memory.copyWith(style: style),
    ));
  }

  // ============================================================================
  // DELETE OPERATIONS
  // ============================================================================

  Future<void> deleteProject(String projectId) async {
    await _projectBox?.delete(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    
    if (_activeProjectId == projectId) {
      _activeProjectId = _projects.isNotEmpty ? _projects.first.id : null;
      await _settingsBox?.put('activeProjectId', _activeProjectId);
    }
    
    notifyListeners();
  }

  // ============================================================================
  // ACTIVE PROJECT
  // ============================================================================

  Future<void> setActiveProject(String projectId) async {
    _activeProjectId = projectId;
    await _settingsBox?.put('activeProjectId', projectId);
    notifyListeners();
  }

  // ============================================================================
  // RECORDING INTEGRATION
  // ============================================================================

  /// Add a recording to a project section
  Future<void> addRecordingToSection(
    String projectId,
    String sectionId,
    String recordingId,
  ) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _addRecordingToSection(
      project.structure,
      sectionId,
      recordingId,
    );
    
    final itemIds = List<String>.from(project.itemIds);
    if (!itemIds.contains(recordingId)) {
      itemIds.add(recordingId);
    }
    
    await updateProject(project.copyWith(
      structure: newStructure,
      itemIds: itemIds,
    ));
  }

  /// Remove a recording from a project
  Future<void> removeRecordingFromProject(
    String projectId,
    String recordingId,
  ) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _removeRecordingFromStructure(
      project.structure,
      recordingId,
    );
    
    final itemIds = List<String>.from(project.itemIds)
      ..remove(recordingId);
    
    await updateProject(project.copyWith(
      structure: newStructure,
      itemIds: itemIds,
    ));
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<void> _saveProject(EliteProject project) async {
    await _projectBox?.put(project.id, jsonEncode(project.toJson()));
  }

  int _countSections(List<ProjectSection> sections) {
    int count = 0;
    for (final section in sections) {
      count++;
      count += _countSections(section.children);
    }
    return count;
  }

  int _countCompletedSections(List<ProjectSection> sections) {
    int count = 0;
    for (final section in sections) {
      if (section.status == SectionStatus.complete) count++;
      count += _countCompletedSections(section.children);
    }
    return count;
  }

  ProjectStructure _addSectionToStructure(
    ProjectStructure structure,
    ProjectSection section,
    String? parentId,
  ) {
    if (parentId == null) {
      return structure.copyWith(
        sections: [...structure.sections, section],
      );
    }
    
    return structure.copyWith(
      sections: _addSectionToList(structure.sections, section, parentId),
    );
  }

  List<ProjectSection> _addSectionToList(
    List<ProjectSection> sections,
    ProjectSection newSection,
    String parentId,
  ) {
    return sections.map((section) {
      if (section.id == parentId) {
        return section.copyWith(
          children: [...section.children, newSection],
        );
      }
      return section.copyWith(
        children: _addSectionToList(section.children, newSection, parentId),
      );
    }).toList();
  }

  ProjectStructure _updateSectionInStructure(
    ProjectStructure structure,
    ProjectSection updated,
  ) {
    return structure.copyWith(
      sections: _updateSectionInList(structure.sections, updated),
    );
  }

  List<ProjectSection> _updateSectionInList(
    List<ProjectSection> sections,
    ProjectSection updated,
  ) {
    return sections.map((section) {
      if (section.id == updated.id) {
        return updated;
      }
      return section.copyWith(
        children: _updateSectionInList(section.children, updated),
      );
    }).toList();
  }

  ProjectStructure _deleteSectionFromStructure(
    ProjectStructure structure,
    String sectionId,
  ) {
    return structure.copyWith(
      sections: _deleteSectionFromList(structure.sections, sectionId),
    );
  }

  List<ProjectSection> _deleteSectionFromList(
    List<ProjectSection> sections,
    String sectionId,
  ) {
    return sections
        .where((s) => s.id != sectionId)
        .map((s) => s.copyWith(
          children: _deleteSectionFromList(s.children, sectionId),
        ))
        .toList();
  }

  ProjectStructure _reorderSectionsInStructure(
    ProjectStructure structure,
    List<String> sectionIds,
    String? parentId,
  ) {
    if (parentId == null) {
      // Reorder top-level sections
      final reordered = <ProjectSection>[];
      for (final id in sectionIds) {
        final section = structure.sections.firstWhere(
          (s) => s.id == id,
          orElse: () => throw Exception('Section not found: $id'),
        );
        reordered.add(section.copyWith(order: reordered.length));
      }
      return structure.copyWith(sections: reordered);
    }
    
    return structure.copyWith(
      sections: _reorderSectionsInList(structure.sections, sectionIds, parentId),
    );
  }

  List<ProjectSection> _reorderSectionsInList(
    List<ProjectSection> sections,
    List<String> sectionIds,
    String parentId,
  ) {
    return sections.map((section) {
      if (section.id == parentId) {
        final reordered = <ProjectSection>[];
        for (final id in sectionIds) {
          final child = section.children.firstWhere(
            (s) => s.id == id,
            orElse: () => throw Exception('Section not found: $id'),
          );
          reordered.add(child.copyWith(order: reordered.length));
        }
        return section.copyWith(children: reordered);
      }
      return section.copyWith(
        children: _reorderSectionsInList(section.children, sectionIds, parentId),
      );
    }).toList();
  }

  ProjectStructure _addRecordingToSection(
    ProjectStructure structure,
    String sectionId,
    String recordingId,
  ) {
    return structure.copyWith(
      sections: _addRecordingToSectionList(
        structure.sections,
        sectionId,
        recordingId,
      ),
    );
  }

  List<ProjectSection> _addRecordingToSectionList(
    List<ProjectSection> sections,
    String sectionId,
    String recordingId,
  ) {
    return sections.map((section) {
      if (section.id == sectionId) {
        final itemIds = List<String>.from(section.itemIds);
        if (!itemIds.contains(recordingId)) {
          itemIds.add(recordingId);
        }
        return section.copyWith(itemIds: itemIds);
      }
      return section.copyWith(
        children: _addRecordingToSectionList(
          section.children,
          sectionId,
          recordingId,
        ),
      );
    }).toList();
  }

  ProjectStructure _removeRecordingFromStructure(
    ProjectStructure structure,
    String recordingId,
  ) {
    return structure.copyWith(
      sections: _removeRecordingFromList(structure.sections, recordingId),
    );
  }

  List<ProjectSection> _removeRecordingFromList(
    List<ProjectSection> sections,
    String recordingId,
  ) {
    return sections.map((section) {
      final itemIds = List<String>.from(section.itemIds)..remove(recordingId);
      return section.copyWith(
        itemIds: itemIds,
        children: _removeRecordingFromList(section.children, recordingId),
      );
    }).toList();
  }
}

// ============================================================================
// STATISTICS AND ANALYTICS
// ============================================================================

class ProjectStatistics {
  final int totalProjects;
  final int totalWords;
  final int totalSections;
  final int completedSections;
  final Duration totalTimeWorked;
  final int currentStreak;
  final int longestStreak;
  final Map<EliteProjectType, int> projectsByType;

  ProjectStatistics({
    required this.totalProjects,
    required this.totalWords,
    required this.totalSections,
    required this.completedSections,
    required this.totalTimeWorked,
    required this.currentStreak,
    required this.longestStreak,
    required this.projectsByType,
  });

  double get completionRate {
    if (totalSections == 0) return 0;
    return completedSections / totalSections;
  }

  static ProjectStatistics fromProjects(List<EliteProject> projects) {
    int totalWords = 0;
    int totalSections = 0;
    int completedSections = 0;
    int totalMinutes = 0;
    int maxStreak = 0;
    final projectsByType = <EliteProjectType, int>{};

    for (final project in projects) {
      totalWords += project.progress.totalWordCount;
      totalSections += project.progress.totalSections;
      completedSections += project.progress.sectionsComplete;
      
      for (final daily in project.progress.dailyHistory) {
        totalMinutes += daily.minutesWorked;
      }
      
      if (project.progress.longestStreak > maxStreak) {
        maxStreak = project.progress.longestStreak;
      }
      
      projectsByType[project.type] = (projectsByType[project.type] ?? 0) + 1;
    }

    // Calculate current streak across all projects
    int currentStreak = 0;
    if (projects.isNotEmpty) {
      currentStreak = projects
          .map((p) => p.progress.currentStreak)
          .reduce((a, b) => a > b ? a : b);
    }

    return ProjectStatistics(
      totalProjects: projects.length,
      totalWords: totalWords,
      totalSections: totalSections,
      completedSections: completedSections,
      totalTimeWorked: Duration(minutes: totalMinutes),
      currentStreak: currentStreak,
      longestStreak: maxStreak,
      projectsByType: projectsByType,
    );
  }
}
