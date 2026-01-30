// ============================================================
//        DOCUMENT TEMPLATE MODEL
// ============================================================

class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String structure;
  final List<VoicePrompt> voicePrompts;
  final List<String> tags;
  final int estimatedMinutes;
  final bool isPremium;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.structure,
    required this.voicePrompts,
    required this.tags,
    required this.estimatedMinutes,
    this.isPremium = false,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      structure: json['structure'],
      voicePrompts: (json['voicePrompts'] as List)
          .map((p) => VoicePrompt.fromJson(p))
          .toList(),
      tags: List<String>.from(json['tags']),
      estimatedMinutes: json['estimatedMinutes'],
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'structure': structure,
      'voicePrompts': voicePrompts.map((p) => p.toJson()).toList(),
      'tags': tags,
      'estimatedMinutes': estimatedMinutes,
      'isPremium': isPremium,
    };
  }
}

class VoicePrompt {
  final String id;
  final String placeholder;
  final String prompt;
  final String? example;
  final int? maxWords;          // Made optional
  final int? estimatedSeconds;  // Added
  final bool isRequired;

  const VoicePrompt({
    required this.id,
    required this.placeholder,
    required this.prompt,
    this.example,
    this.maxWords,           // Now optional
    this.estimatedSeconds,   // New field
    this.isRequired = true,
  });

  factory VoicePrompt.fromJson(Map<String, dynamic> json) {
    return VoicePrompt(
      id: json['id'],
      placeholder: json['placeholder'],
      prompt: json['prompt'],
      example: json['example'],
      maxWords: json['maxWords'],
      estimatedSeconds: json['estimatedSeconds'],
      isRequired: json['isRequired'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeholder': placeholder,
      'prompt': prompt,
      'example': example,
      'maxWords': maxWords,
      'estimatedSeconds': estimatedSeconds,
      'isRequired': isRequired,
    };
  }
}

// Elite template categories
enum TemplateCategory {
  business,
  creative,
  academic,
  personal,
  marketing,
  technical,
}

extension TemplateCategoryExtension on TemplateCategory {
  String get displayName {
    switch (this) {
      case TemplateCategory.business:
        return 'Business';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.academic:
        return 'Academic';
      case TemplateCategory.personal:
        return 'Personal';
      case TemplateCategory.marketing:
        return 'Marketing';
      case TemplateCategory.technical:
        return 'Technical';
    }
  }

  String get icon {
    switch (this) {
      case TemplateCategory.business:
        return '💼';
      case TemplateCategory.creative:
        return '🎨';
      case TemplateCategory.academic:
        return '🎓';
      case TemplateCategory.personal:
        return '📝';
      case TemplateCategory.marketing:
        return '📈';
      case TemplateCategory.technical:
        return '⚙️';
    }
  }
}
