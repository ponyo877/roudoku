import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'book.dart';

part 'swipe.g.dart';

/// Swipe interaction modes
enum SwipeMode {
  @JsonValue('tinder')
  tinder,
  @JsonValue('facemash')
  facemash,
}

/// Swipe direction for UI interactions
enum SwipeDirection {
  left,
  right,
  up,
  down,
}

/// Swipe choice options
enum SwipeChoice {
  @JsonValue(-1)
  skip(-1),
  @JsonValue(0)
  dislike(0),
  @JsonValue(1)
  like(1),
  @JsonValue(2)
  love(2);

  const SwipeChoice(this.value);
  final int value;

  bool get isPositive => this == like || this == love;
  bool get isNegative => this == dislike;
  bool get isNeutral => this == skip;

  double get score {
    switch (this) {
      case love:
        return 1.0;
      case like:
        return 0.5;
      case skip:
        return 0.0;
      case dislike:
        return -0.5;
    }
  }

  String get displayName {
    switch (this) {
      case love:
        return 'Love';
      case like:
        return 'Like';
      case skip:
        return 'Skip';
      case dislike:
        return 'Dislike';
    }
  }
}

/// Context data for swipe interactions
@JsonSerializable()
class ContextData {
  // Location context
  final double? latitude;
  final double? longitude;
  final String? location;

  // Weather context
  @JsonKey(name: 'weather_condition')
  final String? weatherCondition;
  final double? temperature;
  final double? humidity;

  // Time context
  @JsonKey(name: 'time_of_day')
  final String timeOfDay;
  @JsonKey(name: 'day_of_week')
  final String dayOfWeek;
  @JsonKey(name: 'is_weekend')
  final bool isWeekend;
  @JsonKey(name: 'is_holiday')
  final bool? isHoliday;

  // User-provided context
  @JsonKey(name: 'user_mood')
  final String? userMood;
  @JsonKey(name: 'user_situation')
  final String? userSituation;
  @JsonKey(name: 'available_time')
  final int? availableTime;

  // Device context
  @JsonKey(name: 'battery_level')
  final double? batteryLevel;
  @JsonKey(name: 'is_charging')
  final bool? isCharging;
  @JsonKey(name: 'connection_type')
  final String? connectionType;
  @JsonKey(name: 'device_motion')
  final String? deviceMotion;
  @JsonKey(name: 'screen_brightness')
  final double? screenBrightness;

  const ContextData({
    this.latitude,
    this.longitude,
    this.location,
    this.weatherCondition,
    this.temperature,
    this.humidity,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.isWeekend,
    this.isHoliday,
    this.userMood,
    this.userSituation,
    this.availableTime,
    this.batteryLevel,
    this.isCharging,
    this.connectionType,
    this.deviceMotion,
    this.screenBrightness,
  });

  factory ContextData.fromJson(Map<String, dynamic> json) =>
      _$ContextDataFromJson(json);

  factory ContextData.fromMap(Map<String, dynamic> map) => ContextData.fromJson(map);

  Map<String, dynamic> toJson() => _$ContextDataToJson(this);

  Map<String, dynamic> toMap() => toJson();

  ContextData copyWith({
    double? latitude,
    double? longitude,
    String? location,
    String? weatherCondition,
    double? temperature,
    double? humidity,
    String? timeOfDay,
    String? dayOfWeek,
    bool? isWeekend,
    bool? isHoliday,
    String? userMood,
    String? userSituation,
    int? availableTime,
    double? batteryLevel,
    bool? isCharging,
    String? connectionType,
    String? deviceMotion,
    double? screenBrightness,
  }) {
    return ContextData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isWeekend: isWeekend ?? this.isWeekend,
      isHoliday: isHoliday ?? this.isHoliday,
      userMood: userMood ?? this.userMood,
      userSituation: userSituation ?? this.userSituation,
      availableTime: availableTime ?? this.availableTime,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      connectionType: connectionType ?? this.connectionType,
      deviceMotion: deviceMotion ?? this.deviceMotion,
      screenBrightness: screenBrightness ?? this.screenBrightness,
    );
  }
}

/// Quote with associated book information for swiping
@JsonSerializable()
class QuoteWithBook {
  final Quote quote;
  final Book book;

  const QuoteWithBook({
    required this.quote,
    required this.book,
  });

  factory QuoteWithBook.fromJson(Map<String, dynamic> json) =>
      _$QuoteWithBookFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteWithBookToJson(this);
}

/// Quote pair for comparison
@JsonSerializable()
class QuotePair {
  final String id;
  @JsonKey(name: 'quote_a')
  final QuoteWithBook quoteA;
  @JsonKey(name: 'quote_b')
  final QuoteWithBook quoteB;

  const QuotePair({
    required this.id,
    required this.quoteA,
    required this.quoteB,
  });

