import 'package:flutter/material.dart';
import '../models/preset.dart';

class AppPresets {
  // Define all preset categories with their presets
  static final List<PresetCategory> categories = [
    PresetCategory(
      name: 'All Presets',
      presets: [
        Preset(
          id: 'magic',
          icon: Icons.auto_awesome,
          name: 'Magic',
          description: 'AI will choose the best way to rewrite',
          category: 'All Presets',
        ),
        Preset(
          id: 'email_professional',
          icon: Icons.mail,
          name: 'Email – Professional',
          description: 'Compose a clear professional email',
          category: 'All Presets',
        ),
        Preset(
          id: 'email_casual',
          icon: Icons.chat_bubble,
          name: 'Email – Casual',
          description: 'Compose an informal email',
          category: 'All Presets',
        ),
        Preset(
          id: 'quick_reply',
          icon: Icons.flash_on,
          name: 'Quick Reply',
          description: 'Fast, concise response',
          category: 'All Presets',
        ),
        Preset(
          id: 'dating_opener',
          icon: Icons.favorite,
          name: 'Dating – Opener',
          description: 'Create an engaging conversation starter',
          category: 'All Presets',
        ),
        Preset(
          id: 'dating_reply',
          icon: Icons.favorite,
          name: 'Dating – Reply',
          description: 'Reply in a fun and interested way',
          category: 'All Presets',
        ),
        Preset(
          id: 'social_viral_caption',
          icon: Icons.local_fire_department,
          name: 'Social – Viral Content',
          description: 'Create engaging social media content',
          category: 'All Presets',
        ),
        Preset(
          id: 'social_viral_video',
          icon: Icons.videocam,
          name: 'Social – Viral Video',
          description: 'Write scripts for viral video content',
          category: 'All Presets',
        ),
        Preset(
          id: 'rewrite_enhance',
          icon: Icons.edit_note,
          name: 'Rewrite / Enhance',
          description: 'Improve and polish your text',
          category: 'All Presets',
        ),
        Preset(
          id: 'shorten',
          icon: Icons.content_cut,
          name: 'Shorten',
          description: 'Reduce length, preserve meaning',
          category: 'All Presets',
        ),
        Preset(
          id: 'expand',
          icon: Icons.add_circle,
          name: 'Expand',
          description: 'Add more detail and depth',
          category: 'All Presets',
        ),
        Preset(
          id: 'formal_business',
          icon: Icons.business_center,
          name: 'Formal / Business',
          description: 'Professional and formal communication',
          category: 'All Presets',
        ),
      ],
    ),
  ];

  // Quick access presets for the main screen
  static final List<Preset> quickPresets = [
    Preset(
      id: 'magic',
      icon: Icons.auto_awesome,
      name: 'Magic',
      description: 'AI will choose the best way to rewrite',
      category: 'All Presets',
    ),
    Preset(
      id: 'email_professional',
      icon: Icons.mail,
      name: 'Email – Professional',
      description: 'Compose a clear professional email',
      category: 'All Presets',
    ),
    Preset(
      id: 'quick_reply',
      icon: Icons.flash_on,
      name: 'Quick Reply',
      description: 'Fast, concise response',
      category: 'All Presets',
    ),
    Preset(
      id: 'social_viral_caption',
      icon: Icons.local_fire_department,
      name: 'Social – Viral Content',
      description: 'Create engaging social media content',
      category: 'All Presets',
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

