import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class SimpleSwipeService {
  final Dio _dio;

  SimpleSwipeService(this._dio);

  /// Get quotes for swiping by fetching from existing APIs
  Future<List<Map<String, dynamic>>> getQuotesForSwipe({int count = 10}) async {
    try {
      // Get books list
      final booksResponse = await _dio.get('${Constants.apiBaseUrl}/books');
      final books = booksResponse.data['books'] as List;

      if (books.isEmpty) {
        throw Exception('No books available');
      }

      // Get random quotes from different books
      List<Map<String, dynamic>> allQuotes = [];

      for (int i = 0; i < books.length && allQuotes.length < count; i++) {
        final book = books[i];
        final bookId = book['id'];

        try {
          final quotesResponse = await _dio.get(
            '${Constants.apiBaseUrl}/books/$bookId/quotes/random',
            queryParameters: {'limit': 3},
          );

          final quotes = quotesResponse.data as List;
          for (var quote in quotes) {
            if (allQuotes.length < count) {
              allQuotes.add({'quote': quote, 'book': book});
            }
          }
        } catch (e) {
          print('Error fetching quotes for book $bookId: $e');
          continue;
        }
      }

      return allQuotes;
    } catch (e) {
      throw Exception('Error getting quotes for swipe: $e');
    }
  }

  /// Log a swipe action
  Future<void> logSwipe({
    required String userId,
    required String quoteId,
    required String mode,
    required int choice, // -1=left, 0=dislike, 1=like
  }) async {
    try {
      await _dio.post(
        '${Constants.apiBaseUrl}/users/$userId/swipes',
        data: {'quote_id': quoteId, 'mode': mode, 'choice': choice},
      );
    } catch (e) {
      print('Error logging swipe: $e');
      // Don't throw error to prevent UI blocking
    }
  }

  /// Create pairs from quotes for comparison
  List<Map<String, dynamic>> createPairs(
    List<Map<String, dynamic>> quotes,
    int count,
  ) {
    List<Map<String, dynamic>> pairs = [];

    for (int i = 0; i < quotes.length - 1 && pairs.length < count; i += 2) {
      pairs.add({
        'id': 'pair_${DateTime.now().millisecondsSinceEpoch}_$i',
        'quote_a': quotes[i],
        'quote_b': quotes[i + 1],
      });
    }

    return pairs;
  }
}
