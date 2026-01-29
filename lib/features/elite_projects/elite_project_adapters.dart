// ============================================================================
// ELITE PROJECT HIVE ADAPTERS
// ============================================================================
// Required for Hive persistence
// Run: flutter packages pub run build_runner build
// OR use these manual adapters
// ============================================================================

import 'package:hive/hive.dart';
import 'elite_project_models.dart';

// ============================================================================
// TYPE IDS - Don't conflict with your existing adapters!
// ============================================================================
// If you have existing Hive adapters, make sure these IDs don't overlap
// Default assumption: your existing adapters use 0-49, so we start at 50

const int _eliteProjectTypeId = 50;
const int _projectTypeEnumTypeId = 51;
const int _projectStructureTypeId = 52;
const int _projectSectionTypeId = 53;
const int _sectionStatusTypeId = 54;
const int _projectProgressTypeId = 55;
const int _dailyProgressTypeId = 56;
const int _projectGoalsTypeId = 57;
const int _projectAIMemoryTypeId = 58;
const int _characterMemoryTypeId = 59;
const int _locationMemoryTypeId = 60;
const int _topicMemoryTypeId = 61;
const int _factMemoryTypeId = 62;
const int _plotPointTypeId = 63;
const int _plotPointTypeEnumTypeId = 64;
const int _styleMemoryTypeId = 65;

// ============================================================================
// ADAPTERS
// ============================================================================

class EliteProjectAdapter extends TypeAdapter<EliteProject> {
  @override
  final int typeId = _eliteProjectTypeId;

  @override
  EliteProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EliteProject(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as EliteProjectType,
      subtitle: fields[3] as String?,
      structure: fields[4] as ProjectStructure,
      progress: fields[5] as ProjectProgress,
      memory: fields[6] as ProjectAIMemory,
      goals: fields[7] as ProjectGoals?,
      templateId: fields[8] as String?,
      colorIndex: fields[9] as int? ?? 0,
      isArchived: fields[10] as bool? ?? false,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EliteProject obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.subtitle)
      ..writeByte(4)
      ..write(obj.structure)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.memory)
      ..writeByte(7)
      ..write(obj.goals)
      ..writeByte(8)
      ..write(obj.templateId)
      ..writeByte(9)
      ..write(obj.colorIndex)
      ..writeByte(10)
      ..write(obj.isArchived)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }
}

class EliteProjectTypeAdapter extends TypeAdapter<EliteProjectType> {
  @override
  final int typeId = _projectTypeEnumTypeId;

  @override
  EliteProjectType read(BinaryReader reader) {
    return EliteProjectType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, EliteProjectType obj) {
    writer.writeByte(obj.index);
  }
}

class ProjectStructureAdapter extends TypeAdapter<ProjectStructure> {
  @override
  final int typeId = _projectStructureTypeId;

  @override
  ProjectStructure read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectStructure(
      sections: (fields[0] as List).cast<ProjectSection>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectStructure obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.sections);
  }
}

class ProjectSectionAdapter extends TypeAdapter<ProjectSection> {
  @override
  final int typeId = _projectSectionTypeId;

  @override
  ProjectSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectSection(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      content: fields[3] as String?,
      status: fields[4] as SectionStatus,
      children: (fields[5] as List?)?.cast<ProjectSection>() ?? [],
      recordingIds: (fields[6] as List?)?.cast<String>() ?? [],
      order: fields[7] as int? ?? 0,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectSection obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.children)
      ..writeByte(6)
      ..write(obj.recordingIds)
      ..writeByte(7)
      ..write(obj.order)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }
}

class SectionStatusAdapter extends TypeAdapter<SectionStatus> {
  @override
  final int typeId = _sectionStatusTypeId;

  @override
  SectionStatus read(BinaryReader reader) {
    return SectionStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SectionStatus obj) {
    writer.writeByte(obj.index);
  }
}

class ProjectProgressAdapter extends TypeAdapter<ProjectProgress> {
  @override
  final int typeId = _projectProgressTypeId;

