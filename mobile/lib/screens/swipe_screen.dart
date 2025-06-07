import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/swipe.dart';
import '../services/swipe_service.dart';
import '../services/context_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/swipe_card_widget.dart';

class SwipeScreen extends StatefulWidget {
  final SwipeMode mode;

  const SwipeScreen({
    Key? key,
    this.mode = SwipeMode.tinder,
  }) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  late SwipeService _swipeService;
  late ContextService _contextService;
  late AuthProvider _authProvider;

  List<QuoteWithBook> _quotes = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _sessionId;
  int _currentIndex = 0;
  
  // Context and stats
  ContextData? _currentContext;
  int _swipeCount = 0;
  int _likeCount = 0;
  int _loveCount = 0;
  
  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _stackController;
  late Animation<double> _loadingAnimation;

  // Preloading
  static const int _preloadThreshold = 3; // Load more when 3 cards left
  static const int _initialLoadCount = 10;
  static const int _subsequentLoadCount = 5;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialQuotes();
  }

  void _initializeServices() {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Note: In a real app, these would be injected via DI
    // _swipeService = Provider.of<SwipeService>(context, listen: false);
    // _contextService = Provider.of<ContextService>(context, listen: false);
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _stackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _loadingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialQuotes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get current context
      if (_contextService != null) {
        _currentContext = await _contextService.getCurrentContext();
      }

      // Load quotes
      final response = await _swipeService.getSwipeQuotes(
        userId: _authProvider.user!.id,
        mode: widget.mode,
        count: _initialLoadCount,
        context: _currentContext,
      );

      setState(() {
        _quotes = response.quotes;
        _sessionId = response.sessionId;
        _currentIndex = 0;
        _isLoading = false;
      });

      // Cache quotes for offline use
      await _swipeService.cacheQuotes(response, widget.mode);

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      _showErrorSnackBar('Failed to load quotes: $e');
    }
  }

  Future<void> _loadMoreQuotes() async {
    if (_isLoading || _quotes.length - _currentIndex > _preloadThreshold) {
      return;
    }

    try {
      // Get IDs of quotes already shown
      final excludeIds = _quotes.take(_currentIndex + _preloadThreshold).map((q) => q.quote.id).toList();

      final response = await _swipeService.getSwipeQuotes(
        userId: _authProvider.user!.id,
        mode: widget.mode,
        count: _subsequentLoadCount,
        context: _currentContext,
        excludeIds: excludeIds,
      );

      setState(() {
        _quotes.addAll(response.quotes);
      });

      // Update cache
      await _swipeService.cacheQuotes(
        SwipeQuoteResponse(
          quotes: _quotes,
          totalCount: _quotes.length,
          hasMore: response.hasMore,
          sessionId: response.sessionId,
        ),
        widget.mode,
      );

    } catch (e) {
      print('Error loading more quotes: $e');
      // Don't show error for background loading
    }
  }

  void _onSwipe(SwipeChoice choice, int duration) {
    if (_currentIndex >= _quotes.length) return;

    final quote = _quotes[_currentIndex];
    
    // Update stats
    setState(() {
      _swipeCount++;
      if (choice == SwipeChoice.like) _likeCount++;
      if (choice == SwipeChoice.love) _loveCount++;
      _currentIndex++;
    });

    // Log swipe
    _logSwipe(quote, choice, duration);

    // Provide haptic feedback based on choice
    _provideFeedback(choice);

    // Load more quotes if needed
    if (_quotes.length - _currentIndex <= _preloadThreshold) {
      _loadMoreQuotes();
    }

    // Check if we're running out of quotes
    if (_currentIndex >= _quotes.length) {
      _showNoMoreQuotesDialog();
    }
  }

  Future<void> _logSwipe(QuoteWithBook quoteWithBook, SwipeChoice choice, int duration) async {
    try {
      await _swipeService.logSwipe(
        userId: _authProvider.user!.id,
        quoteId: quoteWithBook.quote.id,
        mode: widget.mode,
        choice: choice,
        contextData: _currentContext,
        swipeDurationMs: duration,
        sessionId: _sessionId,
      );
    } catch (e) {
      print('Error logging swipe: $e');
      // Error handling is done in the service (offline logging)
    }
  }

  void _provideFeedback(SwipeChoice choice) {
    switch (choice) {
      case SwipeChoice.love:
        HapticFeedback.heavyImpact();
        break;
      case SwipeChoice.like:
        HapticFeedback.mediumImpact();
        break;
      case SwipeChoice.dislike:
        HapticFeedback.lightImpact();
        break;
      case SwipeChoice.skip:
        HapticFeedback.selectionClick();
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadInitialQuotes,
        ),
      ),
    );
  }

  void _showNoMoreQuotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No More Quotes'),
        content: Text(
          'You\'ve swiped through all available quotes!\n\n'
          'Swipes: $_swipeCount\n'
          'Likes: $_likeCount\n'
          'Loves: $_loveCount',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadInitialQuotes();
            },
            child: const Text('Load More'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _onCardTap() {
    // Show quote details or book information
    if (_currentIndex < _quotes.length) {
      _showQuoteDetails(_quotes[_currentIndex]);
    }
  }

  void _showQuoteDetails(QuoteWithBook quoteWithBook) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Book info
                Text(
                  quoteWithBook.book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${quoteWithBook.book.author}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quote
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quote:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quoteWithBook.quote.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Book description
                        if (quoteWithBook.book.description.isNotEmpty) ...[
                          Text(
                            'About the Book:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quoteWithBook.book.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Navigate to book detail
                                },
                                child: const Text('Read Book'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Add to favorites or bookmarks
                                },
                                child: const Text('Save Quote'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchMode() {
    final newMode = widget.mode == SwipeMode.tinder ? SwipeMode.facemash : SwipeMode.tinder;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SwipeScreen(mode: newMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.mode.displayName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _switchMode,
            tooltip: 'Switch Mode',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // Show stats
            },
            tooltip: 'Stats',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _quotes.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError && _quotes.isEmpty) {
      return _buildErrorState();
    }

    if (_quotes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSwipeStack();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_loadingAnimation.value * 0.4),
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Loading quotes...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.mode.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load quotes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialQuotes,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No quotes available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialQuotes,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeStack() {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Build stack of cards (show up to 3)
            for (int i = _currentIndex; i < _currentIndex + 3 && i < _quotes.length; i++)
              AnimationConfiguration.staggeredList(
                position: i - _currentIndex,
                duration: const Duration(milliseconds: 300),
                child: SlideAnimation(
                  verticalOffset: (i - _currentIndex) * 10.0,
                  child: SwipeCardWidget(
                    key: ValueKey('quote_${_quotes[i].quote.id}'),
                    quoteWithBook: _quotes[i],
                    onSwipe: i == _currentIndex ? _onSwipe : null,
                    onTap: i == _currentIndex ? _onCardTap : null,
                    isTopCard: i == _currentIndex,
                    stackIndex: i - _currentIndex.toDouble(),
                  ),
                ),
              ),
            
            // Loading indicator for next cards
            if (_isLoading && _quotes.length - _currentIndex <= _preloadThreshold)
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading more...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Stats
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_swipeCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'Swipes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                onPressed: () => _performSwipeAction(SwipeChoice.dislike),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.keyboard_arrow_down,
                color: Colors.orange,
                onPressed: () => _performSwipeAction(SwipeChoice.skip),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.favorite,
                color: Colors.green,
                onPressed: () => _performSwipeAction(SwipeChoice.like),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.favorite_border,
                color: Colors.purple,
                onPressed: () => _performSwipeAction(SwipeChoice.love),
              ),
            ],
          ),
          
          // Progress
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_quotes.length - _currentIndex}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _performSwipeAction(SwipeChoice choice) {
    if (_currentIndex >= _quotes.length) return;
    
    // Simulate programmatic swipe
    _onSwipe(choice, 0);
  }
}