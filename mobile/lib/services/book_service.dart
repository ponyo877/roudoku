import 'package:dio/dio.dart';
import '../models/book.dart';
import '../utils/constants.dart';

class BookService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  Future<List<Book>> getRecommendations() async {
    try {
      final response = await _dio.get('/books/recommendations');
      return (response.data['books'] as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      print('Error fetching recommendations: $e');
      // Return mock data for development
      return _getMockBooks();
    }
  }

  Future<List<Book>> getAllBooks() async {
    try {
      final response = await _dio.get('/books');
      return (response.data['books'] as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      print('Error fetching all books: $e');
      return _getMockBooks();
    }
  }

  Future<List<Book>> searchBooks({String? query, String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (query != null && query.isNotEmpty) params['q'] = query;
      if (category != null) params['category'] = category;

      final response = await _dio.get('/books/search', queryParameters: params);
      return (response.data['books'] as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      print('Error searching books: $e');
      return _getMockBooks();
    }
  }

  Future<Book?> getBookById(String id) async {
    try {
      final response = await _dio.get('/books/$id');
      return Book.fromJson(response.data);
    } catch (e) {
      print('Error fetching book by id: $e');
      return _getMockBooks().firstWhere((book) => book.id == id);
    }
  }

  Future<List<Book>> getBookmarks() async {
    try {
      final response = await _dio.get('/user/bookmarks');
      return (response.data['bookmarks'] as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      print('Error fetching bookmarks: $e');
      return [];
    }
  }

  Future<void> addBookmark(String bookId) async {
    try {
      await _dio.post('/user/bookmarks/$bookId');
    } catch (e) {
      print('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark(String bookId) async {
    try {
      await _dio.delete('/user/bookmarks/$bookId');
    } catch (e) {
      print('Error removing bookmark: $e');
    }
  }

  // Mock data for development
  List<Book> _getMockBooks() {
    return [
      Book(
        id: '1',
        title: '7つの習慣',
        author: 'スティーブン・R・コヴィー',
        description: '世界中で支持される自己啓発書の決定版。人格主義の回復を訴え、真の成功を得るための原則を説く。',
        coverUrl: 'https://placehold.jp/300x400',
        audioUrl: 'https://example.com/audio1.mp3',
        duration: 180,
        category: '自己啓発',
        chapters: [
          Chapter(
            id: '1-1',
            title: 'パラダイムと原則',
            duration: 30,
            startTime: 0,
            endTime: 1800,
          ),
          Chapter(
            id: '1-2',
            title: '私的成功',
            duration: 45,
            startTime: 1800,
            endTime: 4500,
          ),
          Chapter(
            id: '1-3',
            title: '公的成功',
            duration: 45,
            startTime: 4500,
            endTime: 7200,
          ),
        ],
        rating: 4.5,
        reviewCount: 1234,
      ),
      Book(
        id: '2',
        title: '人を動かす',
        author: 'デール・カーネギー',
        description: '人間関係の原則を説いた不朽の名著。相手の立場に立って考えることの重要性を説く。',
        coverUrl: 'https://placehold.jp/300x400',
        audioUrl: 'https://example.com/audio2.mp3',
        duration: 150,
        category: 'ビジネス',
        chapters: [
          Chapter(
            id: '2-1',
            title: '人を動かす三原則',
            duration: 40,
            startTime: 0,
            endTime: 2400,
          ),
          Chapter(
            id: '2-2',
            title: '人に好かれる六原則',
            duration: 50,
            startTime: 2400,
            endTime: 5400,
          ),
        ],
        rating: 4.3,
        reviewCount: 856,
        isPremium: true,
      ),
      Book(
        id: '3',
        title: '嫌われる勇気',
        author: '岸見一郎、古賀史健',
        description: 'アドラー心理学を対話形式でわかりやすく解説。自由に生きるための考え方を学ぶ。',
        coverUrl: 'https://placehold.jp/300x400',
        audioUrl: 'https://example.com/audio3.mp3',
        duration: 120,
        category: '心理学',
        chapters: [
          Chapter(
            id: '3-1',
            title: '第一夜',
            duration: 30,
            startTime: 0,
            endTime: 1800,
          ),
          Chapter(
            id: '3-2',
            title: '第二夜',
            duration: 30,
            startTime: 1800,
            endTime: 3600,
          ),
        ],
        rating: 4.7,
        reviewCount: 2156,
      ),
    ];
  }
}
