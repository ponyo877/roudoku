import '../entities/book_entity.dart';
import '../entities/chapter_entity.dart';

abstract class BookRepositoryInterface {
  Future<List<BookEntity>> getAllBooks();
  Future<List<BookEntity>> getRecommendations();
  Future<List<BookEntity>> searchBooks({String? query, String? genre});
  Future<BookEntity?> getBookById(String id);
  Future<List<ChapterEntity>> getBookChapters(String bookId);
  Future<ChapterEntity?> getChapter(String bookId, String chapterId);
  Future<String> getChapterContent(String bookId, String chapterId);
  Future<List<BookEntity>> getBooksByGenre(String genre);
  Future<List<String>> getAvailableGenres();
  Future<void> markBookAsRead(String bookId, String userId);
  Future<void> addBookToFavorites(String bookId, String userId);
  Future<void> removeBookFromFavorites(String bookId, String userId);
  Future<List<BookEntity>> getFavoriteBooks(String userId);
}