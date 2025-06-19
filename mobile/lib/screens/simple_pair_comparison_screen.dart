import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../services/simple_swipe_service.dart';
import '../services/cloud_tts_service.dart';

class SimplePairComparisonScreen extends StatefulWidget {
  const SimplePairComparisonScreen({super.key});

  @override
  State<SimplePairComparisonScreen> createState() =>
      _SimplePairComparisonScreenState();
}

class _SimplePairComparisonScreenState
    extends State<SimplePairComparisonScreen> {
  late SimpleSwipeService _swipeService;
  late CloudTtsService _ttsService;
  List<Map<String, dynamic>> _pairs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentIndex = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _swipeService = SimpleSwipeService(Dio());
    _ttsService = Provider.of<CloudTtsService>(context, listen: false);
    _setupTtsCallbacks();
    _loadPairs();
  }

  void _setupTtsCallbacks() {
    _ttsService.onPlayingChanged = () {
      if (mounted) {
        setState(() {
          _isSpeaking = _ttsService.isPlaying;
        });
      }
    };
  }

  Future<void> _loadPairs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final quotes = await _swipeService.getQuotesForSwipe(count: 10);
      final pairs = _swipeService.createPairs(quotes, 5);

      setState(() {
        _pairs = pairs;
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

  void _selectQuote(String selectedQuoteId) {
    if (_currentIndex < _pairs.length) {
      _swipeService.logSwipe(
        userId: 'test-user', // For testing
        quoteId: selectedQuoteId,
        mode: 'facemash',
        choice: 1, // Selected
      );

      setState(() {
        _currentIndex++;
      });
    }
  }

  Future<void> _speakQuote(String quoteText) async {
    if (_isSpeaking) {
      await _ttsService.stop();
    } else {
      await _ttsService.speak(quoteText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Comparison'), centerTitle: true),
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
            Text('Loading quote pairs...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
              onPressed: _loadPairs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_pairs.isEmpty || _currentIndex >= _pairs.length) {
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
            Text('All done!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('You have compared all available quote pairs.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPairs,
              child: const Text('Load More'),
            ),
          ],
        ),
      );
    }

    final currentPair = _pairs[_currentIndex];
    final quoteA = currentPair['quote_a'];
    final quoteB = currentPair['quote_b'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Which quote do you prefer?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuoteCard(
                    quote: quoteA,
                    onTap: () => _selectQuote(quoteA['quote']['id'].toString()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuoteCard(
                    quote: quoteB,
                    onTap: () => _selectQuote(quoteB['quote']['id'].toString()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Comparison ${_currentIndex + 1} of ${_pairs.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard({
    required Map<String, dynamic> quote,
    required VoidCallback onTap,
  }) {
    final quoteText = quote['quote']['text'] ?? '';
    final bookTitle = quote['book']['title'] ?? '';
    final bookAuthor = quote['book']['author'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    quoteText,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // TTS button
              IconButton(
                icon: Icon(
                  _isSpeaking ? Icons.stop : Icons.volume_up,
                  color: _isSpeaking ? Colors.red : Colors.blue,
                ),
                onPressed: () => _speakQuote(quoteText),
                tooltip: _isSpeaking ? '読み上げを停止' : '引用文を読み上げ',
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    bookTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bookAuthor,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
