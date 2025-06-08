import 'package:flutter/material.dart';
import '../models/reading_analytics.dart';
import '../services/api_service.dart';

class ReadingAnalyticsProvider with ChangeNotifier {
  final ApiService _apiService;
  
  ReadingStatistics? _statistics;
  List<Achievement> _allAchievements = [];
  List<ReadingGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;

  ReadingAnalyticsProvider({required ApiService apiService}) 
      : _apiService = apiService;

  // Getters
  ReadingStatistics? get statistics => _statistics;
  List<Achievement> get allAchievements => _allAchievements;
  List<ReadingGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load comprehensive reading statistics
  Future<void> loadReadingStatistics() async {
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.get('/reading-logs/stats');
      _statistics = ReadingStatistics.fromJson(response);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading reading statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new reading goal
  Future<ReadingGoal> createReadingGoal(CreateReadingGoalRequest request) async {
    try {
      final response = await _apiService.post('/reading-logs/goals', data: request.toJson());
      final goal = ReadingGoal.fromJson(response);
      
      // Update local state
      if (_statistics != null) {
        _statistics!.activeGoals.add(goal);
        notifyListeners();
      }
      
      return goal;
    } catch (e) {
      debugPrint('Error creating reading goal: $e');
      rethrow;
    }
  }

  // Update an existing reading goal
  Future<ReadingGoal> updateReadingGoal(String goalId, UpdateReadingGoalRequest request) async {
    try {
      final response = await _apiService.put('/reading-logs/goals/$goalId', data: request.toJson());
      final updatedGoal = ReadingGoal.fromJson(response);
      
      // Update local state
      if (_statistics != null) {
        final index = _statistics!.activeGoals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          _statistics!.activeGoals[index] = updatedGoal;
          notifyListeners();
        }
      }
      
      return updatedGoal;
    } catch (e) {
      debugPrint('Error updating reading goal: $e');
      rethrow;
    }
  }

