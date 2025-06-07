import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  final Dio _dio;
  final String _baseUrl;

  AudioService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl;

  /// Generate TTS audio for given text
  Future<TTSResponse> generateAudio(TTSRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/audio/generate',
        data: request.toJson(),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return TTSResponse.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to generate audio: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Audio generation failed: $e');
    }
  }

  /// Get chapter audio
  Future<TTSResponse> getChapterAudio(int bookId, int chapterId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/audio/book/$bookId/chapter/$chapterId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return TTSResponse.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to get chapter audio: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Chapter audio fetch failed: $e');
    }
  }

  /// Generate voice preview
  Future<TTSResponse> generatePreview(AudioPreviewRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/audio/preview',
        data: request.toJson(),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return TTSResponse.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to generate preview: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Preview generation failed: $e');
    }
  }

  /// Get available voices
  Future<List<AvailableVoice>> getAvailableVoices() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/audio/voices',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        final voices = response.data['data']['voices'] as List;
        return voices.map((voice) => AvailableVoice.fromJson(voice)).toList();
      } else {
        throw Exception('Failed to get voices: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Voice fetch failed: $e');
    }
  }

  /// Get cached audio
  Future<AudioCache> getCachedAudio(String cacheId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/audio/cache/$cacheId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return AudioCache.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to get cached audio: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Cached audio fetch failed: $e');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

// Data models
class VoiceSettings {
  final String voice;
  final String gender;
  final String language;
  final double speed;
  final double pitch;
  final double volumeGain;

  VoiceSettings({
    required this.voice,
    required this.gender,
    required this.language,
this.speed = 1.0,
    this.pitch = 0.0,
    this.volumeGain = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'voice': voice,
        'gender': gender,
        'language': language,
        'speed': speed,
        'pitch': pitch,
        'volume_gain': volumeGain,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) => VoiceSettings(
        voice: json['voice'],
        gender: json['gender'],
        language: json['language'],
        speed: json['speed']?.toDouble() ?? 1.0,
        pitch: json['pitch']?.toDouble() ?? 0.0,
        volumeGain: json['volume_gain']?.toDouble() ?? 0.0,
      );

  static VoiceSettings get defaultSettings => VoiceSettings(
        voice: 'ja-JP-Wavenet-A',
        gender: 'FEMALE',
        language: 'ja-JP',
      );
}

class TTSRequest {
  final String text;
  final VoiceSettings voiceSettings;
  final int? bookId;
  final int? chapterId;

  TTSRequest({
    required this.text,
    required this.voiceSettings,
    this.bookId,
    this.chapterId,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'voice_settings': voiceSettings.toJson(),
        if (bookId != null) 'book_id': bookId,
        if (chapterId != null) 'chapter_id': chapterId,
      };
}

class TTSResponse {
  final String audioUrl;
  final String cacheId;
  final int durationSeconds;
  final int fileSizeBytes;

  TTSResponse({
    required this.audioUrl,
    required this.cacheId,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  factory TTSResponse.fromJson(Map<String, dynamic> json) => TTSResponse(
        audioUrl: json['audio_url'],
        cacheId: json['cache_id'],
        durationSeconds: json['duration_seconds'],
        fileSizeBytes: json['file_size_bytes'],
      );
}

class AudioPreviewRequest {
  final VoiceSettings voiceSettings;
  final String? sampleText;

  AudioPreviewRequest({
    required this.voiceSettings,
    this.sampleText,
  });

  Map<String, dynamic> toJson() => {
        'voice_settings': voiceSettings.toJson(),
        if (sampleText != null) 'sample_text': sampleText,
      };
}

class AvailableVoice {
  final String name;
  final String language;
  final String gender;
  final String type;
  final int sampleRate;
  final List<String> supportedFeatures;

  AvailableVoice({
    required this.name,
    required this.language,
    required this.gender,
    required this.type,
    required this.sampleRate,
    required this.supportedFeatures,
  });

  factory AvailableVoice.fromJson(Map<String, dynamic> json) => AvailableVoice(
        name: json['name'],
        language: json['language'],
        gender: json['gender'],
        type: json['type'],
        sampleRate: json['sample_rate'],
        supportedFeatures: List<String>.from(json['supported_features']),
      );
}

class AudioCache {
  final String id;
  final int bookId;
  final String chapterHash;
  final String voiceSettingsHash;
  final String filePath;
  final int fileSizeBytes;
  final int durationSeconds;
  final String cacheStatus;
  final int accessCount;
  final DateTime lastAccessedAt;
  final DateTime createdAt;

  AudioCache({
    required this.id,
    required this.bookId,
    required this.chapterHash,
    required this.voiceSettingsHash,
    required this.filePath,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.cacheStatus,
    required this.accessCount,
    required this.lastAccessedAt,
    required this.createdAt,
  });

  factory AudioCache.fromJson(Map<String, dynamic> json) => AudioCache(
        id: json['id'],
        bookId: json['book_id'],
        chapterHash: json['chapter_hash'],
        voiceSettingsHash: json['voice_settings_hash'],
        filePath: json['file_path'],
        fileSizeBytes: json['file_size_bytes'],
        durationSeconds: json['duration_seconds'],
        cacheStatus: json['cache_status'],
        accessCount: json['access_count'],
        lastAccessedAt: DateTime.parse(json['last_accessed_at']),
        createdAt: DateTime.parse(json['created_at']),
      );
}