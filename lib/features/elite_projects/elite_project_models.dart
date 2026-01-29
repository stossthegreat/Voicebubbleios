// =============================================================================
// ELITE PROJECT MODELS - THE FOUNDATION
// =============================================================================
// The data structures that power the world's best voice-powered creation studio
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// PROJECT TYPE ENUM - 9 ELITE PROJECT TYPES
// =============================================================================

enum EliteProjectType {
  novel,        // 📖 Novels, Books, Fiction
  course,       // 🎓 Online Courses, Tutorials
  podcast,      // 🎙️ Podcast Series
  youtube,      // 📺 YouTube Channel
  blog,         // 📰 Blog/Newsletter
  research,     // 📚 Research/Thesis/Academic
  business,     // 💼 Business Plan
  memoir,       // 📝 Memoir/Life Story
  freeform,     // 📋 Free Form (current behavior)
}

extension EliteProjectTypeExtension on EliteProjectType {
  ProjectTypeMetadata get metadata => ProjectTypeMetadata.all[this]!;
  
  String get name => metadata.name;
  String get emoji => metadata.emoji;
  String get tagline => metadata.tagline;
  String get description => metadata.description;
  Color get primaryColor => metadata.primaryColor;
  Color get accentColor => metadata.accentColor;
  IconData get icon => metadata.icon;
  List<String> get benefits => metadata.benefits;
  List<String> get exportFormats => metadata.exportFormats;
  String get progressMetric => metadata.progressMetric;
  int? get suggestedGoal => metadata.suggestedGoal;
  Duration? get suggestedTimeframe => metadata.suggestedTimeframe;
  bool get isPremium => metadata.isPremium;
}

// =============================================================================
// PROJECT TYPE METADATA - EVERYTHING ABOUT EACH TYPE
// =============================================================================

class ProjectTypeMetadata {
  final EliteProjectType type;
  final String name;
  final String emoji;
  final String tagline;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;
  final List<String> benefits;
  final List<String> exportFormats;
  final String progressMetric; // "words", "lessons", "episodes", etc.
  final int? suggestedGoal;
  final Duration? suggestedTimeframe;
  final bool isPremium;

  const ProjectTypeMetadata({
    required this.type,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
    required this.benefits,
    required this.exportFormats,
    required this.progressMetric,
    this.suggestedGoal,
    this.suggestedTimeframe,
    this.isPremium = false,
  });

