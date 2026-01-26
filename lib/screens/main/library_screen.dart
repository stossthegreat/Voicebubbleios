import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../widgets/outcome_chip.dart';
import '../../widgets/preset_chip.dart';
import '../../widgets/project_card.dart';
import '../../widgets/create_project_dialog.dart';
import '../../widgets/preset_filter_chips.dart';
import '../../constants/presets.dart';
import '../../services/continue_service.dart';
import 'project_detail_screen.dart';
import 'recording_detail_screen.dart';
import 'recording_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _showProjects = false; // false = All, true = Projects
  String _searchQuery = '';
  String? _selectedPresetId;
  final ScrollController _scrollController = ScrollController();
  bool _showHeader = true;
  final ContinueService _continueService = ContinueService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _showHeader) {
      setState(() => _showHeader = false);
    } else if (_scrollController.offset <= 50 && !_showHeader) {
      setState(() => _showHeader = true);
    }
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
        child: Column(
          children: [
            // Header - hide on scroll
            if (_showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books,
                      color: textColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All your recordings and projects',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Segmented Control (All / Projects)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showProjects = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showProjects ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'All',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !_showProjects ? textColor : secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showProjects = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showProjects ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Projects',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _showProjects ? textColor : secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar + Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search library...',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_showProjects) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context, surfaceColor, textColor, secondaryTextColor),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _selectedPresetId != null 
                              ? primaryColor.withOpacity(0.2) 
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: _selectedPresetId != null
                              ? Border.all(color: primaryColor, width: 1)
                              : null,
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedPresetId != null ? primaryColor : secondaryTextColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _showProjects
                  ? _buildProjectsView(
                      surfaceColor,
                      textColor,
                      secondaryTextColor,
                      primaryColor,
                    )
                  : _buildAllView(
                      surfaceColor,
                      textColor,
                      secondaryTextColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllView(
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final recordings = appState.recordingItems;

        if (recordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 64,
                  color: secondaryTextColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recordings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recordings will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter recordings based on search and preset
        var filteredRecordings = recordings;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredRecordings = filteredRecordings.where((r) {
            return r.finalText.toLowerCase().contains(_searchQuery) ||
                r.presetUsed.toLowerCase().contains(_searchQuery);
          }).toList();
        }
        
        // Apply preset filter
        if (_selectedPresetId != null) {
          filteredRecordings = filteredRecordings.where((r) {
            return r.presetId == _selectedPresetId;
          }).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filteredRecordings.length,
          itemBuilder: (context, index) {
            final item = filteredRecordings[index];
            return _buildRecordingCard(
              item,
              surfaceColor,
              textColor,
              secondaryTextColor,
            );
          },
        );
      },
    );
  }

  Widget _buildRecordingCard(
    RecordingItem item,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingDetailScreen(
                recordingId: item.id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chips row: Preset chip (large) + Outcome chips (smaller)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Preset chip - FIRST and prominent
                  if (AppPresets.findById(item.presetId) != null)
                    PresetChip(
                      preset: AppPresets.findById(item.presetId)!,
                      isLarge: true,
                    ),
                  
                  // Outcome chips - SECOND and smaller
                  if (item.outcomes.isNotEmpty)
                    ...item.outcomeTypes.map((outcome) {
                      return OutcomeChip(
                        outcomeType: outcome,
                        isSelected: true,
                        onTap: () {}, // Read-only in library view
                      );
                    }).toList(),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                item.finalText,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
                maxLines: 3,
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
                      // Continue button
                      InkWell(
                        onTap: () => _continueFromItem(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.play_arrow,
                            size: 18,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      // Copy button
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
                      // Share button
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
                      // Delete button
                      InkWell(
                        onTap: () => _showDeleteConfirmation(context, item.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: const Color(0xFFEF4444),
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

  Widget _buildProjectsView(
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
  ) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final projects = appState.projects;

        return Stack(
          children: [
            if (projects.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.2),
                            primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Projects Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a project to organize recordings',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            projectId: project.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            // FAB for creating new project
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const CreateProjectDialog(),
                  );
                },
                backgroundColor: primaryColor,
                child: Icon(Icons.add, color: textColor),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _continueFromItem(RecordingItem item) async {
    try {
      final context = await _continueService.buildContextFromItem(item.id);
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
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to continue: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String itemId) {
    final appState = context.read<AppStateProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Recording?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await appState.hideInLibrary(itemId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed from library'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterSheet(BuildContext context, Color surfaceColor, Color textColor, Color secondaryTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Preset',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PresetFilterChips(
                    selectedPresetId: _selectedPresetId,
                    onPresetSelected: (presetId) {
                      setState(() {
                        _selectedPresetId = presetId;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