  // Delete a reading goal
  Future<void> deleteReadingGoal(String goalId) async {
    try {
      await _apiService.delete('/reading-logs/goals/$goalId');
      
      // Update local state
      if (_statistics != null) {
        _statistics!.activeGoals.removeWhere((goal) => goal.id == goalId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting reading goal: $e');
      rethrow;
    }
  }

  // Load all achievements
  Future<void> loadAllAchievements() async {
    try {
      final response = await _apiService.get('/reading-logs/achievements?limit=100');
      _allAchievements = (response['achievements'] as List? ?? [])
          .map((item) => Achievement.fromJson(item))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      rethrow;
    }
  }

  // Get daily reading statistics for a date range
  Future<List<DailyReadingStats>> getDailyStats(DateTime startDate, DateTime endDate) async {
    try {
      final start = startDate.toIso8601String().split('T')[0];
      final end = endDate.toIso8601String().split('T')[0];
      
      final response = await _apiService.get('/reading-logs/daily-stats?start_date=$start&end_date=$end');
      return (response['daily_stats'] as List? ?? [])
          .map((item) => DailyReadingStats.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
      return [];
    }
  }

  // Get weekly reading report
  Future<Map<String, dynamic>?> getWeeklyReport(DateTime weekStart) async {
    try {
      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final response = await _apiService.get('/reading-logs/weekly-report?week_start=$weekStartStr');
      return response;
    } catch (e) {
      debugPrint('Error loading weekly report: $e');
      return null;
    }
  }

  // Get monthly reading report
  Future<MonthlyReadingSummary?> getMonthlyReport(int year, int month) async {
    try {
      final response = await _apiService.get('/reading-logs/monthly-report?year=$year&month=$month');
      return MonthlyReadingSummary.fromJson(response);
    } catch (e) {
      debugPrint('Error loading monthly report: $e');
      return null;
    }
  }

  // Get reading insights
  Future<List<ReadingInsight>> getReadingInsights() async {
    try {
      final response = await _apiService.get('/reading-logs/insights');
      return (response['insights'] as List? ?? [])
          .map((item) => ReadingInsight.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading reading insights: $e');
      return [];
    }
  }

  // Record a reading session
  Future<void> recordReadingSession({
    required String sessionId,
    required String bookId,
    required int readingTimeMinutes,
    required int chaptersRead,
    required int wordsRead,
    required double averageReadingSpeedWpm,
    Map<String, dynamic>? engagementMetrics,
  }) async {
    try {
      final sessionData = {
        'session_id': sessionId,
        'book_id': int.parse(bookId),
        'reading_time_minutes': readingTimeMinutes,
        'chapters_read': chaptersRead,
        'words_read': wordsRead,
        'average_reading_speed_wpm': averageReadingSpeedWpm,
        'engagement_metrics': engagementMetrics ?? {},
        'started_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      };

      await _apiService.post('/reading-logs/sessions', data: sessionData);
      
      // Refresh statistics after recording session
      await loadReadingStatistics();
    } catch (e) {
      debugPrint('Error recording reading session: $e');
      rethrow;
    }
  }

  // Get reading streak information
  Future<Map<String, dynamic>?> getReadingStreaks() async {
    try {
      final response = await _apiService.get('/reading-logs/streaks');
      return response;
    } catch (e) {
      debugPrint('Error loading reading streaks: $e');
      return null;
    }
  }

  // Get genre statistics
  Future<List<GenreStats>> getGenreStats() async {
    try {
      final response = await _apiService.get('/reading-logs/genre-stats');
      return (response['genre_stats'] as List? ?? [])
          .map((item) => GenreStats.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading genre stats: $e');
      return [];
    }
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Calculate progress for specific goal types
  double calculateGoalProgress(ReadingGoal goal) {
    if (_statistics == null) return 0.0;
    
    switch (goal.goalType) {
      case 'daily_minutes':
        // For daily goals, calculate based on today's reading time
        final today = DateTime.now();
        final todayStats = _statistics!.weeklyReadingTime.firstWhere(
          (stat) => stat.date.day == today.day && 
                   stat.date.month == today.month && 
                   stat.date.year == today.year,
          orElse: () => DailyReadingStats(
            userId: _statistics!.userId,
            date: today,
            totalReadingTimeMinutes: 0,
            booksReadCount: 0,
            chaptersCompleted: 0,
            wordsReadCount: 0,
            sessionsCount: 0,
          ),
        );
        return (todayStats.totalReadingTimeMinutes / goal.targetValue * 100).clamp(0.0, 100.0);
        
      case 'weekly_books':
        // Calculate based on current week's book completion
        final weeklyBooks = _statistics!.weeklyReadingTime
            .fold<int>(0, (sum, stat) => sum + stat.booksReadCount);
        return (weeklyBooks / goal.targetValue * 100).clamp(0.0, 100.0);
        
      case 'monthly_chapters':
        // Use current progress from goal
        return goal.progressPercentage;
        
      case 'yearly_books':
        // Use current progress from goal
        return goal.progressPercentage;
        
      default:
        return goal.progressPercentage;
    }
  }

  // Get achievement progress
  Map<String, double> getAchievementProgress() {
    if (_statistics == null) return {};
    
    final progress = <String, double>{};
    
    // Books read achievements
    final totalBooks = _statistics!.totalBooksRead;
    progress['first_book'] = totalBooks >= 1 ? 100.0 : (totalBooks / 1 * 100);
    progress['bookworm'] = totalBooks >= 10 ? 100.0 : (totalBooks / 10 * 100);
    progress['scholar'] = totalBooks >= 50 ? 100.0 : (totalBooks / 50 * 100);
    progress['reading_master'] = totalBooks >= 100 ? 100.0 : (totalBooks / 100 * 100);
    
    // Streak achievements
    final currentStreak = _statistics!.currentStreak?.streakDays ?? 0;
    progress['consistent_reader'] = currentStreak >= 7 ? 100.0 : (currentStreak / 7 * 100);
    progress['reading_streak'] = currentStreak >= 30 ? 100.0 : (currentStreak / 30 * 100);
    
    // Speed achievements
    final avgSpeed = _statistics!.averageReadingSpeedWpm;
    progress['speed_reader'] = avgSpeed >= 300 ? 100.0 : (avgSpeed / 300 * 100);
    
    return progress;
  }

  // Get reading summary for specific period
  Map<String, dynamic> getReadingSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (_statistics == null) {
      return {
        'total_reading_time': 0,
        'books_completed': 0,
        'chapters_read': 0,
        'average_session_length': 0.0,
        'streak_days': 0,
      };
    }

    final relevantStats = _statistics!.weeklyReadingTime.where((stat) =>
        stat.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        stat.date.isBefore(endDate.add(const Duration(days: 1))));

    final totalReadingTime = relevantStats.fold<int>(
        0, (sum, stat) => sum + stat.totalReadingTimeMinutes);
    final booksCompleted = relevantStats.fold<int>(
        0, (sum, stat) => sum + stat.booksReadCount);
    final chaptersRead = relevantStats.fold<int>(
        0, (sum, stat) => sum + stat.chaptersCompleted);
    final totalSessions = relevantStats.fold<int>(
        0, (sum, stat) => sum + stat.sessionsCount);

    return {
      'total_reading_time': totalReadingTime,
      'books_completed': booksCompleted,
      'chapters_read': chaptersRead,
      'average_session_length': totalSessions > 0 ? totalReadingTime / totalSessions : 0.0,
      'streak_days': _statistics!.currentStreak?.streakDays ?? 0,
    };
  }

  // Check if user has achieved daily goal
  bool hasAchievedDailyGoal() {
    if (_statistics == null) return false;
    
    final dailyGoals = _statistics!.activeGoals.where((goal) => goal.goalType == 'daily_minutes');
    if (dailyGoals.isEmpty) return false;
    
    for (final goal in dailyGoals) {
      final progress = calculateGoalProgress(goal);
      if (progress >= 100.0) return true;
    }
    
    return false;
  }

  // Get reading recommendations based on statistics
  List<String> getReadingRecommendations() {
    if (_statistics == null) return [];
    
    final recommendations = <String>[];
    
    // Check reading frequency
    final avgDailyTime = _statistics!.weeklyReadingTime.isNotEmpty
        ? _statistics!.weeklyReadingTime.fold<int>(0, (sum, stat) => sum + stat.totalReadingTimeMinutes) / 7
        : 0;
    
    if (avgDailyTime < 15) {
      recommendations.add('1日15分の読書習慣を身につけましょう');
    }
    
    // Check reading streak
    final currentStreak = _statistics!.currentStreak?.streakDays ?? 0;
    if (currentStreak == 0) {
      recommendations.add('今日から読書を始めて連続記録を作りましょう');
    } else if (currentStreak < 7) {
      recommendations.add('7日連続読書を目指しましょう');
    }
    
    // Check goal completion
    final incompleteGoals = _statistics!.activeGoals.where((goal) => goal.progressPercentage < 100);
    if (incompleteGoals.isNotEmpty) {
      recommendations.add('設定した読書目標の達成を目指しましょう');
    }
    
    // Check genre diversity
    if (_statistics!.favoriteGenres.length < 3) {
      recommendations.add('様々なジャンルの本を読んでみましょう');
    }
    
    return recommendations;
  }
}