  static const Map<EliteProjectType, ProjectTypeMetadata> all = {
    // =========================================================================
    // 📖 NOVEL / BOOK
    // =========================================================================
    EliteProjectType.novel: ProjectTypeMetadata(
      type: EliteProjectType.novel,
      name: 'Novel / Book',
      emoji: '📖',
      tagline: 'Write your masterpiece',
      description: 'Build your novel chapter by chapter with AI that remembers your characters, plot, and world.',
      primaryColor: Color(0xFF6B4E71),  // Deep purple
      accentColor: Color(0xFFE8D5E8),
      icon: Icons.auto_stories,
      benefits: [
        'AI remembers all characters & relationships',
        'Plot consistency tracking',
        'Chapter-by-chapter organization',
        'Word count goals & progress',
        'Export to EPUB, PDF, Kindle',
      ],
      exportFormats: ['EPUB', 'PDF', 'DOCX', 'Kindle (KPF)', 'Markdown'],
      progressMetric: 'words',
      suggestedGoal: 80000,
      suggestedTimeframe: Duration(days: 90),
      isPremium: true,
    ),

    // =========================================================================
    // 🎓 ONLINE COURSE
    // =========================================================================
    EliteProjectType.course: ProjectTypeMetadata(
      type: EliteProjectType.course,
      name: 'Online Course',
      emoji: '🎓',
      tagline: 'Teach the world',
      description: 'Create structured courses with modules, lessons, and learning objectives.',
      primaryColor: Color(0xFF2E7D32),  // Forest green
      accentColor: Color(0xFFE8F5E9),
      icon: Icons.school,
      benefits: [
        'Module → Lesson hierarchy',
        'Learning objectives per lesson',
        'Quiz & exercise suggestions',
        'Progress tracking by module',
        'Export to Teachable, Thinkific',
      ],
      exportFormats: ['Teachable', 'Thinkific', 'PDF Workbook', 'Markdown', 'SCORM'],
      progressMetric: 'lessons',
      suggestedGoal: 30,
      suggestedTimeframe: Duration(days: 60),
      isPremium: true,
    ),

    // =========================================================================
    // 🎙️ PODCAST SERIES
    // =========================================================================
    EliteProjectType.podcast: ProjectTypeMetadata(
      type: EliteProjectType.podcast,
      name: 'Podcast Series',
      emoji: '🎙️',
      tagline: 'Your voice, amplified',
      description: 'Plan episodes, track guests, generate show notes automatically.',
      primaryColor: Color(0xFFE65100),  // Deep orange
      accentColor: Color(0xFFFFF3E0),
      icon: Icons.podcasts,
      benefits: [
        'Episode planning & scheduling',
        'Guest management',
        'Auto-generated show notes',
        'Recurring segment templates',
        'Export transcripts & notes',
      ],
      exportFormats: ['Show Notes (MD)', 'Transcript', 'RSS Feed', 'PDF'],
      progressMetric: 'episodes',
      suggestedGoal: 52,
      suggestedTimeframe: Duration(days: 365),
      isPremium: true,
    ),

    // =========================================================================
    // 📺 YOUTUBE CHANNEL
    // =========================================================================
    EliteProjectType.youtube: ProjectTypeMetadata(
      type: EliteProjectType.youtube,
      name: 'YouTube Channel',
      emoji: '📺',
      tagline: 'Script your success',
      description: 'Plan videos, write scripts, generate descriptions and hooks.',
      primaryColor: Color(0xFFFF0000),  // YouTube red
      accentColor: Color(0xFFFFEBEE),
      icon: Icons.play_circle_fill,
      benefits: [
        'Video script templates',
        'Hook & CTA generation',
        'SEO-optimized descriptions',
        'Series organization',
        'Thumbnail idea generation',
      ],
      exportFormats: ['Script (DOCX)', 'Description (TXT)', 'Markdown', 'PDF'],
      progressMetric: 'videos',
      suggestedGoal: 100,
      suggestedTimeframe: Duration(days: 365),
      isPremium: true,
    ),

    // =========================================================================
    // 📰 BLOG / NEWSLETTER
    // =========================================================================
    EliteProjectType.blog: ProjectTypeMetadata(
      type: EliteProjectType.blog,
      name: 'Blog / Newsletter',
      emoji: '📰',
      tagline: 'Build your audience',
      description: 'Write articles, maintain your voice, plan your editorial calendar.',
      primaryColor: Color(0xFF1565C0),  // Blue
      accentColor: Color(0xFFE3F2FD),
      icon: Icons.article,
      benefits: [
        'Editorial calendar',
        'Voice consistency tracking',
        'SEO optimization',
        'Article series organization',
        'Export to Substack, Medium',
      ],
      exportFormats: ['Markdown', 'HTML', 'Substack', 'Medium', 'WordPress'],
      progressMetric: 'articles',
      suggestedGoal: 52,
      suggestedTimeframe: Duration(days: 365),
      isPremium: false,
    ),

    // =========================================================================
    // 📚 RESEARCH / THESIS
    // =========================================================================
    EliteProjectType.research: ProjectTypeMetadata(
      type: EliteProjectType.research,
      name: 'Research / Thesis',
      emoji: '📚',
      tagline: 'Academic excellence',
      description: 'Structure your research with proper academic formatting and citations.',
      primaryColor: Color(0xFF5D4037),  // Brown
      accentColor: Color(0xFFEFEBE9),
      icon: Icons.science,
      benefits: [
        'Academic structure templates',
        'Citation management',
        'Literature review organization',
        'Section-by-section progress',
        'Export to LaTeX, Academic PDF',
      ],
      exportFormats: ['Academic PDF', 'LaTeX', 'DOCX', 'Markdown'],
      progressMetric: 'sections',
      suggestedGoal: 8,
      suggestedTimeframe: Duration(days: 180),
      isPremium: true,
    ),

    // =========================================================================
    // 💼 BUSINESS PLAN
    // =========================================================================
    EliteProjectType.business: ProjectTypeMetadata(
      type: EliteProjectType.business,
      name: 'Business Plan',
      emoji: '💼',
      tagline: 'Plan for success',
      description: 'Create investor-ready business plans with all required sections.',
      primaryColor: Color(0xFF37474F),  // Blue grey
      accentColor: Color(0xFFECEFF1),
      icon: Icons.business_center,
      benefits: [
        'Standard business plan structure',
        'Financial projection guidance',
        'Market analysis templates',
        'Executive summary generation',
        'Investor-ready PDF export',
      ],
      exportFormats: ['Investor PDF', 'DOCX', 'Pitch Deck', 'One-Pager'],
      progressMetric: 'sections',
      suggestedGoal: 10,
      suggestedTimeframe: Duration(days: 30),
      isPremium: true,
    ),

    // =========================================================================
    // 📝 MEMOIR / LIFE STORY
    // =========================================================================
    EliteProjectType.memoir: ProjectTypeMetadata(
      type: EliteProjectType.memoir,
      name: 'Memoir / Life Story',
      emoji: '📝',
      tagline: 'Preserve your legacy',
      description: 'Capture your life stories organized by era, theme, or timeline.',
      primaryColor: Color(0xFF8D6E63),  // Warm brown
      accentColor: Color(0xFFF5F0EC),
      icon: Icons.history_edu,
      benefits: [
        'Timeline organization',
        'Era & theme grouping',
        'Memory prompts',
        'Family tree integration',
        'Beautiful book export',
      ],
      exportFormats: ['EPUB', 'PDF Book', 'Family Archive', 'DOCX'],
      progressMetric: 'stories',
      suggestedGoal: 50,
      suggestedTimeframe: Duration(days: 180),
      isPremium: true,
    ),

    // =========================================================================
    // 📋 FREE FORM
    // =========================================================================
    EliteProjectType.freeform: ProjectTypeMetadata(
      type: EliteProjectType.freeform,
      name: 'Free Form',
      emoji: '📋',
      tagline: 'Your way',
      description: 'Organize recordings your way with complete flexibility.',
      primaryColor: Color(0xFF607D8B),  // Grey
      accentColor: Color(0xFFECEFF1),
      icon: Icons.folder_open,
      benefits: [
        'Complete flexibility',
        'Custom organization',
        'No structure required',
        'Quick start',
        'Basic exports',
      ],
      exportFormats: ['PDF', 'DOCX', 'Markdown', 'TXT'],
      progressMetric: 'items',
      suggestedGoal: null,
      suggestedTimeframe: null,
      isPremium: false,
    ),
  };

