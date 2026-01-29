import 'package:flutter/material.dart';

// ============================================================
//        TEMPLATE SYSTEM — REAL TEMPLATES PEOPLE USE
// ============================================================
// Not just "title + blank space"
// Each template has:
// - Smart sections with prompts
// - AI-powered auto-fill hints
// - Voice-first input for each section
// ============================================================

class TemplateSection {
  final String id;
  final String title;
  final String hint;           // What to say/write here
  final String aiPrompt;       // How AI should help fill this
  final IconData icon;
  final bool isRequired;
  final int maxLines;          // Suggested input length
  final List<String>? options; // For multiple choice sections

  const TemplateSection({
    required this.id,
    required this.title,
    required this.hint,
    required this.aiPrompt,
    this.icon = Icons.edit,
    this.isRequired = true,
    this.maxLines = 3,
    this.options,
  });
}

class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final List<TemplateSection> sections;
  final String? outputFormat;   // How to combine sections
  final bool isPremium;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.sections,
    this.outputFormat,
    this.isPremium = false,
  });
}

class AppTemplates {
  // ============================================================
  // 📧 EMAIL TEMPLATES
  // ============================================================

  static const emailColdOutreach = DocumentTemplate(
    id: 'email_cold_outreach',
    name: 'Cold Outreach Email',
    description: 'Professional first contact that gets replies',
    category: 'Email',
    icon: Icons.outgoing_mail,
    color: Color(0xFF3B82F6),
    sections: [
      TemplateSection(
        id: 'recipient',
        title: 'Who are you emailing?',
        hint: 'Name, role, company (e.g., "Sarah, Head of Marketing at Nike")',
        aiPrompt: 'Use this to personalize the greeting and show you did research',
        icon: Icons.person,
        maxLines: 1,
      ),
      TemplateSection(
        id: 'connection',
        title: 'Why them specifically?',
        hint: 'How you found them, what caught your attention, mutual connection',
        aiPrompt: 'Create a personalized opening that shows genuine interest, not spam',
        icon: Icons.link,
      ),
      TemplateSection(
        id: 'value',
        title: 'What value can you offer?',
        hint: 'The benefit to THEM, not what you want from them',
        aiPrompt: 'Frame this as solving their problem, not pitching yourself',
        icon: Icons.card_giftcard,
      ),
      TemplateSection(
        id: 'ask',
        title: 'What\'s your ask?',
        hint: 'One specific, easy request (15-min call, quick question, intro)',
        aiPrompt: 'Make the ask small and specific - easy to say yes to',
        icon: Icons.help_outline,
        maxLines: 2,
      ),
    ],
  );

  static const emailFollowUp = DocumentTemplate(
    id: 'email_follow_up',
    name: 'Follow-Up Email',
    description: 'Polite nudge that doesn\'t feel desperate',
    category: 'Email',
    icon: Icons.replay,
    color: Color(0xFF8B5CF6),
    sections: [
      TemplateSection(
        id: 'context',
        title: 'What was the previous email about?',
        hint: 'Brief reminder of your last message or meeting',
        aiPrompt: 'Reference the previous contact naturally, not accusingly',
        icon: Icons.history,
      ),
      TemplateSection(
        id: 'new_value',
        title: 'Any new info or value to add?',
        hint: 'New development, resource, or thought (optional but powerful)',
        aiPrompt: 'Give them a reason to reply beyond "just checking in"',
        icon: Icons.add_circle_outline,
        isRequired: false,
      ),
      TemplateSection(
        id: 'ask',
        title: 'What do you need from them?',
        hint: 'Specific question or next step',
        aiPrompt: 'Be direct but not pushy. Make it easy to respond.',
        icon: Icons.help_outline,
        maxLines: 2,
      ),
    ],
  );

