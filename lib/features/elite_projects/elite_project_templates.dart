// =============================================================================
// ELITE PROJECT TEMPLATES - PRE-BUILT STRUCTURES
// =============================================================================
// Industry-standard templates for each project type
// Based on what professionals actually use
// =============================================================================

import 'elite_project_models.dart';

// =============================================================================
// TEMPLATE GENERATOR
// =============================================================================

class ProjectTemplateGenerator {
  
  /// Generate default sections for a project type
  static List<ProjectSection> generateSections(EliteProjectType type, {
    String? customTitle,
    Map<String, dynamic>? options,
  }) {
    switch (type) {
      case EliteProjectType.novel:
        return _generateNovelSections(options);
      case EliteProjectType.course:
        return _generateCourseSections(options);
      case EliteProjectType.podcast:
        return _generatePodcastSections(options);
      case EliteProjectType.youtube:
        return _generateYouTubeSections(options);
      case EliteProjectType.blog:
        return _generateBlogSections(options);
      case EliteProjectType.research:
        return _generateResearchSections(options);
      case EliteProjectType.business:
        return _generateBusinessSections(options);
      case EliteProjectType.memoir:
        return _generateMemoirSections(options);
      case EliteProjectType.freeform:
        return [];
    }
  }

  // ===========================================================================
  // 📖 NOVEL TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateNovelSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    final structure = options?['structure'] ?? 'three_act';
    
