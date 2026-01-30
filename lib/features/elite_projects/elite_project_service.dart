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
    try {
      return _projects.firstWhere((p) => p.id == _activeProjectId);
    } catch (e) {
      return _projects.isNotEmpty ? _projects.first : null;
    }
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
    
    final now = DateTime.now();
    
    final project = EliteProject(
      id: _uuid.v4(),
      name: name,
      subtitle: subtitle,
      type: type,
      createdAt: now,
      updatedAt: now,
      colorIndex: colorIndex,
      structure: template?.generateStructure() ?? ProjectStructure(sections: [
        ProjectSection(
          id: _uuid.v4(),
          title: 'Section 1',
          description: 'Your first section',
        ),
      ]),
      projectGoals: template?.suggestedGoals ?? const ProjectGoals(),
      progress: ProjectProgress(
        totalSections: template?.sections.length ?? 1,
      ),
      memory: ProjectMemory(
        lastUpdated: now,  // FIX: Added required lastUpdated
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
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
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
    
    await updateProject(project.copyWith(projectGoals: goals));
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

  Future<void> updateSectionContent(
    String projectId,
    String sectionId,
    String content,
  ) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final section = _findSection(project.structure.sections, sectionId);
    if (section == null) return;
    
    final wordCount = content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    
    final updatedSection = section.copyWith(
      content: content,
      wordCount: wordCount,
      updatedAt: DateTime.now(),
    );
    
    await updateSection(projectId, updatedSection);
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
    String? parentId,
  }) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final newStructure = _reorderSectionsInStructure(
      project.structure,
      sectionIds,
      parentId,
    );
    
    await updateProject(project.copyWith(structure: newStructure));
  }

  // ============================================================================
  // PROGRESS OPERATIONS
  // ============================================================================

  Future<void> updateProgress(String projectId, {
    int? wordsAdded,
    int? minutesWorked,
    bool? sectionCompleted,
  }) async {
    final project = getProject(projectId);
    if (project == null) return;
    
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final dailyProgress = Map<String, int>.from(project.progress.dailyProgress);
    dailyProgress[dateKey] = (dailyProgress[dateKey] ?? 0) + (wordsAdded ?? 0);
    
    await updateProject(project.copyWith(
      progress: project.progress.copyWith(
        totalWordCount: project.progress.totalWordCount + (wordsAdded ?? 0),
        lastWorkedOn: now,
        dailyProgress: dailyProgress,
        totalTimeMinutes: project.progress.totalTimeMinutes + (minutesWorked ?? 0),
        lastSessionAt: now,
      ),
    ));
  }

  // ============================================================================
  // AI MEMORY OPERATIONS
  // ============================================================================

  Future<void> addCharacter(String projectId, CharacterMemory character) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    final characters = Map<String, CharacterMemory>.from(project.memory!.characters);
    characters[character.id] = character;
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        characters: characters,
        lastUpdated: DateTime.now(),
      ),
    ));
  }

  Future<void> updateCharacter(String projectId, CharacterMemory character) async {
    await addCharacter(projectId, character); // Same operation for maps
  }

  Future<void> deleteCharacter(String projectId, String characterId) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    final characters = Map<String, CharacterMemory>.from(project.memory!.characters);
    characters.remove(characterId);
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        characters: characters,
        lastUpdated: DateTime.now(),
      ),
    ));
  }

  Future<void> addLocation(String projectId, LocationMemory location) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    final locations = Map<String, LocationMemory>.from(project.memory!.locations);
    locations[location.id] = location;
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        locations: locations,
        lastUpdated: DateTime.now(),
      ),
    ));
  }

  Future<void> addFact(String projectId, FactMemory fact) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    final facts = List<FactMemory>.from(project.memory!.facts)..add(fact);
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        facts: facts,
        lastUpdated: DateTime.now(),
      ),
    ));
  }

  Future<void> addPlotPoint(String projectId, PlotPoint plotPoint) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    final plotPoints = List<PlotPoint>.from(project.memory!.plotPoints)
      ..add(plotPoint);
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        plotPoints: plotPoints,
        lastUpdated: DateTime.now(),
      ),
    ));
  }

  Future<void> updateStyle(String projectId, StyleMemory style) async {
    final project = getProject(projectId);
    if (project == null || project.memory == null) return;
    
    await updateProject(project.copyWith(
      memory: project.memory!.copyWith(
        style: style,
        lastUpdated: DateTime.now(),
      ),
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
      if (section.status == SectionStatus.completed || 
          section.status == SectionStatus.complete) {
        count++;
      }
      count += _countCompletedSections(section.children);
    }
    return count;
  }

  ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
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
      final sectionMap = {for (var s in structure.sections) s.id: s};
      final reordered = sectionIds
          .where((id) => sectionMap.containsKey(id))
          .map((id) => sectionMap[id]!)
          .toList();
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
        final childMap = {for (var c in section.children) c.id: c};
        final reordered = sectionIds
            .where((id) => childMap.containsKey(id))
            .map((id) => childMap[id]!)
            .toList();
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
      sections: _addRecordingToSectionList(structure.sections, sectionId, recordingId),
    );
  }

  List<ProjectSection> _addRecordingToSectionList(
    List<ProjectSection> sections,
    String sectionId,
    String recordingId,
  ) {
    return sections.map((section) {
      if (section.id == sectionId) {
        final recordingIds = List<String>.from(section.recordingIds);
        if (!recordingIds.contains(recordingId)) {
          recordingIds.add(recordingId);
        }
        return section.copyWith(recordingIds: recordingIds);
      }
      return section.copyWith(
        children: _addRecordingToSectionList(section.children, sectionId, recordingId),
      );
    }).toList();
  }

  ProjectStructure _removeRecordingFromStructure(
    ProjectStructure structure,
    String recordingId,
  ) {
    return structure.copyWith(
      sections: _removeRecordingFromSectionList(structure.sections, recordingId),
    );
  }

  List<ProjectSection> _removeRecordingFromSectionList(
    List<ProjectSection> sections,
    String recordingId,
  ) {
    return sections.map((section) {
      return section.copyWith(
        recordingIds: section.recordingIds.where((id) => id != recordingId).toList(),
        children: _removeRecordingFromSectionList(section.children, recordingId),
      );
    }).toList();
  }
}
