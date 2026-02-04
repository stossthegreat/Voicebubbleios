import '../models/recording_item.dart';
import '../providers/app_state_provider.dart';
import '../services/project_service.dart';

enum BatchOperationType {
  delete,
  addTag,
  removeTag,
  moveToProject,
  export,
  archive,
}

class BatchOperationsService {
  // Delete multiple notes
  Future<void> deleteNotes(
    List<RecordingItem> notes,
    AppStateProvider appState,
  ) async {
    for (var note in notes) {
      await appState.deleteRecording(note.id);
    }
  }

  // Add tag to multiple notes
  Future<void> addTagToNotes(
    List<RecordingItem> notes,
    String tagId,
    AppStateProvider appState,
  ) async {
    for (var note in notes) {
      if (!note.tags.contains(tagId)) {
        // FIX: Use the existing working method from AppStateProvider
        await appState.addTagToRecording(note.id, tagId);
      }
    }
  }

  // Remove tag from multiple notes
  Future<void> removeTagFromNotes(
    List<RecordingItem> notes,
    String tagId,
    AppStateProvider appState,
  ) async {
    for (var note in notes) {
      if (note.tags.contains(tagId)) {
        await appState.removeTagFromRecording(note.id, tagId);
      }
    }
  }

  // Move multiple notes to project
  Future<void> moveNotesToProject(
    List<RecordingItem> notes,
    String projectId,
    ProjectService projectService,
  ) async {
    for (var note in notes) {
      // FIX: Use the existing project service method that works
      await projectService.addItemToProject(projectId, note.id);
    }
  }

  // Archive multiple notes
  Future<void> archiveNotes(
    List<RecordingItem> notes,
    AppStateProvider appState,
  ) async {
    for (var note in notes) {
      final updatedNote = note.copyWith(hiddenInLibrary: true);
      await appState.updateRecording(updatedNote);
    }
  }

  // Unarchive multiple notes
  Future<void> unarchiveNotes(
    List<RecordingItem> notes,
    AppStateProvider appState,
  ) async {
    for (var note in notes) {
      final updatedNote = note.copyWith(hiddenInLibrary: false);
      await appState.updateRecording(updatedNote);
    }
  }

  // Get operation description
  String getOperationDescription(BatchOperationType type, int count) {
    final itemText = count == 1 ? 'item' : 'items';
    
    switch (type) {
      case BatchOperationType.delete:
        return 'Delete $count $itemText';
      case BatchOperationType.addTag:
        return 'Add tag to $count $itemText';
      case BatchOperationType.removeTag:
        return 'Remove tag from $count $itemText';
      case BatchOperationType.moveToProject:
        return 'Move $count $itemText to project';
      case BatchOperationType.export:
        return 'Export $count $itemText';
      case BatchOperationType.archive:
        return 'Archive $count $itemText';
    }
  }
}
