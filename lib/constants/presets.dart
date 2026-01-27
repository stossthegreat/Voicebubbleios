import 'package:flutter/material.dart';
import '../models/preset.dart';

class AppPresets {
  // Define all preset categories with their presets
  static final List<PresetCategory> categories = [
    PresetCategory(
      name: 'All Presets',
      presets: [
        // 1. MAGIC - Deep Purple (FIRST!)
        Preset(
          id: 'magic',
          icon: Icons.auto_awesome,
          name: 'Magic',
          description: 'AI chooses the perfect format for you',
          category: 'All Presets',
          color: const Color(0xFF9333EA), // Deep Purple
        ),
        
        // 2. OUTCOMES - Bright Cyan (CLARITY)
        Preset(
          id: 'outcomes',
          icon: Icons.splitscreen,
          name: 'Outcomes',
          description: 'Extract clear action items and key points',
          category: 'All Presets',
          color: const Color(0xFF22D3EE), // Bright Cyan
        ),
        
        // 3. UNSTUCK - Light Cyan (CALM)
        Preset(
          id: 'unstuck',
          icon: Icons.psychology,
          name: 'Unstuck',
          description: 'One insight, one small action',
          category: 'All Presets',
          color: const Color(0xFF67E8F9), // Light Cyan - calming
        ),
        
        // 4. Quick Reply - Bright Blue (CONTRAST)
        Preset(
          id: 'quick_reply',
          icon: Icons.flash_on,
          name: 'Quick Reply',
          description: 'Fast, concise response',
          category: 'All Presets',
          color: const Color(0xFF0EA5E9), // Bright Sky Blue
        ),
        
        // 3. Email Professional - Deep Red (CONTRAST)
        Preset(
          id: 'email_professional',
          icon: Icons.mail,
          name: 'Email – Professional',
          description: 'Clear professional email',
          category: 'All Presets',
          color: const Color(0xFFDC2626), // Deep Red
        ),
        
        // 4. Email Casual - Bright Green (CONTRAST)
        Preset(
          id: 'email_casual',
          icon: Icons.chat_bubble,
          name: 'Email – Casual',
          description: 'Friendly informal email',
          category: 'All Presets',
          color: const Color(0xFF10B981), // Bright Emerald
        ),
        
        // 5. X Thread - Bright Orange (CONTRAST)
        Preset(
          id: 'x_thread',
          icon: Icons.format_list_bulleted,
          name: '𝕏 (Twitter) Thread',
          description: 'Engaging thread with hooks',
          category: 'All Presets',
          color: const Color(0xFFF97316), // Bright Orange
        ),
        
        // 6. X Post - Hot Pink (CONTRAST)
        Preset(
          id: 'x_post',
          icon: Icons.chat,
          name: '𝕏 (Twitter) Post',
          description: 'Viral single post',
          category: 'All Presets',
          color: const Color(0xFFEC4899), // Hot Pink
        ),
        
        // 7. Facebook - Deep Blue (CONTRAST)
        Preset(
          id: 'facebook_post',
          icon: Icons.public,
          name: 'Facebook Post',
          description: 'Engaging Facebook content',
          category: 'All Presets',
          color: const Color(0xFF1E40AF), // Deep Navy Blue
        ),
        
        // 8. Instagram Caption - Vibrant Magenta (CONTRAST)
        Preset(
          id: 'instagram_caption',
          icon: Icons.camera_alt,
          name: 'Instagram Caption',
          description: 'Perfect caption with hashtags',
          category: 'All Presets',
          color: const Color(0xFFD946EF), // Vibrant Magenta
        ),
        
        // 9. Instagram Hook - Bright Yellow (CONTRAST)
        Preset(
          id: 'instagram_hook',
          icon: Icons.catching_pokemon,
          name: 'Instagram Hook',
          description: 'Attention-grabbing first line',
          category: 'All Presets',
          color: const Color(0xFFFBBF24), // Bright Yellow
        ),
        
        // 10. LinkedIn - Teal (CONTRAST)
        Preset(
          id: 'linkedin_post',
          icon: Icons.work,
          name: 'LinkedIn Post',
          description: 'Professional thought leadership',
          category: 'All Presets',
          color: const Color(0xFF14B8A6), // Bright Teal
        ),
        
        // 11. To-Do - Lime Green (CONTRAST)
        Preset(
          id: 'to_do',
          icon: Icons.check_circle,
          name: 'To-Do List',
          description: 'Convert thoughts to action items',
          category: 'All Presets',
          color: const Color(0xFF84CC16), // Lime Green
        ),
        
        // 12. Meeting Notes - Deep Indigo (CONTRAST)
        Preset(
          id: 'meeting_notes',
          icon: Icons.event_note,
          name: 'Meeting Notes',
          description: 'Structured meeting summary',
          category: 'All Presets',
          color: const Color(0xFF6366F1), // Deep Indigo
        ),
        
        // 13. Story/Novel - Rose Pink (CONTRAST)
        Preset(
          id: 'story_novel',
          icon: Icons.menu_book,
          name: 'Story / Novel Style',
          description: 'Transform into narrative prose',
          category: 'All Presets',
          color: const Color(0xFFF43F5E), // Rose Pink
        ),
        
        // 14. Poem - Amber (CONTRAST)
        Preset(
          id: 'poem',
          icon: Icons.auto_stories,
          name: 'Poem',
          description: 'Create poetic verse',
          category: 'All Presets',
          color: const Color(0xFFF59E0B), // Amber
        ),
        
        // 15. Script - Cyan (CONTRAST)
        Preset(
          id: 'script_dialogue',
          icon: Icons.theater_comedy,
          name: 'Script / Dialogue',
          description: 'Movie or play script format',
          category: 'All Presets',
          color: const Color(0xFF06B6D4), // Bright Cyan
        ),
        
        // 16. Shorten - Violet (CONTRAST)
        Preset(
          id: 'shorten',
          icon: Icons.content_cut,
          name: 'Shorten',
          description: 'Reduce length, keep meaning',
          category: 'All Presets',
          color: const Color(0xFF8B5CF6), // Violet
        ),
        
        // 17. Expand - Coral (CONTRAST)
        Preset(
          id: 'expand',
          icon: Icons.add_circle,
          name: 'Expand',
          description: 'Add detail and depth',
          category: 'All Presets',
          color: const Color(0xFFFB923C), // Coral/Light Orange
        ),
        
        // 18. Make Formal - Steel Blue (CONTRAST)
        Preset(
          id: 'formal_business',
          icon: Icons.business_center,
          name: 'Make Formal',
          description: 'Professional business tone',
          category: 'All Presets',
          color: const Color(0xFF0891B2), // Steel Blue/Cyan-600
        ),
        
        // 19. Make Casual - Bright Lime (CONTRAST)
        Preset(
          id: 'casual_friendly',
          icon: Icons.emoji_emotions,
          name: 'Make Casual',
          description: 'Friendly conversational tone',
          category: 'All Presets',
          color: const Color(0xFFA3E635), // Bright Lime
        ),
      ],
    ),
  ];

  // Quick access presets for the main screen (show top 4)
  static final List<Preset> quickPresets = [
    Preset(
      id: 'magic',
      icon: Icons.auto_awesome,
      name: 'Magic',
      description: 'AI chooses the perfect format',
      category: 'All Presets',
      color: const Color(0xFF9333EA),
    ),
    Preset(
      id: 'quick_reply',
      icon: Icons.flash_on,
      name: 'Quick Reply',
      description: 'Fast, concise response',
      category: 'All Presets',
      color: const Color(0xFF0EA5E9),
    ),
    Preset(
      id: 'instagram_caption',
      icon: Icons.camera_alt,
      name: 'Instagram Caption',
      description: 'Perfect caption with hashtags',
      category: 'All Presets',
      color: const Color(0xFFD946EF),
    ),
    Preset(
      id: 'x_thread',
      icon: Icons.format_list_bulleted,
      name: '𝕏 Thread',
      description: 'Engaging Twitter thread',
      category: 'All Presets',
      color: const Color(0xFFF97316),
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
