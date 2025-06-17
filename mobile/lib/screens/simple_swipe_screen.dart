import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../models/swipe.dart';
import '../services/simple_swipe_service.dart';
import '../services/cloud_tts_service.dart';
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
  late CloudTtsService _ttsService;
  List<Map<String, dynamic>> _quotes = [];
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
    _loadQuotes();
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
      
      // Auto-speak next quote if enabled
      _autoSpeakCurrentQuote();
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
      
      // Auto-speak next quote if enabled
      _autoSpeakCurrentQuote();
    }
  }
  
  void _autoSpeakCurrentQuote() {
    if (_currentIndex < _quotes.length) {
      final quote = _quotes[_currentIndex];
      final quoteText = quote['quote']['text'] ?? '';
      _ttsService.autoSpeak(quoteText);
    }
  }

  Future<void> _speakCurrentQuote() async {
    if (_currentIndex < _quotes.length) {
      final quote = _quotes[_currentIndex];
      final quoteText = quote['quote']['text'] ?? '';
      
      if (_isSpeaking) {
        print("Stopping TTS...");
        await _ttsService.stop();
      } else {
        print("Starting TTS for quote: $quoteText");
        await _ttsService.speak(quoteText);
      }
    }
  }

  Future<void> _testTTS() async {
    const testText = "これはテスト音声です。音声が聞こえますか？";
    print("Testing TTS with: $testText");
    
    if (_isSpeaking) {
      await _ttsService.stop();
    } else {
      await _ttsService.speak(testText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == SwipeMode.tinder ? 'Swipe Mode' : 'Quote Comparison'),
        centerTitle: true,
        actions: [
          // Auto-play toggle
          IconButton(
            icon: Icon(
              _ttsService.autoPlayEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: _ttsService.autoPlayEnabled ? Colors.orange : null,
            ),
            onPressed: () {
              setState(() {
                _ttsService.setAutoPlayEnabled(!_ttsService.autoPlayEnabled);
              });
            },
            tooltip: _ttsService.autoPlayEnabled ? '自動読み上げを停止' : '自動読み上げを有効化',
          ),
          // Test TTS button
          IconButton(
            icon: Icon(
              Icons.volume_up,
              color: Colors.green,
            ),
            onPressed: _testTTS,
            tooltip: 'TTS テスト',
          ),
          if (_quotes.isNotEmpty && _currentIndex < _quotes.length)
            IconButton(
              icon: Icon(
                _isSpeaking ? Icons.stop : Icons.record_voice_over,
                color: _isSpeaking ? Colors.red : null,
              ),
              onPressed: _speakCurrentQuote,
              tooltip: _isSpeaking ? '読み上げを停止' : '引用文を読み上げ',
            ),
        ],
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