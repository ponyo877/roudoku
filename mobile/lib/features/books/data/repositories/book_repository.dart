import '../../domain/repositories/book_repository_interface.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/chapter_entity.dart';
import '../datasources/book_remote_datasource.dart';
import '../models/book_models.dart';
import '../../../../core/logging/logger.dart';

class BookRepository implements BookRepositoryInterface {
  final BookRemoteDataSource _remoteDataSource;

  BookRepository({required BookRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<BookEntity>> getAllBooks() async {
    try {
      Logger.book('Fetching all books from repository');
      final bookModels = await _remoteDataSource.getAllBooks();
      final books = bookModels.map((model) => _mapBookModelToEntity(model)).toList();
      Logger.book('Retrieved ${books.length} books from repository');
      return books;
    } catch (e) {
      Logger.error('Error getting all books from repository', e);
      rethrow;
    }
  }

  @override
  Future<List<BookEntity>> getRecommendations() async {
    try {
      Logger.book('Fetching book recommendations from repository');
      final bookModels = await _remoteDataSource.getRecommendations();
      final books = bookModels.map((model) => _mapBookModelToEntity(model)).toList();
      Logger.book('Retrieved ${books.length} recommended books from repository');
      return books;
    } catch (e) {
      Logger.error('Error getting book recommendations from repository', e);
      rethrow;
    }
  }

  @override
  Future<List<BookEntity>> searchBooks({String? query, String? genre}) async {
    try {
      Logger.book('Searching books: query=$query, genre=$genre');
      final bookModels = await _remoteDataSource.searchBooks(query: query, genre: genre);
      final books = bookModels.map((model) => _mapBookModelToEntity(model)).toList();
      Logger.book('Found ${books.length} books matching search criteria');
      return books;
    } catch (e) {
      Logger.error('Error searching books in repository', e);
      rethrow;
    }
  }

  @override
  Future<BookEntity?> getBookById(String id) async {
    try {
      Logger.book('Fetching book by ID: $id');
      final bookModel = await _remoteDataSource.getBookById(id);
      if (bookModel == null) {
        Logger.warning('Book not found: $id');
        return null;
      }
      return _mapBookModelToEntity(bookModel);
    } catch (e) {
      Logger.error('Error getting book by ID: $id', e);
      rethrow;
    }
  }

  @override
  Future<List<ChapterEntity>> getBookChapters(String bookId) async {
    try {
      Logger.book('Fetching chapters for book: $bookId');
      final chapterModels = await _remoteDataSource.getBookChapters(bookId);
      final chapters = chapterModels.map((model) => _mapChapterModelToEntity(model)).toList();
      Logger.book('Retrieved ${chapters.length} chapters for book: $bookId');
      return chapters;
    } catch (e) {
      Logger.error('Error getting chapters for book: $bookId', e);
      rethrow;
    }
  }

  @override
  Future<ChapterEntity?> getChapter(String bookId, String chapterId) async {
    try {
      Logger.book('Fetching chapter: $chapterId from book: $bookId');
      final chapterModel = await _remoteDataSource.getChapter(bookId, chapterId);
      if (chapterModel == null) {
        Logger.warning('Chapter not found: $chapterId');
        return null;
      }
      return _mapChapterModelToEntity(chapterModel);
    } catch (e) {
      Logger.error('Error getting chapter: $chapterId', e);
      rethrow;
    }
  }

  @override
  Future<String> getChapterContent(String bookId, String chapterId) async {
    try {
      Logger.book('Fetching content for chapter: $chapterId');
      return await _remoteDataSource.getChapterContent(bookId, chapterId);
    } catch (e) {
      Logger.error('Error getting chapter content: $chapterId', e);
      rethrow;
    }
  }

  @override
  Future<List<BookEntity>> getBooksByGenre(String genre) async {
    try {
      Logger.book('Fetching books by genre: $genre');
      final bookModels = await _remoteDataSource.getBooksByGenre(genre);
      final books = bookModels.map((model) => _mapBookModelToEntity(model)).toList();
      Logger.book('Retrieved ${books.length} books for genre: $genre');
      return books;
    } catch (e) {
      Logger.error('Error getting books by genre: $genre', e);
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableGenres() async {
    try {
      Logger.book('Fetching available genres');
      final genres = await _remoteDataSource.getAvailableGenres();
      Logger.book('Retrieved ${genres.length} available genres');
      return genres;
    } catch (e) {
      Logger.error('Error getting available genres', e);
      rethrow;
    }
  }

  @override
  Future<void> markBookAsRead(String bookId, String userId) async {
    try {
      Logger.book('Marking book as read: $bookId for user: $userId');
      await _remoteDataSource.markBookAsRead(bookId, userId);
    } catch (e) {
      Logger.error('Error marking book as read: $bookId', e);
      rethrow;
    }
  }

  @override
  Future<void> addBookToFavorites(String bookId, String userId) async {
    try {
      Logger.book('Adding book to favorites: $bookId for user: $userId');
      await _remoteDataSource.addBookToFavorites(bookId, userId);
    } catch (e) {
      Logger.error('Error adding book to favorites: $bookId', e);
      rethrow;
    }
  }

  @override
  Future<void> removeBookFromFavorites(String bookId, String userId) async {
    try {
      Logger.book('Removing book from favorites: $bookId for user: $userId');
      await _remoteDataSource.removeBookFromFavorites(bookId, userId);
    } catch (e) {
      Logger.error('Error removing book from favorites: $bookId', e);
      rethrow;
    }
  }

  @override
  Future<List<BookEntity>> getFavoriteBooks(String userId) async {
    try {
      Logger.book('Fetching favorite books for user: $userId');
      final bookModels = await _remoteDataSource.getFavoriteBooks(userId);
      final books = bookModels.map((model) => _mapBookModelToEntity(model)).toList();
      Logger.book('Retrieved ${books.length} favorite books for user: $userId');
      return books;
    } catch (e) {
      Logger.error('Error getting favorite books for user: $userId', e);
      rethrow;
    }
  }

  BookEntity _mapBookModelToEntity(BookModel model) {
    return BookEntity(
      id: model.id,
      title: model.title,
      author: model.author,
      summary: model.summary,
      genre: model.genre,
      epoch: model.epoch,
      wordCount: model.wordCount,
      contentUrl: model.contentUrl,
      audioUrl: model.audioUrl,
      difficultyLevel: model.difficultyLevel,
      estimatedReadingMinutes: model.estimatedReadingMinutes,
      downloadCount: model.downloadCount,
      ratingAverage: model.ratingAverage,
      ratingCount: model.ratingCount,
      isPremium: model.isPremium,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      chapters: model.chapters.map((ch) => _mapChapterModelToEntity(ch)).toList(),
    );
  }

  ChapterEntity _mapChapterModelToEntity(ChapterModel model) {
    return ChapterEntity(
      id: model.id,
      bookId: model.bookId,
      title: model.title,
      content: model.content,
      position: model.position,
      wordCount: model.wordCount,
      audioUrl: model.audioUrl,
      audioDuration: model.audioDuration,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}