// ============================================================================
// ELITE PROJECT AI SERVICE
// ============================================================================
// AI context generation for elite projects
// ============================================================================

import 'elite_project_models.dart';

// ============================================================================
// AI PRESET
// ============================================================================

class AIPreset {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String prompt;
  final List<EliteProjectType> supportedTypes;

  const AIPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.prompt,
    this.supportedTypes = const [],
  });
}

// Alias for backward compatibility
typedef EliteProjectPresets = EliteProjectAIContextService;

// ============================================================================
// AI CONTEXT SERVICE
// ============================================================================

class EliteProjectAIContextService {
  
  /// Get AI presets for a project type
  static List<AIPreset> getPresetsForType(EliteProjectType type) {
    final allPresets = <AIPreset>[
      const AIPreset(
        id: 'continue',
        name: 'Continue Writing',
        description: 'Continue from where you left off',
        icon: '✍️',
        prompt: 'Continue writing from where we left off, maintaining the same tone and style.',
        supportedTypes: [],
      ),
      const AIPreset(
        id: 'expand',
        name: 'Expand',
        description: 'Expand on the current content',
        icon: '📝',
        prompt: 'Expand on this content with more detail and depth.',
        supportedTypes: [],
      ),
      const AIPreset(
        id: 'summarize',
        name: 'Summarize',
        description: 'Create a summary',
        icon: '📋',
        prompt: 'Summarize the key points concisely.',
        supportedTypes: [],
      ),
      const AIPreset(
        id: 'rewrite',
        name: 'Rewrite',
        description: 'Rewrite for clarity',
        icon: '🔄',
        prompt: 'Rewrite this content for better clarity and flow.',
        supportedTypes: [],
      ),
      // Novel-specific
      const AIPreset(
        id: 'dialogue',
        name: 'Write Dialogue',
        description: 'Create character dialogue',
        icon: '💬',
        prompt: 'Write engaging dialogue between the characters.',
        supportedTypes: [EliteProjectType.novel, EliteProjectType.memoir],
      ),
      const AIPreset(
        id: 'scene',
        name: 'Describe Scene',
        description: 'Create vivid scene description',
        icon: '🎬',
        prompt: 'Write a vivid, immersive scene description.',
        supportedTypes: [EliteProjectType.novel, EliteProjectType.memoir],
      ),
      // Podcast-specific
      const AIPreset(
        id: 'shownotes',
        name: 'Show Notes',
        description: 'Generate show notes',
        icon: '📝',
        prompt: 'Create comprehensive show notes for this episode.',
        supportedTypes: [EliteProjectType.podcast],
      ),
      const AIPreset(
        id: 'intro',
        name: 'Episode Intro',
        description: 'Write episode introduction',
        icon: '🎙️',
        prompt: 'Write an engaging introduction for this podcast episode.',
        supportedTypes: [EliteProjectType.podcast],
      ),
      // YouTube-specific
      const AIPreset(
        id: 'hook',
        name: 'Video Hook',
        description: 'Create attention-grabbing hook',
        icon: '🎣',
        prompt: 'Write an attention-grabbing hook for the first 10 seconds.',
        supportedTypes: [EliteProjectType.youtube],
      ),
      const AIPreset(
        id: 'description',
        name: 'Video Description',
        description: 'Generate SEO description',
        icon: '📋',
        prompt: 'Write an SEO-optimized video description.',
        supportedTypes: [EliteProjectType.youtube],
      ),
      // Blog-specific
      const AIPreset(
        id: 'headline',
        name: 'Headlines',
        description: 'Generate headline options',
        icon: '📰',
        prompt: 'Generate 5 compelling headline options for this article.',
        supportedTypes: [EliteProjectType.blog],
      ),
      // Research-specific
      const AIPreset(
        id: 'abstract',
        name: 'Abstract',
        description: 'Write research abstract',
        icon: '📚',
        prompt: 'Write a formal academic abstract for this research.',
        supportedTypes: [EliteProjectType.research],
      ),
      // Business-specific
      const AIPreset(
        id: 'executive',
        name: 'Executive Summary',
        description: 'Write executive summary',
        icon: '💼',
        prompt: 'Write a compelling executive summary for investors.',
        supportedTypes: [EliteProjectType.business],
      ),
    ];

    return allPresets.where((preset) {
      if (preset.supportedTypes.isEmpty) return true;
      return preset.supportedTypes.contains(type);
    }).toList();
  }

  /// Generate full context (alias for getFullContext)
  static String generateFullContext(EliteProject project, {String? sectionId}) {
    return getFullContext(project, sectionId: sectionId);
  }

