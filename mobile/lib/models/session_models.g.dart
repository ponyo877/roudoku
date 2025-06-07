// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadingSession _$ReadingSessionFromJson(Map<String, dynamic> json) =>
    ReadingSession(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String,
      currentPos: (json['currentPos'] as num).toInt(),
      totalChapters: (json['totalChapters'] as num).toInt(),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      isActive: json['isActive'] as bool,
      voiceSettings: json['voiceSettings'] == null
          ? null
          : VoiceSettings.fromJson(
              json['voiceSettings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReadingSessionToJson(ReadingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'userId': instance.userId,
      'currentPos': instance.currentPos,
      'totalChapters': instance.totalChapters,
      'duration': instance.duration.inMicroseconds,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'isActive': instance.isActive,
      'voiceSettings': instance.voiceSettings,
    };

CreateSessionRequest _$CreateSessionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateSessionRequest(
      bookId: json['bookId'] as String,
      startPos: (json['startPos'] as num).toInt(),
      voiceSettings: json['voiceSettings'] == null
          ? null
          : VoiceSettings.fromJson(
              json['voiceSettings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateSessionRequestToJson(
        CreateSessionRequest instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'startPos': instance.startPos,
      'voiceSettings': instance.voiceSettings,
    };

SessionProgressUpdate _$SessionProgressUpdateFromJson(
        Map<String, dynamic> json) =>
    SessionProgressUpdate(
      currentPos: (json['currentPos'] as num).toInt(),
      currentTime: Duration(microseconds: (json['currentTime'] as num).toInt()),
      contextData: json['contextData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionProgressUpdateToJson(
        SessionProgressUpdate instance) =>
    <String, dynamic>{
      'currentPos': instance.currentPos,
      'currentTime': instance.currentTime.inMicroseconds,
      'contextData': instance.contextData,
    };

VoiceSettings _$VoiceSettingsFromJson(Map<String, dynamic> json) =>
    VoiceSettings(
      pitch: (json['pitch'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      voiceId: json['voiceId'] as String?,
      language: json['language'] as String?,
    );

Map<String, dynamic> _$VoiceSettingsToJson(VoiceSettings instance) =>
    <String, dynamic>{
      'pitch': instance.pitch,
      'rate': instance.rate,
      'volume': instance.volume,
      'voiceId': instance.voiceId,
      'language': instance.language,
    };

SessionStats _$SessionStatsFromJson(Map<String, dynamic> json) => SessionStats(
      totalSessions: (json['totalSessions'] as num).toInt(),
      totalDuration:
          Duration(microseconds: (json['totalDuration'] as num).toInt()),
      booksStarted: (json['booksStarted'] as num).toInt(),
      booksCompleted: (json['booksCompleted'] as num).toInt(),
      averageSession:
          Duration(microseconds: (json['averageSession'] as num).toInt()),
      mostReadBook: json['mostReadBook'] == null
          ? null
          : BookStat.fromJson(json['mostReadBook'] as Map<String, dynamic>),
      favoriteMood: json['favoriteMood'] as String?,
    );

Map<String, dynamic> _$SessionStatsToJson(SessionStats instance) =>
    <String, dynamic>{
      'totalSessions': instance.totalSessions,
      'totalDuration': instance.totalDuration.inMicroseconds,
      'booksStarted': instance.booksStarted,
      'booksCompleted': instance.booksCompleted,
      'averageSession': instance.averageSession.inMicroseconds,
      'mostReadBook': instance.mostReadBook,
      'favoriteMood': instance.favoriteMood,
    };

BookStat _$BookStatFromJson(Map<String, dynamic> json) => BookStat(
      bookId: (json['bookId'] as num).toInt(),
      title: json['title'] as String,
      totalTime: Duration(microseconds: (json['totalTime'] as num).toInt()),
      sessionCount: (json['sessionCount'] as num).toInt(),
    );

Map<String, dynamic> _$BookStatToJson(BookStat instance) => <String, dynamic>{
      'bookId': instance.bookId,
      'title': instance.title,
      'totalTime': instance.totalTime.inMicroseconds,
      'sessionCount': instance.sessionCount,
    };
