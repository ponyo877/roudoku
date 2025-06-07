import 'package:flutter/foundation.dart';
import '../models/swipe.dart';
import '../services/swipe_service.dart';
import '../services/context_service.dart';

class SwipeProvider extends ChangeNotifier {
  final SwipeService _swipeService;
  final ContextService _contextService;

  SwipeProvider(this._swipeService, this._contextService);

  // Current state
  List<QuoteWithBook> _quotes = [];
  List<QuotePair> _pairs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  ContextData? _currentContext;
  
  // Swipe statistics
  int _totalSwipes = 0;
  int _likesCount = 0;
  int _lovesCount = 0;
  int _dislikesCount = 0;
  int _skipsCount = 0;
  
  // Performance optimizations
  final Map<String, QuoteWithBook> _quoteCache = {};
  final Map<String, SwipeQuoteResponse> _responseCache = {};
  bool _isPreloading = false;

  // Getters
  List<QuoteWithBook> get quotes => _quotes;
  List<QuotePair> get pairs => _pairs;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  ContextData? get currentContext => _currentContext;
  
  // Statistics getters
  int get totalSwipes => _totalSwipes;
  int get likesCount => _likesCount;
  int get lovesCount => _lovesCount;
  int get dislikesCount => _dislikesCount;
  int get skipsCount => _skipsCount;
  
  double get likePercentage => _totalSwipes > 0 ? (_likesCount + _lovesCount) / _totalSwipes * 100 : 0.0;

  /// Load quotes for swiping
  Future<void> loadQuotes({
    required String userId,
    required SwipeMode mode,
    int count = 10,
    List<String>? excludeIds,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _setLoading(true);
    _clearError();

    try {
      // Get current context
      _currentContext = await _contextService.getCurrentContext();

      // Check cache first (if not forcing refresh)
      final cacheKey = '${mode.name}_${userId}_$count';
      if (!forceRefresh && _responseCache.containsKey(cacheKey)) {
        final cached = _responseCache[cacheKey]!;
        _quotes = cached.quotes;
        _setLoading(false);
        return;
      }

      // Load from service
      final response = await _swipeService.getSwipeQuotes(
        userId: userId,
        mode: mode,
        count: count,
        context: _currentContext,
        excludeIds: excludeIds,
      );

      _quotes = response.quotes;
      
      // Cache the response
      _responseCache[cacheKey] = response;
      
      // Cache individual quotes for faster access
      for (final quote in response.quotes) {
        _quoteCache[quote.quote.id] = quote;
      }

      _setLoading(false);
      
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load quote pairs for comparison
  Future<void> loadPairs({
    required String userId,
    int count = 5,
    List<String>? excludeIds,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _setLoading(true);
    _clearError();

    try {
      // Get current context
      _currentContext = await _contextService.getCurrentContext();

      // Load from service
      final response = await _swipeService.getSwipePairs(
        userId: userId,
        count: count,
        context: _currentContext,
        excludeIds: excludeIds,
      );

      _pairs = response.pairs;
      _setLoading(false);
      
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Preload additional quotes in the background
  Future<void> preloadQuotes({
    required String userId,
    required SwipeMode mode,
    int count = 5,
    List<String>? excludeIds,
  }) async {
    if (_isPreloading) return;

    _isPreloading = true;

    try {
      final response = await _swipeService.getSwipeQuotes(
        userId: userId,
        mode: mode,
        count: count,
        context: _currentContext,
        excludeIds: excludeIds,
      );

      // Add to existing quotes
      _quotes.addAll(response.quotes);
      
      // Cache individual quotes
      for (final quote in response.quotes) {
        _quoteCache[quote.quote.id] = quote;
      }

      notifyListeners();
      
    } catch (e) {
      // Silent fail for preloading
      debugPrint('Preloading failed: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Log a swipe action and update statistics
  Future<void> logSwipe({
    required String userId,
    required String quoteId,
    required SwipeMode mode,
    required SwipeChoice choice,
    String? comparedQuoteId,
    int? swipeDurationMs,
    String? sessionId,
  }) async {
    try {
      // Log to service
      await _swipeService.logSwipe(
        userId: userId,
        quoteId: quoteId,
        mode: mode,
        choice: choice,
        comparedQuoteId: comparedQuoteId,
        contextData: _currentContext,
        swipeDurationMs: swipeDurationMs,
        sessionId: sessionId,
      );

      // Update local statistics
      _updateStatistics(choice);
      
    } catch (e) {
      debugPrint('Failed to log swipe: $e');
      // Still update local stats even if logging fails
      _updateStatistics(choice);
    }
  }

  /// Log a comparison choice
  Future<void> logComparison({
    required String userId,
    required String chosenQuoteId,
    required String otherQuoteId,
    int? swipeDurationMs,
    String? sessionId,
  }) async {
    try {
      await _swipeService.logComparison(
        userId: userId,
        chosenQuoteId: chosenQuoteId,
        otherQuoteId: otherQuoteId,
        contextData: _currentContext,
        swipeDurationMs: swipeDurationMs,
        sessionId: sessionId,
      );

      // Update statistics for comparison (count as like)
      _updateStatistics(SwipeChoice.like);
      
    } catch (e) {
      debugPrint('Failed to log comparison: $e');
      _updateStatistics(SwipeChoice.like);
    }
  }

  /// Get cached quote by ID
  QuoteWithBook? getCachedQuote(String quoteId) {
    return _quoteCache[quoteId];
  }

  /// Update current context
  Future<void> updateContext({
    String? userMood,
    String? userSituation,
    int? availableTime,
  }) async {
    try {
      _currentContext = await _contextService.getCurrentContext(
        userMood: userMood,
        userSituation: userSituation,
        availableTime: availableTime,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update context: $e');
    }
  }

  /// Get mood suggestions based on current context
  List<String> getMoodSuggestions() {
    if (_currentContext == null) return [];
    return _contextService.getMoodSuggestions(_currentContext!);
  }

  /// Get situation suggestions based on current context
  List<String> getSituationSuggestions() {
    if (_currentContext == null) return [];
    return _contextService.getSituationSuggestions(_currentContext!);
  }

  /// Clear all cached data
  void clearCache() {
    _quoteCache.clear();
    _responseCache.clear();
    _quotes.clear();
    _pairs.clear();
    notifyListeners();
  }

  /// Reset statistics
  void resetStatistics() {
    _totalSwipes = 0;
    _likesCount = 0;
    _lovesCount = 0;
    _dislikesCount = 0;
    _skipsCount = 0;
    notifyListeners();
  }

  /// Get offline logs count
  Future<int> getOfflineLogsCount() async {
    return await _swipeService.getPendingOfflineLogsCount();
  }

  /// Force sync offline logs
  Future<bool> syncOfflineLogs() async {
    return await _swipeService.forceSyncOfflineLogs();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_hasError) {
      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _updateStatistics(SwipeChoice choice) {
    _totalSwipes++;
    
    switch (choice) {
      case SwipeChoice.like:
        _likesCount++;
        break;
      case SwipeChoice.love:
        _lovesCount++;
        break;
      case SwipeChoice.dislike:
        _dislikesCount++;
        break;
      case SwipeChoice.skip:
        _skipsCount++;
        break;
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _quoteCache.clear();
    _responseCache.clear();
    super.dispose();
  }
}