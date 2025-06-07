import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/swipe.dart';
import '../utils/constants.dart';

class SwipeService {
  final Dio _dio;
  final SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();
  
  // Offline swipe logs queue
  static const String _offlineSwipeLogsKey = 'offline_swipe_logs';
  static const String _swipeSessionKey = 'current_swipe_session';
  
  SwipeService(this._dio, this._prefs) {
    _setupInterceptors();
    _startPeriodicSync();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        // If network error, try to save swipe logs offline
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          print('Network error detected, swipe logs will be queued offline');
        }
        handler.next(error);
      },
    ));
  }

  /// Start periodic sync of offline swipe logs
  void _startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (_) async {
      await _syncOfflineSwipeLogs();
    });
  }

  /// Get quotes for swiping
  Future<SwipeQuoteResponse> getSwipeQuotes({
    required String userId,
    required SwipeMode mode,
    int count = 10,
    ContextData? context,
    List<String>? excludeIds,
  }) async {
    try {
      final request = SwipeQuoteRequest(
        userId: userId,
        mode: mode,
        count: count,
        context: context,
        excludeIds: excludeIds,
      );

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/swipe/quotes',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SwipeQuoteResponse.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to get swipe quotes: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        // Return cached quotes if available
        return await _getCachedQuotes(mode, count);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting swipe quotes: $e');
    }
  }

  /// Get quote pairs for comparison
  Future<SwipePairResponse> getSwipePairs({
    required String userId,
    int count = 5,
    ContextData? context,
    List<String>? excludeIds,
  }) async {
    try {
      final request = SwipePairRequest(
        userId: userId,
        count: count,
        context: context,
        excludeIds: excludeIds,
      );

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/swipe/pairs',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SwipePairResponse.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to get swipe pairs: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        // Return cached pairs if available
        return await _getCachedPairs(count);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting swipe pairs: $e');
    }
  }

  /// Log a single swipe action
  Future<LogSwipeResponse> logSwipe({
    required String userId,
    required String quoteId,
    required SwipeMode mode,
    required SwipeChoice choice,
    String? comparedQuoteId,
    ContextData? contextData,
    int? swipeDurationMs,
    String? sessionId,
  }) async {
    final request = LogSwipeRequest(
      userId: userId,
      quoteId: quoteId,
      mode: mode,
      choice: choice,
      comparedQuoteId: comparedQuoteId,
      contextData: contextData,
      swipeDurationMs: swipeDurationMs,
      sessionId: sessionId,
    );

    // Try to send immediately
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw const SocketException('No internet connection');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/swipe/log',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return LogSwipeResponse.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to log swipe: ${response.statusMessage}');
      }
    } catch (e) {
      // Save offline for later sync
      await _saveSwipeLogOffline(request);
      
      // Return a mock successful response for offline logging
      return LogSwipeResponse(
        success: true,
        logId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Swipe logged offline, will sync when online',
      );
    }
  }

  /// Log comparison choice
  Future<LogSwipeResponse> logComparison({
    required String userId,
    required String chosenQuoteId,
    required String otherQuoteId,
    ContextData? contextData,
    int? swipeDurationMs,
    String? sessionId,
  }) async {
    return await logSwipe(
      userId: userId,
      quoteId: chosenQuoteId,
      mode: SwipeMode.facemash,
      choice: SwipeChoice.like, // In comparison, chosen quote is always "liked"
      comparedQuoteId: otherQuoteId,
      contextData: contextData,
      swipeDurationMs: swipeDurationMs,
      sessionId: sessionId,
    );
  }

  /// Batch log multiple swipes
  Future<BatchSwipeResponse> logSwipesBatch({
    required String userId,
    required List<LogSwipeRequest> swipeLogs,
    String? sessionId,
  }) async {
    final request = BatchSwipeRequest(
      userId: userId,
      swipeLogs: swipeLogs,
      sessionId: sessionId,
    );

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw const SocketException('No internet connection');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/swipe/log/batch',
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return BatchSwipeResponse.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to batch log swipes: ${response.statusMessage}');
      }
    } catch (e) {
      // Save all swipe logs offline
      for (final swipeLog in swipeLogs) {
        await _saveSwipeLogOffline(swipeLog);
      }
      
      return BatchSwipeResponse(
        success: true,
        processedCount: swipeLogs.length,
        failedCount: 0,
        errors: null,
      );
    }
  }

  /// Get swipe statistics
  Future<SwipeStats> getSwipeStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    SwipeMode? mode,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      if (mode != null) {
        queryParams['mode'] = mode.name;
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/swipe/stats/$userId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return SwipeStats.fromJson(response.data['data'] ?? response.data);
      } else {
        throw Exception('Failed to get swipe stats: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting swipe stats: $e');
    }
  }

  /// Get swipe history
  Future<List<SwipeLog>> getSwipeHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/swipe/history',
        queryParameters: {
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final historyList = data['history'] as List;
        return historyList.map((item) => SwipeLog.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get swipe history: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting swipe history: $e');
    }
  }

  /// Save swipe log offline for later sync
  Future<void> _saveSwipeLogOffline(LogSwipeRequest request) async {
    try {
      final offlineLogsJson = _prefs.getString(_offlineSwipeLogsKey) ?? '[]';
      final offlineLogs = json.decode(offlineLogsJson) as List;
      
      // Add timestamp for offline logging
      final logWithTimestamp = {
        ...request.toJson(),
        'offline_timestamp': DateTime.now().toIso8601String(),
      };
      
      offlineLogs.add(logWithTimestamp);
      
      // Limit offline logs to prevent excessive storage usage
      if (offlineLogs.length > 1000) {
        offlineLogs.removeRange(0, offlineLogs.length - 1000);
      }
      
      await _prefs.setString(_offlineSwipeLogsKey, json.encode(offlineLogs));
      print('Swipe log saved offline: ${request.quoteId}');
    } catch (e) {
      print('Error saving swipe log offline: $e');
    }
  }

  /// Sync offline swipe logs when connection is available
  Future<void> _syncOfflineSwipeLogs() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return; // No connection available
      }

      final offlineLogsJson = _prefs.getString(_offlineSwipeLogsKey);
      if (offlineLogsJson == null || offlineLogsJson == '[]') {
        return; // No offline logs to sync
      }

      final offlineLogs = json.decode(offlineLogsJson) as List;
      if (offlineLogs.isEmpty) return;

      print('Syncing ${offlineLogs.length} offline swipe logs...');

      // Convert to LogSwipeRequest objects
      final swipeRequests = offlineLogs.map((logJson) {
        // Remove offline timestamp
        logJson.remove('offline_timestamp');
        return LogSwipeRequest.fromJson(logJson);
      }).toList();

      // Group by user ID for batch requests
      final Map<String, List<LogSwipeRequest>> groupedLogs = {};
      for (final request in swipeRequests) {
        groupedLogs.putIfAbsent(request.userId, () => []).add(request);
      }

      // Send batch requests for each user
      bool allSynced = true;
      for (final entry in groupedLogs.entries) {
        try {
          await logSwipesBatch(
            userId: entry.key,
            swipeLogs: entry.value,
          );
        } catch (e) {
          print('Failed to sync logs for user ${entry.key}: $e');
          allSynced = false;
        }
      }

      // Clear offline logs if all were synced successfully
      if (allSynced) {
        await _prefs.remove(_offlineSwipeLogsKey);
        print('All offline swipe logs synced successfully');
      }
    } catch (e) {
      print('Error syncing offline swipe logs: $e');
    }
  }

  /// Get cached quotes for offline use
  Future<SwipeQuoteResponse> _getCachedQuotes(SwipeMode mode, int count) async {
    try {
      final cacheKey = 'cached_quotes_${mode.name}';
      final cachedJson = _prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        final cached = SwipeQuoteResponse.fromJson(json.decode(cachedJson));
        // Return limited quotes based on request count
        final limitedQuotes = cached.quotes.take(count).toList();
        return SwipeQuoteResponse(
          quotes: limitedQuotes,
          totalCount: limitedQuotes.length,
          hasMore: false,
          sessionId: 'offline_session',
        );
      }
    } catch (e) {
      print('Error getting cached quotes: $e');
    }
    
    // Return empty response if no cache available
    return const SwipeQuoteResponse(
      quotes: [],
      totalCount: 0,
      hasMore: false,
      sessionId: 'offline_session',
    );
  }

  /// Get cached pairs for offline use
  Future<SwipePairResponse> _getCachedPairs(int count) async {
    try {
      const cacheKey = 'cached_pairs';
      final cachedJson = _prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        final cached = SwipePairResponse.fromJson(json.decode(cachedJson));
        // Return limited pairs based on request count
        final limitedPairs = cached.pairs.take(count).toList();
        return SwipePairResponse(
          pairs: limitedPairs,
          totalCount: limitedPairs.length,
          hasMore: false,
          sessionId: 'offline_session',
        );
      }
    } catch (e) {
      print('Error getting cached pairs: $e');
    }
    
    // Return empty response if no cache available
    return const SwipePairResponse(
      pairs: [],
      totalCount: 0,
      hasMore: false,
      sessionId: 'offline_session',
    );
  }

  /// Cache quotes for offline use
  Future<void> cacheQuotes(SwipeQuoteResponse response, SwipeMode mode) async {
    try {
      final cacheKey = 'cached_quotes_${mode.name}';
      await _prefs.setString(cacheKey, json.encode(response.toJson()));
    } catch (e) {
      print('Error caching quotes: $e');
    }
  }

  /// Cache pairs for offline use
  Future<void> cachePairs(SwipePairResponse response) async {
    try {
      const cacheKey = 'cached_pairs';
      await _prefs.setString(cacheKey, json.encode(response.toJson()));
    } catch (e) {
      print('Error caching pairs: $e');
    }
  }

  /// Get current swipe session ID
  String? getCurrentSessionId() {
    return _prefs.getString(_swipeSessionKey);
  }

  /// Set current swipe session ID
  Future<void> setCurrentSessionId(String sessionId) async {
    await _prefs.setString(_swipeSessionKey, sessionId);
  }

  /// Clear current swipe session
  Future<void> clearCurrentSession() async {
    await _prefs.remove(_swipeSessionKey);
  }

  /// Get pending offline swipe logs count
  Future<int> getPendingOfflineLogsCount() async {
    try {
      final offlineLogsJson = _prefs.getString(_offlineSwipeLogsKey) ?? '[]';
      final offlineLogs = json.decode(offlineLogsJson) as List;
      return offlineLogs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Force sync offline logs
  Future<bool> forceSyncOfflineLogs() async {
    try {
      await _syncOfflineSwipeLogs();
      final remainingCount = await getPendingOfflineLogsCount();
      return remainingCount == 0;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _prefs.remove('cached_quotes_tinder');
      await _prefs.remove('cached_quotes_facemash');
      await _prefs.remove('cached_pairs');
      await _prefs.remove(_swipeSessionKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear offline logs (use with caution)
  Future<void> clearOfflineLogs() async {
    try {
      await _prefs.remove(_offlineSwipeLogsKey);
    } catch (e) {
      print('Error clearing offline logs: $e');
    }
  }
}