// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextData _$ContextDataFromJson(Map<String, dynamic> json) => ContextData(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      weatherCondition: json['weather_condition'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      timeOfDay: json['time_of_day'] as String,
      dayOfWeek: json['day_of_week'] as String,
      isWeekend: json['is_weekend'] as bool,
      isHoliday: json['is_holiday'] as bool?,
      userMood: json['user_mood'] as String?,
      userSituation: json['user_situation'] as String?,
      availableTime: (json['available_time'] as num?)?.toInt(),
      batteryLevel: (json['battery_level'] as num?)?.toDouble(),
      isCharging: json['is_charging'] as bool?,
      connectionType: json['connection_type'] as String?,
      deviceMotion: json['device_motion'] as String?,
      screenBrightness: (json['screen_brightness'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ContextDataToJson(ContextData instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'location': instance.location,
      'weather_condition': instance.weatherCondition,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'time_of_day': instance.timeOfDay,
      'day_of_week': instance.dayOfWeek,
      'is_weekend': instance.isWeekend,
      'is_holiday': instance.isHoliday,
      'user_mood': instance.userMood,
      'user_situation': instance.userSituation,
      'available_time': instance.availableTime,
      'battery_level': instance.batteryLevel,
      'is_charging': instance.isCharging,
      'connection_type': instance.connectionType,
      'device_motion': instance.deviceMotion,
      'screen_brightness': instance.screenBrightness,
    };

QuoteWithBook _$QuoteWithBookFromJson(Map<String, dynamic> json) =>
    QuoteWithBook(
      quote: Quote.fromJson(json['quote'] as Map<String, dynamic>),
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuoteWithBookToJson(QuoteWithBook instance) =>
    <String, dynamic>{
      'quote': instance.quote,
      'book': instance.book,
    };

SwipeQuoteData _$SwipeQuoteDataFromJson(Map<String, dynamic> json) =>
    SwipeQuoteData(
      quote: Quote.fromJson(json['quote'] as Map<String, dynamic>),
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwipeQuoteDataToJson(SwipeQuoteData instance) =>
    <String, dynamic>{
      'quote': instance.quote,
      'book': instance.book,
    };

SwipePairData _$SwipePairDataFromJson(Map<String, dynamic> json) =>
    SwipePairData(
      id: json['id'] as String,
      quoteA: SwipeQuoteData.fromJson(json['quote_a'] as Map<String, dynamic>),
      quoteB: SwipeQuoteData.fromJson(json['quote_b'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwipePairDataToJson(SwipePairData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quote_a': instance.quoteA,
      'quote_b': instance.quoteB,
    };

QuotePair _$QuotePairFromJson(Map<String, dynamic> json) => QuotePair(
      id: json['id'] as String,
      quoteA: QuoteWithBook.fromJson(json['quote_a'] as Map<String, dynamic>),
      quoteB: QuoteWithBook.fromJson(json['quote_b'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuotePairToJson(QuotePair instance) => <String, dynamic>{
      'id': instance.id,
      'quote_a': instance.quoteA,
      'quote_b': instance.quoteB,
    };

SwipeQuoteRequest _$SwipeQuoteRequestFromJson(Map<String, dynamic> json) =>
    SwipeQuoteRequest(
      userId: json['user_id'] as String,
      mode: $enumDecode(_$SwipeModeEnumMap, json['mode']),
      count: (json['count'] as num?)?.toInt() ?? 10,
      context: json['context'] == null
          ? null
          : ContextData.fromJson(json['context'] as Map<String, dynamic>),
      excludeIds: (json['exclude_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SwipeQuoteRequestToJson(SwipeQuoteRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'mode': _$SwipeModeEnumMap[instance.mode]!,
      'count': instance.count,
      'context': instance.context,
      'exclude_ids': instance.excludeIds,
    };

const _$SwipeModeEnumMap = {
  SwipeMode.tinder: 'tinder',
  SwipeMode.facemash: 'facemash',
};

SwipeQuoteResponse _$SwipeQuoteResponseFromJson(Map<String, dynamic> json) =>
    SwipeQuoteResponse(
      quotes: (json['quotes'] as List<dynamic>)
          .map((e) => QuoteWithBook.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      sessionId: json['session_id'] as String,
    );

Map<String, dynamic> _$SwipeQuoteResponseToJson(SwipeQuoteResponse instance) =>
    <String, dynamic>{
      'quotes': instance.quotes,
      'total_count': instance.totalCount,
      'has_more': instance.hasMore,
      'session_id': instance.sessionId,
    };

SwipePairRequest _$SwipePairRequestFromJson(Map<String, dynamic> json) =>
    SwipePairRequest(
      userId: json['user_id'] as String,
      count: (json['count'] as num?)?.toInt() ?? 5,
      context: json['context'] == null
          ? null
          : ContextData.fromJson(json['context'] as Map<String, dynamic>),
      excludeIds: (json['exclude_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SwipePairRequestToJson(SwipePairRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'count': instance.count,
      'context': instance.context,
      'exclude_ids': instance.excludeIds,
    };

SwipePairResponse _$SwipePairResponseFromJson(Map<String, dynamic> json) =>
    SwipePairResponse(
      pairs: (json['pairs'] as List<dynamic>)
          .map((e) => QuotePair.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      sessionId: json['session_id'] as String,
    );

Map<String, dynamic> _$SwipePairResponseToJson(SwipePairResponse instance) =>
    <String, dynamic>{
      'pairs': instance.pairs,
      'total_count': instance.totalCount,
      'has_more': instance.hasMore,
      'session_id': instance.sessionId,
    };

LogSwipeRequest _$LogSwipeRequestFromJson(Map<String, dynamic> json) =>
    LogSwipeRequest(
      userId: json['user_id'] as String,
      quoteId: json['quote_id'] as String,
      mode: $enumDecode(_$SwipeModeEnumMap, json['mode']),
      choice: $enumDecode(_$SwipeChoiceEnumMap, json['choice']),
      comparedQuoteId: json['compared_quote_id'] as String?,
      contextData: json['context_data'] == null
          ? null
          : ContextData.fromJson(json['context_data'] as Map<String, dynamic>),
      swipeDurationMs: (json['swipe_duration_ms'] as num?)?.toInt(),
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$LogSwipeRequestToJson(LogSwipeRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'quote_id': instance.quoteId,
      'mode': _$SwipeModeEnumMap[instance.mode]!,
      'choice': _$SwipeChoiceEnumMap[instance.choice]!,
      'compared_quote_id': instance.comparedQuoteId,
      'context_data': instance.contextData,
      'swipe_duration_ms': instance.swipeDurationMs,
      'session_id': instance.sessionId,
    };

const _$SwipeChoiceEnumMap = {
  SwipeChoice.skip: -1,
  SwipeChoice.dislike: 0,
  SwipeChoice.like: 1,
  SwipeChoice.love: 2,
};

LogSwipeResponse _$LogSwipeResponseFromJson(Map<String, dynamic> json) =>
    LogSwipeResponse(
      success: json['success'] as bool,
      logId: json['log_id'] as String,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$LogSwipeResponseToJson(LogSwipeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'log_id': instance.logId,
      'message': instance.message,
    };

SwipeStats _$SwipeStatsFromJson(Map<String, dynamic> json) => SwipeStats(
      userId: json['user_id'] as String,
      totalSwipes: (json['total_swipes'] as num).toInt(),
      swipesByChoice: (json['swipes_by_choice'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$SwipeChoiceEnumMap, k), (e as num).toInt()),
      ),
      swipesByMode: (json['swipes_by_mode'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$SwipeModeEnumMap, k), (e as num).toInt()),
      ),
      avgSwipeTime: (json['avg_swipe_time'] as num?)?.toDouble(),
      topGenres: (json['top_genres'] as List<dynamic>)
          .map((e) => GenreStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAuthors: (json['top_authors'] as List<dynamic>)
          .map((e) => AuthorStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateRange: DateRange.fromJson(json['date_range'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwipeStatsToJson(SwipeStats instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'total_swipes': instance.totalSwipes,
      'swipes_by_choice': instance.swipesByChoice
          .map((k, e) => MapEntry(_$SwipeChoiceEnumMap[k]!, e)),
      'swipes_by_mode': instance.swipesByMode
          .map((k, e) => MapEntry(_$SwipeModeEnumMap[k]!, e)),
      'avg_swipe_time': instance.avgSwipeTime,
      'top_genres': instance.topGenres,
      'top_authors': instance.topAuthors,
      'date_range': instance.dateRange,
    };

GenreStats _$GenreStatsFromJson(Map<String, dynamic> json) => GenreStats(
      genre: json['genre'] as String,
      swipeCount: (json['swipe_count'] as num).toInt(),
      likeRate: (json['like_rate'] as num).toDouble(),
      loveRate: (json['love_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$GenreStatsToJson(GenreStats instance) =>
    <String, dynamic>{
      'genre': instance.genre,
      'swipe_count': instance.swipeCount,
      'like_rate': instance.likeRate,
      'love_rate': instance.loveRate,
    };

AuthorStats _$AuthorStatsFromJson(Map<String, dynamic> json) => AuthorStats(
      author: json['author'] as String,
      swipeCount: (json['swipe_count'] as num).toInt(),
      likeRate: (json['like_rate'] as num).toDouble(),
      loveRate: (json['love_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$AuthorStatsToJson(AuthorStats instance) =>
    <String, dynamic>{
      'author': instance.author,
      'swipe_count': instance.swipeCount,
      'like_rate': instance.likeRate,
      'love_rate': instance.loveRate,
    };

DateRange _$DateRangeFromJson(Map<String, dynamic> json) => DateRange(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );

Map<String, dynamic> _$DateRangeToJson(DateRange instance) => <String, dynamic>{
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
    };

SwipeLog _$SwipeLogFromJson(Map<String, dynamic> json) => SwipeLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quoteId: json['quote_id'] as String,
      mode: $enumDecode(_$SwipeModeEnumMap, json['mode']),
      choice: $enumDecode(_$SwipeChoiceEnumMap, json['choice']),
      comparedQuoteId: json['compared_quote_id'] as String?,
      contextData: json['context_data'] == null
          ? null
          : ContextData.fromJson(json['context_data'] as Map<String, dynamic>),
      swipeDurationMs: (json['swipe_duration_ms'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SwipeLogToJson(SwipeLog instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'quote_id': instance.quoteId,
      'mode': _$SwipeModeEnumMap[instance.mode]!,
      'choice': _$SwipeChoiceEnumMap[instance.choice]!,
      'compared_quote_id': instance.comparedQuoteId,
      'context_data': instance.contextData,
      'swipe_duration_ms': instance.swipeDurationMs,
      'created_at': instance.createdAt.toIso8601String(),
    };

BatchSwipeRequest _$BatchSwipeRequestFromJson(Map<String, dynamic> json) =>
    BatchSwipeRequest(
      userId: json['user_id'] as String,
      swipeLogs: (json['swipe_logs'] as List<dynamic>)
          .map((e) => LogSwipeRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$BatchSwipeRequestToJson(BatchSwipeRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'swipe_logs': instance.swipeLogs,
      'session_id': instance.sessionId,
    };

BatchSwipeResponse _$BatchSwipeResponseFromJson(Map<String, dynamic> json) =>
    BatchSwipeResponse(
      success: json['success'] as bool,
      processedCount: (json['processed_count'] as num).toInt(),
      failedCount: (json['failed_count'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => BatchSwipeError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BatchSwipeResponseToJson(BatchSwipeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'processed_count': instance.processedCount,
      'failed_count': instance.failedCount,
      'errors': instance.errors,
    };

BatchSwipeError _$BatchSwipeErrorFromJson(Map<String, dynamic> json) =>
    BatchSwipeError(
      index: (json['index'] as num).toInt(),
      error: json['error'] as String,
    );

Map<String, dynamic> _$BatchSwipeErrorToJson(BatchSwipeError instance) =>
    <String, dynamic>{
      'index': instance.index,
      'error': instance.error,
    };
