import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  final Dio _dio;
  final String _baseUrl;

  SessionService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl;

  /// Create a new reading session
  Future<ReadingSession> createSession(CreateSessionRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/sessions',
        data: request.toJson(),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 201) {
        return ReadingSession.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create session: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Session creation failed: $e');
    }
  }

  /// Get session by ID
  Future<ReadingSession> getSession(String sessionId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/sessions/$sessionId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return ReadingSession.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to get session: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Session fetch failed: $e');
    }
  }

  /// Update session progress
  Future<void> updateProgress(String sessionId, SessionProgressUpdate update) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/api/sessions/$sessionId/progress',
        data: update.toJson(),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update progress: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Progress update failed: $e');
    }
  }

  /// End a reading session
  Future<void> endSession(String sessionId) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/api/sessions/$sessionId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to end session: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Session end failed: $e');
    }
  }

  /// Get user sessions
  Future<List<ReadingSession>> getUserSessions({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/sessions',
        queryParameters: {'limit': limit},
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        final sessions = response.data['data']['sessions'] as List;
        return sessions.map((session) => ReadingSession.fromJson(session)).toList();
      } else {
        throw Exception('Failed to get sessions: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Sessions fetch failed: $e');
    }
  }

  /// Get active session for a book
  Future<ReadingSession?> getActiveSession(int bookId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/sessions/active',
        queryParameters: {'book_id': bookId},
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return ReadingSession.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        return null; // No active session
      } else {
        throw Exception('Failed to get active session: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Active session fetch failed: $e');
    }
  }

  /// Get session statistics
  Future<SessionStats> getSessionStats({int periodDays = 30}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/sessions/stats',
        queryParameters: {'period': periodDays},
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return SessionStats.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to get stats: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Stats fetch failed: $e');
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
class CreateSessionRequest {
  final int bookId;
  final int startPos;
  final String? mood;
  final String? weather;

  CreateSessionRequest({
    required this.bookId,
    this.startPos = 0,
    this.mood,
    this.weather,
  });

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'start_pos': startPos,
        if (mood != null) 'mood': mood,
        if (weather != null) 'weather': weather,
      };
}

class SessionProgressUpdate {
  final int currentPos;
  final int durationSec;
  final String? mood;
  final String? weather;

  SessionProgressUpdate({
    required this.currentPos,
    required this.durationSec,
    this.mood,
    this.weather,
  });

  Map<String, dynamic> toJson() => {
        'current_pos': currentPos,
        'duration_sec': durationSec,
        if (mood != null) 'mood': mood,
        if (weather != null) 'weather': weather,
      };
}

class ReadingSession {
  final String id;
  final String userId;
  final int bookId;
  final int startPos;
  final int currentPos;
  final int durationSec;
  final String? mood;
  final String? weather;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadingSession({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.startPos,
    required this.currentPos,
    required this.durationSec,
    this.mood,
    this.weather,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
        id: json['id'],
        userId: json['user_id'],
        bookId: json['book_id'],
        startPos: json['start_pos'],
        currentPos: json['current_pos'],
        durationSec: json['duration_sec'],
        mood: json['mood'],
        weather: json['weather'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'book_id': bookId,
        'start_pos': startPos,
        'current_pos': currentPos,
        'duration_sec': durationSec,
        'mood': mood,
        'weather': weather,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

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

  factory SessionStats.fromJson(Map<String, dynamic> json) => SessionStats(
        totalSessions: json['total_sessions'],
        totalDuration: Duration(seconds: json['total_duration']),
        booksStarted: json['books_started'],
        booksCompleted: json['books_completed'],
        averageSession: Duration(seconds: json['average_session']),
        mostReadBook: json['most_read_book'] != null
            ? BookStat.fromJson(json['most_read_book'])
            : null,
        favoriteMood: json['favorite_mood'],
      );
}

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

  factory BookStat.fromJson(Map<String, dynamic> json) => BookStat(
        bookId: json['book_id'],
        title: json['title'],
        totalTime: Duration(seconds: json['total_time']),
        sessionCount: json['session_count'],
      );
}