  static const emailApology = DocumentTemplate(
    id: 'email_apology',
    name: 'Professional Apology',
    description: 'Own the mistake, offer solution, move forward',
    category: 'Email',
    icon: Icons.sentiment_dissatisfied,
    color: Color(0xFFEF4444),
    sections: [
      TemplateSection(
        id: 'mistake',
        title: 'What went wrong?',
        hint: 'Be specific about the mistake - don\'t be vague',
        aiPrompt: 'Acknowledge the specific issue directly without excuses',
        icon: Icons.error_outline,
      ),
      TemplateSection(
        id: 'impact',
        title: 'How did it affect them?',
        hint: 'Show you understand the impact on their end',
        aiPrompt: 'Demonstrate empathy - you understand their frustration',
        icon: Icons.psychology,
      ),
      TemplateSection(
        id: 'solution',
        title: 'How will you fix it?',
        hint: 'Concrete steps you\'re taking to resolve this',
        aiPrompt: 'Focus on action, not just saying sorry',
        icon: Icons.build,
      ),
      TemplateSection(
        id: 'prevention',
        title: 'How will you prevent this?',
        hint: 'What changes to ensure it doesn\'t happen again',
        aiPrompt: 'Show this is a one-time issue, not a pattern',
        icon: Icons.shield,
        isRequired: false,
      ),
    ],
  );

  static const emailResignation = DocumentTemplate(
    id: 'email_resignation',
    name: 'Resignation Letter',
    description: 'Leave professionally, preserve relationships',
    category: 'Email',
    icon: Icons.exit_to_app,
    color: Color(0xFFF59E0B),
    sections: [
      TemplateSection(
        id: 'position',
        title: 'Your current role',
        hint: 'Job title and department',
        aiPrompt: 'State position formally for HR records',
        icon: Icons.badge,
        maxLines: 1,
      ),
      TemplateSection(
        id: 'last_day',
        title: 'When is your last day?',
        hint: 'Give adequate notice (usually 2 weeks)',
        aiPrompt: 'Be clear about the timeline',
        icon: Icons.calendar_today,
        maxLines: 1,
      ),
      TemplateSection(
        id: 'gratitude',
        title: 'What are you grateful for?',
        hint: 'Specific experiences, lessons, or people',
        aiPrompt: 'Be genuine - mention specific positive experiences',
        icon: Icons.favorite,
      ),
      TemplateSection(
        id: 'transition',
        title: 'How will you help transition?',
        hint: 'Training replacement, documentation, handover',
        aiPrompt: 'Show professionalism by offering smooth handover',
        icon: Icons.sync_alt,
      ),
    ],
  );

  // ============================================================
  // 💼 WORK TEMPLATES
  // ============================================================

  static const workMeetingAgenda = DocumentTemplate(
    id: 'work_meeting_agenda',
    name: 'Meeting Agenda',
    description: 'Productive meetings that respect everyone\'s time',
    category: 'Work',
    icon: Icons.event_note,
    color: Color(0xFF10B981),
    sections: [
      TemplateSection(
        id: 'purpose',
        title: 'Meeting purpose',
        hint: 'One sentence: why are we meeting?',
        aiPrompt: 'Make the goal crystal clear',
        icon: Icons.flag,
        maxLines: 2,
      ),
      TemplateSection(
        id: 'attendees',
        title: 'Who needs to be there?',
        hint: 'Only people who need to contribute or decide',
        aiPrompt: 'List attendees and their role in the meeting',
        icon: Icons.group,
      ),
      TemplateSection(
        id: 'topics',
        title: 'Discussion topics',
        hint: 'List each item with time estimate',
        aiPrompt: 'Format as bullet points with time allocations',
        icon: Icons.list,
        maxLines: 6,
      ),
      TemplateSection(
        id: 'decisions',
        title: 'Decisions needed',
        hint: 'What must be decided by end of meeting?',
        aiPrompt: 'Frame as specific yes/no or A/B decisions',
        icon: Icons.gavel,
      ),
      TemplateSection(
        id: 'prep',
        title: 'Pre-meeting prep',
        hint: 'What should people review beforehand?',
        aiPrompt: 'List any documents or context to review',
        icon: Icons.assignment,
        isRequired: false,
      ),
    ],
  );

