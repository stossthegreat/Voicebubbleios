import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_state_provider.dart';
import '../../models/outcome_type.dart';
import '../../models/recording_item.dart';
import '../../widgets/multi_option_fab.dart';
import '../../services/analytics_service.dart';
import '../../services/review_service.dart';
import 'recording_screen.dart';
import 'recording_detail_screen.dart';
import 'outcome_creation_screen.dart';
import 'outcome_image_creation_screen.dart';

// ============================================================
//        🔥 ELITE OUTCOMES TAB - WORLD CLASS 🔥
// ============================================================

class OutcomesScreenElite extends StatefulWidget {
  const OutcomesScreenElite({super.key});

  @override
  State<OutcomesScreenElite> createState() => _OutcomesScreenEliteState();
}

class _OutcomesScreenEliteState extends State<OutcomesScreenElite> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'Outcomes');
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabNames = ['All', 'Tasks', 'Content', 'Ideas'];
        if (_tabController.index < tabNames.length) {
          AnalyticsService().logTabSelected(tabName: 'Outcomes_${tabNames[_tabController.index]}');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            final allItems = appState.outcomesItems;
            
            // Calculate stats
            final todayItems = _getTodayItems(allItems);
            final overdueItems = _getOverdueItems(allItems);
            final completedToday = _getCompletedToday(allItems);
            final totalTasks = allItems.where((i) => i.outcomes.contains('task')).length;
            final completedTasks = allItems.where((i) => i.outcomes.contains('task') && (i.isCompleted == true)).length;

            return Column(
              children: [
                // ═══════════════════════════════════════════════════
                // ELITE HEADER WITH STATS
                // ═══════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF000000),
                        const Color(0xFF000000).withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Outcomes',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Get Things Done',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // FOCUS NOW - PRIORITY SECTION
                      if (overdueItems.isNotEmpty || todayItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFEF4444).withOpacity(0.15),
                                const Color(0xFFF59E0B).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.priority_high, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'FOCUS NOW',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (overdueItems.isNotEmpty)
                                    Expanded(
                                      child: _buildFocusChip(
                                        '${overdueItems.length} Overdue',
                                        Icons.warning_rounded,
                                        const Color(0xFFEF4444),
                                      ),
                                    ),
                                  if (overdueItems.isNotEmpty && todayItems.isNotEmpty)
                                    const SizedBox(width: 8),
                                  if (todayItems.isNotEmpty)
                                    Expanded(
                                      child: _buildFocusChip(
                                        '${todayItems.length} Today',
                                        Icons.today_rounded,
                                        const Color(0xFFF59E0B),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // STATS ROW
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              '$completedToday',
                              'today',
                              const Color(0xFF10B981),
                              Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Tasks',
                              '$completedTasks/$totalTasks',
                              totalTasks > 0 ? '${((completedTasks / totalTasks) * 100).toInt()}%' : '0%',
                              const Color(0xFF3B82F6),
                              Icons.assignment_turned_in_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              '${allItems.length}',
                              'items',
                              const Color(0xFF8B5CF6),
                              Icons.dashboard_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════════════
                // TABS (SMART VIEWS)
                // ═══════════════════════════════════════════════════
                Container(
                  color: const Color(0xFF000000),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF3B82F6),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    tabs: const [
                      Tab(text: 'ALL'),
                      Tab(text: 'TASKS'),
                      Tab(text: 'CONTENT'),
                      Tab(text: 'IDEAS'),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════════════
                // TAB VIEWS
                // ═══════════════════════════════════════════════════
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllView(allItems),
                      _buildCategoryView(allItems, OutcomeType.task),
                      _buildCategoryView(allItems, OutcomeType.content),
                      _buildCategoryView(allItems, OutcomeType.idea),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: MultiOptionFab(
        onVoicePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecordingScreen()),
          );
        },
        onTextPressed: () async {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Outcome Document',
            outcomes: [],
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'outcome_document',
            tags: [],
            contentType: 'text',
            hiddenInLibrary: true,
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
        onTodoPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutcomeCreationScreen(contentType: 'todo'),
            ),
          );
        },
        onImagePressed: () async {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          final newItem = RecordingItem(
            id: const Uuid().v4(),
            rawTranscript: '',
            finalText: '',
            presetUsed: 'Outcome Image',
            outcomes: [],
            projectId: null,
            createdAt: DateTime.now(),
            editHistory: [],
            presetId: 'outcome_image',
            tags: [],
            contentType: 'image',
            hiddenInLibrary: true,
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
        onNotePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OutcomeCreationScreen(contentType: 'note'),
            ),
          );
        },
        onProjectPressed: null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // BUILD ALL VIEW
  // ═══════════════════════════════════════════════════
  Widget _buildAllView(List<RecordingItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    // Group by priority
    final overdue = _getOverdueItems(items);
    final today = _getTodayItems(items);
    final upcoming = _getUpcomingItems(items);
    final other = items.where((i) => 
      !overdue.contains(i) && !today.contains(i) && !upcoming.contains(i)
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (overdue.isNotEmpty) ...[
          _buildSectionHeader('🔴 Overdue', overdue.length, const Color(0xFFEF4444)),
          ...overdue.map((item) => _buildEliteCard(item, isOverdue: true)),
          const SizedBox(height: 24),
        ],
        if (today.isNotEmpty) ...[
          _buildSectionHeader('🟡 Today', today.length, const Color(0xFFF59E0B)),
          ...today.map((item) => _buildEliteCard(item)),
          const SizedBox(height: 24),
        ],
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader('🔵 Upcoming', upcoming.length, const Color(0xFF3B82F6)),
          ...upcoming.map((item) => _buildEliteCard(item)),
          const SizedBox(height: 24),
        ],
        if (other.isNotEmpty) ...[
          _buildSectionHeader('⚪️ Other', other.length, const Color(0xFF64748B)),
          ...other.map((item) => _buildEliteCard(item)),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // BUILD CATEGORY VIEW
  // ═══════════════════════════════════════════════════
  Widget _buildCategoryView(List<RecordingItem> items, OutcomeType type) {
    final filtered = items.where((i) => 
      i.outcomes.contains(type.name.toLowerCase())
    ).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(type: type);
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: filtered.map((item) => _buildEliteCard(item)).toList(),
    );
  }

  // ═══════════════════════════════════════════════════
  // ELITE CARD (WORLD CLASS DESIGN)
  // ═══════════════════════════════════════════════════
  Widget _buildEliteCard(RecordingItem item, {bool isOverdue = false}) {
    final outcomeType = item.outcomes.isNotEmpty 
        ? OutcomeTypeExtension.fromString(item.outcomes.first)
        : OutcomeType.note;
    final color = _getColorForType(outcomeType);
    final isCompleted = item.isCompleted == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id),
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Mark as complete
            HapticFeedback.mediumImpact();
            _toggleCompletion(item);
            return false;
          } else {
            // Delete
            HapticFeedback.heavyImpact();
            return await _confirmDelete(item);
          }
        },
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingDetailScreen(recordingId: item.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOverdue 
                    ? const Color(0xFFEF4444).withOpacity(0.5)
                    : color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isOverdue
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Completion checkbox
                    GestureDetector(
                      onTap: () => _toggleCompletion(item),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isCompleted
                              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                              : null,
                          border: Border.all(
                            color: isCompleted ? Colors.transparent : color,
                            width: 2.5,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            outcomeType.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            outcomeType.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Time indicator
                    if (item.reminderDateTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverdue 
                              ? const Color(0xFFEF4444).withOpacity(0.15)
                              : const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(item.reminderDateTime!),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Content
                Text(
                  item.finalText.isNotEmpty ? item.finalText : item.rawTranscript,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isCompleted 
                        ? const Color(0xFF64748B) 
                        : Colors.white,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════

  Widget _buildFocusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({OutcomeType? type}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 64,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            type != null ? 'No ${type.displayName.toLowerCase()} yet' : 'No outcomes yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create your first one',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════

  List<RecordingItem> _getTodayItems(List<RecordingItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      if (item.reminderDateTime == null) return false;
      final reminder = item.reminderDateTime!;
      return reminder.year == now.year &&
          reminder.month == now.month &&
          reminder.day == now.day &&
          item.isCompleted != true;
    }).toList();
  }

  List<RecordingItem> _getOverdueItems(List<RecordingItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      if (item.reminderDateTime == null) return false;
      return item.reminderDateTime!.isBefore(now) && item.isCompleted != true;
    }).toList();
  }

  List<RecordingItem> _getUpcomingItems(List<RecordingItem> items) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return items.where((item) {
      if (item.reminderDateTime == null) return false;
      final reminder = item.reminderDateTime!;
      return reminder.isAfter(now) &&
          reminder.isBefore(tomorrow.add(const Duration(days: 7))) &&
          item.isCompleted != true;
    }).toList();
  }

  List<RecordingItem> _getCompletedToday(List<RecordingItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      if (item.isCompleted != true) return false;
      // Assuming there's a completedAt field, otherwise use createdAt
      final completedDate = item.createdAt;
      return completedDate.year == now.year &&
          completedDate.month == now.month &&
          completedDate.day == now.day;
    }).toList();
  }

  Color _getColorForType(OutcomeType type) {
    switch (type) {
      case OutcomeType.message:
        return const Color(0xFF3B82F6);
      case OutcomeType.content:
        return const Color(0xFF8B5CF6);
      case OutcomeType.task:
        return const Color(0xFF10B981);
      case OutcomeType.idea:
        return const Color(0xFFF59E0B);
      case OutcomeType.note:
        return const Color(0xFF64748B);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);
    
    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  void _toggleCompletion(RecordingItem item) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final newStatus = !(item.isCompleted ?? false);
    final updated = item.copyWith(isCompleted: newStatus);
    await appState.updateRecording(updated);
    HapticFeedback.mediumImpact();

    if (newStatus) {
      AnalyticsService().logOutcomeCompleted(
        outcomeType: item.outcomes.isNotEmpty
          ? item.outcomes.first.toString()
          : 'generic',
      );
      await ReviewService().trackOutcomeCompletion();
    }

    setState(() {});
  }

  Future<bool> _confirmDelete(RecordingItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Item?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appState = Provider.of<AppStateProvider>(context, listen: false);
              await appState.deleteRecording(item.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    ) ?? false;
  }
}