  /// Generate context string for AI from project memory
  static String generateContextForProject(EliteProject project) {
    final buffer = StringBuffer();
    final memory = project.memory;
    
    buffer.writeln('=== PROJECT CONTEXT ===');
    buffer.writeln('Project: ${project.name}');
    buffer.writeln('Type: ${project.type.displayName}');
    
    if (project.subtitle != null) {
      buffer.writeln('Subtitle: ${project.subtitle}');
    }
    
    if (memory?.style.customInstructions != null) {
      buffer.writeln('Instructions: ${memory!.style.customInstructions}');
    }
    
    // Add characters for novels
    if (project.type == EliteProjectType.novel && (memory?.characters.isNotEmpty ?? false)) {
      buffer.writeln('\n=== CHARACTERS ===');
      for (final char in memory!.characters.values.take(5)) {
        buffer.writeln('${char.name}: ${char.description}');
        if (char.traits.isNotEmpty) {
          buffer.writeln('  Traits: ${char.traits.join(", ")}');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Generate continuation context
  static String generateContinuationContext(EliteProject project, String sectionId) {
    final buffer = StringBuffer();
    final memory = project.memory;
    
    buffer.writeln('=== CONTINUATION CONTEXT ===');
    buffer.writeln('Project: ${project.name}');
    buffer.writeln('Type: ${project.type.displayName}');
    
    // Find section
    final section = _findSection(project.structure.sections, sectionId);
    if (section != null) {
      buffer.writeln('Section: ${section.title}');
      if (section.content != null && section.content!.isNotEmpty) {
        final lastContent = section.content!.length > 500 
            ? section.content!.substring(section.content!.length - 500)
            : section.content!;
        buffer.writeln('\nLast content:\n$lastContent');
      }
    }
    
    // Add memory context if available
    if (memory != null) {
      if (memory.characters.isNotEmpty) {
        buffer.writeln('\n=== CHARACTERS ===');
        for (final char in memory.characters.values) {
          buffer.writeln('${char.name}: ${char.description}');
          if (char.traits.isNotEmpty) {
            buffer.writeln('  Traits: ${char.traits.join(", ")}');
          }
        }
      }
      
      if (memory.locations.isNotEmpty) {
        buffer.writeln('\n=== LOCATIONS ===');
        for (final loc in memory.locations.values) {
          buffer.writeln('${loc.name}: ${loc.description}');
        }
      }
      
      if (memory.plotPoints.isNotEmpty) {
        buffer.writeln('\n=== PLOT POINTS ===');
        for (final point in memory.plotPoints) {
          buffer.writeln('- ${point.description}');
        }
      }
      
      if (memory.facts.isNotEmpty) {
        buffer.writeln('\n=== KEY FACTS ===');
        for (final fact in memory.facts) {
          buffer.writeln('- ${fact.fact}');
        }
      }
      
      buffer.writeln('\n=== STYLE ===');
      buffer.writeln(memory.style.toContextString());
    }
    
    return buffer.toString();
  }

  /// Generate context for podcast episodes
  static String generatePodcastContext(EliteProject project, String sectionId) {
    final buffer = StringBuffer();
    final memory = project.memory;
    
    buffer.writeln('=== PODCAST CONTEXT ===');
    buffer.writeln('Show: ${project.name}');
    
    if (memory?.topics.isNotEmpty ?? false) {
      buffer.writeln('\n=== TOPICS ===');
      for (final topic in memory!.topics) {
        buffer.writeln('${topic.name}: ${topic.description}');
      }
    }
    
    if (memory?.style.tone != null) {
      buffer.writeln('Tone: ${memory!.style.tone}');
    }
    if (memory?.style.customInstructions != null) {
      buffer.writeln('Instructions: ${memory!.style.customInstructions}');
    }
    
    return buffer.toString();
  }

  /// Generate context for YouTube videos
  static String generateYouTubeContext(EliteProject project, String sectionId) {
    final buffer = StringBuffer();
    final memory = project.memory;
    
    buffer.writeln('=== VIDEO CONTEXT ===');
    buffer.writeln('Channel: ${project.name}');
    
    if (memory?.style.tone != null) {
      buffer.writeln('Tone: ${memory!.style.tone}');
    }
    if (memory?.style.customInstructions != null) {
      buffer.writeln('Format notes: ${memory!.style.customInstructions}');
    }
    
    if (memory?.topics.isNotEmpty ?? false) {
      buffer.writeln('\n=== TOPICS ===');
      for (final topic in memory!.topics) {
        buffer.writeln('${topic.name}: ${topic.description}');
      }
    }
    
    return buffer.toString();
  }

  /// Get full AI context for a project
  static String getFullContext(EliteProject project, {String? sectionId}) {
    switch (project.type) {
      case EliteProjectType.podcast:
        return generatePodcastContext(project, sectionId ?? '');
      case EliteProjectType.youtube:
        return generateYouTubeContext(project, sectionId ?? '');
      default:
        if (sectionId != null) {
          return generateContinuationContext(project, sectionId);
        }
        return generateContextForProject(project);
    }
  }

  static ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }
}