  static const workProjectBrief = DocumentTemplate(
    id: 'work_project_brief',
    name: 'Project Brief',
    description: 'Align everyone before starting',
    category: 'Work',
    icon: Icons.description,
    color: Color(0xFF6366F1),
    sections: [
      TemplateSection(
        id: 'problem',
        title: 'Problem we\'re solving',
        hint: 'What pain point or opportunity?',
        aiPrompt: 'Define the problem clearly - why does this matter?',
        icon: Icons.report_problem,
      ),
      TemplateSection(
        id: 'goal',
        title: 'Success looks like...',
        hint: 'Measurable outcome when this is done',
        aiPrompt: 'Make it specific and measurable',
        icon: Icons.emoji_events,
      ),
      TemplateSection(
        id: 'scope',
        title: 'What\'s included (and NOT included)',
        hint: 'Boundaries of this project',
        aiPrompt: 'Be explicit about what\'s out of scope',
        icon: Icons.crop_free,
      ),
      TemplateSection(
        id: 'timeline',
        title: 'Key milestones',
        hint: 'Major checkpoints and deadlines',
        aiPrompt: 'List milestones with dates',
        icon: Icons.timeline,
      ),
      TemplateSection(
        id: 'stakeholders',
        title: 'Who\'s involved?',
        hint: 'Roles and responsibilities',
        aiPrompt: 'Clarify who decides, who executes, who\'s informed',
        icon: Icons.people,
      ),
      TemplateSection(
        id: 'risks',
        title: 'Potential risks',
        hint: 'What could go wrong?',
        aiPrompt: 'Identify risks and mitigation strategies',
        icon: Icons.warning,
        isRequired: false,
      ),
    ],
  );

  static const workStatusUpdate = DocumentTemplate(
    id: 'work_status_update',
    name: 'Weekly Status Update',
    description: 'Keep stakeholders informed efficiently',
    category: 'Work',
    icon: Icons.update,
    color: Color(0xFF0891B2),
    sections: [
      TemplateSection(
        id: 'wins',
        title: '✅ Completed this week',
        hint: 'What did you ship or finish?',
        aiPrompt: 'List accomplishments with impact',
        icon: Icons.check_circle,
      ),
      TemplateSection(
        id: 'progress',
        title: '🔄 In progress',
        hint: 'What\'s actively being worked on?',
        aiPrompt: 'Show progress percentage or next steps',
        icon: Icons.pending,
      ),
      TemplateSection(
        id: 'blockers',
        title: '🚧 Blockers',
        hint: 'What\'s slowing you down? What help do you need?',
        aiPrompt: 'Be specific about what\'s blocking and what would unblock',
        icon: Icons.block,
      ),
      TemplateSection(
        id: 'next_week',
        title: '📅 Next week\'s focus',
        hint: 'Top priorities for the coming week',
        aiPrompt: 'List 2-3 key priorities',
        icon: Icons.arrow_forward,
      ),
    ],
  );

