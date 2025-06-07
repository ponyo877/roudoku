import 'package:dio/dio.dart';
import '../models/book.dart';
import '../models/swipe.dart';
import 'context_service.dart';

enum RecommendationMode { tinder, facemash }

class RecommendationService {
  final Dio _dio;
  final String _baseUrl;
  final ContextService _contextService;

  RecommendationService({
    required Dio dio,
    required String baseUrl,
    required ContextService contextService,
  })  : _dio = dio,
        _baseUrl = baseUrl,
        _contextService = contextService;

  // Get personalized book recommendations
  Future<List<Book>> getRecommendations({
    required String userId,
    int limit = 10,
    RecommendationMode mode = RecommendationMode.tinder,
  }) async {
    try {
      // Get current context
      final context = await _contextService.getCurrentContext();
      
      final response = await _dio.post(
        '$_baseUrl/api/v1/recommendations',
        data: {
          'userId': userId,
          'limit': limit,
          'mode': mode.name,
          'context': context.toMap(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> booksData = response.data['books'] ?? [];
        return booksData.map((data) => Book.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Get quotes for swipe interface
  Future<List<Quote>> getQuotesForSwipe({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final context = await _contextService.getCurrentContext();
      
      final response = await _dio.post(
        '$_baseUrl/api/v1/recommendations/quotes',
        data: {
          'userId': userId,
          'limit': limit,
          'context': context.toMap(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> quotesData = response.data['quotes'] ?? [];
        return quotesData.map((data) => Quote.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get quotes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get quotes: $e');
    }
  }

  // Submit swipe feedback
  Future<void> submitSwipeFeedback({
    required String userId,
    required String quoteId,
    required SwipeDirection direction,
    required RecommendationMode mode,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/users/$userId/swipes',
        data: {
          'quoteId': quoteId,
          'mode': mode.name,
          'choice': direction == SwipeDirection.right ? 1 : (direction == SwipeDirection.left ? -1 : 0),
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit swipe feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit swipe feedback: $e');
    }
  }

  // Get pair comparison data for Facemash mode
  Future<List<QuotePair>> getQuotePairs({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final context = await _contextService.getCurrentContext();
      
      final response = await _dio.post(
        '$_baseUrl/api/v1/recommendations/pairs',
        data: {
          'userId': userId,
          'limit': limit,
          'context': context.toMap(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> pairsData = response.data['pairs'] ?? [];
        return pairsData.map((data) => QuotePair.fromJson(data)).toList();
      } else {
        throw Exception('Failed to get quote pairs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get quote pairs: $e');
    }
  }

  // Submit pair comparison choice
  Future<void> submitPairChoice({
    required String userId,
    required String winnerQuoteId,
    required String loserQuoteId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/users/$userId/comparisons',
        data: {
          'winnerQuoteId': winnerQuoteId,
          'loserQuoteId': loserQuoteId,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit pair choice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit pair choice: $e');
    }
  }

  // Get recommendation explanation
  Future<String> getRecommendationExplanation({
    required String userId,
    required String bookId,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/recommendations/explain',
        queryParameters: {
          'userId': userId,
          'bookId': bookId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['explanation'] ?? 'この本をおすすめしました。';
      } else {
        throw Exception('Failed to get explanation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get explanation: $e');
    }
  }

  // Update user preferences based on feedback
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/api/v1/users/$userId/preferences',
        data: preferences,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Get trending books
  Future<List<Book>> getTrendingBooks({
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/books/trending',
        queryParameters: {
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> booksData = response.data['books'] ?? [];
        return booksData.map((data) => Book.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get trending books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get trending books: $e');
    }
  }
}