    if (structure == 'three_act') {
      return [
        // PREMISE & SETUP
        ProjectSection(
          id: 'premise',
          title: 'Premise',
          subtitle: 'Your story in one sentence',
          description: 'The core idea that drives your entire story',
          order: 0,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'planning'},
        ),
        ProjectSection(
          id: 'characters',
          title: 'Characters',
          subtitle: 'Who populates your world',
          description: 'Define your protagonist, antagonist, and supporting characters',
          order: 1,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'planning'},
        ),
        ProjectSection(
          id: 'world',
          title: 'World Building',
          subtitle: 'Your story\'s setting',
          description: 'The rules, history, and atmosphere of your world',
          order: 2,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'planning'},
        ),
        
        // ACT 1
        ProjectSection(
          id: 'act1_setup',
          title: 'Act 1: Setup',
          subtitle: 'Introduce the world',
          order: 3,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'act', 'act': 1},
          subsections: [
            ProjectSection(
              id: 'ch1',
              title: 'Chapter 1',
              subtitle: 'Opening Hook',
              description: 'Grab the reader immediately',
              order: 0,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch2',
              title: 'Chapter 2',
              subtitle: 'Establish Normal World',
              order: 1,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch3',
              title: 'Chapter 3',
              subtitle: 'Inciting Incident',
              description: 'The event that disrupts the normal world',
              order: 2,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
        
        // ACT 2
        ProjectSection(
          id: 'act2_confrontation',
          title: 'Act 2: Confrontation',
          subtitle: 'Rising action & complications',
          order: 4,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'act', 'act': 2},
          subsections: [
            ProjectSection(
              id: 'ch4',
              title: 'Chapter 4',
              subtitle: 'First Obstacle',
              order: 0,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch5',
              title: 'Chapter 5',
              subtitle: 'Developing Conflict',
              order: 1,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch6',
              title: 'Chapter 6',
              subtitle: 'Midpoint Twist',
              description: 'A major revelation or shift',
              order: 2,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch7',
              title: 'Chapter 7',
              subtitle: 'Escalating Stakes',
              order: 3,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch8',
              title: 'Chapter 8',
              subtitle: 'All Is Lost Moment',
              description: 'The darkest hour before the climax',
              order: 4,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
        
        // ACT 3
        ProjectSection(
          id: 'act3_resolution',
          title: 'Act 3: Resolution',
          subtitle: 'Climax & ending',
          order: 5,
          createdAt: now,
          updatedAt: now,
          metadata: {'type': 'act', 'act': 3},
          subsections: [
            ProjectSection(
              id: 'ch9',
              title: 'Chapter 9',
              subtitle: 'The Climax',
              description: 'The final confrontation',
              order: 0,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'ch10',
              title: 'Chapter 10',
              subtitle: 'Resolution',
              description: 'Tie up loose ends',
              order: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
      ];
    }
    
    // Simple chapter structure
    return List.generate(10, (i) => ProjectSection(
      id: 'ch${i + 1}',
      title: 'Chapter ${i + 1}',
      order: i,
      createdAt: now,
      updatedAt: now,
    ));
  }

  // ===========================================================================
  // 🎓 COURSE TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateCourseSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    final moduleCount = options?['modules'] ?? 4;
    
    return [
      // COURSE INTRO
      ProjectSection(
        id: 'intro',
        title: 'Course Introduction',
        subtitle: 'Welcome & overview',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'intro'},
        subsections: [
          ProjectSection(
            id: 'intro_welcome',
            title: 'Welcome Video',
            description: 'Introduce yourself and the course',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'intro_overview',
            title: 'Course Overview',
            description: 'What students will learn',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'intro_prereqs',
            title: 'Prerequisites',
            description: 'What students need before starting',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // MODULES
      ...List.generate(moduleCount, (i) => ProjectSection(
        id: 'module_${i + 1}',
        title: 'Module ${i + 1}',
        subtitle: 'Enter module title',
        order: i + 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'module'},
        subsections: [
          ProjectSection(
            id: 'module_${i + 1}_lesson_1',
            title: 'Lesson ${i + 1}.1',
            subtitle: 'Core Concept',
            order: 0,
            createdAt: now,
            updatedAt: now,
            metadata: {'learningObjective': ''},
          ),
          ProjectSection(
            id: 'module_${i + 1}_lesson_2',
            title: 'Lesson ${i + 1}.2',
            subtitle: 'Deep Dive',
            order: 1,
            createdAt: now,
            updatedAt: now,
            metadata: {'learningObjective': ''},
          ),
          ProjectSection(
            id: 'module_${i + 1}_lesson_3',
            title: 'Lesson ${i + 1}.3',
            subtitle: 'Practical Application',
            order: 2,
            createdAt: now,
            updatedAt: now,
            metadata: {'learningObjective': ''},
          ),
          ProjectSection(
            id: 'module_${i + 1}_quiz',
            title: 'Module ${i + 1} Quiz',
            order: 3,
            createdAt: now,
            updatedAt: now,
            metadata: {'type': 'quiz'},
          ),
        ],
      )),
      
      // CONCLUSION
      ProjectSection(
        id: 'conclusion',
        title: 'Course Conclusion',
        subtitle: 'Wrap up & next steps',
        order: moduleCount + 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'conclusion'},
        subsections: [
          ProjectSection(
            id: 'conclusion_summary',
            title: 'Course Summary',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'conclusion_next',
            title: 'Next Steps',
            description: 'Where to go from here',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'conclusion_bonus',
            title: 'Bonus Resources',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    ];
  }

  // ===========================================================================
  // 🎙️ PODCAST TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generatePodcastSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    final format = options?['format'] ?? 'interview';
    
    return [
      // SHOW PLANNING
      ProjectSection(
        id: 'show_info',
        title: 'Show Information',
        subtitle: 'Your podcast identity',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'planning'},
        subsections: [
          ProjectSection(
            id: 'show_description',
            title: 'Show Description',
            description: 'What your podcast is about',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'show_format',
            title: 'Episode Format',
            description: 'Standard structure for episodes',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'show_segments',
            title: 'Recurring Segments',
            description: 'Regular features in your show',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // EPISODE TEMPLATES
      ProjectSection(
        id: 'episode_template',
        title: 'Episode Template',
        subtitle: format == 'interview' ? 'Interview format' : 'Solo format',
        order: 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'template', 'format': format},
        subsections: format == 'interview' ? [
          ProjectSection(
            id: 'template_intro',
            title: 'Intro',
            description: 'Hook + introduce guest',
            order: 0,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '2-3 min'},
          ),
          ProjectSection(
            id: 'template_guest_background',
            title: 'Guest Background',
            description: 'Who is your guest?',
            order: 1,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '5-7 min'},
          ),
          ProjectSection(
            id: 'template_main',
            title: 'Main Discussion',
            description: 'Core interview questions',
            order: 2,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '20-30 min'},
          ),
          ProjectSection(
            id: 'template_rapid',
            title: 'Rapid Fire',
            description: 'Quick fun questions',
            order: 3,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '5 min'},
          ),
          ProjectSection(
            id: 'template_outro',
            title: 'Outro',
            description: 'Where to find guest + CTA',
            order: 4,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '2-3 min'},
          ),
        ] : [
          ProjectSection(
            id: 'template_hook',
            title: 'Hook',
            description: 'Grab attention immediately',
            order: 0,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '30 sec'},
          ),
          ProjectSection(
            id: 'template_intro',
            title: 'Intro',
            description: 'What this episode covers',
            order: 1,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '2 min'},
          ),
          ProjectSection(
            id: 'template_main',
            title: 'Main Content',
            description: 'The meat of your episode',
            order: 2,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '15-25 min'},
          ),
          ProjectSection(
            id: 'template_recap',
            title: 'Recap & Takeaways',
            description: 'Summarize key points',
            order: 3,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '3-5 min'},
          ),
          ProjectSection(
            id: 'template_outro',
            title: 'Outro & CTA',
            description: 'Call to action',
            order: 4,
            createdAt: now,
            updatedAt: now,
            metadata: {'duration': '1-2 min'},
          ),
        ],
      ),
      
      // EPISODES
      ...List.generate(3, (i) => ProjectSection(
        id: 'episode_${i + 1}',
        title: 'Episode ${i + 1}',
        subtitle: 'Enter episode title',
        order: i + 2,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'type': 'episode',
          'status': 'planned',
          'guest': null,
          'recordingDate': null,
          'publishDate': null,
        },
      )),
    ];
  }

  // ===========================================================================
  // 📺 YOUTUBE TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateYouTubeSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    
    return [
      // CHANNEL PLANNING
      ProjectSection(
        id: 'channel_info',
        title: 'Channel Strategy',
        subtitle: 'Your YouTube identity',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'planning'},
        subsections: [
          ProjectSection(
            id: 'channel_niche',
            title: 'Niche & Positioning',
            description: 'What makes your channel unique',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'channel_audience',
            title: 'Target Audience',
            description: 'Who are you making videos for',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'channel_pillars',
            title: 'Content Pillars',
            description: 'Your main video categories',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // VIDEO SCRIPT TEMPLATE
      ProjectSection(
        id: 'script_template',
        title: 'Video Script Template',
        subtitle: 'Your standard video structure',
        order: 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'template'},
        subsections: [
          ProjectSection(
            id: 'template_hook',
            title: 'Hook (0-30s)',
            description: 'Stop the scroll immediately',
            order: 0,
            createdAt: now,
            updatedAt: now,
            metadata: {'example': 'What if I told you...'},
          ),
          ProjectSection(
            id: 'template_intro',
            title: 'Intro (30s-1m)',
            description: 'What this video covers + credibility',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_body',
            title: 'Main Content',
            description: 'Deliver on your promise',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_cta',
            title: 'CTA',
            description: 'What you want viewers to do',
            order: 3,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_end',
            title: 'End Screen',
            description: 'Suggest next video',
            order: 4,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // VIDEO IDEAS
      ...List.generate(5, (i) => ProjectSection(
        id: 'video_${i + 1}',
        title: 'Video ${i + 1}',
        subtitle: 'Enter video title',
        order: i + 2,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'type': 'video',
          'status': 'idea',
          'targetKeyword': '',
          'thumbnailIdea': '',
        },
      )),
    ];
  }

  // ===========================================================================
  // 📰 BLOG TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateBlogSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    
    return [
      // BLOG STRATEGY
      ProjectSection(
        id: 'blog_strategy',
        title: 'Blog Strategy',
        subtitle: 'Your content plan',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'planning'},
        subsections: [
          ProjectSection(
            id: 'blog_voice',
            title: 'Voice & Tone',
            description: 'How you write',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'blog_topics',
            title: 'Topic Pillars',
            description: 'Main categories you cover',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'blog_schedule',
            title: 'Publishing Schedule',
            description: 'When you publish',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // ARTICLE TEMPLATE
      ProjectSection(
        id: 'article_template',
        title: 'Article Template',
        subtitle: 'Standard structure',
        order: 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'template'},
        subsections: [
          ProjectSection(
            id: 'template_headline',
            title: 'Headline',
            description: 'Click-worthy title',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_hook',
            title: 'Opening Hook',
            description: 'First paragraph that grabs attention',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_body',
            title: 'Body',
            description: 'Main content with subheadings',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'template_conclusion',
            title: 'Conclusion + CTA',
            description: 'Wrap up and next steps',
            order: 3,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      
      // ARTICLE IDEAS
      ...List.generate(5, (i) => ProjectSection(
        id: 'article_${i + 1}',
        title: 'Article ${i + 1}',
        subtitle: 'Enter article title',
        order: i + 2,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'type': 'article',
          'status': 'idea',
          'targetKeyword': '',
          'wordCountTarget': 1500,
        },
      )),
    ];
  }

  // ===========================================================================
  // 📚 RESEARCH TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateResearchSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    final format = options?['format'] ?? 'thesis';
    
    return [
      ProjectSection(
        id: 'title_page',
        title: 'Title Page',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'frontmatter'},
      ),
      ProjectSection(
        id: 'abstract',
        title: 'Abstract',
        description: 'Summary of your research (150-300 words)',
        order: 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'frontmatter'},
      ),
      ProjectSection(
        id: 'introduction',
        title: '1. Introduction',
        order: 2,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'intro_background',
            title: '1.1 Background',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'intro_problem',
            title: '1.2 Problem Statement',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'intro_objectives',
            title: '1.3 Research Objectives',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'intro_scope',
            title: '1.4 Scope & Limitations',
            order: 3,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'literature',
        title: '2. Literature Review',
        order: 3,
        createdAt: now,
        updatedAt: now,
        metadata: {'citations': []},
      ),
      ProjectSection(
        id: 'methodology',
        title: '3. Methodology',
        order: 4,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'method_design',
            title: '3.1 Research Design',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'method_data',
            title: '3.2 Data Collection',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'method_analysis',
            title: '3.3 Data Analysis',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'results',
        title: '4. Results',
        order: 5,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'discussion',
        title: '5. Discussion',
        order: 6,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'conclusion',
        title: '6. Conclusion',
        order: 7,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'conclusion_summary',
            title: '6.1 Summary of Findings',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'conclusion_implications',
            title: '6.2 Implications',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'conclusion_future',
            title: '6.3 Future Research',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'references',
        title: 'References',
        order: 8,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'backmatter'},
      ),
      ProjectSection(
        id: 'appendices',
        title: 'Appendices',
        order: 9,
        createdAt: now,
        updatedAt: now,
        metadata: {'type': 'backmatter'},
      ),
    ];
  }

  // ===========================================================================
  // 💼 BUSINESS PLAN TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateBusinessSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    
    return [
      ProjectSection(
        id: 'executive_summary',
        title: 'Executive Summary',
        description: 'One-page overview (write last)',
        order: 0,
        createdAt: now,
        updatedAt: now,
        metadata: {'writeOrder': 'last'},
      ),
      ProjectSection(
        id: 'company_description',
        title: 'Company Description',
        order: 1,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'company_mission',
            title: 'Mission & Vision',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'company_history',
            title: 'Company History',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'company_structure',
            title: 'Legal Structure',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'market_analysis',
        title: 'Market Analysis',
        order: 2,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'market_industry',
            title: 'Industry Overview',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'market_target',
            title: 'Target Market',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'market_competition',
            title: 'Competitive Analysis',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'products_services',
        title: 'Products & Services',
        order: 3,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'product_description',
            title: 'Description',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'product_differentiation',
            title: 'Differentiation',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'product_pricing',
            title: 'Pricing Strategy',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'marketing_sales',
        title: 'Marketing & Sales Strategy',
        order: 4,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'operations',
        title: 'Operations Plan',
        order: 5,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'team',
        title: 'Management Team',
        order: 6,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'financials',
        title: 'Financial Projections',
        order: 7,
        createdAt: now,
        updatedAt: now,
        subsections: [
          ProjectSection(
            id: 'financial_revenue',
            title: 'Revenue Model',
            order: 0,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'financial_projections',
            title: '3-Year Projections',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
          ProjectSection(
            id: 'financial_funding',
            title: 'Funding Requirements',
            order: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      ProjectSection(
        id: 'appendix',
        title: 'Appendix',
        order: 8,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ===========================================================================
  // 📝 MEMOIR TEMPLATE
  // ===========================================================================
  static List<ProjectSection> _generateMemoirSections(Map<String, dynamic>? options) {
    final now = DateTime.now();
    final structure = options?['structure'] ?? 'chronological';
    
    if (structure == 'chronological') {
      return [
        ProjectSection(
          id: 'intro',
          title: 'Introduction',
          description: 'Why you\'re telling your story',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        ProjectSection(
          id: 'era_childhood',
          title: 'Childhood',
          subtitle: 'Early years',
          order: 1,
          createdAt: now,
          updatedAt: now,
          metadata: {'era': 'childhood'},
          subsections: [
            ProjectSection(
              id: 'childhood_earliest',
              title: 'Earliest Memories',
              order: 0,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'childhood_family',
              title: 'Family Life',
              order: 1,
              createdAt: now,
              updatedAt: now,
            ),
            ProjectSection(
              id: 'childhood_school',
              title: 'School Days',
              order: 2,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
        ProjectSection(
          id: 'era_youth',
          title: 'Youth',
          subtitle: 'Teen years',
          order: 2,
          createdAt: now,
          updatedAt: now,
          metadata: {'era': 'youth'},
        ),
        ProjectSection(
          id: 'era_young_adult',
          title: 'Young Adulthood',
          subtitle: 'Finding your way',
          order: 3,
          createdAt: now,
          updatedAt: now,
          metadata: {'era': 'young_adult'},
        ),
        ProjectSection(
          id: 'era_adult',
          title: 'Adulthood',
          subtitle: 'Building a life',
          order: 4,
          createdAt: now,
          updatedAt: now,
          metadata: {'era': 'adult'},
        ),
        ProjectSection(
          id: 'era_later',
          title: 'Later Years',
          subtitle: 'Wisdom gained',
          order: 5,
          createdAt: now,
          updatedAt: now,
          metadata: {'era': 'later'},
        ),
        ProjectSection(
          id: 'reflections',
          title: 'Reflections',
          description: 'Looking back on your journey',
          order: 6,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
    
    // Thematic structure
    return [
      ProjectSection(
        id: 'intro',
        title: 'Introduction',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      ProjectSection(
        id: 'theme_family',
        title: 'Family',
        subtitle: 'The people who shaped you',
        order: 1,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'family'},
      ),
      ProjectSection(
        id: 'theme_love',
        title: 'Love',
        subtitle: 'Matters of the heart',
        order: 2,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'love'},
      ),
      ProjectSection(
        id: 'theme_work',
        title: 'Work & Purpose',
        subtitle: 'Your professional journey',
        order: 3,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'work'},
      ),
      ProjectSection(
        id: 'theme_challenges',
        title: 'Challenges',
        subtitle: 'Obstacles overcome',
        order: 4,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'challenges'},
      ),
      ProjectSection(
        id: 'theme_triumphs',
        title: 'Triumphs',
        subtitle: 'Your proudest moments',
        order: 5,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'triumphs'},
      ),
      ProjectSection(
        id: 'theme_lessons',
        title: 'Lessons Learned',
        subtitle: 'Wisdom to share',
        order: 6,
        createdAt: now,
        updatedAt: now,
        metadata: {'theme': 'lessons'},
      ),
    ];
  }
}

// =============================================================================
// SECTION PROMPTS - AI GUIDANCE FOR EACH SECTION TYPE
// =============================================================================

class SectionPrompts {
  static String getPromptForSection(EliteProjectType projectType, ProjectSection section) {
    final sectionType = section.metadata?['type'] as String?;
    
    switch (projectType) {
      case EliteProjectType.novel:
        return _getNovelPrompt(section, sectionType);
      case EliteProjectType.course:
        return _getCoursePrompt(section, sectionType);
      case EliteProjectType.podcast:
        return _getPodcastPrompt(section, sectionType);
      case EliteProjectType.youtube:
        return _getYouTubePrompt(section, sectionType);
      case EliteProjectType.blog:
        return _getBlogPrompt(section, sectionType);
      case EliteProjectType.research:
        return _getResearchPrompt(section, sectionType);
      case EliteProjectType.business:
        return _getBusinessPrompt(section, sectionType);
      case EliteProjectType.memoir:
        return _getMemoirPrompt(section, sectionType);
      case EliteProjectType.freeform:
        return '';
    }
  }

  static String _getNovelPrompt(ProjectSection section, String? type) {
    if (section.id.startsWith('ch')) {
      return 'Write this chapter with vivid descriptions and engaging dialogue. '
          'Show don\'t tell. Keep the reader hooked with tension and momentum.';
    }
    if (section.id == 'premise') {
      return 'Describe your story in one compelling sentence. '
          'Format: When [protagonist] [situation], they must [goal] before [stakes].';
    }
    if (section.id == 'characters') {
      return 'Describe each character with their physical traits, personality, '
          'motivations, and arc. What do they want? What stands in their way?';
    }
    return '';
  }

  static String _getCoursePrompt(ProjectSection section, String? type) {
    if (type == 'module') {
      return 'Outline what students will learn in this module. '
          'What\'s the main concept? What will they be able to do after?';
    }
    if (section.metadata?['learningObjective'] != null) {
      return 'Teach this concept clearly. Start with why it matters, '
          'explain the core idea, then give practical examples.';
    }
    return '';
  }

  static String _getPodcastPrompt(ProjectSection section, String? type) {
    if (type == 'episode') {
      return 'Plan your episode: What\'s the main topic? Key talking points? '
          'Any stories or examples to include?';
    }
    return '';
  }

  static String _getYouTubePrompt(ProjectSection section, String? type) {
    if (section.id.contains('hook')) {
      return 'Write a hook that stops the scroll in 5-10 seconds. '
          'Use curiosity, shock, or a bold promise.';
    }
    if (type == 'video') {
      return 'Plan your video: What\'s the promise? The hook? '
          'Main points to cover? Call to action?';
    }
    return '';
  }

  static String _getBlogPrompt(ProjectSection section, String? type) {
    if (section.id.contains('headline')) {
      return 'Write a headline that creates curiosity and promises value. '
          'Use numbers, "how to", or emotional triggers.';
    }
    return '';
  }

  static String _getResearchPrompt(ProjectSection section, String? type) {
    if (section.id == 'abstract') {
      return 'Summarize your research: background, methods, key findings, '
          'and implications in 150-300 words.';
    }
    if (section.id == 'literature') {
      return 'Review existing research on your topic. What has been done? '
          'What gaps exist? How does your work fit?';
    }
    return '';
  }

  static String _getBusinessPrompt(ProjectSection section, String? type) {
    if (section.id == 'executive_summary') {
      return 'Summarize your entire business plan in one page. '
          'Include: what, why, market, team, financials, ask.';
    }
    return '';
  }

  static String _getMemoirPrompt(ProjectSection section, String? type) {
    final era = section.metadata?['era'] as String?;
    final theme = section.metadata?['theme'] as String?;
    
    if (era != null) {
      return 'What memories stand out from this era? '
          'Focus on specific moments, sensory details, and emotions.';
    }
    if (theme != null) {
      return 'What stories from your life relate to this theme? '
          'Be specific and let the reader experience the moment.';
    }
    return 'Tell your story with specific details and emotions. '
        'What did you see, hear, feel?';
  }
}