  factory QuotePair.fromJson(Map<String, dynamic> json) =>
      _$QuotePairFromJson(json);

  Map<String, dynamic> toJson() => _$QuotePairToJson(this);
}

/// Request for swipe quotes
@JsonSerializable()
class SwipeQuoteRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  final SwipeMode mode;
  final int count;
  final ContextData? context;
  @JsonKey(name: 'exclude_ids')
  final List<String>? excludeIds;

  const SwipeQuoteRequest({
    required this.userId,
    required this.mode,
    this.count = 10,
    this.context,
    this.excludeIds,
  });

  factory SwipeQuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$SwipeQuoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeQuoteRequestToJson(this);
}

/// Response with quotes for swiping
@JsonSerializable()
class SwipeQuoteResponse {
  final List<QuoteWithBook> quotes;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  @JsonKey(name: 'session_id')
  final String sessionId;

  const SwipeQuoteResponse({
    required this.quotes,
    required this.totalCount,
    required this.hasMore,
    required this.sessionId,
  });

  factory SwipeQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$SwipeQuoteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeQuoteResponseToJson(this);
}

/// Request for quote pairs
@JsonSerializable()
class SwipePairRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  final int count;
  final ContextData? context;
  @JsonKey(name: 'exclude_ids')
  final List<String>? excludeIds;

  const SwipePairRequest({
    required this.userId,
    this.count = 5,
    this.context,
    this.excludeIds,
  });

  factory SwipePairRequest.fromJson(Map<String, dynamic> json) =>
      _$SwipePairRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SwipePairRequestToJson(this);
}

/// Response with quote pairs
@JsonSerializable()
class SwipePairResponse {
  final List<QuotePair> pairs;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  @JsonKey(name: 'session_id')
  final String sessionId;

  const SwipePairResponse({
    required this.pairs,
    required this.totalCount,
    required this.hasMore,
    required this.sessionId,
  });

  factory SwipePairResponse.fromJson(Map<String, dynamic> json) =>
      _$SwipePairResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SwipePairResponseToJson(this);
}

/// Request to log a swipe
@JsonSerializable()
class LogSwipeRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'quote_id')
  final String quoteId;
  final SwipeMode mode;
  final SwipeChoice choice;
  @JsonKey(name: 'compared_quote_id')
  final String? comparedQuoteId;
  @JsonKey(name: 'context_data')
  final ContextData? contextData;
  @JsonKey(name: 'swipe_duration_ms')
  final int? swipeDurationMs;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  const LogSwipeRequest({
    required this.userId,
    required this.quoteId,
    required this.mode,
    required this.choice,
    this.comparedQuoteId,
    this.contextData,
    this.swipeDurationMs,
    this.sessionId,
  });

  factory LogSwipeRequest.fromJson(Map<String, dynamic> json) =>
      _$LogSwipeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LogSwipeRequestToJson(this);
}

/// Response after logging a swipe
@JsonSerializable()
class LogSwipeResponse {
  final bool success;
  @JsonKey(name: 'log_id')
  final String logId;
  final String? message;

  const LogSwipeResponse({
    required this.success,
    required this.logId,
    this.message,
  });

  factory LogSwipeResponse.fromJson(Map<String, dynamic> json) =>
      _$LogSwipeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogSwipeResponseToJson(this);
}

/// Swipe statistics for a user
@JsonSerializable()
class SwipeStats {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_swipes')
  final int totalSwipes;
  @JsonKey(name: 'swipes_by_choice')
  final Map<SwipeChoice, int> swipesByChoice;
  @JsonKey(name: 'swipes_by_mode')
  final Map<SwipeMode, int> swipesByMode;
  @JsonKey(name: 'avg_swipe_time')
  final double? avgSwipeTime;
  @JsonKey(name: 'top_genres')
  final List<GenreStats> topGenres;
  @JsonKey(name: 'top_authors')
  final List<AuthorStats> topAuthors;
  @JsonKey(name: 'date_range')
  final DateRange dateRange;

  const SwipeStats({
    required this.userId,
    required this.totalSwipes,
    required this.swipesByChoice,
    required this.swipesByMode,
    this.avgSwipeTime,
    required this.topGenres,
    required this.topAuthors,
    required this.dateRange,
  });

  factory SwipeStats.fromJson(Map<String, dynamic> json) =>
      _$SwipeStatsFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeStatsToJson(this);
}

/// Genre statistics
@JsonSerializable()
class GenreStats {
  final String genre;
  @JsonKey(name: 'swipe_count')
  final int swipeCount;
  @JsonKey(name: 'like_rate')
  final double likeRate;
  @JsonKey(name: 'love_rate')
  final double loveRate;

  const GenreStats({
    required this.genre,
    required this.swipeCount,
    required this.likeRate,
    required this.loveRate,
  });

  factory GenreStats.fromJson(Map<String, dynamic> json) =>
      _$GenreStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GenreStatsToJson(this);
}

