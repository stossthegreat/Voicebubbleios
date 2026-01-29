// ============================================================================
// ELITE PROJECT AI CONTEXT SERVICE - The Memory That Changes Everything
// ============================================================================
// This is what makes us DESTROY Scrivener, Notion, and every competitor
// AI that actually REMEMBERS your characters, plot, style, everything
// ============================================================================

import 'dart:convert';
import 'elite_project_models.dart';

/// The AI Context Service generates rich context for AI operations
/// It pulls from project memory to ensure consistency across all content
class EliteProjectAIContextService {
  
  // ============================================================================
  // CONTEXT GENERATION - Build the perfect prompt context
  // ============================================================================

  /// Generate full AI context for a project
  /// This is injected into every AI call to maintain consistency
  static String generateFullContext(EliteProject project, {
    String? currentSectionId,
    String? currentSectionContent,
    int maxTokens = 4000,
  }) {
    final buffer = StringBuffer();
    
    // Project overview
    buffer.writeln('=== PROJECT CONTEXT ===');
    buffer.writeln('Project: ${project.name}');
    if (project.subtitle != null) {
      buffer.writeln('Subtitle: ${project.subtitle}');
    }
    buffer.writeln('Type: ${project.type.displayName}');
    buffer.writeln();
    
    // Memory context (characters, locations, facts, style)
    buffer.writeln(project.memory.toContextString());
    
    // Current section context
    if (currentSectionId != null) {
      final section = _findSection(project.structure.sections, currentSectionId);
      if (section != null) {
        buffer.writeln();
        buffer.writeln('=== CURRENT SECTION ===');
        buffer.writeln('Section: ${section.title}');
        if (section.description != null) {
          buffer.writeln('Description: ${section.description}');
        }
        
        // Add placeholder hint if available
        final placeholder = section.metadata['placeholder'];
        if (placeholder != null) {
          buffer.writeln('Goal: $placeholder');
        }
      }
    }
    
    // Recent content for continuity
    if (currentSectionContent != null && currentSectionContent.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== RECENT CONTENT ===');
      // Take last ~500 words for context
      final words = currentSectionContent.split(' ');
      final recentWords = words.length > 500 
          ? words.sublist(words.length - 500).join(' ')
          : currentSectionContent;
      buffer.writeln(recentWords);
    }
    
    // Truncate if too long
    String context = buffer.toString();
    if (context.length > maxTokens * 4) { // Rough char to token estimate
      context = context.substring(0, maxTokens * 4);
      context += '\n[Context truncated for length]';
    }
    
    return context;
  }

  /// Generate context specifically for continuation
  /// Used when user says "continue writing"
  static String generateContinuationContext(
    EliteProject project,
    String sectionId,
    String existingContent,
  ) {
    final section = _findSection(project.structure.sections, sectionId);
    final buffer = StringBuffer();
    
    buffer.writeln('You are continuing to write content for "${project.name}".');
    buffer.writeln();
    
    // Add style guidelines
    if (project.memory.style.tone != null) {
      buffer.writeln('Tone: ${project.memory.style.tone}');
    }
    if (project.memory.style.pointOfView != null) {
      buffer.writeln('POV: ${project.memory.style.pointOfView}');
    }
    if (project.memory.style.tense != null) {
      buffer.writeln('Tense: ${project.memory.style.tense}');
    }
    if (project.memory.style.customInstructions != null) {
      buffer.writeln('Instructions: ${project.memory.style.customInstructions}');
    }
    buffer.writeln();
    
    // Add relevant characters if novel
    if (project.type == EliteProjectType.novel && project.memory.characters.isNotEmpty) {
      buffer.writeln('=== CHARACTERS TO REMEMBER ===');
      for (final char in project.memory.characters.take(5)) {
        buffer.writeln('${char.name}: ${char.description}');
      }
      buffer.writeln();
    }
    
    // Current section info
    if (section != null) {
      buffer.writeln('=== CURRENT SECTION: ${section.title} ===');
      if (section.description != null) {
        buffer.writeln(section.description);
      }
    }
    
    // The content to continue from
    buffer.writeln();
    buffer.writeln('=== CONTENT SO FAR ===');
    buffer.writeln(existingContent);
    buffer.writeln();
    buffer.writeln('=== CONTINUE FROM HERE ===');
    
    return buffer.toString();
  }

