import '../models/book_models.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/logging/logger.dart';

class BookRemoteDataSource {
  BookRemoteDataSource();

  Future<List<BookModel>> getAllBooks() async {
    try {
      Logger.network('Fetching all books from API');
      final response = await DioClient.instance.dio.get('/books');

      if (response.statusCode == 200 && response.data != null) {
        final books =
            (response.data['books'] as List<dynamic>?)
                ?.map((json) => BookModel.fromJson(json))
                .toList() ??
            [];
        Logger.network('Retrieved ${books.length} books from API');
        return books;
      }

      throw Exception('Failed to fetch books: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching books from API', e);
      rethrow;
    }
  }

  Future<List<BookModel>> getRecommendations() async {
    try {
      Logger.network('Fetching book recommendations from API');
      final response = await DioClient.instance.dio.get(
        '/books',
        queryParameters: {'limit': 20, 'sort_by': 'popularity'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final books =
            (response.data['books'] as List<dynamic>?)
                ?.map((json) => BookModel.fromJson(json))
                .toList() ??
            [];
        Logger.network('Retrieved ${books.length} recommended books from API');
        return books;
      }

      throw Exception(
        'Failed to fetch recommendations: ${response.statusCode}',
      );
    } catch (e) {
      Logger.error('Error fetching recommendations from API', e);
      rethrow;
    }
  }

  Future<List<BookModel>> searchBooks({String? query, String? genre}) async {
    try {
      final params = <String, dynamic>{};
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (genre != null) params['genre'] = genre;

      Logger.network('Searching books in API with params: $params');
      final response = await DioClient.instance.dio.get(
        '/books',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final books =
            (response.data['books'] as List<dynamic>?)
                ?.map((json) => BookModel.fromJson(json))
                .toList() ??
            [];
        Logger.network('Found ${books.length} books matching search criteria');
        return books;
      }

      throw Exception('Failed to search books: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error searching books in API', e);
      rethrow;
    }
  }

  Future<BookModel?> getBookById(String id) async {
    try {
      Logger.network('Fetching book by ID from API: $id');
      final response = await DioClient.instance.dio.get('/books/$id');

      if (response.statusCode == 200 && response.data != null) {
        return BookModel.fromJson(response.data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      throw Exception('Failed to fetch book: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching book by ID from API: $id', e);
      rethrow;
    }
  }

  Future<List<ChapterModel>> getBookChapters(String bookId) async {
    try {
      Logger.network('Fetching chapters for book from API: $bookId');
      final response = await DioClient.instance.dio.get(
        '/books/$bookId/chapters',
      );

      if (response.statusCode == 200 && response.data != null) {
        final chapters =
            (response.data['chapters'] as List<dynamic>?)
                ?.map((json) => ChapterModel.fromJson(json))
                .toList() ??
            [];
        Logger.network(
          'Retrieved ${chapters.length} chapters for book: $bookId',
        );
        return chapters;
      }

      throw Exception('Failed to fetch chapters: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching chapters for book: $bookId', e);
      rethrow;
    }
  }

  Future<ChapterModel?> getChapter(String bookId, String chapterId) async {
    try {
      Logger.network('Fetching chapter from API: $chapterId');
      final response = await DioClient.instance.dio.get(
        '/books/$bookId/chapters/$chapterId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChapterModel.fromJson(response.data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      throw Exception('Failed to fetch chapter: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching chapter from API: $chapterId', e);
      rethrow;
    }
  }

  Future<String> getChapterContent(String bookId, String chapterId) async {
    try {
      Logger.network('Fetching chapter content from API: $chapterId');
      final response = await DioClient.instance.dio.get(
        '/books/$bookId/chapters/$chapterId/content',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['content'] ?? '';
      }

      throw Exception(
        'Failed to fetch chapter content: ${response.statusCode}',
      );
    } catch (e) {
      Logger.error('Error fetching chapter content from API: $chapterId', e);
      rethrow;
    }
  }

  Future<List<BookModel>> getBooksByGenre(String genre) async {
    try {
      Logger.network('Fetching books by genre from API: $genre');
      final response = await DioClient.instance.dio.get(
        '/books',
        queryParameters: {'genre': genre},
      );

      if (response.statusCode == 200 && response.data != null) {
        final books =
            (response.data['books'] as List<dynamic>?)
                ?.map((json) => BookModel.fromJson(json))
                .toList() ??
            [];
        Logger.network('Retrieved ${books.length} books for genre: $genre');
        return books;
      }

      throw Exception('Failed to fetch books by genre: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching books by genre from API: $genre', e);
      rethrow;
    }
  }

  Future<List<String>> getAvailableGenres() async {
    try {
      Logger.network('Fetching available genres from API');
      final response = await DioClient.instance.dio.get('/books/genres');

      if (response.statusCode == 200 && response.data != null) {
        final genres =
            (response.data['genres'] as List<dynamic>?)
                ?.map((genre) => genre.toString())
                .toList() ??
            [];
        Logger.network('Retrieved ${genres.length} available genres');
        return genres;
      }

      throw Exception('Failed to fetch genres: ${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching genres from API', e);
      rethrow;
    }
  }

  Future<void> markBookAsRead(String bookId, String userId) async {
    try {
      Logger.network('Marking book as read in API: $bookId');
      await DioClient.instance.dio.post('/users/$userId/books/$bookId/read');
    } catch (e) {
      Logger.error('Error marking book as read in API: $bookId', e);
      rethrow;
    }
  }

  Future<void> addBookToFavorites(String bookId, String userId) async {
    try {
      Logger.network('Adding book to favorites in API: $bookId');
      await DioClient.instance.dio.post('/users/$userId/favorites/$bookId');
    } catch (e) {
      Logger.error('Error adding book to favorites in API: $bookId', e);
      rethrow;
    }
  }

  Future<void> removeBookFromFavorites(String bookId, String userId) async {
    try {
      Logger.network('Removing book from favorites in API: $bookId');
      await DioClient.instance.dio.delete('/users/$userId/favorites/$bookId');
    } catch (e) {
      Logger.error('Error removing book from favorites in API: $bookId', e);
      rethrow;
    }
  }

  Future<List<BookModel>> getFavoriteBooks(String userId) async {
    try {
      Logger.network('Fetching favorite books from API for user: $userId');
      final response = await DioClient.instance.dio.get(
        '/users/$userId/favorites',
      );

      if (response.statusCode == 200 && response.data != null) {
        final books =
            (response.data['books'] as List<dynamic>?)
                ?.map((json) => BookModel.fromJson(json))
                .toList() ??
            [];
        Logger.network(
          'Retrieved ${books.length} favorite books for user: $userId',
        );
        return books;
      }

      throw Exception('Failed to fetch favorite books: ${response.statusCode}');
    } catch (e) {
      Logger.error(
        'Error fetching favorite books from API for user: $userId',
        e,
      );
      rethrow;
    }
  }
}
