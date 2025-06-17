import 'package:dio/dio.dart';
import '../models/book.dart';
import '../core/network/dio_client.dart';
import '../core/logging/logger.dart';

class BookService {
  late final Dio _dio;
  
  BookService() {
    _dio = DioClient.instance.dio;
    Logger.info('BookService initialized with unified HTTP client');
  }

  Future<List<Book>> getRecommendations() async {
    try {
      Logger.book('Fetching book recommendations');
      final response = await _dio.get('/books', queryParameters: {'limit': 20, 'sort_by': 'popularity'});
      if (response.data != null && response.data['books'] != null) {
        final books = (response.data['books'] as List)
            .map((book) => Book.fromJson(book))
            .toList();
        Logger.book('Retrieved ${books.length} recommended books');
        return books;
      }
      return [];
    } catch (e) {
      Logger.error('Error getting book recommendations', e);
      return [];
    }
  }

  Future<List<Book>> getAllBooks() async {
    try {
      Logger.book('Fetching all books');
      final response = await _dio.get('/books');
      if (response.statusCode == 200 && response.data != null && response.data['books'] != null) {
        final books = (response.data['books'] as List)
            .map((book) => Book.fromJson(book))
            .toList();
        Logger.book('Retrieved ${books.length} books');
        return books;
      }
      return [];
    } catch (e) {
      Logger.error('Error getting all books', e);
      return [];
    }
  }

  Future<List<Book>> searchBooks({String? query, String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (category != null) params['genre'] = category; // Server uses 'genre' not 'category'

      final response = await _dio.get('/books', queryParameters: params);
      if (response.statusCode == 200 && response.data != null && response.data['books'] != null) {
        return (response.data['books'] as List)
            .map((book) => Book.fromJson(book))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Book?> getBookById(String id) async {
    try {
      final response = await _dio.get('/books/$id');
      if (response.statusCode == 200 && response.data != null) {
        return Book.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Book>> getBookmarks() async {
    try {
      final response = await _dio.get('/user/bookmarks');
      if (response.statusCode == 200 && response.data != null && response.data['bookmarks'] != null) {
        return (response.data['bookmarks'] as List)
            .map((book) => Book.fromJson(book))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addBookmark(String bookId) async {
    try {
      await _dio.post('/user/bookmarks/$bookId');
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> removeBookmark(String bookId) async {
    try {
      await _dio.delete('/user/bookmarks/$bookId');
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> getBookChapters(String bookId) async {
    try {
      final response = await _dio.get('/books/$bookId/chapters');
      
      if (response.statusCode == 200 && response.data != null && response.data['chapters'] != null) {
        final chapters = List<Map<String, dynamic>>.from(response.data['chapters']);
        return chapters;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getChapterContent(String bookId, String chapterId) async {
    try {
      final response = await _dio.get('/books/$bookId/chapters/$chapterId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

}