  // ============================================================================
  // TYPE-SPECIFIC CONTEXT BUILDERS
  // ============================================================================

  /// Generate novel-specific context
  static String generateNovelContext(EliteProject project) {
    assert(project.type == EliteProjectType.novel);
    final buffer = StringBuffer();
    
    buffer.writeln('=== NOVEL PROJECT: ${project.name} ===');
    if (project.subtitle != null) {
      buffer.writeln('Genre/Subtitle: ${project.subtitle}');
    }
    buffer.writeln();
    
    // Characters
    if (project.memory.characters.isNotEmpty) {
      buffer.writeln('=== CHARACTERS ===');
      for (final char in project.memory.characters) {
        buffer.writeln('**${char.name}**');
        buffer.writeln('Description: ${char.description}');
        if (char.traits.isNotEmpty) {
          buffer.writeln('Traits: ${char.traits.join(', ')}');
        }
        if (char.voiceStyle != null) {
          buffer.writeln('Speech style: ${char.voiceStyle}');
        }
        if (char.relationships.isNotEmpty) {
          buffer.writeln('Relationships:');
          for (final rel in char.relationships.entries) {
            buffer.writeln('  - ${rel.key}: ${rel.value}');
          }
        }
        buffer.writeln();
      }
    }
    
    // Locations
    if (project.memory.locations.isNotEmpty) {
      buffer.writeln('=== LOCATIONS ===');
      for (final loc in project.memory.locations) {
        buffer.writeln('**${loc.name}**: ${loc.description}');
        if (loc.atmosphere != null) {
          buffer.writeln('  Atmosphere: ${loc.atmosphere}');
        }
      }
      buffer.writeln();
    }
    
    // Plot points
    if (project.memory.plotPoints.isNotEmpty) {
      buffer.writeln('=== ESTABLISHED PLOT POINTS ===');
      for (final point in project.memory.plotPoints) {
        final status = point.isResolved ? '✓' : '○';
        buffer.writeln('$status ${point.description}');
      }
      buffer.writeln();
    }
    
    // Key facts
    if (project.memory.facts.isNotEmpty) {
      buffer.writeln('=== KEY FACTS TO REMEMBER ===');
      for (final fact in project.memory.facts) {
        final marker = fact.isImportant ? '⚠️' : '•';
        buffer.writeln('$marker ${fact.fact}');
      }
      buffer.writeln();
    }
    
    // Writing style
    buffer.writeln('=== WRITING STYLE ===');
    buffer.writeln(project.memory.style.toContextString());
    
    return buffer.toString();
  }

  /// Generate course-specific context
  static String generateCourseContext(EliteProject project) {
    assert(project.type == EliteProjectType.course);
    final buffer = StringBuffer();
    
    buffer.writeln('=== ONLINE COURSE: ${project.name} ===');
    if (project.subtitle != null) {
      buffer.writeln('Topic: ${project.subtitle}');
    }
    buffer.writeln();
    
    // Topics/Concepts
    if (project.memory.topics.isNotEmpty) {
      buffer.writeln('=== KEY CONCEPTS ===');
      for (final topic in project.memory.topics) {
        buffer.writeln('**${topic.name}**: ${topic.description}');
        if (topic.keyPoints.isNotEmpty) {
          buffer.writeln('  Key points: ${topic.keyPoints.join(', ')}');
        }
      }
      buffer.writeln();
    }
    
    // Teaching style
    buffer.writeln('=== TEACHING STYLE ===');
    if (project.memory.style.tone != null) {
      buffer.writeln('Tone: ${project.memory.style.tone}');
    }
    if (project.memory.style.customInstructions != null) {
      buffer.writeln('Instructions: ${project.memory.style.customInstructions}');
    }
    
    // Course structure overview
    buffer.writeln();
    buffer.writeln('=== COURSE STRUCTURE ===');
    for (final section in project.structure.sections) {
      buffer.writeln('${section.title}');
      for (final child in section.children) {
        buffer.writeln('  - ${child.title}');
      }
    }
    
    return buffer.toString();
  }

