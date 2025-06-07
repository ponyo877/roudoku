class ReadingStatistics {
  final String userId;
  final int totalBooksRead;
  final int totalReadingTimeMinutes;
  final ReadingStreak? currentStreak;
  final ReadingStreak? longestStreak;
  final double averageReadingSpeedWpm;
  final List<GenreStats> favoriteGenres;
  final List<Achievement> recentAchievements;
  final List<ReadingGoal> activeGoals;
  final MonthlyReadingSummary monthlyProgress;
  final List<DailyReadingStats> weeklyReadingTime;

  ReadingStatistics({
    required this.userId,
    required this.totalBooksRead,
    required this.totalReadingTimeMinutes,
    this.currentStreak,
    this.longestStreak,
    required this.averageReadingSpeedWpm,
    required this.favoriteGenres,
    required this.recentAchievements,
    required this.activeGoals,
    required this.monthlyProgress,
    required this.weeklyReadingTime,
  });

  factory ReadingStatistics.fromJson(Map<String, dynamic> json) {
    return ReadingStatistics(
      userId: json['user_id'] ?? '',
      totalBooksRead: json['total_books_read'] ?? 0,
      totalReadingTimeMinutes: json['total_reading_time_minutes'] ?? 0,
      currentStreak: json['current_streak'] != null 
          ? ReadingStreak.fromJson(json['current_streak']) 
          : null,
      longestStreak: json['longest_streak'] != null 
          ? ReadingStreak.fromJson(json['longest_streak']) 
          : null,
      averageReadingSpeedWpm: (json['average_reading_speed_wpm'] ?? 0).toDouble(),
      favoriteGenres: (json['favorite_genres'] as List? ?? [])
          .map((item) => GenreStats.fromJson(item))
          .toList(),
      recentAchievements: (json['recent_achievements'] as List? ?? [])
          .map((item) => Achievement.fromJson(item))
          .toList(),
      activeGoals: (json['active_goals'] as List? ?? [])
          .map((item) => ReadingGoal.fromJson(item))
          .toList(),
      monthlyProgress: MonthlyReadingSummary.fromJson(json['monthly_progress'] ?? {}),
      weeklyReadingTime: (json['weekly_reading_time'] as List? ?? [])
          .map((item) => DailyReadingStats.fromJson(item))
          .toList(),
    );
  }

  String get formattedReadingTime {
    final hours = totalReadingTimeMinutes ~/ 60;
    final minutes = totalReadingTimeMinutes % 60;
    return '${hours}時間${minutes}分';
  }

  double get averageSessionLength {
    if (weeklyReadingTime.isEmpty) return 0.0;
    final totalSessions = weeklyReadingTime.fold<int>(0, (sum, day) => sum + day.sessionsCount);
    return totalSessions > 0 ? totalReadingTimeMinutes / totalSessions : 0.0;
  }
}

class ReadingStreak {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int streakDays;
  final bool isActive;

  ReadingStreak({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.streakDays,
    required this.isActive,
  });

