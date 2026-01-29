// ============================================================================
// ELITE PROJECT SECTION EDITOR
// ============================================================================
// The actual writing experience - clean, focused, beautiful
// Distraction-free with smart AI assistance
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';
import 'elite_project_ai_service.dart';

class EliteProjectSectionEditor extends StatefulWidget {
  final EliteProject project;
  final String sectionId;
  final EliteProjectService projectService;
  final Function(String sectionId)? onRecordPressed;
  final Function(String presetId, String context)? onAIPresetSelected;

  const EliteProjectSectionEditor({
    super.key,
    required this.project,
    required this.sectionId,
    required this.projectService,
    this.onRecordPressed,
    this.onAIPresetSelected,
  });

  @override
  State<EliteProjectSectionEditor> createState() => _EliteProjectSectionEditorState();
}

class _EliteProjectSectionEditorState extends State<EliteProjectSectionEditor> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  late FocusNode _contentFocusNode;
  
  bool _isFullscreen = false;
  bool _showWordCount = true;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _showAIPanel = false;
  
  ProjectSection? _section;
  int _wordCount = 0;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _titleController = TextEditingController();
    _contentFocusNode = FocusNode();
    _loadSection();
  }

  void _loadSection() {
    _section = _findSection(widget.project.structure.sections, widget.sectionId);
    if (_section != null) {
      _contentController.text = _section!.content ?? '';
      _titleController.text = _section!.title;
      _updateWordCount();
    }
  }

  ProjectSection? _findSection(List<ProjectSection> sections, String id) {
    for (final section in sections) {
      if (section.id == id) return section;
      final found = _findSection(section.children, id);
      if (found != null) return found;
    }
    return null;
  }

  void _updateWordCount() {
    final text = _contentController.text;
    setState(() {
      _wordCount = text.trim().isEmpty 
          ? 0 
          : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _saveContent() async {
    if (!_hasUnsavedChanges || _isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      await widget.projectService.updateSectionContent(
        widget.project.id,
        widget.sectionId,
        _contentController.text,
      );
      
      // Update title if changed
      if (_titleController.text != _section?.title) {
        await widget.projectService.updateSectionTitle(
          widget.project.id,
          widget.sectionId,
          _titleController.text,
        );
      }
      
      setState(() {
        _hasUnsavedChanges = false;
        _lastSaved = DateTime.now();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    if (_hasUnsavedChanges) {
      _saveContent();
    }
    _contentController.dispose();
    _titleController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_section == null) {
      return const Scaffold(
        body: Center(child: Text('Section not found')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: _isFullscreen ? null : _buildAppBar(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Fullscreen header (minimal)
            if (_isFullscreen) _buildFullscreenHeader(isDark),
            
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Editor
                  Expanded(
                    child: _buildEditor(isDark),
                  ),
                  
                  // AI Panel (collapsible)
                  if (_showAIPanel && !_isFullscreen)
                    _buildAIPanel(isDark),
                ],
              ),
            ),
            
            // Bottom bar
            if (!_isFullscreen) _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
        onPressed: () {
          if (_hasUnsavedChanges) {
            _showUnsavedDialog();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _section!.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              Text(
                widget.project.type.emoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                widget.project.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Save status
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_hasUnsavedChanges)
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveContent,
            tooltip: 'Save',
          )
        else if (_lastSaved != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Saved',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[400],
                ),
              ),
            ),
          ),
        
        // AI panel toggle
        IconButton(
          icon: Icon(
            _showAIPanel ? Icons.psychology : Icons.psychology_outlined,
            color: _showAIPanel 
                ? widget.project.type.accentColor 
                : (isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => setState(() => _showAIPanel = !_showAIPanel),
          tooltip: 'AI Assistant',
        ),
        
        // Fullscreen toggle
        IconButton(
          icon: const Icon(Icons.fullscreen),
          onPressed: () => setState(() => _isFullscreen = true),
          tooltip: 'Focus Mode',
        ),
        
        // More options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'status',
              child: Text('Change Status'),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: Text('Copy All'),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Text('Clear Content'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullscreenHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => setState(() => _isFullscreen = false),
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _section!.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          if (_showWordCount)
            Text(
              '$_wordCount words',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    return GestureDetector(
      onTap: () => _contentFocusNode.requestFocus(),
      child: Container(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _isFullscreen ? 80 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title (editable in non-fullscreen)
              if (!_isFullscreen) ...[
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Section Title',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                    ),
                  ),
                  onChanged: (_) {
                    setState(() => _hasUnsavedChanges = true);
                  },
                ),
                
                // Section description
                if (_section!.description != null && _section!.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _section!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
              ],
              
              // Main content editor
              TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                minLines: _isFullscreen ? 30 : 20,
                style: TextStyle(
                  fontSize: _isFullscreen ? 18 : 16,
                  height: 1.8,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  fontFamily: 'Georgia',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _getPlaceholderText(),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _hasUnsavedChanges = true);
                  _updateWordCount();
                  
                  // Auto-save after delay
                  Future.delayed(const Duration(seconds: 3), () {
                    if (_hasUnsavedChanges && mounted) {
                      _saveContent();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlaceholderText() {
    switch (widget.project.type) {
      case EliteProjectType.novel:
        return 'Start writing your scene...\n\nTip: Press the microphone to dictate!';
      case EliteProjectType.course:
        return 'Write your lesson content here...\n\nTip: Use voice to explain concepts naturally!';
      case EliteProjectType.podcast:
        return 'Write your episode notes or script...\n\nTip: Dictate your talking points!';
      case EliteProjectType.youtube:
        return 'Write your video script...\n\nTip: Speak naturally to capture your authentic voice!';
      case EliteProjectType.blog:
        return 'Start writing your article...\n\nTip: Dictate your first draft for faster writing!';
      case EliteProjectType.research:
        return 'Write your research content...\n\nTip: Dictate notes from your research!';
      case EliteProjectType.business:
        return 'Write your business content...\n\nTip: Explain your ideas out loud first!';
      case EliteProjectType.memoir:
        return 'Tell your story...\n\nTip: Speaking your memories often feels more natural!';
      default:
        return 'Start writing...\n\nTip: Press the microphone to dictate!';
    }
  }

  Widget _buildAIPanel(bool isDark) {
    final presets = EliteProjectAIContextService.getPresetsForType(widget.project.type);
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: widget.project.type.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Presets
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...presets.map((preset) => _buildPresetButton(preset, isDark)),
              ],
            ),
          ),
          
          // Record button
          Container(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: widget.onRecordPressed != null
                  ? () => widget.onRecordPressed!(widget.sectionId)
                  : null,
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.project.type.accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(AIPreset preset, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (widget.onAIPresetSelected != null) {
            final context = EliteProjectAIContextService.generateFullContext(
              widget.project,
              currentSectionId: widget.sectionId,
              currentSectionContent: _contentController.text,
            );
            widget.onAIPresetSelected!(preset.id, context);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.project.type.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPresetIcon(preset.id),
                  color: widget.project.type.accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPresetIcon(String presetId) {
    if (presetId.contains('continue')) return Icons.play_arrow;
    if (presetId.contains('dialogue')) return Icons.chat_bubble_outline;
    if (presetId.contains('describe')) return Icons.visibility;
    if (presetId.contains('action')) return Icons.flash_on;
    if (presetId.contains('emotion')) return Icons.favorite_outline;
    if (presetId.contains('polish')) return Icons.auto_fix_high;
    if (presetId.contains('expand')) return Icons.unfold_more;
    if (presetId.contains('example')) return Icons.lightbulb_outline;
    if (presetId.contains('quiz')) return Icons.quiz;
    if (presetId.contains('intro')) return Icons.start;
    if (presetId.contains('outro')) return Icons.stop;
    if (presetId.contains('hook')) return Icons.catching_pokemon;
    if (presetId.contains('seo')) return Icons.search;
    return Icons.auto_awesome;
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Word count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '$_wordCount words',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status badge
          _buildStatusBadge(isDark),
          
          const Spacer(),
          
          // Record button
          ElevatedButton.icon(
            onPressed: widget.onRecordPressed != null
                ? () => widget.onRecordPressed!(widget.sectionId)
                : null,
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.project.type.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final status = _section!.status;
    
    return GestureDetector(
      onTap: _showStatusPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: status.color,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...SectionStatus.values.map((status) => ListTile(
              leading: Text(status.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(status.displayName),
              trailing: _section!.status == status
                  ? Icon(Icons.check, color: status.color)
                  : null,
              onTap: () async {
                await widget.projectService.updateSectionStatus(
                  widget.project.id,
                  widget.sectionId,
                  status,
                );
                setState(() {
                  _section = _findSection(
                    widget.project.structure.sections,
                    widget.sectionId,
                  );
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'status':
        _showStatusPicker();
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: _contentController.text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
        break;
      case 'clear':
        _showClearDialog();
        break;
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Content'),
        content: const Text('Are you sure you want to clear all content in this section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _contentController.clear();
              setState(() {
                _hasUnsavedChanges = true;
                _wordCount = 0;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveContent();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
