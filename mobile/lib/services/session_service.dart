import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_models.dart';

class SessionService {
  final Dio _dio;
  final String _baseUrl;

  SessionService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl;

  /// Create a new reading session
  Future<ReadingSession> createSession(CreateSessionRequest request, {String? userId}) async {
    try {
      // Use a default user ID for now (in production, this would come from authentication)
      final userIdParam = userId ?? 'default-user';
      final response = await _dio.post(
        '$_baseUrl/api/v1/users/$userIdParam/sessions',
        data: request.toJson(),
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ReadingSession.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to create session: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Session creation failed: $e');
    }
  }

  /// Get session by ID
  Future<ReadingSession> getSession(String sessionId, {String? userId}) async {
    try {
      final userIdParam = userId ?? 'default-user';
      final response = await _dio.get(
        '$_baseUrl/api/v1/users/$userIdParam/sessions/$sessionId',
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        return ReadingSession.fromJson(response.data['data'] ?? response.data);
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