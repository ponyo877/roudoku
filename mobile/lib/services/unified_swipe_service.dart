import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/dio_client.dart';
import '../core/logging/logger.dart';
import '../models/swipe.dart';
import '../models/book.dart';
import '../utils/constants.dart';

enum ServiceMode { full, simple }

class UnifiedSwipeService {
  final ServiceMode mode;
  final bool enableOfflineSupport;
  final bool enableCaching;
  final SharedPreferences? _prefs;
  final Connectivity _connectivity = Connectivity();

  Timer? _syncTimer;

  static const String _offlineSwipeLogsKey = 'offline_swipe_logs';
  static const String _swipeSessionKey = 'current_swipe_session';
  static const String _cachedQuotesKey = 'cached_quotes';
  static const String _cachedPairsKey = 'cached_pairs';

  UnifiedSwipeService._({
    required this.mode,
    this.enableOfflineSupport = true,
    this.enableCaching = true,
    SharedPreferences? prefs,
  }) : _prefs = prefs {
    if (enableOfflineSupport && _prefs == null) {
      Logger.warning(
        'Offline support requested but no SharedPreferences provided',
      );
    }
    _initialize();
  }

  factory UnifiedSwipeService.simple() {
    Logger.info('Creating simple swipe service');
    return UnifiedSwipeService._(
      mode: ServiceMode.simple,
      enableOfflineSupport: false,
      enableCaching: false,
    );
  }

  factory UnifiedSwipeService.full(SharedPreferences prefs) {
    Logger.info('Creating full-featured swipe service');
    return UnifiedSwipeService._(
      mode: ServiceMode.full,
      enableOfflineSupport: true,
      enableCaching: true,
      prefs: prefs,
    );
  }

  factory UnifiedSwipeService.custom({
    required ServiceMode mode,
    bool enableOfflineSupport = false,
    bool enableCaching = false,
    SharedPreferences? prefs,
  }) {
    Logger.info(
      'Creating custom swipe service: $mode, offline=$enableOfflineSupport, cache=$enableCaching',
    );
    return UnifiedSwipeService._(
      mode: mode,
      enableOfflineSupport: enableOfflineSupport,
      enableCaching: enableCaching,
      prefs: prefs,
    );
  }