  /// Generate podcast-specific context
  static String generatePodcastContext(EliteProject project) {
    assert(project.type == EliteProjectType.podcast);
    final buffer = StringBuffer();
    
    buffer.writeln('=== PODCAST: ${project.name} ===');
    if (project.subtitle != null) {
      buffer.writeln('Theme: ${project.subtitle}');
    }
    buffer.writeln();
    
    // Show format
    buffer.writeln('=== SHOW FORMAT ===');
    if (project.memory.style.tone != null) {
      buffer.writeln('Tone: ${project.memory.style.tone}');
    }
    if (project.memory.style.customInstructions != null) {
      buffer.writeln('Format notes: ${project.memory.style.customInstructions}');
    }
    
    // Recurring segments/topics
    if (project.memory.topics.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== RECURRING SEGMENTS ===');
      for (final topic in project.memory.topics) {
        buffer.writeln('• ${topic.name}: ${topic.description}');
      }
    }
    
    return buffer.toString();
  }

  // ============================================================================
  // SMART SUGGESTIONS - AI-powered guidance
  // ============================================================================

  /// Generate suggestions for what to write next
  static String generateNextStepsSuggestionPrompt(EliteProject project) {
    final buffer = StringBuffer();
    
    buffer.writeln('Based on this project, suggest 3 specific next steps:');
    buffer.writeln();
    buffer.writeln('Project: ${project.name} (${project.type.displayName})');
    buffer.writeln('Progress: ${(project.progress.percentComplete * 100).toInt()}% complete');
    buffer.writeln('Word count: ${project.progress.totalWordCount}');
    buffer.writeln();
    
    // Find incomplete sections
    final incompleteSections = <ProjectSection>[];
    void findIncomplete(List<ProjectSection> sections) {
      for (final section in sections) {
        if (section.status != SectionStatus.complete) {
          incompleteSections.add(section);
        }
        findIncomplete(section.children);
      }
    }
    findIncomplete(project.structure.sections);
    
    if (incompleteSections.isNotEmpty) {
      buffer.writeln('Incomplete sections:');
      for (final section in incompleteSections.take(5)) {
        buffer.writeln('- ${section.title} (${section.status.displayName})');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Provide 3 actionable suggestions for what to work on next.');
    
    return buffer.toString();
  }

  /// Generate prompt for "where did I leave off?"
  static String generateContinuationSummaryPrompt(
    EliteProject project,
    String lastSectionId,
    String lastContent,
  ) {
    final section = _findSection(project.structure.sections, lastSectionId);
    
    return '''
Summarize where the user left off in their ${project.type.displayName} project.

Project: ${project.name}
Last section: ${section?.title ?? 'Unknown'}
Last content (final 200 words):
${_getLastNWords(lastContent, 200)}

Provide a brief, encouraging summary of:
1. What they were working on
2. Where they stopped
3. A suggestion to continue

Keep it to 2-3 sentences, warm and motivating.
''';
  }

  // ============================================================================
  // PRESET-SPECIFIC PROMPTS
  // ============================================================================

  /// Get AI preset prompt with project context injected
  static String buildPresetPromptWithContext(
    EliteProject project,
    String basePresetPrompt,
    String userInput, {
    String? sectionId,
    String? sectionContent,
  }) {
    final context = generateFullContext(
      project,
      currentSectionId: sectionId,
      currentSectionContent: sectionContent,
    );
    
    return '''
$context

=== TASK ===
$basePresetPrompt

=== USER INPUT ===
$userInput
''';
  }

  // ============================================================================
  // MEMORY EXTRACTION - Auto-learn from content
  // ============================================================================

  /// Generate prompt to extract characters from content
  static String generateCharacterExtractionPrompt(String content) {
    return '''
Analyze this text and identify any characters mentioned.

For each character found, provide:
- Name
- Brief description (based on what's in the text)
- Key traits mentioned
- Relationships to other characters

Text to analyze:
$content

Return as JSON array:
[
  {
    "name": "Character Name",
    "description": "Brief description",
    "traits": ["trait1", "trait2"],
    "relationships": {"Other Character": "relationship"}
  }
]

Only include characters that are clearly present in the text.
''';
  }

  /// Generate prompt to extract facts from content
  static String generateFactExtractionPrompt(String content, EliteProjectType type) {
    return '''
Analyze this ${type.displayName} content and identify important facts that should be remembered for consistency.

Look for:
- Specific details that might be referenced later
- Rules or constraints established
- Timeline/chronology details
- World-building elements
- Character decisions or promises

Text to analyze:
$content

Return as JSON array:
[
  {
    "fact": "The specific fact",
    "isImportant": true/false
  }
]

Only include facts that matter for story/content consistency.
''';
  }

  /// Generate prompt to extract plot points
  static String generatePlotPointExtractionPrompt(String content, String sectionId) {
    return '''
Analyze this text and identify significant plot points, events, or developments.

Look for:
- Major events that happen
- Revelations or discoveries
- Conflicts introduced or resolved
- Foreshadowing elements
- Character decisions that affect the story

Text to analyze:
$content

Return as JSON array:
[
  {
    "description": "What happened",
    "type": "event|revelation|conflict|resolution|foreshadowing",
    "isResolved": true/false
  }
]
''';
  }

  // ============================================================================
  // CONSISTENCY CHECKING
  // ============================================================================

  /// Generate prompt to check for consistency issues
  static String generateConsistencyCheckPrompt(
    EliteProject project,
    String newContent,
  ) {
    return '''
Check this new content for consistency with the established project context.

=== ESTABLISHED CONTEXT ===
${project.memory.toContextString()}

=== NEW CONTENT ===
$newContent

Look for:
- Character inconsistencies (wrong traits, relationships, speech patterns)
- Factual contradictions
- Timeline issues
- World-building conflicts

Return any issues found as JSON:
{
  "issues": [
    {
      "type": "character|fact|timeline|world",
      "description": "What the issue is",
      "suggestion": "How to fix it"
    }
  ],
  "isConsistent": true/false
}

If no issues found, return {"issues": [], "isConsistent": true}
''';
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  static ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }

  static String _getLastNWords(String text, int n) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= n) return text;
    return words.sublist(words.length - n).join(' ');
  }
}