  @override
  ProjectProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectProgress(
      totalWordCount: fields[0] as int? ?? 0,
      totalSections: fields[1] as int? ?? 0,
      sectionsComplete: fields[2] as int? ?? 0,
      currentStreak: fields[3] as int? ?? 0,
      longestStreak: fields[4] as int? ?? 0,
      lastWorkedDate: fields[5] as DateTime?,
      dailyHistory: (fields[6] as List?)?.cast<DailyProgress>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, ProjectProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalWordCount)
      ..writeByte(1)
      ..write(obj.totalSections)
      ..writeByte(2)
      ..write(obj.sectionsComplete)
      ..writeByte(3)
      ..write(obj.currentStreak)
      ..writeByte(4)
      ..write(obj.longestStreak)
      ..writeByte(5)
      ..write(obj.lastWorkedDate)
      ..writeByte(6)
      ..write(obj.dailyHistory);
  }
}

class DailyProgressAdapter extends TypeAdapter<DailyProgress> {
  @override
  final int typeId = _dailyProgressTypeId;

  @override
  DailyProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyProgress(
      date: fields[0] as DateTime,
      wordsWritten: fields[1] as int,
      minutesWorked: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.wordsWritten)
      ..writeByte(2)
      ..write(obj.minutesWorked);
  }
}

class ProjectGoalsAdapter extends TypeAdapter<ProjectGoals> {
  @override
  final int typeId = _projectGoalsTypeId;

  @override
  ProjectGoals read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectGoals(
      targetWordCount: fields[0] as int?,
      deadline: fields[1] as DateTime?,
      dailyWordGoal: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectGoals obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.targetWordCount)
      ..writeByte(1)
      ..write(obj.deadline)
      ..writeByte(2)
      ..write(obj.dailyWordGoal);
  }
}

class ProjectAIMemoryAdapter extends TypeAdapter<ProjectAIMemory> {
  @override
  final int typeId = _projectAIMemoryTypeId;

  @override
  ProjectAIMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectAIMemory(
      characters: (fields[0] as List?)?.cast<CharacterMemory>() ?? [],
      locations: (fields[1] as List?)?.cast<LocationMemory>() ?? [],
      topics: (fields[2] as List?)?.cast<TopicMemory>() ?? [],
      facts: (fields[3] as List?)?.cast<FactMemory>() ?? [],
      plotPoints: (fields[4] as List?)?.cast<PlotPoint>() ?? [],
      style: fields[5] as StyleMemory? ?? const StyleMemory(),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectAIMemory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.characters)
      ..writeByte(1)
      ..write(obj.locations)
      ..writeByte(2)
      ..write(obj.topics)
      ..writeByte(3)
      ..write(obj.facts)
      ..writeByte(4)
      ..write(obj.plotPoints)
      ..writeByte(5)
      ..write(obj.style);
  }
}

class CharacterMemoryAdapter extends TypeAdapter<CharacterMemory> {
  @override
  final int typeId = _characterMemoryTypeId;

  @override
  CharacterMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterMemory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String? ?? '',
      traits: (fields[3] as List?)?.cast<String>() ?? [],
      relationships: (fields[4] as Map?)?.cast<String, String>() ?? {},
      voiceStyle: fields[5] as String?,
      appearance: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterMemory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.traits)
      ..writeByte(4)
      ..write(obj.relationships)
      ..writeByte(5)
      ..write(obj.voiceStyle)
      ..writeByte(6)
      ..write(obj.appearance);
  }
}

class LocationMemoryAdapter extends TypeAdapter<LocationMemory> {
  @override
  final int typeId = _locationMemoryTypeId;

  @override
  LocationMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationMemory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String? ?? '',
      atmosphere: fields[3] as String?,
      features: (fields[4] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, LocationMemory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.atmosphere)
      ..writeByte(4)
      ..write(obj.features);
  }
}

class TopicMemoryAdapter extends TypeAdapter<TopicMemory> {
  @override
  final int typeId = _topicMemoryTypeId;

  @override
  TopicMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopicMemory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String? ?? '',
      keyPoints: (fields[3] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, TopicMemory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.keyPoints);
  }
}