  static const workOneOnOne = DocumentTemplate(
    id: 'work_one_on_one',
    name: '1:1 Meeting Prep',
    description: 'Make the most of your manager meetings',
    category: 'Work',
    icon: Icons.people_outline,
    color: Color(0xFFEC4899),
    sections: [
      TemplateSection(
        id: 'wins',
        title: 'Wins to share',
        hint: 'What went well? What are you proud of?',
        aiPrompt: 'Highlight accomplishments without bragging',
        icon: Icons.star,
      ),
      TemplateSection(
        id: 'challenges',
        title: 'Challenges or concerns',
        hint: 'What\'s hard right now? Where do you need help?',
        aiPrompt: 'Frame challenges constructively, propose solutions',
        icon: Icons.psychology,
      ),
      TemplateSection(
        id: 'feedback',
        title: 'Feedback to give',
        hint: 'Any feedback for your manager or team?',
        aiPrompt: 'Be specific and constructive',
        icon: Icons.feedback,
        isRequired: false,
      ),
      TemplateSection(
        id: 'growth',
        title: 'Growth & development',
        hint: 'Skills to develop, goals to discuss',
        aiPrompt: 'Connect to career aspirations',
        icon: Icons.trending_up,
        isRequired: false,
      ),
      TemplateSection(
        id: 'questions',
        title: 'Questions to ask',
        hint: 'What do you want clarity on?',
        aiPrompt: 'Prepare thoughtful questions',
        icon: Icons.help,
      ),
    ],
  );

  static const workPerformanceReview = DocumentTemplate(
    id: 'work_performance_review',
    name: 'Self-Review (Performance)',
    description: 'Document your achievements and growth',
    category: 'Work',
    icon: Icons.assessment,
    color: Color(0xFFF59E0B),
    isPremium: true,
    sections: [
      TemplateSection(
        id: 'accomplishments',
        title: 'Key accomplishments',
        hint: 'Major wins with measurable impact',
        aiPrompt: 'Quantify impact where possible (%, \$, time saved)',
        icon: Icons.emoji_events,
        maxLines: 6,
      ),
      TemplateSection(
        id: 'goals_met',
        title: 'Goals achieved',
        hint: 'Which goals did you hit or exceed?',
        aiPrompt: 'Reference specific goals and outcomes',
        icon: Icons.check_circle,
      ),
      TemplateSection(
        id: 'growth',
        title: 'How you\'ve grown',
        hint: 'New skills, improved areas',
        aiPrompt: 'Show self-awareness and development',
        icon: Icons.trending_up,
      ),
      TemplateSection(
        id: 'challenges',
        title: 'Challenges faced',
        hint: 'Obstacles and how you overcame them',
        aiPrompt: 'Show resilience and problem-solving',
        icon: Icons.fitness_center,
      ),
      TemplateSection(
        id: 'next_goals',
        title: 'Goals for next period',
        hint: 'What do you want to achieve?',
        aiPrompt: 'Make goals SMART: Specific, Measurable, Achievable, Relevant, Time-bound',
        icon: Icons.flag,
      ),
    ],
  );

  // ============================================================
  // 🎯 CONTENT TEMPLATES
  // ============================================================

  static const contentBlogPost = DocumentTemplate(
    id: 'content_blog_post',
    name: 'Blog Post',
    description: 'Engaging articles that get read and shared',
    category: 'Content',
    icon: Icons.article,
    color: Color(0xFF8B5CF6),
    sections: [
      TemplateSection(
        id: 'topic',
        title: 'What\'s the topic?',
        hint: 'Main subject you\'re writing about',
        aiPrompt: 'Define the core topic clearly',
        icon: Icons.topic,
        maxLines: 2,
      ),
      TemplateSection(
        id: 'audience',
        title: 'Who is this for?',
        hint: 'Your target reader',
        aiPrompt: 'Keep this audience in mind for tone and examples',
        icon: Icons.people,
        maxLines: 1,
      ),
      TemplateSection(
        id: 'hook',
        title: 'Opening hook',
        hint: 'Why should someone keep reading?',
        aiPrompt: 'Create a compelling first paragraph that hooks the reader',
        icon: Icons.looks_one,
      ),
      TemplateSection(
        id: 'main_points',
        title: 'Main points to cover',
        hint: 'Key takeaways (3-5 points)',
        aiPrompt: 'Structure as clear sections with supporting details',
        icon: Icons.list,
        maxLines: 6,
      ),
      TemplateSection(
        id: 'examples',
        title: 'Examples or stories',
        hint: 'Real examples that illustrate your points',
        aiPrompt: 'Add concrete examples to make points memorable',
        icon: Icons.auto_stories,
      ),
      TemplateSection(
        id: 'cta',
        title: 'Call to action',
        hint: 'What should the reader do next?',
        aiPrompt: 'End with a clear next step',
        icon: Icons.touch_app,
        maxLines: 2,
      ),
    ],
  );