  factory ReadingStreak.fromJson(Map<String, dynamic> json) {
    return ReadingStreak(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      streakDays: json['streak_days'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}

class GenreStats {
  final String genre;
  final int booksReadCount;
  final int totalReadingTimeMinutes;
  final double? averageRating;
  final DateTime? lastReadAt;

  GenreStats({
    required this.genre,
    required this.booksReadCount,
    required this.totalReadingTimeMinutes,
    this.averageRating,
    this.lastReadAt,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) {
    return GenreStats(
      genre: json['genre'] ?? '',
      booksReadCount: json['books_read_count'] ?? 0,
      totalReadingTimeMinutes: json['total_reading_time_minutes'] ?? 0,
      averageRating: json['average_rating']?.toDouble(),
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at']) 
          : null,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String achievementType;
  final int? requirementValue;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.achievementType,
    this.requirementValue,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? json['achievement_id'] ?? '',
      name: json['name'] ?? json['achievement']?['name'] ?? '',
      description: json['description'] ?? json['achievement']?['description'] ?? '',
      iconUrl: json['icon_url'] ?? json['achievement']?['icon_url'],
      achievementType: json['achievement_type'] ?? json['achievement']?['achievement_type'] ?? '',
      requirementValue: json['requirement_value'] ?? json['achievement']?['requirement_value'],
      earnedAt: json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
    );
  }
}

class ReadingGoal {
  final String id;
  final String userId;
  final String goalType;
  final int targetValue;
  final int currentProgress;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  ReadingGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentProgress,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      goalType: json['goal_type'] ?? '',
      targetValue: json['target_value'] ?? 0,
      currentProgress: json['current_progress'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? false,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }

  String get progressText {
    switch (goalType) {
      case 'daily_minutes':
        return '$currentProgress / $targetValue 分';
      case 'weekly_books':
        return '$currentProgress / $targetValue 冊';
      case 'monthly_chapters':
        return '$currentProgress / $targetValue 章';
      case 'yearly_books':
        return '$currentProgress / $targetValue 冊';
      default:
        return '$currentProgress / $targetValue';
    }
  }

  String get goalTypeDisplayName {
    switch (goalType) {
      case 'daily_minutes':
        return '1日の読書時間';
      case 'weekly_books':
        return '週間読書冊数';
      case 'monthly_chapters':
        return '月間読書章数';
      case 'yearly_books':
        return '年間読書冊数';
      default:
        return goalType;
    }
  }
}

class MonthlyReadingSummary {
  final int year;
  final int month;
  final int totalBooksRead;
  final int totalReadingTimeMinutes;
  final int totalWordsRead;
  final double? averageSessionLengthMinutes;
  final String? favoriteGenre;
  final int? longestReadingSessionMinutes;
  final int readingStreakDays;
  final int goalsAchievedCount;
  final int newAchievementsCount;

  MonthlyReadingSummary({
    required this.year,
    required this.month,
    required this.totalBooksRead,
    required this.totalReadingTimeMinutes,
    required this.totalWordsRead,
    this.averageSessionLengthMinutes,
    this.favoriteGenre,
    this.longestReadingSessionMinutes,
    required this.readingStreakDays,
    required this.goalsAchievedCount,
    required this.newAchievementsCount,
  });

  factory MonthlyReadingSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyReadingSummary(
      year: json['year'] ?? DateTime.now().year,
      month: json['month'] ?? DateTime.now().month,
      totalBooksRead: json['total_books_read'] ?? 0,
      totalReadingTimeMinutes: json['total_reading_time_minutes'] ?? 0,
      totalWordsRead: json['total_words_read'] ?? 0,
      averageSessionLengthMinutes: json['average_session_length_minutes']?.toDouble(),
      favoriteGenre: json['favorite_genre'],
      longestReadingSessionMinutes: json['longest_reading_session_minutes'],
      readingStreakDays: json['reading_streak_days'] ?? 0,
      goalsAchievedCount: json['goals_achieved_count'] ?? 0,
      newAchievementsCount: json['new_achievements_count'] ?? 0,
    );
  }

  String get monthName {
    const monthNames = [
      '', '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    return month > 0 && month <= 12 ? monthNames[month] : '$month月';
  }
}

class DailyReadingStats {
  final String userId;
  final DateTime date;
  final int totalReadingTimeMinutes;
  final int booksReadCount;
  final int chaptersCompleted;
  final int wordsReadCount;
  final double? averageReadingSpeedWpm;
  final int sessionsCount;

  DailyReadingStats({
    required this.userId,
    required this.date,
    required this.totalReadingTimeMinutes,
    required this.booksReadCount,
    required this.chaptersCompleted,
    required this.wordsReadCount,
    this.averageReadingSpeedWpm,
    required this.sessionsCount,
  });

  factory DailyReadingStats.fromJson(Map<String, dynamic> json) {
    return DailyReadingStats(
      userId: json['user_id'] ?? '',
      date: DateTime.parse(json['date']),
      totalReadingTimeMinutes: json['total_reading_time_minutes'] ?? 0,
      booksReadCount: json['books_read_count'] ?? 0,
      chaptersCompleted: json['chapters_completed'] ?? 0,
      wordsReadCount: json['words_read_count'] ?? 0,
      averageReadingSpeedWpm: json['average_reading_speed_wpm']?.toDouble(),
      sessionsCount: json['sessions_count'] ?? 0,
    );
  }

  String get formattedDate {
    return '${date.month}/${date.day}';
  }

  String get dayOfWeek {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }
}

class CreateReadingGoalRequest {
  final String goalType;
  final int targetValue;
  final DateTime startDate;
  final DateTime? endDate;

  CreateReadingGoalRequest({
    required this.goalType,
    required this.targetValue,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'goal_type': goalType,
      'target_value': targetValue,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
    };
  }
}

class UpdateReadingGoalRequest {
  final int? targetValue;
  final int? currentProgress;
  final DateTime? endDate;
  final bool? isActive;

  UpdateReadingGoalRequest({
    this.targetValue,
    this.currentProgress,
    this.endDate,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (targetValue != null) json['target_value'] = targetValue;
    if (currentProgress != null) json['current_progress'] = currentProgress;
    if (endDate != null) json['end_date'] = endDate!.toIso8601String();
    if (isActive != null) json['is_active'] = isActive;
    return json;
  }
}

class ReadingInsight {
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic>? data;
  final String priority;
  final DateTime createdAt;

  ReadingInsight({
    required this.type,
    required this.title,
    required this.description,
    this.data,
    required this.priority,
    required this.createdAt,
  });

  factory ReadingInsight.fromJson(Map<String, dynamic> json) {
    return ReadingInsight(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReadingSession {
  final String id;
  final String userId;
  final String bookId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int startPosition;
  final int endPosition;
  final String? mood;
  final String? weather;
  final String? location;

  ReadingSession({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.startPosition,
    required this.endPosition,
    this.mood,
    this.weather,
    this.location,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      bookId: json['book_id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'] ?? 0,
      startPosition: json['start_position'] ?? 0,
      endPosition: json['end_position'] ?? 0,
      mood: json['mood'],
      weather: json['weather'],
      location: json['location'],
    );
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) => ReadingSession.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'duration_minutes': durationMinutes,
      'start_position': startPosition,
      'end_position': endPosition,
      if (mood != null) 'mood': mood,
      if (weather != null) 'weather': weather,
      if (location != null) 'location': location,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  bool get isActive => endTime == null;

  double get progressPercentage {
    if (endPosition <= startPosition) return 0.0;
    return ((endPosition - startPosition) / endPosition * 100).clamp(0.0, 100.0);
  }
}