  void _initialize() {
    if (enableOfflineSupport && _prefs != null) {
      _startPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _syncOfflineSwipeLogs();
    });
    Logger.debug('Periodic sync started for offline swipe logs');
  }

  Future<SwipeQuoteResponse> getSwipeQuotes({
    required String userId,
    required SwipeMode mode,
    int count = 10,
    ContextData? context,
    List<String>? excludeIds,
  }) async {
    Logger.debug(
      'Getting swipe quotes: userId=$userId, mode=$mode, count=$count',
    );

    try {
      final quotes = await _fetchQuotesFromBooks(count, excludeIds);

      final response = SwipeQuoteResponse(
        quotes: quotes.map((q) => q.toQuoteWithBook()).toList(),
        totalCount: quotes.length,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
        hasMore: quotes.length >= count,
      );

      if (enableCaching) {
        await _cacheQuotes(response);
      }

      return response;
    } catch (e) {
      Logger.error('Error getting swipe quotes', e);

      if (enableOfflineSupport) {
        Logger.warning('Attempting to load cached quotes');
        return await _getCachedQuotes(mode, count);
      }

      rethrow;
    }
  }

  Future<List<SwipeQuoteData>> getQuotes({int count = 10}) async {
    Logger.debug('Getting quotes (simple): count=$count');

    try {
      return await _fetchQuotesFromBooks(count, null);
    } catch (e) {
      Logger.error('Error getting quotes', e);

      if (enableCaching) {
        final cached = await _getCachedQuotesSimple(count);
        if (cached.isNotEmpty) {
          Logger.info('Returning ${cached.length} cached quotes');
          return cached
              .map((q) => SwipeQuoteData(quote: q.quote, book: q.book))
              .toList();
        }
      }

      rethrow;
    }
  }

  Future<List<SwipeQuoteData>> _fetchQuotesFromBooks(
    int count,
    List<String>? excludeIds,
  ) async {
    Logger.network('Fetching quotes from books API');

    final booksResponse = await DioClient.instance.dio.get('/books');
    final books = booksResponse.data['books'] as List;

    if (books.isEmpty) {
      throw Exception('No books available');
    }

    List<SwipeQuoteData> allQuotes = [];

    for (int i = 0; i < books.length && allQuotes.length < count; i++) {
      final book = books[i];
      final bookId = book['id'];

      try {
        final quotesResponse = await DioClient.instance.dio.get(
          '/books/$bookId/quotes/random',
          queryParameters: {'limit': 5},
        );

        final quotes = quotesResponse.data as List;
        for (var quoteData in quotes) {
          if (allQuotes.length < count) {
            if (excludeIds != null && excludeIds.contains(quoteData['id'])) {
              continue;
            }

            final quote = Quote.fromJson(quoteData);
            final bookObj = Book.fromJson(book);

            allQuotes.add(SwipeQuoteData(quote: quote, book: bookObj));
          }
        }
      } catch (e) {
        Logger.warning('Error fetching quotes for book $bookId: $e');
        continue;
      }
    }

    Logger.book(
      'Fetched ${allQuotes.length} quotes from ${books.length} books',
    );
    return allQuotes;
  }

  Future<SwipePairResponse> getSwipePairs({
    required String userId,
    int count = 5,
    ContextData? context,
    List<String>? excludeIds,
  }) async {
    Logger.debug('Getting swipe pairs: userId=$userId, count=$count');

    try {
      final quotes = await _fetchQuotesFromBooks(count * 2, excludeIds);
      final pairs = _createQuotePairs(quotes, count);

      final response = SwipePairResponse(
        pairs: pairs.map((p) => p.toQuotePair()).toList(),
        totalCount: pairs.length,
        sessionId: 'pair_session_${DateTime.now().millisecondsSinceEpoch}',
        hasMore: pairs.length >= count,
      );

      if (enableCaching) {
        await _cachePairs(response);
      }

      return response;
    } catch (e) {
      Logger.error('Error getting swipe pairs', e);

      if (enableOfflineSupport) {
        Logger.warning('Attempting to load cached pairs');
        return await _getCachedPairs(count);
      }

      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> createPairs({int count = 5}) async {
    Logger.debug('Creating pairs (simple): count=$count');

    try {
      final quotes = await _fetchQuotesFromBooks(count * 2, null);
      return _createQuotePairsSimple(quotes, count);
    } catch (e) {
      Logger.error('Error creating pairs', e);
      rethrow;
    }
  }

  List<SwipePairData> _createQuotePairs(
    List<SwipeQuoteData> quotes,
    int count,
  ) {
    List<SwipePairData> pairs = [];

    for (int i = 0; i < quotes.length - 1 && pairs.length < count; i += 2) {
      final pairId = 'pair_${DateTime.now().millisecondsSinceEpoch}_$i';
      final pair = SwipePairData(
        id: pairId,
        quoteA: quotes[i],
        quoteB: quotes[i + 1],
      );
      pairs.add(pair);
    }

    return pairs;
  }

  List<Map<String, dynamic>> _createQuotePairsSimple(
    List<SwipeQuoteData> quotes,
    int count,
  ) {
    List<Map<String, dynamic>> pairs = [];

    for (int i = 0; i < quotes.length - 1 && pairs.length < count; i += 2) {
      pairs.add({
        'id': 'pair_${DateTime.now().millisecondsSinceEpoch}_$i',
        'quote_a': _quoteDataToMap(quotes[i]),
        'quote_b': _quoteDataToMap(quotes[i + 1]),
      });
    }

    return pairs;
  }

  Map<String, dynamic> _quoteDataToMap(SwipeQuoteData quoteData) {
    return {
      'quote': {
        'id': quoteData.quote.id,
        'text': quoteData.quote.text,
        'book_id': quoteData.quote.bookId,
        'position': quoteData.quote.position,
        'chapter_title': quoteData.quote.chapterTitle,
      },
      'book': {
        'id': quoteData.book.id,
        'title': quoteData.book.title,
        'author': quoteData.book.author,
        'description': quoteData.book.description,
        'coverUrl': quoteData.book.coverUrl,
        'audioUrl': quoteData.book.audioUrl,
        'duration': quoteData.book.duration,
        'category': quoteData.book.category,
        'rating': quoteData.book.rating,
        'reviewCount': quoteData.book.reviewCount,
        'isPremium': quoteData.book.isPremium,
      },
    };
  }

  Future<void> logSwipe({
    required String userId,
    required String quoteId,
    required SwipeChoice choice,
    String? sessionId,
    ContextData? context,
  }) async {
    final request = LogSwipeRequest(
      userId: userId,
      quoteId: quoteId,
      mode: SwipeMode.tinder,
      choice: choice,
      sessionId: sessionId,
      contextData: context,
    );

    await _logSwipeInternal(request);
  }

  Future<void> logSwipeSimple({
    required String userId,
    required String quoteId,
    required int choice, // -1, 0, 1
  }) async {
    SwipeChoice swipeChoice;
    switch (choice) {
      case -1:
        swipeChoice = SwipeChoice.dislike;
        break;
      case 0:
        swipeChoice = SwipeChoice.skip;
        break;
      case 1:
        swipeChoice = SwipeChoice.like;
        break;
      default:
        throw ArgumentError('Invalid choice: $choice. Must be -1, 0, or 1');
    }

    await logSwipe(userId: userId, quoteId: quoteId, choice: swipeChoice);
  }

  Future<void> _logSwipeInternal(LogSwipeRequest request) async {
    Logger.debug(
      'Logging swipe: ${request.userId} -> ${request.quoteId} (${request.choice.name})',
    );

    try {
      await DioClient.instance.dio.post('/swipe/log', data: request.toJson());

      Logger.debug('Swipe logged successfully');
    } catch (e) {
      Logger.error('Error logging swipe', e);

      if (enableOfflineSupport) {
        await _saveOfflineSwipeLog(request);
        Logger.info('Swipe saved for offline sync');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _saveOfflineSwipeLog(LogSwipeRequest request) async {
    if (_prefs == null) return;

    final existingLogs = _prefs.getString(_offlineSwipeLogsKey) ?? '[]';
    final logs = jsonDecode(existingLogs) as List;

    logs.add(request.toJson());

    await _prefs.setString(_offlineSwipeLogsKey, jsonEncode(logs));
    Logger.debug('Saved offline swipe log (${logs.length} total)');
  }

  Future<void> _syncOfflineSwipeLogs() async {
    if (_prefs == null) return;

    final existingLogs = _prefs.getString(_offlineSwipeLogsKey);
    if (existingLogs == null || existingLogs == '[]') {
      return;
    }

    Logger.debug('Syncing offline swipe logs');

    try {
      final logs = jsonDecode(existingLogs) as List;

      for (final logData in logs) {
        final request = LogSwipeRequest.fromJson(logData);
        await DioClient.instance.dio.post('/swipe/log', data: request.toJson());
      }

      await _prefs.remove(_offlineSwipeLogsKey);
      Logger.info('Synced ${logs.length} offline swipe logs');
    } catch (e) {
      Logger.error('Error syncing offline swipe logs', e);
    }
  }

  Future<void> _cacheQuotes(SwipeQuoteResponse response) async {
    if (_prefs == null) return;

    try {
      final cacheData = {
        'quotes': response.quotes.map((q) => q.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_id': response.sessionId,
        'has_more': response.hasMore,
      };

      await _prefs.setString(_cachedQuotesKey, jsonEncode(cacheData));
      Logger.debug('Cached ${response.quotes.length} quotes');
    } catch (e) {
      Logger.error('Error caching quotes', e);
    }
  }

  Future<SwipeQuoteResponse> _getCachedQuotes(SwipeMode mode, int count) async {
    if (_prefs == null) {
      throw Exception('No cached quotes available');
    }

    try {
      final cachedData = _prefs.getString(_cachedQuotesKey);
      if (cachedData == null) {
        throw Exception('No cached quotes found');
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final quotes = (data['quotes'] as List)
          .map((q) => QuoteWithBook.fromJson(q))
          .take(count)
          .toList();

      Logger.info('Loaded ${quotes.length} cached quotes');

      return SwipeQuoteResponse(
        quotes: quotes,
        totalCount: quotes.length,
        sessionId: data['session_id'] ?? 'cached_session',
        hasMore: data['has_more'] ?? false,
      );
    } catch (e) {
      Logger.error('Error loading cached quotes', e);
      throw Exception('Failed to load cached quotes');
    }
  }

  Future<List<QuoteWithBook>> _getCachedQuotesSimple(int count) async {
    if (_prefs == null) return [];

    try {
      final cachedData = _prefs.getString(_cachedQuotesKey);
      if (cachedData == null) return [];

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final quotes = (data['quotes'] as List)
          .map((q) => QuoteWithBook.fromJson(q))
          .take(count)
          .toList();

      return quotes;
    } catch (e) {
      Logger.error('Error loading cached quotes (simple)', e);
      return [];
    }
  }

  Future<void> _cachePairs(SwipePairResponse response) async {
    if (_prefs == null) return;

    try {
      final cacheData = {
        'pairs': response.pairs.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'session_id': response.sessionId,
        'has_more': response.hasMore,
      };

      await _prefs.setString(_cachedPairsKey, jsonEncode(cacheData));
      Logger.debug('Cached ${response.pairs.length} pairs');
    } catch (e) {
      Logger.error('Error caching pairs', e);
    }
  }

  Future<SwipePairResponse> _getCachedPairs(int count) async {
    if (_prefs == null) {
      throw Exception('No cached pairs available');
    }

    try {
      final cachedData = _prefs.getString(_cachedPairsKey);
      if (cachedData == null) {
        throw Exception('No cached pairs found');
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final pairs = (data['pairs'] as List)
          .map((p) => QuotePair.fromJson(p))
          .take(count)
          .toList();

      Logger.info('Loaded ${pairs.length} cached pairs');

      return SwipePairResponse(
        pairs: pairs,
        totalCount: pairs.length,
        sessionId: data['session_id'] ?? 'cached_session',
        hasMore: data['has_more'] ?? false,
      );
    } catch (e) {
      Logger.error('Error loading cached pairs', e);
      throw Exception('Failed to load cached pairs');
    }
  }

  Future<Map<String, dynamic>> getSwipeStats(String userId) async {
    if (mode == ServiceMode.simple) {
      Logger.warning('Stats not available in simple mode');
      return {};
    }

    try {
      Logger.network('Fetching swipe stats for user $userId');
      final response = await DioClient.instance.dio.get('/swipe/stats/$userId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Error getting swipe stats', e);
      return {};
    }
  }

  Future<void> clearCache() async {
    if (_prefs == null) return;

    await _prefs.remove(_cachedQuotesKey);
    await _prefs.remove(_cachedPairsKey);
    Logger.info('Swipe cache cleared');
  }

  void dispose() {
    _syncTimer?.cancel();
    Logger.info('Unified swipe service disposed');
  }
}
