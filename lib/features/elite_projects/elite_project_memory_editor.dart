// ============================================================================
// ELITE PROJECT MEMORY EDITOR
// ============================================================================
// Control the AI's brain - characters, locations, facts, style
// This is what makes users never want to leave
// ============================================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';

const _uuid = Uuid();

class EliteProjectMemoryEditor extends StatefulWidget {
  final EliteProject project;
  final EliteProjectService projectService;

  const EliteProjectMemoryEditor({
    super.key,
    required this.project,
    required this.projectService,
  });

  @override
  State<EliteProjectMemoryEditor> createState() => _EliteProjectMemoryEditorState();
}

class _EliteProjectMemoryEditorState extends State<EliteProjectMemoryEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  EliteProject get _project =>
      widget.projectService.getProject(widget.project.id) ?? widget.project;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getTabCount(), vsync: this);
  }

  int _getTabCount() {
    switch (_project.type) {
      case EliteProjectType.novel:
      case EliteProjectType.memoir:
        return 5; // Characters, Locations, Plot Points, Facts, Style
      case EliteProjectType.course:
      case EliteProjectType.blog:
      case EliteProjectType.podcast:
      case EliteProjectType.youtube:
        return 3; // Topics, Facts, Style
      case EliteProjectType.research:
      case EliteProjectType.business:
        return 2; // Facts, Style
      default:
        return 2;
    }
  }

  List<Tab> _getTabs() {
    switch (_project.type) {
      case EliteProjectType.novel:
      case EliteProjectType.memoir:
        return const [
          Tab(text: 'Characters'),
          Tab(text: 'Locations'),
          Tab(text: 'Plot'),
          Tab(text: 'Facts'),
          Tab(text: 'Style'),
        ];
      case EliteProjectType.course:
      case EliteProjectType.blog:
      case EliteProjectType.podcast:
      case EliteProjectType.youtube:
        return const [
          Tab(text: 'Topics'),
          Tab(text: 'Facts'),
          Tab(text: 'Style'),
        ];
      default:
        return const [
          Tab(text: 'Facts'),
          Tab(text: 'Style'),
        ];
    }
  }

  List<Widget> _getTabViews(bool isDark) {
    switch (_project.type) {
      case EliteProjectType.novel:
      case EliteProjectType.memoir:
        return [
          _buildCharactersTab(isDark),
          _buildLocationsTab(isDark),
          _buildPlotPointsTab(isDark),
          _buildFactsTab(isDark),
          _buildStyleTab(isDark),
        ];
      case EliteProjectType.course:
      case EliteProjectType.blog:
      case EliteProjectType.podcast:
      case EliteProjectType.youtube:
        return [
          _buildTopicsTab(isDark),
          _buildFactsTab(isDark),
          _buildStyleTab(isDark),
        ];
      default:
        return [
          _buildFactsTab(isDark),
          _buildStyleTab(isDark),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.psychology, color: _project.type.accentColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'AI Memory',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _project.type.accentColor,
          labelColor: _project.type.accentColor,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          tabs: _getTabs(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _getTabViews(isDark),
      ),
    );
  }

  // ============================================================================
  // CHARACTERS TAB
  // ============================================================================

  Widget _buildCharactersTab(bool isDark) {
    final characters = _project.memory.characters;

    return Column(
      children: [
        _buildTabHeader(
          'Characters',
          'AI remembers these characters across all sections',
          Icons.person,
          isDark,
          onAdd: _addCharacter,
        ),
        Expanded(
          child: characters.isEmpty
              ? _buildEmptyState(
                  'No characters yet',
                  'Add characters to help AI maintain consistency',
                  Icons.person_add,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    return _buildCharacterCard(characters[index], isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(CharacterMemory character, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _project.type.accentColor.withOpacity(0.2),
              child: Text(
                character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _project.type.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              character.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            subtitle: character.description.isNotEmpty
                ? Text(
                    character.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  )
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleCharacterAction(action, character),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          if (character.traits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: character.traits.map((trait) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trait,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _addCharacter() {
    _showCharacterDialog(null);
  }

  void _handleCharacterAction(String action, CharacterMemory character) {
    if (action == 'edit') {
      _showCharacterDialog(character);
    } else if (action == 'delete') {
      _confirmDelete(
        'Delete Character',
        'Are you sure you want to delete "${character.name}"?',
        () => widget.projectService.deleteCharacter(_project.id, character.id),
      );
    }
  }

  void _showCharacterDialog(CharacterMemory? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final traitsController = TextEditingController(text: existing?.traits.join(', ') ?? '');
    final voiceController = TextEditingController(text: existing?.voiceStyle ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add Character' : 'Edit Character',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Name', nameController, 'e.g., Sarah Chen', isDark),
              const SizedBox(height: 12),
              _buildTextField('Description', descController,
                  'e.g., 32-year-old detective with a troubled past', isDark,
                  maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField('Traits (comma separated)', traitsController,
                  'e.g., stubborn, intelligent, compassionate', isDark),
              const SizedBox(height: 12),
              _buildTextField('Voice/Speech Style', voiceController,
                  'e.g., formal, uses technical jargon', isDark),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final character = CharacterMemory(
                          id: existing?.id ?? _uuid.v4(),
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          traits: traitsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList(),
                          voiceStyle: voiceController.text.trim().isEmpty
                              ? null
                              : voiceController.text.trim(),
                        );

                        if (existing == null) {
                          await widget.projectService.addCharacter(_project.id, character);
                        } else {
                          await widget.projectService.updateCharacter(_project.id, character);
                        }

                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _project.type.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(existing == null ? 'Add' : 'Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LOCATIONS TAB
  // ============================================================================

  Widget _buildLocationsTab(bool isDark) {
    final locations = _project.memory.locations;

    return Column(
      children: [
        _buildTabHeader(
          'Locations',
          'Places AI remembers for consistent world-building',
          Icons.place,
          isDark,
          onAdd: _addLocation,
        ),
        Expanded(
          child: locations.isEmpty
              ? _buildEmptyState(
                  'No locations yet',
                  'Add locations to build a consistent world',
                  Icons.add_location_alt,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    return _buildLocationCard(locations[index], isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(LocationMemory location, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, color: _project.type.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'delete') {
                    _confirmDelete(
                      'Delete Location',
                      'Delete "${location.name}"?',
                      () async {
                        final locs = _project.memory.locations
                            .where((l) => l.id != location.id)
                            .toList();
                        await widget.projectService.updateProjectMemory(
                          _project.id,
                          _project.memory.copyWith(locations: locs),
                        );
                        setState(() {});
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          if (location.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              location.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
          if (location.atmosphere != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    location.atmosphere!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addLocation() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final atmosphereController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Name', nameController, 'e.g., The Old Library', isDark),
            const SizedBox(height: 12),
            _buildTextField('Description', descController,
                'e.g., A crumbling Victorian building full of secrets', isDark,
                maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField('Atmosphere', atmosphereController,
                'e.g., dusty, mysterious, quiet', isDark),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;

                      final location = LocationMemory(
                        id: _uuid.v4(),
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        atmosphere: atmosphereController.text.trim().isEmpty
                            ? null
                            : atmosphereController.text.trim(),
                      );

                      final locs = [..._project.memory.locations, location];
                      await widget.projectService.updateProjectMemory(
                        _project.id,
                        _project.memory.copyWith(locations: locs),
                      );

                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _project.type.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PLOT POINTS TAB
  // ============================================================================

  Widget _buildPlotPointsTab(bool isDark) {
    final plotPoints = _project.memory.plotPoints;

    return Column(
      children: [
        _buildTabHeader(
          'Plot Points',
          'Track story events and maintain continuity',
          Icons.timeline,
          isDark,
          onAdd: _addPlotPoint,
        ),
        Expanded(
          child: plotPoints.isEmpty
              ? _buildEmptyState(
                  'No plot points yet',
                  'Track important events in your story',
                  Icons.add_chart,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plotPoints.length,
                  itemBuilder: (context, index) {
                    return _buildPlotPointCard(plotPoints[index], isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlotPointCard(PlotPoint plotPoint, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plotPoint.isResolved
              ? const Color(0xFF10B981).withOpacity(0.3)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final updated = PlotPoint(
                id: plotPoint.id,
                description: plotPoint.description,
                sectionId: plotPoint.sectionId,
                type: plotPoint.type,
                isResolved: !plotPoint.isResolved,
              );
              final points = _project.memory.plotPoints
                  .map((p) => p.id == plotPoint.id ? updated : p)
                  .toList();
              await widget.projectService.updateProjectMemory(
                _project.id,
                _project.memory.copyWith(plotPoints: points),
              );
              setState(() {});
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: plotPoint.isResolved
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: plotPoint.isResolved
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: plotPoint.isResolved
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plotPoint.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
                decoration: plotPoint.isResolved
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPlotTypeColor(plotPoint.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              plotPoint.type.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getPlotTypeColor(plotPoint.type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlotTypeColor(PlotPointType type) {
    switch (type) {
      case PlotPointType.event:
        return const Color(0xFF3B82F6);
      case PlotPointType.revelation:
        return const Color(0xFFF59E0B);
      case PlotPointType.conflict:
        return const Color(0xFFEF4444);
      case PlotPointType.resolution:
        return const Color(0xFF10B981);
      case PlotPointType.foreshadowing:
        return const Color(0xFF8B5CF6);
      case PlotPointType.callback:
        return const Color(0xFFEC4899);
    }
  }

  void _addPlotPoint() {
    final descController = TextEditingController();
    PlotPointType selectedType = PlotPointType.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Plot Point',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Description', descController,
                  'e.g., Sarah discovers the hidden letter', isDark,
                  maxLines: 2),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlotPointType.values.map((type) {
                  final isSelected = type == selectedType;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getPlotTypeColor(type)
                            : _getPlotTypeColor(type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : _getPlotTypeColor(type),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (descController.text.trim().isEmpty) return;

                        await widget.projectService.addPlotPoint(
                          _project.id,
                          PlotPoint(
                            id: _uuid.v4(),
                            description: descController.text.trim(),
                            type: selectedType,
                          ),
                        );

                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _project.type.accentColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TOPICS TAB (for courses, blogs, etc.)
  // ============================================================================

  Widget _buildTopicsTab(bool isDark) {
    final topics = _project.memory.topics;

    return Column(
      children: [
        _buildTabHeader(
          'Topics',
          'Key concepts AI uses for consistent content',
          Icons.topic,
          isDark,
          onAdd: _addTopic,
        ),
        Expanded(
          child: topics.isEmpty
              ? _buildEmptyState(
                  'No topics yet',
                  'Add topics to maintain consistent messaging',
                  Icons.add_box,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (topic.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              topic.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                          if (topic.keyPoints.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: topic.keyPoints.map((point) {
                                return Chip(
                                  label: Text(point, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: isDark
                                      ? const Color(0xFF252525)
                                      : const Color(0xFFF5F5F5),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addTopic() {
    // Similar pattern to other add dialogs
  }

  // ============================================================================
  // FACTS TAB
  // ============================================================================

  Widget _buildFactsTab(bool isDark) {
    final facts = _project.memory.facts;

    return Column(
      children: [
        _buildTabHeader(
          'Key Facts',
          'Important details AI must remember',
          Icons.lightbulb_outline,
          isDark,
          onAdd: _addFactDialog,
        ),
        Expanded(
          child: facts.isEmpty
              ? _buildEmptyState(
                  'No facts yet',
                  'Add facts to ensure AI consistency',
                  Icons.add_circle_outline,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: facts.length,
                  itemBuilder: (context, index) {
                    final fact = facts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: fact.isImportant
                            ? Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.5))
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (fact.isImportant)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text('⚠️', style: TextStyle(fontSize: 14)),
                            ),
                          Expanded(
                            child: Text(
                              fact.fact,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addFactDialog() {
    final controller = TextEditingController();
    bool isImportant = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Fact', controller,
                  'e.g., The war ended in 2045', isDark),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: isImportant,
                onChanged: (v) => setModalState(() => isImportant = v ?? false),
                title: const Text('Mark as important'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;
                        await widget.projectService.addFact(
                          _project.id,
                          FactMemory(
                            id: _uuid.v4(),
                            fact: controller.text.trim(),
                            isImportant: isImportant,
                          ),
                        );
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _project.type.accentColor,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // STYLE TAB
  // ============================================================================

  Widget _buildStyleTab(bool isDark) {
    final style = _project.memory.style;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Writing Style',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These settings guide how AI writes for this project',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildStyleOption('Tone', style.tone, [
            'formal',
            'casual',
            'professional',
            'friendly',
            'witty',
            'serious',
            'inspirational',
          ], isDark),
          const SizedBox(height: 16),
          if (_project.type == EliteProjectType.novel ||
              _project.type == EliteProjectType.memoir) ...[
            _buildStyleOption('Point of View', style.pointOfView, [
              'first person',
              'third person limited',
              'third person omniscient',
              'second person',
            ], isDark),
            const SizedBox(height: 16),
            _buildStyleOption('Tense', style.tense, [
              'past',
              'present',
              'future',
            ], isDark),
            const SizedBox(height: 16),
          ],
          _buildCustomInstructions(style.customInstructions, isDark),
        ],
      ),
    );
  }

  Widget _buildStyleOption(
    String label,
    String? currentValue,
    List<String> options,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = currentValue == option;
            return GestureDetector(
              onTap: () async {
                final newStyle = StyleMemory(
                  tone: label == 'Tone' ? option : _project.memory.style.tone,
                  pointOfView: label == 'Point of View'
                      ? option
                      : _project.memory.style.pointOfView,
                  tense: label == 'Tense' ? option : _project.memory.style.tense,
                  avoidWords: _project.memory.style.avoidWords,
                  preferWords: _project.memory.style.preferWords,
                  customInstructions: _project.memory.style.customInstructions,
                );
                await widget.projectService.updateStyle(_project.id, newStyle);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _project.type.accentColor
                      : (isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomInstructions(String? current, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Instructions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current ?? 'No custom instructions set',
                style: TextStyle(
                  fontSize: 13,
                  color: current == null
                      ? (isDark ? Colors.grey[600] : Colors.grey[500])
                      : (isDark ? Colors.white : Colors.black),
                  fontStyle: current == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _editCustomInstructions,
                child: Text(current == null ? 'Add Instructions' : 'Edit'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editCustomInstructions() {
    final controller = TextEditingController(
      text: _project.memory.style.customInstructions ?? '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              'Custom Instructions',
              controller,
              'e.g., Keep sentences short. Avoid clichés. Use British spelling.',
              isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newStyle = StyleMemory(
                        tone: _project.memory.style.tone,
                        pointOfView: _project.memory.style.pointOfView,
                        tense: _project.memory.style.tense,
                        avoidWords: _project.memory.style.avoidWords,
                        preferWords: _project.memory.style.preferWords,
                        customInstructions: controller.text.trim().isEmpty
                            ? null
                            : controller.text.trim(),
                      );
                      await widget.projectService.updateStyle(_project.id, newStyle);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _project.type.accentColor,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _buildTabHeader(
    String title,
    String subtitle,
    IconData icon,
    bool isDark, {
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _project.type.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _project.type.accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle),
              color: _project.type.accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: isDark ? Colors.grey[700] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _confirmDelete(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
