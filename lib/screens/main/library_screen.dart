import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../models/tag.dart';
import '../../widgets/preset_chip.dart';
import '../../widgets/project_card.dart';
import '../../widgets/create_project_dialog.dart';
import '../../widgets/tag_filter_chips.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_management_dialog.dart';
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
  bool _showProjects = false;
  String _searchQuery = '';
  String? _selectedTagId;

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

            if (_selectedTagId != null && !_showProjects) {
              recordings = recordings.where((r) => r.tags.contains(_selectedTagId)).toList();
            }

            return CustomScrollView(
              slivers: [
                // Everything in one scrollable list
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header with All/Projects buttons on same line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.library_books, color: textColor, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Library',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          
                          // Compact All/Projects control
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _showProjects = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_showProjects ? primaryColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: !_showProjects ? textColor : secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showProjects = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _showProjects ? primaryColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Projects',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _showProjects ? textColor : secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          if (!_showProjects) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) => const TagManagementDialog(),
                                );
                                if (mounted) appState.refreshTags();
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
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tag Filter Chips (moved up)
                      if (!_showProjects)
                        TagFilterChips(
                          selectedTagId: _selectedTagId,
                          onTagSelected: (tagId) => setState(() => _selectedTagId = tagId),
                        ),
                      if (!_showProjects) const SizedBox(height: 16),
                      if (_showProjects) const SizedBox(height: 8),

                      // Content based on mode
                      if (_showProjects) ...[
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
                      ] else ...[
                        // Recordings grid
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
    return GestureDetector(
      onTap: () {
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
            // Date/time at top
            Text(
              item.formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title (first line of content, bold)
            Text(
              item.finalText.split('\n').first,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Preview text (remaining content)
            Text(
              item.finalText,
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
      floatingActionButton: _showProjects
          ? FloatingActionButton(
              onPressed: () => _showCreateProjectDialog(context),
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