class FactMemoryAdapter extends TypeAdapter<FactMemory> {
  @override
  final int typeId = _factMemoryTypeId;

  @override
  FactMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FactMemory(
      id: fields[0] as String,
      fact: fields[1] as String,
      category: fields[2] as String?,
      isImportant: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, FactMemory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fact)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isImportant);
  }
}

class PlotPointAdapter extends TypeAdapter<PlotPoint> {
  @override
  final int typeId = _plotPointTypeId;

  @override
  PlotPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlotPoint(
      id: fields[0] as String,
      description: fields[1] as String,
      sectionId: fields[2] as String?,
      type: fields[3] as PlotPointType? ?? PlotPointType.event,
      isResolved: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PlotPoint obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.sectionId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isResolved);
  }
}

class PlotPointTypeAdapter extends TypeAdapter<PlotPointType> {
  @override
  final int typeId = _plotPointTypeEnumTypeId;

  @override
  PlotPointType read(BinaryReader reader) {
    return PlotPointType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PlotPointType obj) {
    writer.writeByte(obj.index);
  }
}

class StyleMemoryAdapter extends TypeAdapter<StyleMemory> {
  @override
  final int typeId = _styleMemoryTypeId;

  @override
  StyleMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StyleMemory(
      tone: fields[0] as String?,
      pointOfView: fields[1] as String?,
      tense: fields[2] as String?,
      avoidWords: (fields[3] as List?)?.cast<String>() ?? [],
      preferWords: (fields[4] as List?)?.cast<String>() ?? [],
      customInstructions: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StyleMemory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.tone)
      ..writeByte(1)
      ..write(obj.pointOfView)
      ..writeByte(2)
      ..write(obj.tense)
      ..writeByte(3)
      ..write(obj.avoidWords)
      ..writeByte(4)
      ..write(obj.preferWords)
      ..writeByte(5)
      ..write(obj.customInstructions);
  }
}

// ============================================================================
// REGISTRATION HELPER
// ============================================================================

/// Call this once during app initialization
void registerEliteProjectAdapters() {
  if (!Hive.isAdapterRegistered(_eliteProjectTypeId)) {
    Hive.registerAdapter(EliteProjectAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectTypeEnumTypeId)) {
    Hive.registerAdapter(EliteProjectTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectStructureTypeId)) {
    Hive.registerAdapter(ProjectStructureAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectSectionTypeId)) {
    Hive.registerAdapter(ProjectSectionAdapter());
  }
  if (!Hive.isAdapterRegistered(_sectionStatusTypeId)) {
    Hive.registerAdapter(SectionStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectProgressTypeId)) {
    Hive.registerAdapter(ProjectProgressAdapter());
  }
  if (!Hive.isAdapterRegistered(_dailyProgressTypeId)) {
    Hive.registerAdapter(DailyProgressAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectGoalsTypeId)) {
    Hive.registerAdapter(ProjectGoalsAdapter());
  }
  if (!Hive.isAdapterRegistered(_projectAIMemoryTypeId)) {
    Hive.registerAdapter(ProjectAIMemoryAdapter());
  }
  if (!Hive.isAdapterRegistered(_characterMemoryTypeId)) {
    Hive.registerAdapter(CharacterMemoryAdapter());
  }
  if (!Hive.isAdapterRegistered(_locationMemoryTypeId)) {
    Hive.registerAdapter(LocationMemoryAdapter());
  }
  if (!Hive.isAdapterRegistered(_topicMemoryTypeId)) {
    Hive.registerAdapter(TopicMemoryAdapter());
  }
  if (!Hive.isAdapterRegistered(_factMemoryTypeId)) {
    Hive.registerAdapter(FactMemoryAdapter());
  }
  if (!Hive.isAdapterRegistered(_plotPointTypeId)) {
    Hive.registerAdapter(PlotPointAdapter());
  }
  if (!Hive.isAdapterRegistered(_plotPointTypeEnumTypeId)) {
    Hive.registerAdapter(PlotPointTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(_styleMemoryTypeId)) {
    Hive.registerAdapter(StyleMemoryAdapter());
  }
}