// ============================================================================
// PROJECT-SPECIFIC PRESETS - AI modes that understand the format
// ============================================================================

class EliteProjectPresets {
  // Novel presets
  static const List<ProjectPreset> novelPresets = [
    ProjectPreset(
      id: 'novel_continue',
      name: 'Continue Writing',
      description: 'Continue the story naturally from where you left off',
      prompt: 'Continue writing this story naturally, maintaining the established voice, tone, and pacing. Stay true to the characters and plot points established.',
      projectType: EliteProjectType.novel,
    ),
    ProjectPreset(
      id: 'novel_dialogue',
      name: 'Write Dialogue',
      description: 'Generate natural dialogue between characters',
      prompt: 'Write dialogue between the characters. Make it natural and true to each character\'s voice and personality. Include appropriate dialogue tags and action beats.',
      projectType: EliteProjectType.novel,
    ),
    ProjectPreset(
      id: 'novel_describe',
      name: 'Describe Scene',
      description: 'Add rich sensory description to a scene',
      prompt: 'Add vivid sensory description to this scene. Include sight, sound, smell, touch, and taste where appropriate. Make the reader feel present in the moment.',
      projectType: EliteProjectType.novel,
    ),
    ProjectPreset(
      id: 'novel_action',
      name: 'Write Action',
      description: 'Write an action or tense scene',
      prompt: 'Write this action scene with urgency and tension. Use short sentences, active verbs, and visceral details. Keep the pacing tight.',
      projectType: EliteProjectType.novel,
    ),
    ProjectPreset(
      id: 'novel_emotion',
      name: 'Deepen Emotion',
      description: 'Add emotional depth to a passage',
      prompt: 'Rewrite this passage with deeper emotional resonance. Show internal conflict, physical sensations of emotion, and meaningful subtext.',
      projectType: EliteProjectType.novel,
    ),
    ProjectPreset(
      id: 'novel_polish',
      name: 'Polish Prose',
      description: 'Refine and elevate the writing',
      prompt: 'Polish this prose while maintaining the author\'s voice. Remove redundancy, strengthen verbs, vary sentence structure, and enhance the rhythm.',
      projectType: EliteProjectType.novel,
    ),
  ];

