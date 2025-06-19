import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/book.dart';
import '../models/session_models.dart' as session_models;
import '../services/audio_service.dart';
import '../services/session_service.dart';
import '../services/unified_tts_service.dart';
import '../utils/constants.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioService _audioService;
  final SessionService _sessionService;
  final UnifiedTtsService _ttsService;
  Book? _currentBook;
  int _currentChapterIndex = 0;
  Timer? _sleepTimer;
  session_models.ReadingSession? _currentSession;
  session_models.VoiceSettings _voiceSettings =
      session_models.VoiceSettings.defaultSettings;
  Timer? _progressUpdateTimer;

  // Loading states
  bool _isLoadingAudio = false;
  String? _loadingError;
  bool _isUsingTts = false;

  Book? get currentBook => _currentBook;
  int get currentChapterIndex => _currentChapterIndex;
  Chapter? get currentChapter =>
      _currentBook != null &&
          _currentChapterIndex < _currentBook!.chapters.length
      ? _currentBook!.chapters[_currentChapterIndex]
      : null;
  session_models.ReadingSession? get currentSession => _currentSession;
  session_models.VoiceSettings get voiceSettings => _voiceSettings;
  bool get isLoadingAudio => _isLoadingAudio;
  String? get loadingError => _loadingError;

  bool get hasNextChapter =>
      _currentBook != null &&
      _currentChapterIndex < _currentBook!.chapters.length - 1;

  bool get hasPreviousChapter => _currentChapterIndex > 0;

  Duration? get duration => _audioPlayer.duration;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  AudioPlayer get audioPlayer => _audioPlayer;

  AudioPlayerProvider({
    required AudioService audioService,
    required SessionService sessionService,
    required UnifiedTtsService ttsService,
  }) : _audioService = audioService,
       _sessionService = sessionService,
       _ttsService = ttsService {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Set up audio session
    _audioPlayer.playbackEventStream.listen(
      (event) {
        // Handle playback events
      },
      onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      },
    );

    // Set the audio player for the unified TTS service
    _ttsService.setAudioPlayer(_audioPlayer);
  }

  Future<void> setBook(Book book, {int chapterIndex = 0}) async {
    _currentBook = book;
    _currentChapterIndex = chapterIndex;

    // Check for active session
    try {
      _currentSession = await _sessionService.getActiveSession(
        int.parse(book.id),
      );
      if (_currentSession != null) {
        _currentChapterIndex = _currentSession!.currentPos;
      }
    } catch (e) {
      print('No active session found: $e');
    }

    // Skip session creation for now to avoid 404 errors
    // TODO: Implement proper user management and session creation
    print('Skipping session creation until user management is implemented');

    await _loadAudio();
    _startProgressTracking();
    notifyListeners();
  }

  Future<void> _loadAudio() async {
    if (_currentBook == null) return;

    print(
      '🎵 _loadAudio: Starting audio load for book: ${_currentBook!.title}, chapter: $_currentChapterIndex',
    );
    print(
      '🎵 _loadAudio: Book chapters count: ${_currentBook!.chapters.length}',
    );
    print('🎵 _loadAudio: Book audioUrl: ${_currentBook!.audioUrl}');

    _isLoadingAudio = true;
    _loadingError = null;
    _isUsingTts = false;
    notifyListeners();

    try {
      AudioSource? audioSource;

      // Skip original audio file loading for now since we're using database content
      // Instead, directly use TTS for the chapter content
      print('Skipping original audio, using TTS for database content');

      // Use TTS to read the actual chapter content from database
      _isUsingTts = true;
      print('Using TTS for chapter content from database');

      // Use TTS to speak the chapter content
      if (_currentBook != null && currentChapter != null) {
        await _ttsService.speak(currentChapter!.title);
        print('TTS started for chapter title');
      }

      _isLoadingAudio = false;
      notifyListeners();
    } catch (e) {
      _isLoadingAudio = false;
      _loadingError = e.toString();
      notifyListeners();
      print("Error loading audio: $e");
    }
  }

  Future<void> _loadTtsAudio() async {
    if (_currentBook == null) return;

    try {
      // Generate sample text for the chapter
      final chapterText = _generateChapterText();

      // Use TTS service to generate audio (this will create a temporary file)
      await _ttsService.speak(chapterText);

      // For now, we'll create a placeholder audio source
      // In a real implementation, you'd save the TTS audio to a file and use that
      final audioSource = AudioSource.uri(
        Uri.parse(
          'https://www.soundjay.com/misc/sounds/beep-07a.wav',
        ), // Placeholder
        tag: MediaItem(
          id: '${_currentBook!.id}_$_currentChapterIndex',
          album: _currentBook!.author,
          title: '${_currentBook!.title} - Chapter ${_currentChapterIndex + 1}',
          artUri: Uri.tryParse(_currentBook!.coverUrl),
        ),
      );

      await _audioPlayer.setAudioSource(audioSource);
      _isLoadingAudio = false;
      notifyListeners();
    } catch (e) {
      throw Exception('TTS audio loading failed: $e');
    }
  }

  String _generateChapterText() {
    print(
      '🎵 _generateChapterText: Book=${_currentBook?.title}, chapterIndex=$_currentChapterIndex, chaptersLength=${_currentBook?.chapters.length}',
    );

    if (_currentBook == null) {
      print('🎵 _generateChapterText: ERROR - No current book');
      return '書籍が選択されていません。';
    }

    if (_currentChapterIndex >= _currentBook!.chapters.length) {
      print('🎵 _generateChapterText: ERROR - Chapter index out of range');
      // Instead of error, provide fallback content for the book
      return '''${_currentBook!.title}の内容です。
      
このアプリでは、${_currentBook!.author}による「${_currentBook!.title}」の音声版をお楽しみいただけます。
${_currentBook!.description}''';
    }

    final chapter = _currentBook!.chapters[_currentChapterIndex];
    print('🎵 _generateChapterText: Chapter title=${chapter.title}');

    // Use sample chapter content based on the book
    String chapterContent = _getSampleChapterContent();
    print(
      '🎵 _generateChapterText: Generated content length=${chapterContent.length}',
    );

    return '''
第${_currentChapterIndex + 1}章: ${chapter.title}

$chapterContent
''';
  }

  String _getSampleChapterContent() {
    if (_currentBook == null) return '';

    print(
      '🎵 _getSampleChapterContent: Checking book title: "${_currentBook!.title}"',
    );

    // Sample content based on book title
    if (_currentBook!.title.contains('吾輩は猫である')) {
      print('🎵 _getSampleChapterContent: Matched 吾輩は猫である');
      switch (_currentChapterIndex) {
        case 0:
          return '''吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ。何でも薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。

吾輩はここで始めて人間というものを見た。しかもあとで聞くとそれは書生という人間中で一番獰悪な種族であったそうだ。この書生というのは時々我々を捕えて煮て食うという話である。しかしその当時は何という考もなかったから別段恐しいとも思わなかった。

ただ彼の掌に載せられてスーと持ち上げられた時何だかフワフワした感じがあったばかりである。''';
        case 1:
          return '''この書生の掌の裏でしばらくはよい心持に坐っておったが、しばらくすると非常に苦しくなった。第一胃袋が空虚な時に、振動を感ずるのは猫も同様である。

「ニャー、ニャー」と試みにやって見たが誰も何とも云わない。その内おかしな音がする。最初雨かと思ったが日は照っている。よく聞いて見ると御飯を炊く音であった。''';
        default:
          return '''${_currentBook!.title}の続きの内容です。猫の視点から人間社会を観察し、風刺的に描いた夏目漱石の代表作の一部です。''';
      }
    } else if (_currentBook!.title.contains('坊') ||
        _currentBook!.title.toLowerCase().contains('botchan')) {
      print(
        '🎵 _getSampleChapterContent: Matched 坊っちゃん - chapterIndex=$_currentChapterIndex',
      );
      switch (_currentChapterIndex) {
        case 0:
          return '''親譲りの無鉄砲で小供の時から損ばかりしている。小学校に居る時分学校の二階から飛び降りて一週間ほど腰を抜かした事がある。

なぜそんな無闇をしたと聞く人があるかも知れぬ。別段深い理由でもない。新築の二階から首を出していたら、同級生の一人が冗談に、いくら威張っても、そこから飛び降りる事は出来まい、弱虫やーい、と囃したからである。

小使に負ぶさって帰って来た時、おやじが大きな眼をして二階ぐらいから飛び降りて腰を抜かす奴があるかと云ったから、この次は抜かさずに飛んで見せますと答えた。''';
        case 1:
          return '''おやじは先妻の子があるからと云って、継母には滅多に逢わせない方針であった。継母にしても自分の関係しない子供を、無責任に庇護する必要はないと明言して憚らなかった。

もっとも古い時代にはとても現代ほど自由でなかった時代であったから、継母と雖も多少は遠慮をする風もあったが、この頃はだんだん自由になって、教育上にもわるい影響がないとは云えぬようになって来た。

継母は好い女であった。今でも時々継母の事を思い出す。''';
        case 2:
          return '''おれの父は継母にしても案外出来た人で、おれを手厳しく取り扱う事もなければ、甘く見る様な事もなかった。正月にくれる小遣も兄と同額で、えり分けをする様な事は決してなかった。
          
しかし時によると厳格すぎて、おれなんかが悪戯をするとよく小言を云われた。しかし継母の方は愛想のよい人で、どんなに叱られても、後でそっと髪を撫でて、坊ちゃんはお前のようにご正直だから、あんなひどい目に合うのですと慰めてくれる事もあった。''';
        default:
          return '''${_currentBook!.title}の続きの内容です。夏目漱石の代表作の一つで、江戸っ子気質の青年教師が四国の中学校に赴任し、様々な騒動を巻き起こす痛快な小説です。
          
この物語は、主人公の坊ちゃんが愛媛県の松山中学校に数学教師として赴任し、そこで出会う個性豊かな同僚たちや生徒たちとの交流を通じて成長していく様子を描いています。''';
      }
    }

    print(
      '🎵 _getSampleChapterContent: No specific match found, using default content',
    );
    // Default content with safe access
    final chapterTitle = _currentChapterIndex < _currentBook!.chapters.length
        ? _currentBook!.chapters[_currentChapterIndex].title
        : '第${_currentChapterIndex + 1}章';
    final chapterDuration = _currentChapterIndex < _currentBook!.chapters.length
        ? _currentBook!.chapters[_currentChapterIndex].duration
        : 30;

    return '''これは${_currentBook!.title}の第${_currentChapterIndex + 1}章、「$chapterTitle」の内容です。

${_currentBook!.description}

実際の書籍では、ここに章の本文が含まれます。
この章の予想読書時間は約$chapterDuration分です。''';
  }

  Future<String> _getGeneratedAudioUrl() async {
    if (_currentBook == null) {
      throw Exception('No book selected');
    }

    // Construct the URL for the generated audio
    // Use Constants.baseUrl to handle both dev and production environments
    final baseUrl = Constants.baseUrl;
    final audioUrl =
        '$baseUrl/api/v1/audio/book?book_id=${_currentBook!.id}&chapter_id=$_currentChapterIndex';

    print(
      'Generated audio URL: $audioUrl for book "${_currentBook!.title}" chapter ${_currentChapterIndex + 1}',
    );

    return audioUrl;
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
        chapterIndex >= _currentBook!.chapters.length) {
      return;
    }

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
    await _audioPlayer.seek(
      newPosition.isNegative ? Duration.zero : newPosition,
    );
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

  void setVoiceSettings(session_models.VoiceSettings settings) {
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

      final update = session_models.SessionProgressUpdate(
        currentPos: _currentChapterIndex,
        currentTime: position,
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
