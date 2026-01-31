import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../models/project.dart';
import '../../models/recording_item.dart';
import '../../services/project_service.dart';
import '../../services/continue_service.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/multi_option_fab.dart';
import 'recording_screen.dart';
import 'recording_detail_screen.dart';
import 'text_creation_screen.dart';
import 'image_creation_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _projectService = ProjectService();
  final _continueService = ContinueService();
  Project? _project;
  List<RecordingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
    });

    final projects = await _projectService.getAllProjects();
    final project = projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => projects.first,
    );

    final items = await _projectService.getProjectItems(widget.projectId);

    setState(() {
      _project = project;
      _items = items;
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final secondaryTextColor = const Color(0xFF94A3B8);
    final primaryColor = const Color(0xFF3B82F6);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'Project not found',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    final gradientColors = _getGradientColors(_project!.colorIndex ?? 0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showProjectMenu(context),
                        icon: Icon(Icons.more_vert, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.folder,
                          color: textColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _project!.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${_project!.itemCount} items • ${_project!.formattedDate}',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_project!.description != null && _project!.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _project!.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),


            // Continue Project Button
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _continueProject,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: textColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Continue Project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Items Timeline
            _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: secondaryTextColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in this project yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      ..._items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: _buildItemCard(
                          item,
                          surfaceColor,
                          textColor,
                          secondaryTextColor,
                          gradientColors,
                        ),
                      )).toList(),
                      const SizedBox(height: 100), // Extra space at bottom
                    ],
                  ),
          ],
        ),
        ),
      ),
      floatingActionButton: MultiOptionFab(
        onVoicePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecordingScreen(),
            ),
          );
        },
        onTextPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextCreationScreen(projectId: widget.projectId),
            ),
          );
        },
        onNotePressed: () {
          // Quick note creation within project
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextCreationScreen(
                projectId: widget.projectId,
                isQuickNote: true,
              ),
            ),
          );
        },
        onImagePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageCreationScreen(projectId: widget.projectId),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildItemCard(
    RecordingItem item,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    List<Color> gradientColors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingDetailScreen(recordingId: item.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: gradientColors[0].withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outcome chips
              if (item.outcomes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.outcomeTypes.map((outcome) {
                      return OutcomeChip(
                        outcomeType: outcome,
                        isSelected: true,
                        onTap: () {},
                      );
                    }).toList(),
                  ),
                ),

              // Preset name
              Text(
                item.presetUsed,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: gradientColors[0],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Text(
                item.finalText,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Row(
                    children: [
                      // Remove from project
                      InkWell(
                        onTap: () => _removeItemFromProject(item.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      // Copy
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.finalText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.copy,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      // Share
                      InkWell(
                        onTap: () {
                          Share.share(item.finalText);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.share,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int colorIndex) {
    final gradients = [
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      [const Color(0xFF9333EA), const Color(0xFFEC4899)],
      [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    ];
    return gradients[colorIndex % gradients.length];
  }

  Future<void> _continueProject() async {
    try {
      final context = await _continueService.buildContextFromProject(widget.projectId);
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(this.context, listen: false);
        appState.setContinueContext(context);
        
        // Navigate to recording screen
        Navigator.push(
          this.context,
          MaterialPageRoute(
            builder: (context) => const RecordingScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _removeItemFromProject(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Remove from project?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This item will not be deleted, just removed from this project.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _projectService.removeItemFromProject(widget.projectId, itemId);
      await _loadProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from project'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _showProjectMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text('Delete Project', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProject();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete project?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'The items will not be deleted, only the project.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.deleteProject(widget.projectId);
      if (mounted) {
        Navigator.pop(context); // Go back to library
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
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
      case 'voice':
      default:
        return const Color(0xFFEF4444);
    }
  }
}
