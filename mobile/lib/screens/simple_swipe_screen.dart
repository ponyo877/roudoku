import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/swipe.dart';
import '../services/simple_swipe_service.dart';
import '../widgets/simple_swipe_card.dart';

class SimpleSwipeScreen extends StatefulWidget {
  final SwipeMode mode;

  const SimpleSwipeScreen({
    Key? key,
    this.mode = SwipeMode.tinder,
  }) : super(key: key);

  @override
  State<SimpleSwipeScreen> createState() => _SimpleSwipeScreenState();
}

class _SimpleSwipeScreenState extends State<SimpleSwipeScreen> {
  late SimpleSwipeService _swipeService;
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _swipeService = SimpleSwipeService(Dio());
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final quotes = await _swipeService.getQuotesForSwipe(count: 10);
      setState(() {
        _quotes = quotes;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSwipeLeft() {
    if (_currentIndex < _quotes.length) {
      final quote = _quotes[_currentIndex];
      final quoteId = quote['quote']['id'].toString();
      
      _swipeService.logSwipe(
        userId: 'test-user', // For testing
        quoteId: quoteId,
        mode: widget.mode.name,
        choice: -1, // Dislike
      );

      setState(() {
        _currentIndex++;
      });
    }
  }

  void _onSwipeRight() {
    if (_currentIndex < _quotes.length) {
      final quote = _quotes[_currentIndex];
      final quoteId = quote['quote']['id'].toString();
      
      _swipeService.logSwipe(
        userId: 'test-user', // For testing
        quoteId: quoteId,
        mode: widget.mode.name,
        choice: 1, // Like
      );

      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == SwipeMode.tinder ? 'Swipe Mode' : 'Quote Comparison'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading quotes...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuotes,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_quotes.isEmpty || _currentIndex >= _quotes.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All done!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('You have swiped through all available quotes.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuotes,
              child: const Text('Load More'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SimpleSwipeCard(
        quoteData: _quotes[_currentIndex],
        onSwipeLeft: _onSwipeLeft,
        onSwipeRight: _onSwipeRight,
      ),
    );
  }
}