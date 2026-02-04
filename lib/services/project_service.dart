import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/recording_item.dart';

class ProjectService {
  static const String _projectsBoxName = 'projects';
  static const String _recordingItemsBoxName = 'recording_items';

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    return box.values.toList();
  }

  /// Create a new project
  Future<Project> createProject(
    String name, {
    String? description,
    int? colorIndex,
  }) async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    
    final now = DateTime.now();
    final project = Project(
      id: '${now.millisecondsSinceEpoch}_${name.hashCode}',
      name: name,
      itemIds: [],
      createdAt: now,
      updatedAt: now,
      description: description,
      colorIndex: colorIndex,
    );

    await box.put(project.id, project);
    return project;
  }

  /// Add item to project
  Future<void> addItemToProject(String projectId, String itemId) async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    final project = box.get(projectId);
    
    if (project == null) {
      throw Exception('Project not found: $projectId');
    }

    // Don't add duplicate
    if (project.itemIds.contains(itemId)) {
      return;
    }

    final updatedProject = project.copyWith(
      itemIds: [...project.itemIds, itemId],
      updatedAt: DateTime.now(),
    );

    await box.put(projectId, updatedProject);

    // Update the recording item's projectId
    final recordingBox = await Hive.openBox<RecordingItem>(_recordingItemsBoxName);
    final keys = recordingBox.keys.toList();
    for (final key in keys) {
      final item = recordingBox.get(key);
      if (item?.id == itemId) {
        final updatedItem = item!.copyWith(projectId: projectId);
        await recordingBox.put(key, updatedItem);
        break;
      }
    }
  }

  /// Remove item from project
  Future<void> removeItemFromProject(String projectId, String itemId) async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    final project = box.get(projectId);
    
    if (project == null) {
      throw Exception('Project not found: $projectId');
    }

    final updatedItemIds = List<String>.from(project.itemIds)..remove(itemId);
    final updatedProject = project.copyWith(
      itemIds: updatedItemIds,
      updatedAt: DateTime.now(),
    );

    await box.put(projectId, updatedProject);

    // Clear the recording item's projectId
    final recordingBox = await Hive.openBox<RecordingItem>(_recordingItemsBoxName);
    final keys = recordingBox.keys.toList();
    for (final key in keys) {
      final item = recordingBox.get(key);
      if (item?.id == itemId) {
        final updatedItem = item!.copyWith(projectId: null);
        await recordingBox.put(key, updatedItem);
        break;
      }
    }
  }

  /// Delete project (and clear projectId from items)
  Future<void> deleteProject(String projectId) async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    final project = box.get(projectId);
    
    if (project == null) {
      return;
    }

    // Clear projectId from all items in this project
    final recordingBox = await Hive.openBox<RecordingItem>(_recordingItemsBoxName);
    final keys = recordingBox.keys.toList();
    for (final key in keys) {
      final item = recordingBox.get(key);
      if (item != null && project.itemIds.contains(item.id)) {
        final updatedItem = item.copyWith(projectId: null);
        await recordingBox.put(key, updatedItem);
      }
    }

    await box.delete(projectId);
  }

  /// Get all items in a project (NO DUPLICATES)
  Future<List<RecordingItem>> getProjectItems(String projectId) async {
    final projectBox = await Hive.openBox<Project>(_projectsBoxName);
    final project = projectBox.get(projectId);

    if (project == null) {
      return [];
    }

    final recordingBox = await Hive.openBox<RecordingItem>(_recordingItemsBoxName);
    final allItems = recordingBox.values.toList();

    // Use Set to prevent duplicates
    final seenIds = <String>{};
    final projectItems = <RecordingItem>[];

    for (final item in allItems) {
      // Item belongs if in itemIds OR has projectId set
      final belongsToProject = project.itemIds.contains(item.id) || item.projectId == projectId;

      if (belongsToProject && !seenIds.contains(item.id)) {
        seenIds.add(item.id);
        projectItems.add(item);
      }
    }

    projectItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return projectItems;
  }

  /// Update project name and description
  Future<void> updateProject({
    required String projectId,
    String? name,
    String? description,
    int? colorIndex,
  }) async {
    final box = await Hive.openBox<Project>(_projectsBoxName);
    final project = box.get(projectId);
    
    if (project == null) {
      throw Exception('Project not found: $projectId');
    }

    final updatedProject = project.copyWith(
      name: name ?? project.name,
      description: description ?? project.description,
      colorIndex: colorIndex ?? project.colorIndex,
      updatedAt: DateTime.now(),
    );

    await box.put(projectId, updatedProject);
  }
}
