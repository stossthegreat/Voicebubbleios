// ============================================================
//        TEMPLATE SERVICE
// ============================================================
//
// Elite document template management.
// Provides instant access to professional document structures.
//
// ============================================================

import '../models/document_template.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  // Elite document templates - professionally crafted
  static final List<DocumentTemplate> _eliteTemplates = [
    // BUSINESS TEMPLATES
    DocumentTemplate(
      id: 'business_proposal',
      name: 'Business Proposal',
      description: 'Professional proposal to win clients and close deals',
      icon: '💼',
      category: 'Business',
      estimatedMinutes: 15,
      tags: ['proposal', 'business', 'sales', 'professional'],
      structure: '''# Business Proposal

## Executive Summary
[VOICE: Summarize your proposal in 2-3 powerful sentences that grab attention]

## Problem Statement
[VOICE: Describe the specific problem your client is facing]

## Proposed Solution
[VOICE: Explain your solution and why it's the best approach]

## Benefits & Value
[VOICE: List the key benefits and ROI your client will receive]

## Implementation Timeline
[VOICE: Outline the project phases and timeline]

## Investment & Next Steps
[VOICE: Present your pricing and call-to-action]

---
*Prepared by: [Your Name]*
*Date: [Current Date]*''',
      voicePrompts: [
        VoicePrompt(
          id: 'executive_summary',
          placeholder: 'Executive Summary',
          prompt: 'Summarize your proposal in 2-3 powerful sentences. What are you proposing and why should they care?',
          example: 'We propose a comprehensive digital marketing strategy that will increase your online revenue by 40% within 6 months.',
          maxWords: 100,
        ),
        VoicePrompt(
          id: 'problem_statement',
          placeholder: 'Problem Statement',
          prompt: 'What specific problem is your client facing? Be clear and specific.',
          example: 'Your current website converts only 1.2% of visitors, well below the industry average of 3.5%.',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'solution',
          placeholder: 'Proposed Solution',
          prompt: 'Explain your solution. How will you solve their problem?',
          maxWords: 300,
        ),
        VoicePrompt(
          id: 'benefits',
          placeholder: 'Benefits & Value',
          prompt: 'What specific benefits and ROI will they receive? Use numbers when possible.',
          maxWords: 200,
        ),
        VoicePrompt(
          id: 'timeline',
          placeholder: 'Implementation Timeline',
          prompt: 'Break down the project phases and timeline. When will they see results?',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'investment',
          placeholder: 'Investment & Next Steps',
          prompt: 'Present your pricing and what they need to do next to get started.',
          maxWords: 100,
        ),
      ],
    ),

    DocumentTemplate(
      id: 'meeting_notes',
      name: 'Meeting Notes',
      description: 'Structured notes that capture decisions and action items',
      icon: '📋',
      category: 'Business',
      estimatedMinutes: 5,
      tags: ['meeting', 'notes', 'action items', 'decisions'],
      structure: '''# Meeting Notes

**Date:** [Current Date]
**Attendees:** [VOICE: Who was in the meeting?]
**Duration:** [Meeting Length]

## Agenda
[VOICE: What were the main topics discussed?]

## Key Discussions
[VOICE: Summarize the main points and decisions made]

## Action Items
[VOICE: List who needs to do what by when]

## Next Meeting
[VOICE: When is the follow-up and what will be covered?]

---
*Notes by: [Your Name]*''',
      voicePrompts: [
        VoicePrompt(
          id: 'attendees',
          placeholder: 'Attendees',
          prompt: 'Who attended this meeting? List names and roles.',
          maxWords: 50,
        ),
        VoicePrompt(
          id: 'agenda',
          placeholder: 'Agenda',
          prompt: 'What were the main topics or agenda items discussed?',
          maxWords: 100,
        ),
        VoicePrompt(
          id: 'discussions',
          placeholder: 'Key Discussions',
          prompt: 'Summarize the main points, decisions, and important discussions.',
          maxWords: 300,
        ),
        VoicePrompt(
          id: 'action_items',
          placeholder: 'Action Items',
          prompt: 'List the action items: who needs to do what by when?',
          maxWords: 200,
        ),
        VoicePrompt(
          id: 'next_meeting',
          placeholder: 'Next Meeting',
          prompt: 'When is the next meeting and what will be covered?',
          maxWords: 75,
          isRequired: false,
        ),
      ],
    ),

    // CREATIVE TEMPLATES
    DocumentTemplate(
      id: 'blog_post',
      name: 'Blog Post',
      description: 'Engaging blog post that captures readers and drives traffic',
      icon: '📰',
      category: 'Creative',
      estimatedMinutes: 20,
      tags: ['blog', 'content', 'SEO', 'engagement'],
      structure: '''# [VOICE: Your Compelling Blog Title]

*[VOICE: Write a hook sentence that makes readers want to continue]*

## Introduction
[VOICE: Set up the problem or topic you're addressing]

## Main Content
[VOICE: Share your insights, tips, or story with examples and details]

## Key Takeaways
[VOICE: Summarize the main points readers should remember]

## Conclusion & Call-to-Action
[VOICE: Wrap up and tell readers what to do next]

---
*Published: [Current Date]*
*Tags: [Relevant Tags]*''',
      voicePrompts: [
        VoicePrompt(
          id: 'title',
          placeholder: 'Blog Title',
          prompt: 'Create a compelling title that makes people want to click and read.',
          example: '5 Productivity Hacks That Will Transform Your Workday',
          maxWords: 15,
        ),
        VoicePrompt(
          id: 'hook',
          placeholder: 'Hook Sentence',
          prompt: 'Write an opening sentence that grabs attention and makes readers curious.',
          example: 'What if I told you that you could double your productivity with just 5 simple changes?',
          maxWords: 30,
        ),
        VoicePrompt(
          id: 'introduction',
          placeholder: 'Introduction',
          prompt: 'Set up the problem or topic. Why should readers care about this?',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'main_content',
          placeholder: 'Main Content',
          prompt: 'Share your main insights, tips, or story. Include examples and details.',
          maxWords: 800,
        ),
        VoicePrompt(
          id: 'takeaways',
          placeholder: 'Key Takeaways',
          prompt: 'Summarize the main points readers should remember.',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'conclusion',
          placeholder: 'Conclusion & CTA',
          prompt: 'Wrap up your post and tell readers what to do next.',
          maxWords: 100,
        ),
      ],
    ),

    DocumentTemplate(
      id: 'book_chapter',
      name: 'Book Chapter',
      description: 'Structured chapter for your book with compelling narrative flow',
      icon: '📖',
      category: 'Creative',
      estimatedMinutes: 45,
      isPremium: true,
      tags: ['book', 'chapter', 'writing', 'narrative'],
      structure: '''# Chapter [Number]: [VOICE: Chapter Title]

## Opening Scene
[VOICE: Start with action, dialogue, or a compelling moment]

## Development
[VOICE: Build the story, introduce concepts, or develop characters]

## Conflict/Challenge
[VOICE: Present the main challenge or turning point]

## Resolution/Insight
[VOICE: Show how the challenge is addressed or what's learned]

## Transition
[VOICE: Set up the next chapter or conclude this section]

---
*Chapter [Number] - [Word Count] words*''',
      voicePrompts: [
        VoicePrompt(
          id: 'chapter_title',
          placeholder: 'Chapter Title',
          prompt: 'What is this chapter called? Make it intriguing.',
          maxWords: 10,
        ),
        VoicePrompt(
          id: 'opening_scene',
          placeholder: 'Opening Scene',
          prompt: 'Start with action, dialogue, or a compelling moment that hooks readers.',
          maxWords: 300,
        ),
        VoicePrompt(
          id: 'development',
          placeholder: 'Development',
          prompt: 'Build your story, introduce new concepts, or develop characters.',
          maxWords: 800,
        ),
        VoicePrompt(
          id: 'conflict',
          placeholder: 'Conflict/Challenge',
          prompt: 'Present the main challenge, conflict, or turning point of this chapter.',
          maxWords: 400,
        ),
        VoicePrompt(
          id: 'resolution',
          placeholder: 'Resolution/Insight',
          prompt: 'Show how the challenge is addressed or what insight is gained.',
          maxWords: 300,
        ),
        VoicePrompt(
          id: 'transition',
          placeholder: 'Transition',
          prompt: 'Set up the next chapter or provide a satisfying conclusion.',
          maxWords: 100,
        ),
      ],
    ),

    // PERSONAL TEMPLATES
    DocumentTemplate(
      id: 'daily_journal',
      name: 'Daily Journal',
      description: 'Reflective journal entry to process your day and thoughts',
      icon: '📔',
      category: 'Personal',
      estimatedMinutes: 10,
      tags: ['journal', 'reflection', 'personal', 'mindfulness'],
      structure: '''# Daily Journal - [Current Date]

## Today's Highlights
[VOICE: What were the best parts of your day?]

## Challenges & Lessons
[VOICE: What was difficult and what did you learn?]

## Gratitude
[VOICE: What are you grateful for today?]

## Tomorrow's Focus
[VOICE: What do you want to focus on tomorrow?]

## Random Thoughts
[VOICE: Any other thoughts, ideas, or feelings you want to capture?]

---
*Mood: [Your Current Mood]*''',
      voicePrompts: [
        VoicePrompt(
          id: 'highlights',
          placeholder: 'Today\'s Highlights',
          prompt: 'What were the best parts of your day? What made you happy or proud?',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'challenges',
          placeholder: 'Challenges & Lessons',
          prompt: 'What was challenging today? What did you learn from it?',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'gratitude',
          placeholder: 'Gratitude',
          prompt: 'What are you grateful for today? Big or small things.',
          maxWords: 100,
        ),
        VoicePrompt(
          id: 'tomorrow_focus',
          placeholder: 'Tomorrow\'s Focus',
          prompt: 'What do you want to focus on or accomplish tomorrow?',
          maxWords: 100,
        ),
        VoicePrompt(
          id: 'random_thoughts',
          placeholder: 'Random Thoughts',
          prompt: 'Any other thoughts, ideas, or feelings you want to capture?',
          maxWords: 200,
          isRequired: false,
        ),
      ],
    ),

    // MARKETING TEMPLATES
    DocumentTemplate(
      id: 'email_campaign',
      name: 'Email Campaign',
      description: 'High-converting email that drives engagement and sales',
      icon: '📧',
      category: 'Marketing',
      estimatedMinutes: 12,
      isPremium: true,
      tags: ['email', 'marketing', 'sales', 'conversion'],
      structure: '''# Email Campaign: [VOICE: Campaign Name]

**Subject Line:** [VOICE: Compelling subject that gets opens]
**Preview Text:** [VOICE: Supporting text that appears in inbox]

## Email Body

### Hook
[VOICE: Start with something that grabs attention immediately]

### Value Proposition
[VOICE: What's in it for them? Why should they care?]

### Social Proof
[VOICE: Testimonials, reviews, or success stories]

### Call-to-Action
[VOICE: What exactly do you want them to do?]

### P.S.
[VOICE: Add urgency or reinforce the main benefit]

---
**Campaign:** [Campaign Name]
**Audience:** [Target Audience]
**Goal:** [Primary Objective]''',
      voicePrompts: [
        VoicePrompt(
          id: 'campaign_name',
          placeholder: 'Campaign Name',
          prompt: 'What is this email campaign called?',
          maxWords: 10,
        ),
        VoicePrompt(
          id: 'subject_line',
          placeholder: 'Subject Line',
          prompt: 'Create a compelling subject line that makes people want to open your email.',
          example: 'Your productivity hack is waiting inside...',
          maxWords: 15,
        ),
        VoicePrompt(
          id: 'preview_text',
          placeholder: 'Preview Text',
          prompt: 'Write supporting text that appears in the inbox preview.',
          maxWords: 20,
        ),
        VoicePrompt(
          id: 'hook',
          placeholder: 'Hook',
          prompt: 'Start with something that immediately grabs their attention.',
          maxWords: 50,
        ),
        VoicePrompt(
          id: 'value_proposition',
          placeholder: 'Value Proposition',
          prompt: 'What\'s in it for them? Why should they care about your offer?',
          maxWords: 150,
        ),
        VoicePrompt(
          id: 'social_proof',
          placeholder: 'Social Proof',
          prompt: 'Share testimonials, reviews, or success stories that build trust.',
          maxWords: 100,
        ),
        VoicePrompt(
          id: 'call_to_action',
          placeholder: 'Call-to-Action',
          prompt: 'What exactly do you want them to do? Be specific and compelling.',
          maxWords: 50,
        ),
        VoicePrompt(
          id: 'ps',
          placeholder: 'P.S.',
          prompt: 'Add urgency or reinforce the main benefit in your P.S.',
          maxWords: 30,
        ),
      ],
    ),
  ];

  /// Get all available templates
  List<DocumentTemplate> getAllTemplates() {
    return List.unmodifiable(_eliteTemplates);
  }

  /// Get templates by category
  List<DocumentTemplate> getTemplatesByCategory(String category) {
    return _eliteTemplates
        .where((template) => template.category == category)
        .toList();
  }

  /// Get featured templates (most popular)
  List<DocumentTemplate> getFeaturedTemplates() {
    return [
      _eliteTemplates.firstWhere((t) => t.id == 'business_proposal'),
      _eliteTemplates.firstWhere((t) => t.id == 'blog_post'),
      _eliteTemplates.firstWhere((t) => t.id == 'meeting_notes'),
      _eliteTemplates.firstWhere((t) => t.id == 'daily_journal'),
    ];
  }

  /// Get premium templates
  List<DocumentTemplate> getPremiumTemplates() {
    return _eliteTemplates.where((template) => template.isPremium).toList();
  }

  /// Search templates
  List<DocumentTemplate> searchTemplates(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _eliteTemplates.where((template) {
      return template.name.toLowerCase().contains(lowercaseQuery) ||
          template.description.toLowerCase().contains(lowercaseQuery) ||
          template.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get template by ID
  DocumentTemplate? getTemplateById(String id) {
    try {
      return _eliteTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get available categories
  List<String> getCategories() {
    return _eliteTemplates
        .map((template) => template.category)
        .toSet()
        .toList()
      ..sort();
  }

  /// Create document from template
  String createDocumentFromTemplate(DocumentTemplate template, Map<String, String> responses) {
    String document = template.structure;
    
    // Replace voice prompts with user responses
    for (final prompt in template.voicePrompts) {
      final response = responses[prompt.id] ?? '';
      final placeholder = '[VOICE: ${prompt.prompt}]';
      document = document.replaceAll(placeholder, response);
    }
    
    // Replace current date
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    document = document.replaceAll('[Current Date]', dateStr);
    
    return document;
  }
}