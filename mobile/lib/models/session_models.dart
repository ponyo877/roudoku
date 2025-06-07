import 'package:json_annotation/json_annotation.dart';

part 'session_models.g.dart';

@JsonSerializable()
class ReadingSession {
  final String id;
  final String bookId;
  final String userId;
  final int currentPos;
  final int totalChapters;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final VoiceSettings? voiceSettings;

  ReadingSession({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.currentPos,
    required this.totalChapters,
    required this.duration,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.voiceSettings,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) =>
      _$ReadingSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ReadingSessionToJson(this);
}

@JsonSerializable()
class CreateSessionRequest {
  final String bookId;
  final int startPos;
  final VoiceSettings? voiceSettings;

  CreateSessionRequest({
    required this.bookId,
    required this.startPos,
    this.voiceSettings,
  });

  factory CreateSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSessionRequestToJson(this);
}

@JsonSerializable()
class SessionProgressUpdate {
  final int currentPos;
  final Duration currentTime;
  final Map<String, dynamic>? contextData;

  SessionProgressUpdate({
    required this.currentPos,
    required this.currentTime,
    this.contextData,
  });

  factory SessionProgressUpdate.fromJson(Map<String, dynamic> json) =>
      _$SessionProgressUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$SessionProgressUpdateToJson(this);
}

@JsonSerializable()
class VoiceSettings {
  final double pitch;
  final double rate;
  final double volume;
  final String? voiceId;
  final String? language;

  VoiceSettings({
    required this.pitch,
    required this.rate,
    required this.volume,
    this.voiceId,
    this.language,
  });

  static VoiceSettings get defaultSettings => VoiceSettings(
    pitch: 1.0,
    rate: 1.0,
    volume: 1.0,
    language: 'en-US',
  );

  factory VoiceSettings.fromJson(Map<String, dynamic> json) =>
      _$VoiceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSettingsToJson(this);
}

@JsonSerializable()
class SessionStats {
  final int totalSessions;
  final Duration totalDuration;
  final int booksStarted;
  final int booksCompleted;
  final Duration averageSession;
  final BookStat? mostReadBook;
  final String? favoriteMood;

  SessionStats({
    required this.totalSessions,
    required this.totalDuration,
    required this.booksStarted,
    required this.booksCompleted,
    required this.averageSession,
    this.mostReadBook,
    this.favoriteMood,
  });

  factory SessionStats.fromJson(Map<String, dynamic> json) =>
      _$SessionStatsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStatsToJson(this);
}

@JsonSerializable()
class BookStat {
  final int bookId;
  final String title;
  final Duration totalTime;
  final int sessionCount;

  BookStat({
    required this.bookId,
    required this.title,
    required this.totalTime,
    required this.sessionCount,
  });

  factory BookStat.fromJson(Map<String, dynamic> json) =>
      _$BookStatFromJson(json);

  Map<String, dynamic> toJson() => _$BookStatToJson(this);
}