  static const contentLinkedInPost = DocumentTemplate(
    id: 'content_linkedin_post',
    name: 'LinkedIn Post',
    description: 'Professional posts that build authority',
    category: 'Content',
    icon: Icons.work,
    color: Color(0xFF0077B5),
    sections: [
      TemplateSection(
        id: 'hook',
        title: 'Opening line (the hook)',
        hint: 'Stop the scroll — what makes people click "see more"?',
        aiPrompt: 'Create a punchy first line that creates curiosity',
        icon: Icons.flash_on,
        maxLines: 2,
      ),
      TemplateSection(
        id: 'story',
        title: 'The story or insight',
        hint: 'Personal experience, lesson learned, observation',
        aiPrompt: 'Make it personal and relatable. Vulnerability works.',
        icon: Icons.auto_stories,
        maxLines: 5,
      ),
      TemplateSection(
        id: 'takeaway',
        title: 'The takeaway',
        hint: 'What\'s the lesson? What should people remember?',
        aiPrompt: 'Distill into a clear, memorable insight',
        icon: Icons.lightbulb,
      ),
      TemplateSection(
        id: 'cta',
        title: 'Engagement question',
        hint: 'Question that invites comments',
        aiPrompt: 'Ask something that\'s easy and interesting to answer',
        icon: Icons.forum,
        maxLines: 2,
      ),
    ],
  );

  static const contentYouTubeScript = DocumentTemplate(
    id: 'content_youtube_script',
    name: 'YouTube Video Script',
    description: 'Videos that keep viewers watching',
    category: 'Content',
    icon: Icons.video_library,
    color: Color(0xFFFF0000),
    isPremium: true,
    sections: [
      TemplateSection(
        id: 'hook',
        title: 'Hook (first 30 seconds)',
        hint: 'Why should they keep watching? Tease the value.',
        aiPrompt: 'Create urgency and curiosity immediately',
        icon: Icons.flash_on,
      ),
      TemplateSection(
        id: 'intro',
        title: 'Quick intro',
        hint: 'Who you are (brief!) and what this video covers',
        aiPrompt: 'Keep under 15 seconds - get to the content',
        icon: Icons.person,
        maxLines: 2,
      ),
      TemplateSection(
        id: 'content',
        title: 'Main content',
        hint: 'Your key points, steps, or story',
        aiPrompt: 'Structure clearly. Use transitions between sections.',
        icon: Icons.list,
        maxLines: 10,
      ),
      TemplateSection(
        id: 'cta',
        title: 'Call to action',
        hint: 'Subscribe, comment, check out link, etc.',
        aiPrompt: 'Make it specific and give them a reason',
        icon: Icons.touch_app,
      ),
      TemplateSection(
        id: 'outro',
        title: 'Outro / Next video tease',
        hint: 'What to watch next, final thought',
        aiPrompt: 'Keep them on your channel',
        icon: Icons.navigate_next,
        maxLines: 2,
      ),
    ],
  );

  // ============================================================
  // 📝 PERSONAL TEMPLATES
  // ============================================================

