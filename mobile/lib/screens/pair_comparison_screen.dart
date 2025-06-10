import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/swipe.dart';
import '../services/swipe_service.dart';
import '../services/context_service.dart';
import '../providers/auth_provider.dart';

class PairComparisonScreen extends StatefulWidget {
  const PairComparisonScreen({super.key});

  @override
  State<PairComparisonScreen> createState() => _PairComparisonScreenState();
}

class _PairComparisonScreenState extends State<PairComparisonScreen>
    with TickerProviderStateMixin {
  late SwipeService _swipeService;
  late ContextService _contextService;
  late AuthProvider _authProvider;

  List<QuotePair> _pairs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _sessionId;
  int _currentIndex = 0;

  // Context and stats
  ContextData? _currentContext;
  int _comparisonCount = 0;
  final Map<String, int> _authorWins = {};

  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _choiceController;
  late AnimationController _transitionController;

  late Animation<double> _loadingAnimation;
  late Animation<double> _choiceScaleAnimation;
  late Animation<Offset> _transitionAnimation;

  // Choice tracking
  bool _isChoosing = false;
  String? _chosenQuoteId;
  DateTime? _choiceStartTime;

  // Preloading constants
  static const int _preloadThreshold = 2;
  static const int _initialLoadCount = 5;
  static const int _subsequentLoadCount = 3;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialPairs();
  }

  void _initializeServices() {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Note: In a real app, these would be injected via DI
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _choiceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _choiceScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _choiceController, curve: Curves.easeOut),
    );

    _transitionAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.0)).animate(
          CurvedAnimation(
            parent: _transitionController,
            curve: Curves.easeInCubic,
          ),
        );

    _loadingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _choiceController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPairs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get current context
      _currentContext = await _contextService.getCurrentContext();

      // Load pairs
      final response = await _swipeService.getSwipePairs(
        userId: _authProvider.currentUser!.id,
        count: _initialLoadCount,
        context: _currentContext,
      );

      setState(() {
        _pairs = response.pairs;
        _sessionId = response.sessionId;
        _currentIndex = 0;
        _isLoading = false;
      });

      // Cache pairs for offline use
      await _swipeService.cachePairs(response);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // Defer showing SnackBar until after the build is complete
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showErrorSnackBar('Failed to load quote pairs: $e');
          }
        });
      }
    }
  }

  Future<void> _loadMorePairs() async {
    if (_isLoading || _pairs.length - _currentIndex > _preloadThreshold) {
      return;
    }

    try {
      // Get IDs of quotes already shown
      final excludeIds = <String>[];
      for (
        int i = 0;
        i < _currentIndex + _preloadThreshold && i < _pairs.length;
        i++
      ) {
        excludeIds.add(_pairs[i].quoteA.quote.id);
        excludeIds.add(_pairs[i].quoteB.quote.id);
      }

      final response = await _swipeService.getSwipePairs(
        userId: _authProvider.currentUser!.id,
        count: _subsequentLoadCount,
        context: _currentContext,
        excludeIds: excludeIds,
      );

      setState(() {
        _pairs.addAll(response.pairs);
      });

      // Update cache
      await _swipeService.cachePairs(
        SwipePairResponse(
          pairs: _pairs,
          totalCount: _pairs.length,
          hasMore: response.hasMore,
          sessionId: response.sessionId,
        ),
      );
    } catch (e) {
      print('Error loading more pairs: $e');
    }
  }

  void _onQuoteChosen(QuoteWithBook chosen, QuoteWithBook other) async {
    if (_isChoosing || _currentIndex >= _pairs.length) return;

    setState(() {
      _isChoosing = true;
      _chosenQuoteId = chosen.quote.id;
    });

    // Calculate choice duration
    final choiceDuration = _choiceStartTime != null
        ? DateTime.now().difference(_choiceStartTime!).inMilliseconds
        : null;

    // Animate choice
    await _choiceController.forward();

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Wait a moment to show the choice
    await Future.delayed(const Duration(milliseconds: 300));

    // Log the comparison
    await _logComparison(chosen, other, choiceDuration);

    // Update stats
    setState(() {
      _comparisonCount++;
      _authorWins[chosen.book.author] =
          (_authorWins[chosen.book.author] ?? 0) + 1;
      _currentIndex++;
    });

    // Transition to next pair
    await _transitionController.forward();

    // Reset for next comparison
    _choiceController.reset();
    _transitionController.reset();

    setState(() {
      _isChoosing = false;
      _chosenQuoteId = null;
      _choiceStartTime = DateTime.now();
    });

    // Load more pairs if needed
    if (_pairs.length - _currentIndex <= _preloadThreshold) {
      _loadMorePairs();
    }

    // Check if we're running out of pairs
    if (_currentIndex >= _pairs.length) {
      _showNoMorePairsDialog();
    }
  }

  Future<void> _logComparison(
    QuoteWithBook chosen,
    QuoteWithBook other,
    int? duration,
  ) async {
    try {
      await _swipeService.logComparison(
        userId: _authProvider.currentUser!.id,
        chosenQuoteId: chosen.quote.id,
        otherQuoteId: other.quote.id,
        contextData: _currentContext,
        swipeDurationMs: duration,
        sessionId: _sessionId,
      );
    } catch (e) {
      print('Error logging comparison: $e');
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
          onPressed: _loadInitialPairs,
        ),
      ),
    );
  }

  void _showNoMorePairsDialog() {
    // Get top authors
    final sortedAuthors = _authorWins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comparison Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'ve compared $_comparisonCount quote pairs!'),
            const SizedBox(height: 16),
            if (sortedAuthors.isNotEmpty) ...[
              const Text(
                'Your favorite authors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sortedAuthors
                  .take(3)
                  .map((entry) => Text('${entry.key}: ${entry.value} wins')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadInitialPairs();
            },
            child: const Text('Compare More'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quote Comparison'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatsDialog,
            tooltip: 'Stats',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _pairs.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError && _pairs.isEmpty) {
      return _buildErrorState();
    }

    if (_pairs.isEmpty) {
      return _buildEmptyState();
    }

    if (_currentIndex >= _pairs.length) {
      return _buildCompletedState();
    }

    return _buildComparisonView();
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
            'Loading quote pairs...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred quote between two options',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load quote pairs',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialPairs,
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
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No quote pairs available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialPairs,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Great job!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve compared $_comparisonCount quote pairs',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialPairs,
              child: const Text('Compare More'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    final pair = _pairs[_currentIndex];

    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Transform.translate(
          offset:
              _transitionAnimation.value * MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _pairs.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Instruction
                Text(
                  'Which quote do you prefer?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the quote you like better',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Quote comparison cards
                Expanded(
                  child: AnimationConfiguration.staggeredList(
                    position: _currentIndex,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildQuoteCard(
                            pair.quoteA,
                            () => _onQuoteChosen(pair.quoteA, pair.quoteB),
                            isChosen: _chosenQuoteId == pair.quoteA.quote.id,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // VS divider
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VS',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 2,
                                ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildQuoteCard(
                            pair.quoteB,
                            () => _onQuoteChosen(pair.quoteB, pair.quoteA),
                            isChosen: _chosenQuoteId == pair.quoteB.quote.id,
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
      },
    );
  }

  Widget _buildQuoteCard(
    QuoteWithBook quoteWithBook,
    VoidCallback onTap, {
    bool isChosen = false,
  }) {
    return AnimatedBuilder(
      animation: _choiceController,
      builder: (context, child) {
        final scale = isChosen ? _choiceScaleAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _isChoosing ? null : onTap,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isChosen
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChosen
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isChosen ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            quoteWithBook.book.author,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (isChosen) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      quoteWithBook.book.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Quote text
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            quoteWithBook.quote.text,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    // Chapter info
                    if (quoteWithBook.quote.chapterTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'From: ${quoteWithBook.quote.chapterTitle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          // Comparisons count
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_comparisonCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'Comparisons',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),

          // Current position
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentIndex + 1}/${_pairs.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Progress',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),

          // Skip button
          ElevatedButton.icon(
            onPressed: _isChoosing || _currentIndex >= _pairs.length
                ? null
                : _skipComparison,
            icon: const Icon(Icons.skip_next, size: 18),
            label: const Text('Skip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade700,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _skipComparison() {
    if (_isChoosing || _currentIndex >= _pairs.length) return;

    setState(() {
      _currentIndex++;
    });

    // Provide light haptic feedback
    HapticFeedback.lightImpact();

    // Load more pairs if needed
    if (_pairs.length - _currentIndex <= _preloadThreshold) {
      _loadMorePairs();
    }

    // Check if we're running out of pairs
    if (_currentIndex >= _pairs.length) {
      _showNoMorePairsDialog();
    }
  }

  void _showStatsDialog() {
    final sortedAuthors = _authorWins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comparison Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total comparisons: $_comparisonCount'),
            const SizedBox(height: 16),
            if (sortedAuthors.isNotEmpty) ...[
              const Text(
                'Favorite authors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sortedAuthors
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value} wins'),
                        ],
                      ),
                    ),
                  ),
            ] else ...[
              const Text(
                'No comparisons yet. Start comparing quotes to see your preferences!',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
