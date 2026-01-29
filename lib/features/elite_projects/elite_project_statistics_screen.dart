// ============================================================================
// ELITE PROJECT STATISTICS DASHBOARD
// ============================================================================
// Beautiful progress visualization that makes users WANT to write more
// Gamification done right - motivation without being annoying
// ============================================================================

import 'package:flutter/material.dart';
import 'elite_project_models.dart';
import 'elite_project_service.dart';

class EliteProjectStatisticsScreen extends StatefulWidget {
  final EliteProjectService projectService;
  final EliteProject? project; // null = show all projects

  const EliteProjectStatisticsScreen({
    super.key,
    required this.projectService,
    this.project,
  });

  @override
  State<EliteProjectStatisticsScreen> createState() => _EliteProjectStatisticsScreenState();
}

class _EliteProjectStatisticsScreenState extends State<EliteProjectStatisticsScreen> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = widget.project != null
        ? _getProjectStats(widget.project!)
        : ProjectStatistics.fromProjects(widget.projectService.projects);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.project?.name ?? 'Your Statistics',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero stats
            _buildHeroStats(stats, isDark),
            const SizedBox(height: 24),

            // Streak section
            _buildStreakSection(stats, isDark),
            const SizedBox(height: 24),

            // Period selector
            _buildPeriodSelector(isDark),
            const SizedBox(height: 16),

            // Activity chart
            _buildActivityChart(isDark),
            const SizedBox(height: 24),

            // Progress breakdown
            if (widget.project != null)
              _buildProjectProgress(widget.project!, isDark)
            else
              _buildProjectsBreakdown(isDark),
            const SizedBox(height: 24),

            // Achievements
            _buildAchievements(stats, isDark),
            const SizedBox(height: 24),

            // Writing insights
            _buildWritingInsights(stats, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats(ProjectStatistics stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildHeroStatItem(
                  value: _formatNumber(stats.totalWords),
                  label: 'Total Words',
                  icon: Icons.text_fields,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildHeroStatItem(
                  value: stats.totalProjects.toString(),
                  label: 'Projects',
                  icon: Icons.folder_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildHeroStatItem(
                  value: '${(stats.completionRate * 100).toInt()}%',
                  label: 'Completion',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(stats.totalTimeWorked)} total time',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection(ProjectStatistics stats, bool isDark) {
    final hasStreak = stats.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasStreak
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
          width: hasStreak ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: hasStreak
                  ? const Color(0xFFF59E0B).withOpacity(0.15)
                  : (isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                hasStreak ? '🔥' : '❄️',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak ? '${stats.currentStreak} Day Streak!' : 'No Active Streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: hasStreak
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasStreak
                      ? 'Keep going! You\'re on fire!'
                      : 'Write today to start a new streak',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                if (stats.longestStreak > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Longest streak: ${stats.longestStreak} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('week', 'Week', isDark),
          _buildPeriodButton('month', 'Month', isDark),
          _buildPeriodButton('year', 'Year', isDark),
          _buildPeriodButton('all', 'All Time', isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label, bool isDark) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart(bool isDark) {
    // Generate sample data based on selected period
    final days = _selectedPeriod == 'week'
        ? 7
        : _selectedPeriod == 'month'
            ? 30
            : _selectedPeriod == 'year'
                ? 12
                : 52;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Writing Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+12% vs last period',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                _selectedPeriod == 'week' ? 7 : (_selectedPeriod == 'year' ? 12 : 14),
                (index) {
                  // Random heights for demo
                  final height = 20.0 + (index * 7 % 80);
                  final isToday = _selectedPeriod == 'week' && index == 6;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF6366F1)
                                  : (isDark
                                      ? const Color(0xFF333333)
                                      : const Color(0xFFE5E5E5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getBarLabel(index),
                            style: TextStyle(
                              fontSize: 9,
                              color: isToday
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.grey[600] : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBarLabel(int index) {
    if (_selectedPeriod == 'week') {
      return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
    } else if (_selectedPeriod == 'year') {
      return ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][index];
    }
    return '';
  }

  Widget _buildProjectProgress(EliteProject project, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: project.progress.percentComplete,
              minHeight: 12,
              backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5),
              valueColor: AlwaysStoppedAnimation(project.type.accentColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(project.progress.percentComplete * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: project.type.accentColor,
                ),
              ),
              Text(
                '${project.progress.sectionsComplete}/${project.progress.totalSections} sections',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Section status breakdown
          _buildSectionStatusBreakdown(project, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionStatusBreakdown(EliteProject project, bool isDark) {
    final statusCounts = <SectionStatus, int>{};
    void countStatuses(List<ProjectSection> sections) {
      for (final section in sections) {
        statusCounts[section.status] = (statusCounts[section.status] ?? 0) + 1;
        countStatuses(section.children);
      }
    }
    countStatuses(project.structure.sections);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: SectionStatus.values.map((status) {
        final count = statusCounts[status] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                '$count ${status.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: status.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectsBreakdown(bool isDark) {
    final projectsByType = <EliteProjectType, List<EliteProject>>{};
    for (final project in widget.projectService.projects) {
      projectsByType[project.type] ??= [];
      projectsByType[project.type]!.add(project);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projects by Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...projectsByType.entries.map((entry) {
            final type = entry.key;
            final projects = entry.value;
            final totalWords = projects.fold(0, (sum, p) => sum + p.progress.totalWordCount);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: type.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          '${projects.length} projects • ${_formatNumber(totalWords)} words',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements(ProjectStatistics stats, bool isDark) {
    final achievements = _getUnlockedAchievements(stats);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '${achievements.length}/12 unlocked',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) => _buildAchievementBadge(a, isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(_Achievement achievement, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            achievement.color.withOpacity(0.2),
            achievement.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: achievement.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: achievement.color,
                ),
              ),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWritingInsights(ProjectStatistics stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Writing Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            '📝',
            'Average session',
            '${(stats.totalWords / (stats.totalProjects > 0 ? stats.totalProjects : 1) / 10).toInt()} words',
            isDark,
          ),
          _buildInsightRow(
            '⏱️',
            'Best writing time',
            'Morning (9-11am)',
            isDark,
          ),
          _buildInsightRow(
            '📅',
            'Most productive day',
            'Tuesday',
            isDark,
          ),
          _buildInsightRow(
            '🎯',
            'Goal completion rate',
            '${(stats.completionRate * 100).toInt()}%',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String emoji, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  ProjectStatistics _getProjectStats(EliteProject project) {
    return ProjectStatistics(
      totalProjects: 1,
      totalWords: project.progress.totalWordCount,
      totalSections: project.progress.totalSections,
      completedSections: project.progress.sectionsComplete,
      totalTimeWorked: Duration(
        minutes: project.progress.dailyHistory.fold(0, (sum, d) => sum + d.minutesWorked),
      ),
      currentStreak: project.progress.currentStreak,
      longestStreak: project.progress.longestStreak,
      projectsByType: {project.type: 1},
    );
  }

  List<_Achievement> _getUnlockedAchievements(ProjectStatistics stats) {
    final achievements = <_Achievement>[];

    if (stats.totalWords >= 100) {
      achievements.add(_Achievement(
        emoji: '✏️',
        title: 'First Words',
        description: 'Write 100 words',
        color: const Color(0xFF10B981),
      ));
    }
    if (stats.totalWords >= 1000) {
      achievements.add(_Achievement(
        emoji: '📝',
        title: 'Getting Started',
        description: 'Write 1,000 words',
        color: const Color(0xFF3B82F6),
      ));
    }
    if (stats.totalWords >= 10000) {
      achievements.add(_Achievement(
        emoji: '📚',
        title: 'Prolific Writer',
        description: 'Write 10,000 words',
        color: const Color(0xFF8B5CF6),
      ));
    }
    if (stats.totalWords >= 50000) {
      achievements.add(_Achievement(
        emoji: '🏆',
        title: 'NaNoWriMo Ready',
        description: 'Write 50,000 words',
        color: const Color(0xFFF59E0B),
      ));
    }
    if (stats.currentStreak >= 3) {
      achievements.add(_Achievement(
        emoji: '🔥',
        title: 'On Fire',
        description: '3 day streak',
        color: const Color(0xFFEF4444),
      ));
    }
    if (stats.currentStreak >= 7) {
      achievements.add(_Achievement(
        emoji: '⚡',
        title: 'Week Warrior',
        description: '7 day streak',
        color: const Color(0xFFF59E0B),
      ));
    }
    if (stats.longestStreak >= 30) {
      achievements.add(_Achievement(
        emoji: '👑',
        title: 'Streak Master',
        description: '30 day streak',
        color: const Color(0xFFEC4899),
      ));
    }
    if (stats.totalProjects >= 3) {
      achievements.add(_Achievement(
        emoji: '📂',
        title: 'Multi-Tasker',
        description: '3 active projects',
        color: const Color(0xFF6366F1),
      ));
    }
    if (stats.completedSections >= 10) {
      achievements.add(_Achievement(
        emoji: '✅',
        title: 'Section Slayer',
        description: 'Complete 10 sections',
        color: const Color(0xFF10B981),
      ));
    }

    return achievements;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _Achievement {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  _Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
