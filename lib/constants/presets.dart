import 'package:flutter/material.dart';
import '../models/preset.dart';

class AppPresets {
  // Define all preset categories with their presets
  static final List<PresetCategory> categories = [
    PresetCategory(
      name: 'General',
      presets: [
        Preset(
          id: 'magic',
          icon: Icons.auto_fix_high,
          name: 'Magic',
          description: 'AI will choose the best way to rewrite',
          category: 'General',
        ),
        Preset(
          id: 'slightly',
          icon: Icons.edit_outlined,
          name: 'Slightly',
          description: 'Clean up the text',
          category: 'General',
        ),
        Preset(
          id: 'significantly',
          icon: Icons.create,
          name: 'Significantly',
          description: 'Revise for better understanding',
          category: 'General',
        ),
      ],
    ),
    PresetCategory(
      name: 'Text Editing',
      presets: [
        Preset(
          id: 'structured',
          icon: Icons.checklist,
          name: 'Structured',
          description: 'Organize using bullet points, headings',
          category: 'Text Editing',
        ),
        Preset(
          id: 'shorter',
          icon: Icons.content_cut,
          name: 'Shorter',
          description: 'Reduce length, preserve meaning',
          category: 'Text Editing',
        ),
        Preset(
          id: 'list',
          icon: Icons.format_list_bulleted,
          name: 'List',
          description: 'Make a list for tasks, shopping, etc.',
          category: 'Text Editing',
        ),
      ],
    ),
    PresetCategory(
      name: 'Content Creation',
      presets: [
        Preset(
          id: 'x-post',
          icon: Icons.message,
          name: 'X Post',
          description: 'Make an engaging tweet',
          category: 'Content Creation',
        ),
        Preset(
          id: 'x-thread',
          icon: Icons.people,
          name: 'X Thread',
          description: 'Transform into a series of tweets',
          category: 'Content Creation',
        ),
        Preset(
          id: 'facebook',
          icon: Icons.facebook,
          name: 'Facebook Post',
          description: 'Make an interesting social media post',
          category: 'Content Creation',
        ),
        Preset(
          id: 'linkedin',
          icon: Icons.business,
          name: 'LinkedIn Post',
          description: 'Make a professional post',
          category: 'Content Creation',
        ),
        Preset(
          id: 'instagram',
          icon: Icons.photo_camera,
          name: 'Instagram Post',
          description: 'Make a captivating post for Instagram',
          category: 'Content Creation',
        ),
        Preset(
          id: 'video-script',
          icon: Icons.videocam,
          name: 'Video Script',
          description: 'Write a script for a video, like for YouTube',
          category: 'Content Creation',
        ),
        Preset(
          id: 'short-video',
          icon: Icons.video_library,
          name: 'Short Video Script',
          description: 'Write a short script for Reels, TikTok, or Shorts',
          category: 'Content Creation',
        ),
        Preset(
          id: 'newsletter',
          icon: Icons.email,
          name: 'Newsletter',
          description: 'Write an email for a newsletter',
          category: 'Content Creation',
        ),
        Preset(
          id: 'outline',
          icon: Icons.article_outlined,
          name: 'Outline',
          description: 'Create a structured outline with headings for future text',
          category: 'Content Creation',
        ),
        Preset(
          id: 'product-description',
          icon: Icons.shopping_bag_outlined,
          name: 'Product Description',
          description: 'Write compelling product copy',
          category: 'Content Creation',
        ),
        Preset(
          id: 'sales-message',
          icon: Icons.trending_up,
          name: 'Sales Message',
          description: 'Create persuasive sales pitch',
          category: 'Content Creation',
        ),
      ],
    ),
    PresetCategory(
      name: 'Journaling',
      presets: [
        Preset(
          id: 'journal',
          icon: Icons.book,
          name: 'Journal Entry',
          description: 'Present thoughts in an easy-to-read format',
          category: 'Journaling',
        ),
        Preset(
          id: 'gratitude',
          icon: Icons.favorite,
          name: 'Gratitude Journal',
          description: 'Express gratitude in an easy-to-read format',
          category: 'Journaling',
        ),
      ],
    ),
    PresetCategory(
      name: 'Emails',
      presets: [
        Preset(
          id: 'casual-email',
          icon: Icons.chat_bubble_outline,
          name: 'Casual Email',
          description: 'Compose an informal email',
          category: 'Emails',
        ),
        Preset(
          id: 'formal-email',
          icon: Icons.mail_outline,
          name: 'Formal Email',
          description: 'Compose a clear professional email',
          category: 'Emails',
        ),
      ],
    ),
    PresetCategory(
      name: 'Summary',
      presets: [
        Preset(
          id: 'short-summary',
          icon: Icons.short_text,
          name: 'Short Summary',
          description: 'Highlight key points briefly',
          category: 'Summary',
        ),
        Preset(
          id: 'detailed-summary',
          icon: Icons.subject,
          name: 'Detailed Summary',
          description: 'Cover key points thoroughly',
          category: 'Summary',
        ),
        Preset(
          id: 'meeting-takeaways',
          icon: Icons.assignment,
          name: 'Meeting Takeaways',
          description: 'Note key points and follow-up actions',
          category: 'Summary',
        ),
      ],
    ),
    PresetCategory(
      name: 'Writing Styles',
      presets: [
        Preset(
          id: 'business',
          icon: Icons.work_outline,
          name: 'Business',
          description: 'Communicate your message effectively',
          category: 'Writing Styles',
        ),
        Preset(
          id: 'formal',
          icon: Icons.description,
          name: 'Formal',
          description: 'Write formally, as you would for officials',
          category: 'Writing Styles',
        ),
        Preset(
          id: 'casual',
          icon: Icons.coffee,
          name: 'Casual',
          description: 'Write informally without strict formalities',
          category: 'Writing Styles',
        ),
        Preset(
          id: 'friendly',
          icon: Icons.emoji_emotions,
          name: 'Friendly',
          description: 'Write as if to a friend',
          category: 'Writing Styles',
        ),
        Preset(
          id: 'clear-concise',
          icon: Icons.center_focus_strong,
          name: 'Clear & Concise',
          description: 'Write clearly and to the point, without unnecessary words',
          category: 'Writing Styles',
        ),
      ],
    ),
    PresetCategory(
      name: 'Holiday Greetings',
      presets: [
        Preset(
          id: 'funny',
          icon: Icons.sentiment_very_satisfied,
          name: 'Funny & Lighthearted',
          description: 'Write with humor and lightness',
          category: 'Holiday Greetings',
        ),
        Preset(
          id: 'warm',
          icon: Icons.wb_sunny,
          name: 'Friendly & Warm',
          description: 'Write warmly and friendly',
          category: 'Holiday Greetings',
        ),
        Preset(
          id: 'simple-professional',
          icon: Icons.create,
          name: 'Simple & Professional',
          description: 'Write simply and professionally',
          category: 'Holiday Greetings',
        ),
      ],
    ),
    PresetCategory(
      name: 'Dating',
      presets: [
        Preset(
          id: 'flirty-message',
          icon: Icons.favorite_border,
          name: 'Flirty Message',
          description: 'Make it playful and charming',
          category: 'Dating',
        ),
        Preset(
          id: 'opening-line',
          icon: Icons.chat_bubble_outline,
          name: 'Opening Line',
          description: 'Create an engaging conversation starter',
          category: 'Dating',
        ),
        Preset(
          id: 'dating-response',
          icon: Icons.reply,
          name: 'Response',
          description: 'Reply in a fun and interested way',
          category: 'Dating',
        ),
        Preset(
          id: 'compliment',
          icon: Icons.star_border,
          name: 'Compliment',
          description: 'Express appreciation genuinely',
          category: 'Dating',
        ),
      ],
    ),
    PresetCategory(
      name: 'Quick Replies',
      presets: [
        Preset(
          id: 'thank-you',
          icon: Icons.thumb_up_outlined,
          name: 'Thank You',
          description: 'Express gratitude professionally',
          category: 'Quick Replies',
        ),
        Preset(
          id: 'apology',
          icon: Icons.sentiment_dissatisfied_outlined,
          name: 'Apology',
          description: 'Apologize sincerely and clearly',
          category: 'Quick Replies',
        ),
        Preset(
          id: 'congratulations',
          icon: Icons.celebration,
          name: 'Congratulations',
          description: 'Celebrate someone\'s achievement',
          category: 'Quick Replies',
        ),
        Preset(
          id: 'invitation',
          icon: Icons.event,
          name: 'Invitation',
          description: 'Invite someone warmly',
          category: 'Quick Replies',
        ),
      ],
    ),
  ];

  // Quick access presets for the main screen
  static final List<Preset> quickPresets = [
    Preset(
      id: 'formal-email',
      icon: Icons.mail_outline,
      name: 'Professional Email',
      description: 'Compose a clear professional email',
      category: 'Emails',
    ),
    Preset(
      id: 'casual',
      icon: Icons.chat_bubble_outline,
      name: 'Casual Message',
      description: 'Write informally without strict formalities',
      category: 'Writing Styles',
    ),
    Preset(
      id: 'list',
      icon: Icons.format_list_bulleted,
      name: 'To-Do List',
      description: 'Make a list for tasks, shopping, etc.',
      category: 'Text Editing',
    ),
    Preset(
      id: 'magic',
      icon: Icons.auto_fix_high,
      name: 'Magic',
      description: 'AI will choose the best way to rewrite',
      category: 'General',
    ),
  ];

  // Get all presets as a flat list
  static List<Preset> get allPresets {
    return categories.expand((category) => category.presets).toList();
  }

  // Find preset by ID
  static Preset? findById(String id) {
    try {
      return allPresets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }
}

