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