  // Course presets
  static const List<ProjectPreset> coursePresets = [
    ProjectPreset(
      id: 'course_explain',
      name: 'Explain Concept',
      description: 'Break down a concept clearly for students',
      prompt: 'Explain this concept in a clear, educational way. Use analogies, examples, and simple language. Build from foundational ideas to more complex ones.',
      projectType: EliteProjectType.course,
    ),
    ProjectPreset(
      id: 'course_example',
      name: 'Create Example',
      description: 'Generate a practical example',
      prompt: 'Create a practical, relatable example that illustrates this concept. Make it specific and actionable so students can apply it immediately.',
      projectType: EliteProjectType.course,
    ),
    ProjectPreset(
      id: 'course_exercise',
      name: 'Create Exercise',
      description: 'Design a hands-on exercise',
      prompt: 'Design a hands-on exercise for students to practice this concept. Include clear instructions, expected outcomes, and tips for success.',
      projectType: EliteProjectType.course,
    ),
    ProjectPreset(
      id: 'course_quiz',
      name: 'Create Quiz Questions',
      description: 'Generate quiz questions to test understanding',
      prompt: 'Create quiz questions that test understanding of this material. Include a mix of difficulty levels. Provide answer explanations.',
      projectType: EliteProjectType.course,
    ),
    ProjectPreset(
      id: 'course_summary',
      name: 'Summarize Module',
      description: 'Create a module summary with key takeaways',
      prompt: 'Summarize this module with key takeaways. List the main concepts covered, skills learned, and action items for students.',
      projectType: EliteProjectType.course,
    ),
  ];

  // Podcast presets
  static const List<ProjectPreset> podcastPresets = [
    ProjectPreset(
      id: 'podcast_intro',
      name: 'Write Episode Intro',
      description: 'Create an engaging episode introduction',
      prompt: 'Write an engaging podcast episode intro that hooks listeners immediately. Tease the value they\'ll get, introduce the topic, and set up what\'s coming.',
      projectType: EliteProjectType.podcast,
    ),
    ProjectPreset(
      id: 'podcast_questions',
      name: 'Generate Interview Questions',
      description: 'Create thoughtful interview questions',
      prompt: 'Generate thoughtful interview questions for this guest. Include a mix of standard background questions, deep-dive topics, and unexpected angles.',
      projectType: EliteProjectType.podcast,
    ),
    ProjectPreset(
      id: 'podcast_shownotes',
      name: 'Write Show Notes',
      description: 'Create comprehensive show notes',
      prompt: 'Write comprehensive show notes for this episode. Include timestamps, key points discussed, resources mentioned, and guest information.',
      projectType: EliteProjectType.podcast,
    ),
    ProjectPreset(
      id: 'podcast_outro',
      name: 'Write Episode Outro',
      description: 'Create a strong episode ending',
      prompt: 'Write a podcast outro that wraps up the episode, provides a clear call to action, and leaves listeners wanting more.',
      projectType: EliteProjectType.podcast,
    ),
  ];

  // YouTube presets
  static const List<ProjectPreset> youtubePresets = [
    ProjectPreset(
      id: 'youtube_hook',
      name: 'Write Video Hook',
      description: 'Create an attention-grabbing opening',
      prompt: 'Write a video hook that grabs attention in the first 3 seconds. Create urgency, curiosity, or emotional connection immediately.',
      projectType: EliteProjectType.youtube,
    ),
    ProjectPreset(
      id: 'youtube_script',
      name: 'Write Video Script',
      description: 'Create a complete video script',
      prompt: 'Write a video script with clear sections, natural transitions, and viewer retention in mind. Include cues for visuals and B-roll.',
      projectType: EliteProjectType.youtube,
    ),
    ProjectPreset(
      id: 'youtube_description',
      name: 'Write Video Description',
      description: 'Create an SEO-optimized description',
      prompt: 'Write a YouTube description optimized for search. Include keywords naturally, timestamps, links, and a compelling summary.',
      projectType: EliteProjectType.youtube,
    ),
    ProjectPreset(
      id: 'youtube_titles',
      name: 'Generate Title Options',
      description: 'Create clickable title variations',
      prompt: 'Generate 10 title options for this video. Make them curiosity-inducing, specific, and optimized for click-through rate.',
      projectType: EliteProjectType.youtube,
    ),
  ];

