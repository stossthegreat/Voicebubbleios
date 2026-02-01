import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../models/tag.dart';
import '../../widgets/preset_chip.dart';
import '../../widgets/project_card.dart';
import '../../widgets/create_project_dialog.dart';
import '../../widgets/tag_filter_chips.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_management_dialog.dart';
import '../../widgets/multi_option_fab.dart';
import '../../constants/presets.dart';
import '../../services/continue_service.dart';
import '../templates/template_models.dart';
import '../templates/template_registry.dart';
import '../templates/template_fill_screen.dart';
import 'project_detail_screen.dart';
import 'recording_detail_screen.dart';
import 'recording_screen.dart';
// ✨ NEW IMPORT ✨
import '../batch_operations_screen.dart';
import '../templates/template_selection_screen.dart';
// ✨ END NEW IMPORT ✨

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // View modes: 0 = Library, 1 = Projects, 2 = Templates
  int _viewMode = 0;
  String _searchQuery = '';
  String? _selectedTagId;
  
  // Template search/filter state
  TemplateCategory? _selectedTemplateCategory;
  String _templateSearchQuery = '';

  Future<void> _showCreateProjectDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            // Get data
            var recordings = appState.recordingItems;
            final projects = appState.projects;

            // Filter recordings
            if (_searchQuery.isNotEmpty) {
              recordings = recordings.where((r) {
                return r.finalText.toLowerCase().contains(_searchQuery) ||
                    r.presetUsed.toLowerCase().contains(_searchQuery);
              }).toList();
            }

            if (_selectedTagId != null && _viewMode == 0) {
              recordings = recordings.where((r) => r.tags.contains(_selectedTagId)).toList();
            }

            return CustomScrollView(
              slivers: [
                // Everything in one scrollable list
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Full-width tabs spanning from edge to edge
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            // Library button - takes 1/3 width
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _viewMode == 0 ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Library',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _viewMode == 0 ? textColor : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Projects button - takes 1/3 width
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _viewMode == 1 ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Projects',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _viewMode == 1 ? textColor : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Templates button - takes 1/3 width
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _viewMode == 2 ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Templates',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _viewMode == 2 ? textColor : secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Bar + Tag Button (no subtitle)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                                style: TextStyle(color: textColor, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Search library...',
                                  hintStyle: TextStyle(color: secondaryTextColor),
                                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                          if (_viewMode == 0) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) => const TagManagementDialog(),
                                );
                                if (mounted) {
                                  await appState.refreshTags();
                                  setState(() {}); // Force rebuild
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _selectedTagId != null ? primaryColor.withOpacity(0.2) : surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _selectedTagId != null ? Border.all(color: primaryColor, width: 1) : null,
                                ),
                                child: Icon(
                                  Icons.label,
                                  color: _selectedTagId != null ? primaryColor : secondaryTextColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            // ✨ BATCH OPERATIONS BUTTON ✨
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BatchOperationsScreen(
                                      allNotes: recordings,
                                      onComplete: (_) {
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.checklist,
                                  color: secondaryTextColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            // ✨ END BATCH OPERATIONS BUTTON ✨
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tag Filter Chips (moved up)
                      if (_viewMode == 0)
                        TagFilterChips(
                          selectedTagId: _selectedTagId,
                          onTagSelected: (tagId) => setState(() => _selectedTagId = tagId),
                        ),
                      if (_viewMode == 0) const SizedBox(height: 16),
                      if (_viewMode == 1) const SizedBox(height: 8),

                      // Content based on mode
                      if (_viewMode == 1) ...[
                        // Projects list
                        if (projects.isEmpty)
                          _buildEmptyState('No projects yet', 'Create your first project', secondaryTextColor)
                        else
                          ...projects.map((project) => ProjectCard(
                                project: project,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectDetailScreen(projectId: project.id),
                                    ),
                                  );
                                },
                              )),
                      ] else if (_viewMode == 2) ...[
                        // Templates view - show the full template UI
                        _buildTemplatesView(surfaceColor, textColor, secondaryTextColor),
                      ] else ...[
                        // Library - Recordings grid
                        if (recordings.isEmpty)
                          _buildEmptyState('No recordings yet', 'Your recordings will appear here', secondaryTextColor)
                        else
                          // Grid layout for recordings
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: recordings.length,
                            itemBuilder: (context, index) {
                              return _buildRecordingCard(
                                recordings[index],
                                surfaceColor,
                                textColor,
                                secondaryTextColor,
                              );
                            },
                          ),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _viewMode == 2 ? null : MultiOptionFab(
        showProjectOption: _viewMode == 1,
        onVoicePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecordingScreen(),
            ),
          );
        },
        onTextPressed: () async {
          // Create empty text document and open in main editor
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Text Document',
            outcomes: [],
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'text_document',
            tags: [],
            contentType: 'text',
          );
          await appState.saveRecording(newItem);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
              ),
            );
          }
        },
        onNotePressed: () async {
          // Create empty quick note and open in main editor
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Quick Note',
            outcomes: [],
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'quick_note',
            tags: [],
            contentType: 'text',
          );
          await appState.saveRecording(newItem);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
              ),
            );
          }
        },
        onTodoPressed: () async {
          // Create empty todo and open in main editor
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Todo List',
            outcomes: [],
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'todo_list',
            tags: [],
            contentType: 'todo',
          );
          await appState.saveRecording(newItem);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
              ),
            );
          }
        },
        onImagePressed: () async {
          // Show image picker FIRST, then create document with image
          final ImagePicker picker = ImagePicker();
          final ImageSource? source = await showDialog<ImageSource>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Add Image', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
                    title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                    title: const Text('Camera', style: TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
            ),
          );
          
          if (source == null) return;
          
          try {
            final XFile? imageFile = await picker.pickImage(source: source);
            if (imageFile == null) return;
            
            // Save image permanently
            final appDir = await getApplicationDocumentsDirectory();
            final String fileName = '${const Uuid().v4()}.jpg';
            final String permanentPath = '${appDir.path}/images/$fileName';
            
            await Directory('${appDir.path}/images').create(recursive: true);
            await File(imageFile.path).copy(permanentPath);
            
            // Create image document with permanent image path
            final appState = Provider.of<AppStateProvider>(context, listen: false);
            final newItem = RecordingItem(
              id: const Uuid().v4(),
              rawTranscript: permanentPath, // Store image path
              finalText: '',
              presetUsed: 'Image',
              outcomes: [],
              projectId: null,
              createdAt: DateTime.now(),
              editHistory: [],
              presetId: 'image',
              tags: [],
              contentType: 'image',
            );
            
            await appState.saveRecording(newItem);
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordingDetailScreen(recordingId: newItem.id),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error picking image: $e')),
              );
            }
          }
        },
        onProjectPressed: () {
          _showCreateProjectDialog(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, Color color) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: color)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(
    RecordingItem item,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final contentTypeColor = _getContentTypeColor(item.contentType);
    final contentTypeIcon = _getContentTypeIcon(item.contentType);
    
    return GestureDetector(
      onTap: () {
        // All content types now use the unified RecordingDetailScreen with RichTextEditor
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecordingDetailScreen(recordingId: item.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with content type indicator and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Content type indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: contentTypeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        contentTypeIcon,
                        size: 12,
                        color: contentTypeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.contentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: contentTypeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Date/time
                Text(
                  item.formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title (custom title if available, otherwise first line of content)
            Text(
              item.customTitle?.isNotEmpty == true 
                  ? item.customTitle! 
                  : item.finalText.split('\n').first,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Preview text (show content, but skip first line if we used it as title and no custom title)
            Text(
              item.customTitle?.isNotEmpty == true 
                  ? item.finalText
                  : _getPreviewText(item.finalText),
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Tags at bottom as colored text
            Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                final tags = appState.tags;
                final itemTags = item.tags
                    .map((tagId) => tags.where((t) => t.id == tagId).firstOrNull)
                    .where((t) => t != null)
                    .cast<Tag>()
                    .toList();
                
                if (itemTags.isEmpty) return const SizedBox(height: 8);
                
                return Text(
                  itemTags.map((tag) => tag.name).join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(itemTags.first.color),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String fullText) {
    final lines = fullText.split('\n');
    if (lines.length <= 1) {
      return ''; // No preview if only one line
    }
    return lines.skip(1).join('\n');
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'todo':
        return Icons.checklist;
      case 'voice':
      default:
        return Icons.mic;
    }
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'text':
        return const Color(0xFFF59E0B);
      case 'image':
        return const Color(0xFF10B981);
      case 'todo':
        return const Color(0xFF8B5CF6);
      case 'voice':
      default:
        return const Color(0xFFEF4444);
    }
  }

  // Build templates view (embedded template selection)
  Widget _buildTemplatesView(Color surfaceColor, Color textColor, Color secondaryTextColor) {
    // Get filtered templates
    List<AppTemplate> filteredTemplates;
    if (_templateSearchQuery.isNotEmpty) {
      filteredTemplates = searchTemplates(_templateSearchQuery);
    } else if (_selectedTemplateCategory != null) {
      filteredTemplates = getTemplatesByCategory(_selectedTemplateCategory!);
    } else {
      filteredTemplates = allTemplates;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTemplateCategoryPill(null, 'All', Icons.apps, surfaceColor, textColor, secondaryTextColor),
              ...TemplateCategory.values.map((cat) => 
                _buildTemplateCategoryPill(cat, cat.displayName, cat.icon, surfaceColor, textColor, secondaryTextColor)
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Featured section (when no filter)
        if (_selectedTemplateCategory == null && _templateSearchQuery.isEmpty) ...[
          Row(
            children: [
              Icon(Icons.star, color: const Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                'Featured',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: getFeaturedTemplates().length,
              itemBuilder: (context, index) {
                final template = getFeaturedTemplates()[index];
                return _buildFeaturedTemplateCard(template, surfaceColor, textColor, secondaryTextColor);
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Templates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Templates grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredTemplates.length,
          itemBuilder: (context, index) {
            final template = filteredTemplates[index];
            return _buildTemplateCard(template, surfaceColor, textColor, secondaryTextColor);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCategoryPill(TemplateCategory? category, String label, IconData icon, 
      Color surfaceColor, Color textColor, Color secondaryTextColor) {
    final isSelected = _selectedTemplateCategory == category;
    final color = category?.color ?? const Color(0xFF8B5CF6);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTemplateCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : secondaryTextColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTemplateCard(AppTemplate template, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TemplateFillScreen(template: template)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [template.category.color.withOpacity(0.2), template.category.color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: template.category.color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: template.category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(template.category.icon, color: template.category.color, size: 20),
                ),
                const Spacer(),
                if (template.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(AppTemplate template, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TemplateFillScreen(template: template)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: template.category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(template.category.icon, color: template.category.color, size: 18),
                ),
                if (template.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              template.name,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              template.description,
              style: TextStyle(fontSize: 11, color: secondaryTextColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: template.category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                template.category.displayName,
                style: TextStyle(fontSize: 10, color: template.category.color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