  static const personalDailyReflection = DocumentTemplate(
    id: 'personal_daily_reflection',
    name: 'Daily Reflection',
    description: 'End-of-day review for continuous improvement',
    category: 'Personal',
    icon: Icons.nights_stay,
    color: Color(0xFF6366F1),
    sections: [
      TemplateSection(
        id: 'wins',
        title: 'What went well today?',
        hint: '3 things you\'re proud of or grateful for',
        aiPrompt: 'Celebrate small wins too',
        icon: Icons.star,
      ),
      TemplateSection(
        id: 'learned',
        title: 'What did you learn?',
        hint: 'New insight, skill, or realization',
        aiPrompt: 'Capture lessons while fresh',
        icon: Icons.school,
      ),
      TemplateSection(
        id: 'improve',
        title: 'What could be better?',
        hint: 'One thing to improve tomorrow',
        aiPrompt: 'Be constructive, not critical',
        icon: Icons.trending_up,
      ),
      TemplateSection(
        id: 'tomorrow',
        title: 'Tomorrow\'s #1 priority',
        hint: 'The ONE thing that matters most',
        aiPrompt: 'Focus on high-impact, not urgent',
        icon: Icons.looks_one,
        maxLines: 2,
      ),
    ],
  );

  static const personalGoalSetting = DocumentTemplate(
    id: 'personal_goal_setting',
    name: 'Goal Setting',
    description: 'Turn dreams into actionable plans',
    category: 'Personal',
    icon: Icons.flag,
    color: Color(0xFF10B981),
    sections: [
      TemplateSection(
        id: 'goal',
        title: 'What\'s the goal?',
        hint: 'Be specific — what does success look like?',
        aiPrompt: 'Make it concrete and measurable',
        icon: Icons.emoji_events,
      ),
      TemplateSection(
        id: 'why',
        title: 'Why does this matter?',
        hint: 'Your deeper motivation',
        aiPrompt: 'Connect to values and long-term vision',
        icon: Icons.favorite,
      ),
      TemplateSection(
        id: 'obstacles',
        title: 'What might get in the way?',
        hint: 'Potential obstacles and how you\'ll handle them',
        aiPrompt: 'Anticipate challenges with pre-planned solutions',
        icon: Icons.warning,
      ),
      TemplateSection(
        id: 'first_step',
        title: 'First step (this week)',
        hint: 'The smallest action to start momentum',
        aiPrompt: 'Make it so easy you can\'t say no',
        icon: Icons.directions_walk,
        maxLines: 2,
      ),
      TemplateSection(
        id: 'milestones',
        title: 'Milestones to track',
        hint: 'How will you know you\'re making progress?',
        aiPrompt: 'Break into checkpoints',
        icon: Icons.timeline,
      ),
    ],
  );

  static const personalDecisionMaking = DocumentTemplate(
    id: 'personal_decision',
    name: 'Decision Framework',
    description: 'Think through tough decisions clearly',
    category: 'Personal',
    icon: Icons.compare_arrows,
    color: Color(0xFFF59E0B),
    sections: [
      TemplateSection(
        id: 'decision',
        title: 'What\'s the decision?',
        hint: 'Frame it as a clear question',
        aiPrompt: 'State the decision precisely',
        icon: Icons.help_outline,
      ),
      TemplateSection(
        id: 'options',
        title: 'What are the options?',
        hint: 'List all realistic choices (including doing nothing)',
        aiPrompt: 'Include the status quo as an option',
        icon: Icons.list,
      ),
      TemplateSection(
        id: 'pros_cons',
        title: 'Pros and cons of each',
        hint: 'What you gain and lose with each option',
        aiPrompt: 'Be honest about tradeoffs',
        icon: Icons.balance,
        maxLines: 6,
      ),
      TemplateSection(
        id: 'values',
        title: 'What matters most here?',
        hint: 'Which of your values should guide this?',
        aiPrompt: 'Connect to deeper priorities',
        icon: Icons.favorite,
      ),
      TemplateSection(
        id: 'gut',
        title: 'What does your gut say?',
        hint: 'If you had to decide right now...',
        aiPrompt: 'Trust intuition as data',
        icon: Icons.psychology,
        maxLines: 2,
      ),
    ],
  );

  // ============================================================
  // 📞 COMMUNICATION TEMPLATES  
  // ============================================================

