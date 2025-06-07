import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/book.dart';
import '../models/session_models.dart' as session_models;
import '../services/audio_service.dart';
import '../services/session_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioService _audioService;
  final SessionService _sessionService;
  Book? _currentBook;
  int _currentChapterIndex = 0;
  Timer? _sleepTimer;
  session_models.ReadingSession? _currentSession;
  session_models.VoiceSettings _voiceSettings = session_models.VoiceSettings.defaultSettings;
  Timer? _progressUpdateTimer;
  
  // Loading states
  bool _isLoadingAudio = false;
  String? _loadingError;
  
  Book? get currentBook => _currentBook;
  int get currentChapterIndex => _currentChapterIndex;
  Chapter? get currentChapter => 
      _currentBook != null && _currentChapterIndex < _currentBook!.chapters.length 
          ? _currentBook!.chapters[_currentChapterIndex] 
          : null;
  session_models.ReadingSession? get currentSession => _currentSession;
  session_models.VoiceSettings get voiceSettings => _voiceSettings;
  bool get isLoadingAudio => _isLoadingAudio;
  String? get loadingError => _loadingError;
  
  bool get hasNextChapter => 
      _currentBook != null && _currentChapterIndex < _currentBook!.chapters.length - 1;
  
  bool get hasPreviousChapter => _currentChapterIndex > 0;
  
  Duration? get duration => _audioPlayer.duration;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  AudioPlayerProvider({
    required AudioService audioService,
    required SessionService sessionService,
  }) : _audioService = audioService,
       _sessionService = sessionService {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Set up audio session
    _audioPlayer.playbackEventStream.listen((event) {
      // Handle playback events
    }, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  Future<void> setBook(Book book, {int chapterIndex = 0}) async {
    _currentBook = book;
    _currentChapterIndex = chapterIndex;
    
    // Check for active session
    try {
      _currentSession = await _sessionService.getActiveSession(book.id);
      if (_currentSession != null) {
        _currentChapterIndex = _currentSession!.currentPos;
      }
    } catch (e) {
      print('No active session found: $e');
    }
    
    // Create new session if none exists
    if (_currentSession == null) {
      try {
        _currentSession = await _sessionService.createSession(
          CreateSessionRequest(
            bookId: book.id,
            startPos: _currentChapterIndex,
          ),
        );
      } catch (e) {
        print('Failed to create session: $e');
      }
    }
    
    await _loadAudio();
    _startProgressTracking();
    notifyListeners();
  }

  Future<void> _loadAudio() async {
    if (_currentBook == null) return;

    _isLoadingAudio = true;
    _loadingError = null;
    notifyListeners();

    try {
      // Generate TTS audio for current chapter
      final ttsResponse = await _audioService.getChapterAudio(
        _currentBook!.id,
        _currentChapterIndex,
      );
      
      // Create audio source with metadata for background playbook
      final audioSource = AudioSource.uri(
        Uri.parse(ttsResponse.audioUrl),
        tag: MediaItem(
          id: '${_currentBook!.id}_$_currentChapterIndex',
          album: _currentBook!.author,
          title: '${_currentBook!.title} - Chapter ${_currentChapterIndex + 1}',
          artUri: Uri.parse(_currentBook!.coverUrl),
        ),
      );

      await _audioPlayer.setAudioSource(audioSource);
      _isLoadingAudio = false;
      notifyListeners();
    } catch (e) {
      _isLoadingAudio = false;
      _loadingError = e.toString();
      notifyListeners();
      print("Error loading audio: $e");
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToChapter(int chapterIndex) async {
    if (_currentBook == null || 
        chapterIndex < 0 || 
        chapterIndex >= _currentBook!.chapters.length) return;

    _currentChapterIndex = chapterIndex;
    await _loadAudio(); // Load new chapter audio
    await _updateSessionProgress();
    notifyListeners();
  }

  Future<void> nextChapter() async {
    if (hasNextChapter) {
      await seekToChapter(_currentChapterIndex + 1);
    }
  }

  Future<void> previousChapter() async {
    if (hasPreviousChapter) {
      await seekToChapter(_currentChapterIndex - 1);
    }
  }

  Future<void> rewind() async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition - const Duration(seconds: 30);
    await _audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  Future<void> fastForward() async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition + const Duration(seconds: 30);
    final maxDuration = _audioPlayer.duration ?? Duration.zero;
    await _audioPlayer.seek(
      newPosition > maxDuration ? maxDuration : newPosition,
    );
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
      _sleepTimer = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    notifyListeners();
  }

  void setVoiceSettings(VoiceSettings settings) {
    _voiceSettings = settings;
    // Reload audio with new voice settings
    if (_currentBook != null) {
      _loadAudio();
    }
  }
  
  void _startProgressTracking() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(seconds: 30), // Update every 30 seconds
      (_) => _updateSessionProgress(),
    );
  }
  
  Future<void> _updateSessionProgress() async {
    if (_currentSession == null) return;
    
    try {
      final position = _audioPlayer.position;
      final duration = _audioPlayer.duration ?? Duration.zero;
      
      final update = SessionProgressUpdate(
        currentPos: _currentChapterIndex,
        durationSec: position.inSeconds,
      );
      
      await _sessionService.updateProgress(_currentSession!.id, update);
    } catch (e) {
      print('Failed to update session progress: $e');
    }
  }
  
  Future<void> endCurrentSession() async {
    if (_currentSession != null) {
      try {
        await _sessionService.endSession(_currentSession!.id);
        _currentSession = null;
      } catch (e) {
        print('Failed to end session: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _sleepTimer?.cancel();
    _progressUpdateTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}