  static ProjectTypeMetadata get(EliteProjectType type) => all[type]!;
}

// =============================================================================
// PROJECT SECTION - A CHAPTER, LESSON, EPISODE, ETC.
// =============================================================================

class ProjectSection {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? content;  // Content field for adapters
  final int order;
  final SectionStatus status;
  final List<String> recordingIds;  // Links to recordings
  final int wordCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;  // Type-specific data
  final List<ProjectSection>? subsections;  // For nested structures
  final List<ProjectSection> children;  // Children field for adapters

  const ProjectSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.content,
    required this.order,
    this.status = SectionStatus.notStarted,
    this.recordingIds = const [],
    this.wordCount = 0,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.subsections,
    this.children = const [],
  });

  ProjectSection copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? content,
    int? order,
    SectionStatus? status,
    List<String>? recordingIds,
    int? wordCount,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<ProjectSection>? subsections,
    List<ProjectSection>? children,
  }) {
    return ProjectSection(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      content: content ?? this.content,
      order: order ?? this.order,
      status: status ?? this.status,
      recordingIds: recordingIds ?? this.recordingIds,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
      subsections: subsections ?? this.subsections,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'order': order,
    'status': status.name,
    'recordingIds': recordingIds,
    'wordCount': wordCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'metadata': metadata,
    'subsections': subsections?.map((s) => s.toJson()).toList(),
  };

  factory ProjectSection.fromJson(Map<String, dynamic> json) => ProjectSection(
    id: json['id'],
    title: json['title'],
    subtitle: json['subtitle'],
    description: json['description'],
    order: json['order'],
    status: SectionStatus.values.firstWhere((s) => s.name == json['status']),
    recordingIds: List<String>.from(json['recordingIds'] ?? []),
    wordCount: json['wordCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    metadata: json['metadata'],
    subsections: json['subsections'] != null 
        ? (json['subsections'] as List).map((s) => ProjectSection.fromJson(s)).toList()
        : null,
  );
}

enum SectionStatus {
  notStarted,
  inProgress,
  drafted,
  reviewing,
  completed,
}

extension SectionStatusExtension on SectionStatus {
  Color get color {
    switch (this) {
      case SectionStatus.notStarted:
        return Colors.grey;
      case SectionStatus.inProgress:
        return Colors.blue;
      case SectionStatus.drafted:
        return Colors.orange;
      case SectionStatus.reviewing:
        return Colors.purple;
      case SectionStatus.completed:
        return Colors.green;
    }
  }
}

enum PlotPointType {
  event,
  revelation,
  conflict,
  resolution,
  foreshadowing,
  callback,
  twist,
}

// =============================================================================
// PROJECT GOAL - TARGETS AND DEADLINES
// =============================================================================

class ProjectGoal {
  final String id;
  final String name;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;

  const ProjectGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progressPercent => 
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue => 
      deadline != null && DateTime.now().isAfter(deadline!) && !isCompleted;

  int get daysRemaining => 
      deadline != null ? deadline!.difference(DateTime.now()).inDays : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'deadline': deadline?.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProjectGoal.fromJson(Map<String, dynamic> json) => ProjectGoal(
    id: json['id'],
    name: json['name'],
    type: GoalType.values.firstWhere((t) => t.name == json['type']),
    targetValue: json['targetValue'],
    currentValue: json['currentValue'] ?? 0,
    deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
    isCompleted: json['isCompleted'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum GoalType {
  words,
  sections,
  episodes,
  lessons,
  articles,
  videos,
  stories,
  custom,
}

// =============================================================================
// PROJECT MEMORY - AI CONTEXT & KNOWLEDGE
// =============================================================================

class ProjectMemory {
  final Map<String, CharacterMemory> characters;
  final Map<String, LocationMemory> locations;
  final Map<String, ConceptMemory> concepts;
  final List<PlotPoint> plotPoints;
  final Map<String, String> customFacts;  // Key-value pairs
  final String? voiceStyle;  // Writing style/tone
  final String? targetAudience;
  final DateTime lastUpdated;

  const ProjectMemory({
    this.characters = const {},
    this.locations = const {},
    this.concepts = const {},
    this.plotPoints = const [],
    this.customFacts = const {},
    this.voiceStyle,
    this.targetAudience,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'characters': characters.map((k, v) => MapEntry(k, v.toJson())),
    'locations': locations.map((k, v) => MapEntry(k, v.toJson())),
    'concepts': concepts.map((k, v) => MapEntry(k, v.toJson())),
    'plotPoints': plotPoints.map((p) => p.toJson()).toList(),
    'customFacts': customFacts,
    'voiceStyle': voiceStyle,
    'targetAudience': targetAudience,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ProjectMemory.fromJson(Map<String, dynamic> json) => ProjectMemory(
    characters: (json['characters'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, CharacterMemory.fromJson(v))) ?? {},
    locations: (json['locations'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, LocationMemory.fromJson(v))) ?? {},
    concepts: (json['concepts'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, ConceptMemory.fromJson(v))) ?? {},
    plotPoints: (json['plotPoints'] as List<dynamic>?)
        ?.map((p) => PlotPoint.fromJson(p)).toList() ?? [],
    customFacts: Map<String, String>.from(json['customFacts'] ?? {}),
    voiceStyle: json['voiceStyle'],
    targetAudience: json['targetAudience'],
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );

  /// Generate context string for AI
  String toContextString() {
    final buffer = StringBuffer();
    
    if (characters.isNotEmpty) {
      buffer.writeln('=== CHARACTERS ===');
      for (final char in characters.values) {
        buffer.writeln('${char.name}: ${char.description}');
        if (char.traits.isNotEmpty) {
          buffer.writeln('  Traits: ${char.traits.join(", ")}');
        }
      }
      buffer.writeln();
    }
    
    if (locations.isNotEmpty) {
      buffer.writeln('=== LOCATIONS ===');
      for (final loc in locations.values) {
        buffer.writeln('${loc.name}: ${loc.description}');
      }
      buffer.writeln();
    }
    
    if (plotPoints.isNotEmpty) {
      buffer.writeln('=== KEY PLOT POINTS ===');
      for (final point in plotPoints) {
        buffer.writeln('- ${point.description}');
      }
      buffer.writeln();
    }
    
    if (voiceStyle != null) {
      buffer.writeln('=== WRITING STYLE ===');
      buffer.writeln(voiceStyle);
      buffer.writeln();
    }
    
    if (customFacts.isNotEmpty) {
      buffer.writeln('=== KEY FACTS ===');
      for (final entry in customFacts.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }
    
    return buffer.toString();
  }
}

class CharacterMemory {
  final String id;
  final String name;
  final String description;
  final List<String> traits;
  final Map<String, String> relationships;  // characterId -> relationship
  final String? backstory;
  final Map<String, dynamic>? customFields;
  final String? voiceStyle;  // Voice style for adapters
  final String? appearance;  // Appearance for adapters

  const CharacterMemory({
    required this.id,
    required this.name,
    this.description = '',
    this.traits = const [],
    this.relationships = const {},
    this.backstory,
    this.customFields,
    this.voiceStyle,
    this.appearance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'traits': traits,
    'relationships': relationships,
    'backstory': backstory,
    'customFields': customFields,
    'voiceStyle': voiceStyle,
    'appearance': appearance,
  };

  factory CharacterMemory.fromJson(Map<String, dynamic> json) => CharacterMemory(
    id: json['id'],
    name: json['name'],
    description: json['description'] ?? '',
    traits: List<String>.from(json['traits'] ?? []),
    relationships: Map<String, String>.from(json['relationships'] ?? {}),
    backstory: json['backstory'],
    customFields: json['customFields'],
    voiceStyle: json['voiceStyle'],
    appearance: json['appearance'],
  );
}

class LocationMemory {
  final String id;
  final String name;
  final String description;
  final List<String> features;
  final String? mood;
  final String? atmosphere;  // Atmosphere for adapters

  const LocationMemory({
    required this.id,
    required this.name,
    this.description = '',
    this.features = const [],
    this.mood,
    this.atmosphere,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'features': features,
    'mood': mood,
    'atmosphere': atmosphere,
  };

  factory LocationMemory.fromJson(Map<String, dynamic> json) => LocationMemory(
    id: json['id'],
    name: json['name'],
    description: json['description'] ?? '',
    features: List<String>.from(json['features'] ?? []),
    mood: json['mood'],
    atmosphere: json['atmosphere'],
  );
}

class ConceptMemory {
  final String id;
  final String name;
  final String definition;
  final List<String> relatedTerms;

  const ConceptMemory({
    required this.id,
    required this.name,
    required this.definition,
    this.relatedTerms = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'definition': definition,
    'relatedTerms': relatedTerms,
  };

  factory ConceptMemory.fromJson(Map<String, dynamic> json) => ConceptMemory(
    id: json['id'],
    name: json['name'],
    definition: json['definition'],
    relatedTerms: List<String>.from(json['relatedTerms'] ?? []),
  );
}

class PlotPoint {
  final String id;
  final String description;
  final String? sectionId;
  final int order;
  final bool isResolved;
  final PlotPointType type;  // Type for adapters

  const PlotPoint({
    required this.id,
    required this.description,
    this.sectionId,
    this.order = 0,
    this.isResolved = false,
    this.type = PlotPointType.event,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'sectionId': sectionId,
    'type': type.name,
    'order': order,
    'isResolved': isResolved,
    'type': type.name,
  };

  factory PlotPoint.fromJson(Map<String, dynamic> json) => PlotPoint(
    id: json['id'],
    description: json['description'],
    sectionId: json['sectionId'],
<<<<<<< HEAD
    order: json['order'] ?? 0,
=======
    type: PlotPointType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => PlotPointType.event,
    ),
    order: json['order'],
>>>>>>> 27aa54cf (🔧 Fix Elite Projects build errors - Add missing getters and enum cases)
    isResolved: json['isResolved'] ?? false,
    type: json['type'] != null
        ? PlotPointType.values.firstWhere((t) => t.name == json['type'], orElse: () => PlotPointType.event)
        : PlotPointType.event,
  );
}

// =============================================================================
// ELITE PROJECT - THE MAIN PROJECT MODEL
// =============================================================================

class EliteProject {
  final String id;
  final String name;
  final String? description;
  final String? subtitle;  // Subtitle for adapters
  final EliteProjectType type;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;

  // Structure
  final List<ProjectSection> sections;
  final String? currentSectionId;  // What user is working on
  final ProjectStructure structure;  // Structure for adapters

  // Goals & Progress
  final List<ProjectGoal> goals;
  final int totalWordCount;
  final ProjectProgress progress;  // Progress for adapters
  final ProjectGoals? projectGoals;  // Goals container for adapters

  // AI Memory
  final ProjectMemory? memory;
  final ProjectAIMemory aiMemory;  // AI Memory for adapters

  // Type-specific settings
  final Map<String, dynamic>? settings;
  final String? templateId;  // Template ID for adapters

  // Metadata
  final String? coverImagePath;
  final List<String> tags;
  final bool isArchived;
  final bool isPinned;

  EliteProject({
    required this.id,
    required this.name,
    this.description,
    this.subtitle,
    required this.type,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpenedAt,
    this.sections = const [],
    this.currentSectionId,
    ProjectStructure? structure,
    this.goals = const [],
    this.totalWordCount = 0,
    ProjectProgress? progress,
    this.projectGoals,
    this.memory,
    ProjectAIMemory? aiMemory,
    this.settings,
    this.templateId,
    this.coverImagePath,
    this.tags = const [],
    this.isArchived = false,
    this.isPinned = false,
  }) : structure = structure ?? const ProjectStructure(),
       progress = progress ?? const ProjectProgress(),
       aiMemory = aiMemory ?? const ProjectAIMemory();

  ProjectTypeMetadata get metadata => ProjectTypeMetadata.get(type);

  double get progressPercent {
    if (sections.isEmpty) return 0.0;
    final completed = sections.where((s) => s.status == SectionStatus.completed).length;
    return completed / sections.length;
  }

  int get completedSectionsCount => 
      sections.where((s) => s.status == SectionStatus.completed).length;

  ProjectSection? get currentSection => 
      currentSectionId != null 
          ? sections.firstWhere((s) => s.id == currentSectionId, orElse: () => sections.first)
          : sections.isNotEmpty ? sections.first : null;

  EliteProject copyWith({
    String? name,
    String? description,
    String? subtitle,
    EliteProjectType? type,
    int? colorIndex,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    List<ProjectSection>? sections,
    String? currentSectionId,
    ProjectStructure? structure,
    List<ProjectGoal>? goals,
    int? totalWordCount,
    ProjectProgress? progress,
    ProjectGoals? projectGoals,
    ProjectMemory? memory,
    ProjectAIMemory? aiMemory,
    Map<String, dynamic>? settings,
    String? templateId,
    String? coverImagePath,
    List<String>? tags,
    bool? isArchived,
    bool? isPinned,
  }) {
    return EliteProject(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      sections: sections ?? this.sections,
      currentSectionId: currentSectionId ?? this.currentSectionId,
      structure: structure ?? this.structure,
      goals: goals ?? this.goals,
      totalWordCount: totalWordCount ?? this.totalWordCount,
      progress: progress ?? this.progress,
      projectGoals: projectGoals ?? this.projectGoals,
      memory: memory ?? this.memory,
      aiMemory: aiMemory ?? this.aiMemory,
      settings: settings ?? this.settings,
      templateId: templateId ?? this.templateId,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'colorIndex': colorIndex,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    'sections': sections.map((s) => s.toJson()).toList(),
    'currentSectionId': currentSectionId,
    'goals': goals.map((g) => g.toJson()).toList(),
    'totalWordCount': totalWordCount,
    'memory': memory?.toJson(),
    'settings': settings,
    'coverImagePath': coverImagePath,
    'tags': tags,
    'isArchived': isArchived,
    'isPinned': isPinned,
  };

  factory EliteProject.fromJson(Map<String, dynamic> json) => EliteProject(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    type: EliteProjectType.values.firstWhere((t) => t.name == json['type']),
    colorIndex: json['colorIndex'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    lastOpenedAt: json['lastOpenedAt'] != null ? DateTime.parse(json['lastOpenedAt']) : null,
    sections: (json['sections'] as List<dynamic>?)
        ?.map((s) => ProjectSection.fromJson(s)).toList() ?? [],
    currentSectionId: json['currentSectionId'],
    goals: (json['goals'] as List<dynamic>?)
        ?.map((g) => ProjectGoal.fromJson(g)).toList() ?? [],
    totalWordCount: json['totalWordCount'] ?? 0,
    memory: json['memory'] != null ? ProjectMemory.fromJson(json['memory']) : null,
    settings: json['settings'],
    coverImagePath: json['coverImagePath'],
    tags: List<String>.from(json['tags'] ?? []),
    isArchived: json['isArchived'] ?? false,
    isPinned: json['isPinned'] ?? false,
  );
}

// =============================================================================
// ADAPTER-COMPATIBLE CLASSES
// These classes are required by the Hive adapters in elite_project_adapters.dart
// =============================================================================

/// Wrapper class for project sections (used by adapters)
class ProjectStructure {
  final List<ProjectSection> sections;

  const ProjectStructure({
    this.sections = const [],
  });

  ProjectStructure copyWith({List<ProjectSection>? sections}) {
    return ProjectStructure(sections: sections ?? this.sections);
  }
}

/// Progress tracking for projects (used by adapters)
class ProjectProgress {
  final int totalWordCount;
  final int totalSections;
  final int sectionsComplete;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkedDate;
  final List<DailyProgress> dailyHistory;

  const ProjectProgress({
    this.totalWordCount = 0,
    this.totalSections = 0,
    this.sectionsComplete = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWorkedDate,
    this.dailyHistory = const [],
  });

  ProjectProgress copyWith({
    int? totalWordCount,
    int? totalSections,
    int? sectionsComplete,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkedDate,
    List<DailyProgress>? dailyHistory,
  }) {
    return ProjectProgress(
      totalWordCount: totalWordCount ?? this.totalWordCount,
      totalSections: totalSections ?? this.totalSections,
      sectionsComplete: sectionsComplete ?? this.sectionsComplete,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkedDate: lastWorkedDate ?? this.lastWorkedDate,
      dailyHistory: dailyHistory ?? this.dailyHistory,
    );
  }
}

/// Daily progress entry (used by adapters)
class DailyProgress {
  final DateTime date;
  final int wordsWritten;
  final int minutesWorked;

  const DailyProgress({
    required this.date,
    required this.wordsWritten,
    required this.minutesWorked,
  });
}

/// Project goals container (used by adapters)
class ProjectGoals {
  final int? targetWordCount;
  final DateTime? deadline;
  final int? dailyWordGoal;

  const ProjectGoals({
    this.targetWordCount,
    this.deadline,
    this.dailyWordGoal,
  });

  ProjectGoals copyWith({
    int? targetWordCount,
    DateTime? deadline,
    int? dailyWordGoal,
  }) {
    return ProjectGoals(
      targetWordCount: targetWordCount ?? this.targetWordCount,
      deadline: deadline ?? this.deadline,
      dailyWordGoal: dailyWordGoal ?? this.dailyWordGoal,
    );
  }
}

/// AI memory for projects (used by adapters)
class ProjectAIMemory {
  final List<CharacterMemory> characters;
  final List<LocationMemory> locations;
  final List<TopicMemory> topics;
  final List<FactMemory> facts;
  final List<PlotPoint> plotPoints;
  final StyleMemory style;

  const ProjectAIMemory({
    this.characters = const [],
    this.locations = const [],
    this.topics = const [],
    this.facts = const [],
    this.plotPoints = const [],
    this.style = const StyleMemory(),
  });

  ProjectAIMemory copyWith({
    List<CharacterMemory>? characters,
    List<LocationMemory>? locations,
    List<TopicMemory>? topics,
    List<FactMemory>? facts,
    List<PlotPoint>? plotPoints,
    StyleMemory? style,
  }) {
    return ProjectAIMemory(
      characters: characters ?? this.characters,
      locations: locations ?? this.locations,
      topics: topics ?? this.topics,
      facts: facts ?? this.facts,
      plotPoints: plotPoints ?? this.plotPoints,
      style: style ?? this.style,
    );
  }
}

/// Topic memory (used by adapters)
class TopicMemory {
  final String id;
  final String name;
  final String description;
  final List<String> keyPoints;

  const TopicMemory({
    required this.id,
    required this.name,
    this.description = '',
    this.keyPoints = const [],
  });
}

/// Fact memory (used by adapters)
class FactMemory {
  final String id;
  final String fact;
  final String? category;
  final bool isImportant;

  const FactMemory({
    required this.id,
    required this.fact,
    this.category,
    this.isImportant = false,
  });
}

/// Plot point type enum (used by adapters)
enum PlotPointType {
  event,
  twist,
  revelation,
  conflict,
  resolution,
  foreshadowing,
  climax,
  other,
}

/// Style memory for writing preferences (used by adapters)
class StyleMemory {
  final String? tone;
  final String? pointOfView;
  final String? tense;
  final List<String> avoidWords;
  final List<String> preferWords;
  final String? customInstructions;

  const StyleMemory({
    this.tone,
    this.pointOfView,
    this.tense,
    this.avoidWords = const [],
    this.preferWords = const [],
    this.customInstructions,
  });

  StyleMemory copyWith({
    String? tone,
    String? pointOfView,
    String? tense,
    List<String>? avoidWords,
    List<String>? preferWords,
    String? customInstructions,
  }) {
    return StyleMemory(
      tone: tone ?? this.tone,
      pointOfView: pointOfView ?? this.pointOfView,
      tense: tense ?? this.tense,
      avoidWords: avoidWords ?? this.avoidWords,
      preferWords: preferWords ?? this.preferWords,
      customInstructions: customInstructions ?? this.customInstructions,
    );
  }
}