/// Author statistics
@JsonSerializable()
class AuthorStats {
  final String author;
  @JsonKey(name: 'swipe_count')
  final int swipeCount;
  @JsonKey(name: 'like_rate')
  final double likeRate;
  @JsonKey(name: 'love_rate')
  final double loveRate;

  const AuthorStats({
    required this.author,
    required this.swipeCount,
    required this.likeRate,
    required this.loveRate,
  });

  factory AuthorStats.fromJson(Map<String, dynamic> json) =>
      _$AuthorStatsFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorStatsToJson(this);
}

/// Date range for statistics
@JsonSerializable()
class DateRange {
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);

  Map<String, dynamic> toJson() => _$DateRangeToJson(this);
}

/// Swipe log entry
@JsonSerializable()
class SwipeLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'quote_id')
  final String quoteId;
  final SwipeMode mode;
  final SwipeChoice choice;
  @JsonKey(name: 'compared_quote_id')
  final String? comparedQuoteId;
  @JsonKey(name: 'context_data')
  final ContextData? contextData;
  @JsonKey(name: 'swipe_duration_ms')
  final int? swipeDurationMs;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const SwipeLog({
    required this.id,
    required this.userId,
    required this.quoteId,
    required this.mode,
    required this.choice,
    this.comparedQuoteId,
    this.contextData,
    this.swipeDurationMs,
    required this.createdAt,
  });

  factory SwipeLog.fromJson(Map<String, dynamic> json) =>
      _$SwipeLogFromJson(json);

  factory SwipeLog.fromMap(Map<String, dynamic> map) => SwipeLog.fromJson(map);

  Map<String, dynamic> toJson() => _$SwipeLogToJson(this);

  Map<String, dynamic> toMap() => toJson();
}

/// Batch swipe request
@JsonSerializable()
class BatchSwipeRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'swipe_logs')
  final List<LogSwipeRequest> swipeLogs;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  const BatchSwipeRequest({
    required this.userId,
    required this.swipeLogs,
    this.sessionId,
  });

  factory BatchSwipeRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchSwipeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BatchSwipeRequestToJson(this);
}

/// Batch swipe response
@JsonSerializable()
class BatchSwipeResponse {
  final bool success;
  @JsonKey(name: 'processed_count')
  final int processedCount;
  @JsonKey(name: 'failed_count')
  final int failedCount;
  final List<BatchSwipeError>? errors;

  const BatchSwipeResponse({
    required this.success,
    required this.processedCount,
    required this.failedCount,
    this.errors,
  });

  factory BatchSwipeResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchSwipeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BatchSwipeResponseToJson(this);
}

/// Batch swipe error
@JsonSerializable()
class BatchSwipeError {
  final int index;
  final String error;

  const BatchSwipeError({
    required this.index,
    required this.error,
  });

  factory BatchSwipeError.fromJson(Map<String, dynamic> json) =>
      _$BatchSwipeErrorFromJson(json);

  Map<String, dynamic> toJson() => _$BatchSwipeErrorToJson(this);
}

/// Helper extension for SwipeMode
extension SwipeModeExtension on SwipeMode {
  String get displayName {
    switch (this) {
      case SwipeMode.tinder:
        return 'Swipe Mode';
      case SwipeMode.facemash:
        return 'Compare Mode';
    }
  }

  String get description {
    switch (this) {
      case SwipeMode.tinder:
        return 'Swipe left to dislike, right to like, up to love, down to skip';
      case SwipeMode.facemash:
        return 'Choose your preferred quote between two options';
    }
  }
}

/// Helper for creating current context data
class ContextDataHelper {
  static ContextData getCurrentContext({
    double? latitude,
    double? longitude,
    String? location,
    String? weatherCondition,
    double? temperature,
    double? humidity,
    String? userMood,
    String? userSituation,
    int? availableTime,
    double? batteryLevel,
    bool? isCharging,
    String? connectionType,
    String? deviceMotion,
    double? screenBrightness,
  }) {
    final now = DateTime.now();
    final timeOfDay = _getTimeOfDay(now);
    final dayOfWeek = _getDayOfWeek(now);
    final isWeekend = now.weekday >= 6;

    return ContextData(
      latitude: latitude,
      longitude: longitude,
      location: location,
      weatherCondition: weatherCondition,
      temperature: temperature,
      humidity: humidity,
      timeOfDay: timeOfDay,
      dayOfWeek: dayOfWeek,
      isWeekend: isWeekend,
      userMood: userMood,
      userSituation: userSituation,
      availableTime: availableTime,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      connectionType: connectionType,
      deviceMotion: deviceMotion,
      screenBrightness: screenBrightness,
    );
  }

  static String _getTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  static String _getDayOfWeek(DateTime dateTime) {
    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return weekdays[dateTime.weekday - 1];
  }
}