  // Blog presets
  static const List<ProjectPreset> blogPresets = [
    ProjectPreset(
      id: 'blog_outline',
      name: 'Create Article Outline',
      description: 'Structure a blog post with headers',
      prompt: 'Create a comprehensive outline for this blog post. Include H2s and H3s that guide readers through the topic logically.',
      projectType: EliteProjectType.blog,
    ),
    ProjectPreset(
      id: 'blog_intro',
      name: 'Write Blog Introduction',
      description: 'Create a compelling article opening',
      prompt: 'Write a blog introduction that hooks readers and clearly states what they\'ll learn. Address their pain point immediately.',
      projectType: EliteProjectType.blog,
    ),
    ProjectPreset(
      id: 'blog_expand',
      name: 'Expand Section',
      description: 'Add depth to a section',
      prompt: 'Expand this section with more detail, examples, and practical advice. Make it comprehensive while staying readable.',
      projectType: EliteProjectType.blog,
    ),
    ProjectPreset(
      id: 'blog_seo',
      name: 'Optimize for SEO',
      description: 'Improve SEO while maintaining quality',
      prompt: 'Optimize this content for SEO while maintaining readability. Incorporate keywords naturally and improve structure for featured snippets.',
      projectType: EliteProjectType.blog,
    ),
  ];

  // Research presets
  static const List<ProjectPreset> researchPresets = [
    ProjectPreset(
      id: 'research_formal',
      name: 'Write Academic Prose',
      description: 'Write in formal academic style',
      prompt: 'Write this section in formal academic style. Use appropriate hedging language, cite claims properly, and maintain objectivity.',
      projectType: EliteProjectType.research,
    ),
    ProjectPreset(
      id: 'research_methods',
      name: 'Describe Methodology',
      description: 'Write detailed methodology section',
      prompt: 'Describe the methodology in detail sufficient for replication. Include rationale for choices made.',
      projectType: EliteProjectType.research,
    ),
    ProjectPreset(
      id: 'research_discuss',
      name: 'Write Discussion',
      description: 'Analyze results and implications',
      prompt: 'Write a discussion section that interprets findings, relates them to existing literature, and addresses implications and limitations.',
      projectType: EliteProjectType.research,
    ),
  ];

  // Business presets
  static const List<ProjectPreset> businessPresets = [
    ProjectPreset(
      id: 'business_executive',
      name: 'Write Executive Summary',
      description: 'Create a compelling executive summary',
      prompt: 'Write an executive summary that captures the key points in one page. Lead with the most important information. Make it compelling for investors/stakeholders.',
      projectType: EliteProjectType.business,
    ),
    ProjectPreset(
      id: 'business_market',
      name: 'Analyze Market',
      description: 'Write market analysis section',
      prompt: 'Write a market analysis section. Include market size, trends, target customer profile, and competitive landscape.',
      projectType: EliteProjectType.business,
    ),
    ProjectPreset(
      id: 'business_financial',
      name: 'Explain Financials',
      description: 'Write financial projections narrative',
      prompt: 'Write the narrative explaining the financial projections. Justify assumptions and explain the path to profitability.',
      projectType: EliteProjectType.business,
    ),
  ];

  // Memoir presets
  static const List<ProjectPreset> memoirPresets = [
    ProjectPreset(
      id: 'memoir_scene',
      name: 'Write Scene',
      description: 'Recreate a memory as a vivid scene',
      prompt: 'Write this memory as a vivid scene. Include sensory details, dialogue, and emotional resonance. Show, don\'t tell.',
      projectType: EliteProjectType.memoir,
    ),
    ProjectPreset(
      id: 'memoir_reflect',
      name: 'Add Reflection',
      description: 'Add meaningful reflection to a story',
      prompt: 'Add thoughtful reflection to this story. What did you learn? How did it change you? What meaning does it hold now?',
      projectType: EliteProjectType.memoir,
    ),
    ProjectPreset(
      id: 'memoir_dialogue',
      name: 'Recreate Dialogue',
      description: 'Write dialogue from memory',
      prompt: 'Recreate the dialogue from this memory. Capture the essence of what was said and how it was said, even if not word-for-word.',
      projectType: EliteProjectType.memoir,
    ),
  ];

  /// Get presets for a project type
  static List<ProjectPreset> getPresetsForType(EliteProjectType type) {
    switch (type) {
      case EliteProjectType.novel:
        return novelPresets;
      case EliteProjectType.course:
        return coursePresets;
      case EliteProjectType.podcast:
        return podcastPresets;
      case EliteProjectType.youtube:
        return youtubePresets;
      case EliteProjectType.blog:
        return blogPresets;
      case EliteProjectType.research:
        return researchPresets;
      case EliteProjectType.business:
        return businessPresets;
      case EliteProjectType.memoir:
        return memoirPresets;
      case EliteProjectType.freeform:
        return []; // Use standard presets
    }
  }
}