  static const commNegotiation = DocumentTemplate(
    id: 'comm_negotiation',
    name: 'Negotiation Prep',
    description: 'Go in prepared, come out ahead',
    category: 'Communication',
    icon: Icons.handshake,
    color: Color(0xFFDC2626),
    isPremium: true,
    sections: [
      TemplateSection(
        id: 'goal',
        title: 'What do you want?',
        hint: 'Your ideal outcome',
        aiPrompt: 'Be specific about your best case',
        icon: Icons.emoji_events,
      ),
      TemplateSection(
        id: 'minimum',
        title: 'What\'s your walk-away point?',
        hint: 'The minimum you\'ll accept',
        aiPrompt: 'Know your BATNA (best alternative)',
        icon: Icons.do_not_disturb,
      ),
      TemplateSection(
        id: 'their_needs',
        title: 'What do THEY want?',
        hint: 'Their priorities and constraints',
        aiPrompt: 'Understand their perspective',
        icon: Icons.people,
      ),
      TemplateSection(
        id: 'leverage',
        title: 'What leverage do you have?',
        hint: 'Your unique value, alternatives, timing',
        aiPrompt: 'Know your strengths',
        icon: Icons.fitness_center,
      ),
      TemplateSection(
        id: 'opening',
        title: 'Your opening move',
        hint: 'How will you start the conversation?',
        aiPrompt: 'Set the right tone and anchor',
        icon: Icons.play_arrow,
      ),
    ],
  );

  static const commDifficultConversation = DocumentTemplate(
    id: 'comm_difficult',
    name: 'Difficult Conversation',
    description: 'Handle tough talks with grace',
    category: 'Communication',
    icon: Icons.forum,
    color: Color(0xFFEC4899),
    sections: [
      TemplateSection(
        id: 'issue',
        title: 'What needs to be addressed?',
        hint: 'The specific issue (facts, not interpretations)',
        aiPrompt: 'Stick to observable behaviors, not judgments',
        icon: Icons.report_problem,
      ),
      TemplateSection(
        id: 'impact',
        title: 'How does it affect you/others?',
        hint: 'The impact of this behavior or situation',
        aiPrompt: 'Use "I" statements to express impact',
        icon: Icons.psychology,
      ),
      TemplateSection(
        id: 'empathy',
        title: 'Their possible perspective',
        hint: 'Why might they be acting this way?',
        aiPrompt: 'Show you\'ve considered their side',
        icon: Icons.favorite,
      ),
      TemplateSection(
        id: 'request',
        title: 'What do you need?',
        hint: 'Specific change or resolution',
        aiPrompt: 'Be clear about what success looks like',
        icon: Icons.check_circle,
      ),
      TemplateSection(
        id: 'opener',
        title: 'How will you start?',
        hint: 'Opening line that invites dialogue',
        aiPrompt: 'Start soft, stay curious',
        icon: Icons.chat,
        maxLines: 2,
      ),
    ],
  );

  // ============================================================
  // ALL TEMPLATES LIST
  // ============================================================

  static const List<DocumentTemplate> all = [
    // Email
    emailColdOutreach,
    emailFollowUp,
    emailApology,
    emailResignation,
    
    // Work
    workMeetingAgenda,
    workProjectBrief,
    workStatusUpdate,
    workOneOnOne,
    workPerformanceReview,
    
    // Content
    contentBlogPost,
    contentLinkedInPost,
    contentYouTubeScript,
    
    // Personal
    personalDailyReflection,
    personalGoalSetting,
    personalDecisionMaking,
    
    // Communication
    commNegotiation,
    commDifficultConversation,
  ];

  // Get templates by category
  static List<DocumentTemplate> getByCategory(String category) {
    return all.where((t) => t.category == category).toList();
  }

  // Get free templates only
  static List<DocumentTemplate> get freeTemplates {
    return all.where((t) => !t.isPremium).toList();
  }

  // Categories
  static const List<String> categories = [
    'Email',
    'Work', 
    'Content',
    'Personal',
    'Communication',
  ];
}
