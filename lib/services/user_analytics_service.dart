import '../models/recording_item.dart';
import '../models/tag.dart';

class UserAnalyticsData {
  final int totalNotes;
  final int totalWords;
  final int notesThisWeek;
  final int wordsThisWeek;
  final int notesThisMonth;
  final String mostActiveDay;
  final int mostActiveDayCount;
  final Map<String, int> topTags;
  final Map<String, int> notesByPreset;
  final int currentStreak;
  final int longestStreak;
  final double averageNoteLength;
  final Map<DateTime, int> dailyActivity; // Last 30 days

  UserAnalyticsData({
    required this.totalNotes,
    required this.totalWords,
    required this.notesThisWeek,
    required this.wordsThisWeek,
    required this.notesThisMonth,
    required this.mostActiveDay,
    required this.mostActiveDayCount,
    required this.topTags,
    required this.notesByPreset,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageNoteLength,
    required this.dailyActivity,
  });
}

class UserAnalyticsService {
  // Calculate comprehensive analytics
  UserAnalyticsData calculateAnalytics(List<RecordingItem> allNotes, List<Tag> allTags) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    // Basic counts
    final totalNotes = allNotes.length;
    final totalWords = _countTotalWords(allNotes);

    // This week
    final notesThisWeek = allNotes.where((n) => n.createdAt.isAfter(weekAgo)).length;
    final wordsThisWeek = _countTotalWords(
      allNotes.where((n) => n.createdAt.isAfter(weekAgo)).toList(),
    );

    // This month
    final notesThisMonth = allNotes.where((n) => n.createdAt.isAfter(monthAgo)).length;

    // Most active day
    final dayActivity = _calculateDayActivity(allNotes);
    final mostActiveDay = _getMostActiveDay(dayActivity);
    final mostActiveDayCount = dayActivity[mostActiveDay] ?? 0;

    // Top tags
    final topTags = _calculateTopTags(allNotes, allTags);

    // Notes by preset
    final notesByPreset = _calculateNotesByPreset(allNotes);

    // Streaks
    final currentStreak = _calculateCurrentStreak(allNotes);
    final longestStreak = _calculateLongestStreak(allNotes);

    // Average note length
    final averageNoteLength = totalNotes > 0 ? totalWords / totalNotes : 0.0;

    // Daily activity (last 30 days)
    final dailyActivity = _calculateDailyActivity(allNotes, 30);

    return UserAnalyticsData(
      totalNotes: totalNotes,
      totalWords: totalWords,
      notesThisWeek: notesThisWeek,
      wordsThisWeek: wordsThisWeek,
      notesThisMonth: notesThisMonth,
      mostActiveDay: mostActiveDay,
      mostActiveDayCount: mostActiveDayCount,
      topTags: topTags,
      notesByPreset: notesByPreset,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      averageNoteLength: averageNoteLength,
      dailyActivity: dailyActivity,
    );
  }

  // Count total words in notes
  int _countTotalWords(List<RecordingItem> notes) {
    int total = 0;
    for (var note in notes) {
      total += note.finalText.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
    return total;
  }

  // Calculate activity by day of week
  Map<String, int> _calculateDayActivity(List<RecordingItem> notes) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final activity = <String, int>{};
    
    for (var day in days) {
      activity[day] = 0;
    }

    for (var note in notes) {
      final dayIndex = note.createdAt.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        final dayName = days[dayIndex];
        activity[dayName] = (activity[dayName] ?? 0) + 1;
      }
    }

    return activity;
  }

  // Get most active day
  String _getMostActiveDay(Map<String, int> dayActivity) {
    if (dayActivity.isEmpty) return 'No data';
    
    String mostActive = dayActivity.keys.first;
    int maxCount = dayActivity.values.first;

    dayActivity.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActive = day;
      }
    });

    return mostActive;
  }

  // Calculate top tags
  Map<String, int> _calculateTopTags(List<RecordingItem> notes, List<Tag> allTags) {
    final tagCounts = <String, int>{};

    for (var note in notes) {
      for (var tagId in note.tags) {
        // Find tag name
        final tag = allTags.where((t) => t.id == tagId).firstOrNull;
        if (tag != null) {
          tagCounts[tag.name] = (tagCounts[tag.name] ?? 0) + 1;
        }
      }
    }

    // Sort and get top 5
    final sortedEntries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(5));
  }

  // Calculate notes by preset
  Map<String, int> _calculateNotesByPreset(List<RecordingItem> notes) {
    final presetCounts = <String, int>{};

    for (var note in notes) {
      final preset = note.presetUsed;
      presetCounts[preset] = (presetCounts[preset] ?? 0) + 1;
    }

    // Sort and get top 5
    final sortedEntries = presetCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(5));
  }

  // Calculate current streak (consecutive days with notes)
  int _calculateCurrentStreak(List<RecordingItem> notes) {
    if (notes.isEmpty) return 0;

    final sortedNotes = notes.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final today = DateTime.now();
    final latestNote = sortedNotes.first.createdAt;

    // If no note today or yesterday, streak is 0
    if (!_isSameDay(latestNote, today) && 
        !_isSameDay(latestNote, today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = today;

    for (var i = 0; i < 365; i++) { // Max check 1 year
      final hasNoteOnDay = sortedNotes.any((n) => _isSameDay(n.createdAt, checkDate));
      
      if (hasNoteOnDay) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Calculate longest streak ever
  int _calculateLongestStreak(List<RecordingItem> notes) {
    if (notes.isEmpty) return 0;

    final sortedNotes = notes.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int longestStreak = 1;
    int currentStreak = 1;
    DateTime? lastDate;

    for (var note in sortedNotes) {
      if (lastDate == null) {
        lastDate = note.createdAt;
        continue;
      }

      final daysDiff = _daysBetween(lastDate, note.createdAt);

      if (daysDiff == 1) {
        // Consecutive day
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else if (daysDiff > 1) {
        // Gap in streak
        currentStreak = 1;
      }
      // If same day, don't reset streak

      lastDate = note.createdAt;
    }

    return longestStreak;
  }

  // Calculate daily activity for last N days
  Map<DateTime, int> _calculateDailyActivity(List<RecordingItem> notes, int days) {
    final activity = <DateTime, int>{};
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      activity[date] = 0;
    }

    for (var note in notes) {
      final noteDate = DateTime(
        note.createdAt.year,
        note.createdAt.month,
        note.createdAt.day,
      );
      
      if (activity.containsKey(noteDate)) {
        activity[noteDate] = activity[noteDate]! + 1;
      }
    }

    return activity;
  }

  // Helper: Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Helper: Calculate days between two dates
  int _daysBetween(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return bDate.difference(aDate).inDays;
  }
}
