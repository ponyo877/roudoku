import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  final BookService _bookService = BookService();
  
  List<Book> _recommendations = [];
  List<Book> _searchResults = [];
  List<Book> _bookmarks = [];
  bool _isLoading = false;
  bool _isSearching = false;

  List<Book> get recommendations => _recommendations;
  List<Book> get searchResults => _searchResults;
  List<Book> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  Future<void> loadRecommendations() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _recommendations = await _bookService.getRecommendations();
    } catch (e) {
      print('Error loading recommendations: $e');
      _recommendations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCatalog() async {
    try {
      _isSearching = true;
      notifyListeners();
      
      _searchResults = await _bookService.getAllBooks();
    } catch (e) {
      print('Error loading catalog: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchBooks(String query, {String? category}) async {
    if (query.isEmpty && category == 'すべて') {
      await loadCatalog();
      return;
    }

    try {
      _isSearching = true;
      notifyListeners();
      
      _searchResults = await _bookService.searchBooks(
        query: query,
        category: category != 'すべて' ? category : null,
      );
    } catch (e) {
      print('Error searching books: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadBookmarks() async {
    try {
      _bookmarks = await _bookService.getBookmarks();
      notifyListeners();
    } catch (e) {
      print('Error loading bookmarks: $e');
      _bookmarks = [];
    }
  }

  void addBookmark(Book book) {
    if (!_bookmarks.any((b) => b.id == book.id)) {
      _bookmarks.add(book);
      _bookService.addBookmark(book.id);
      notifyListeners();
    }
  }

  void removeBookmark(String bookId) {
    _bookmarks.removeWhere((book) => book.id == bookId);
    _bookService.removeBookmark(bookId);
    notifyListeners();
  }

  bool isBookmarked(String bookId) {
    return _bookmarks.any((book) => book.id == bookId);
  }

  Future<Book?> getBookById(String id) async {
    try {
      return await _bookService.getBookById(id);
    } catch (e) {
      print('Error getting book by id: $e');
      return null;
    }
  }
}