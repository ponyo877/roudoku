import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_client.dart';
import '../core/logging/logger.dart';
import '../utils/constants.dart';

enum TtsMode { local, cloud }
enum TtsState { playing, stopped, paused, continued }

class UnifiedTtsService {
  static final UnifiedTtsService _instance = UnifiedTtsService._internal();
  factory UnifiedTtsService() => _instance;
  UnifiedTtsService._internal();

  // Mode selection
  TtsMode _mode = TtsMode.local;
  
  // Local TTS
  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  
  // Cloud TTS
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  
  // Common settings
  String _language = 'ja-JP';
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String _voice = 'ja-JP-Wavenet-A';
  double _speed = 1.0;
  bool _autoPlayEnabled = false;
  
  // Callbacks
  Function? onPlayingChanged;
  Function? onError;
  Function? onComplete;
  
  // Track last spoken text
  String? _lastSpokenText;
  List<String> _availableVoices = [];

  // Getters
  TtsMode get mode => _mode;
  TtsState get ttsState => _ttsState;
  bool get isPlaying => _mode == TtsMode.local ? 
      (_ttsState == TtsState.playing) : _isPlaying;
  bool get isPaused => _mode == TtsMode.local ? 
      (_ttsState == TtsState.paused) : (!_isPlaying && _audioPlayer?.position != Duration.zero);
  bool get isStopped => _mode == TtsMode.local ? 
      (_ttsState == TtsState.stopped) : (!_isPlaying && _audioPlayer?.position == Duration.zero);
  
  String get language => _language;
  double get volume => _volume;
  double get pitch => _pitch;
  double get speechRate => _speechRate;
  String get voice => _voice;
  double get speed => _speed;
  bool get autoPlayEnabled => _autoPlayEnabled;
  List<String> get availableVoices => _availableVoices;

  Future<void> initialize({TtsMode mode = TtsMode.local}) async {
    _mode = mode;
    Logger.audio('Initializing TTS service in ${_mode.name} mode');
    
    if (_mode == TtsMode.local) {
      await _initializeLocalTts();
    } else {
      await _initializeCloudTts();
    }
  }

  Future<void> _initializeLocalTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.awaitSpeakCompletion(true);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
      );
    }

    await _getAvailableVoices();
    _setupLocalTtsHandlers();
    Logger.audio('Local TTS initialized');
  }

  Future<void> _initializeCloudTts() async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _setupCloudTtsHandlers();
    }
    Logger.audio('Cloud TTS initialized');
  }

  void _setupLocalTtsHandlers() {
    _flutterTts.setStartHandler(() {
      Logger.audio('Local TTS started');
      _ttsState = TtsState.playing;
      onPlayingChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      Logger.audio('Local TTS completed');
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
      onComplete?.call();
    });

    _flutterTts.setCancelHandler(() {
      Logger.audio('Local TTS cancelled');
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
    });

    _flutterTts.setPauseHandler(() {
      Logger.audio('Local TTS paused');
      _ttsState = TtsState.paused;
      onPlayingChanged?.call();
    });

    _flutterTts.setContinueHandler(() {
      Logger.audio('Local TTS continued');
      _ttsState = TtsState.continued;
      onPlayingChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      Logger.error('Local TTS error: $msg');
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
      onError?.call(msg);
    });
  }

  void _setupCloudTtsHandlers() {
    _audioPlayer?.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        _isPlaying = false;
        onPlayingChanged?.call();
        onComplete?.call();
        Logger.audio('Cloud TTS playback completed');
      }
    });

    _audioPlayer?.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      
      if (wasPlaying != _isPlaying) {
        onPlayingChanged?.call();
        Logger.audio('Cloud TTS playing state changed to $_isPlaying');
      }
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) {
      Logger.warning('Empty text provided to TTS');
      return;
    }

    _lastSpokenText = text;
    Logger.audio('Speaking text (${text.length} chars) in ${_mode.name} mode');

    try {
      if (_mode == TtsMode.local) {
        await _speakLocal(text);
      } else {
        await _speakCloud(text);
      }
    } catch (e) {
      Logger.error('TTS speak error in ${_mode.name} mode', e);
      onError?.call(e.toString());
      
      // Fallback to local if cloud fails
      if (_mode == TtsMode.cloud) {
        Logger.warning('Cloud TTS failed, falling back to local');
        await _fallbackToLocal(text);
      }
    }
  }

  Future<void> _speakLocal(String text) async {
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setLanguage(_language);
    
    await _flutterTts.speak(text);
  }

  Future<void> _speakCloud(String text) async {
    if (_audioPlayer == null) {
      throw Exception('Cloud TTS AudioPlayer not initialized');
    }

    final requestData = {
      'text': text,
      'language': _language,
      'voice': _voice,
      'speed': _speed,
    };

    Logger.network('Sending TTS request to server');
    final response = await DioClient.instance.dio.post(
      '${Constants.apiBaseUrl}/tts/synthesize',
      data: requestData,
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      final audioBase64 = responseData['audio_content'];
      final audioBytes = base64Decode(audioBase64);
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(audioBytes);
      
      final audioSource = AudioSource.file(
        tempFile.path,
        tag: MediaItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text.substring(0, text.length > 50 ? 50 : text.length),
          artist: 'Cloud TTS',
          album: 'roudoku',
        ),
      );

      await _audioPlayer?.setAudioSource(audioSource);
      await _audioPlayer?.play();
    } else {
      throw Exception('TTS API returned status ${response.statusCode}');
    }
  }

  Future<void> _fallbackToLocal(String text) async {
    final originalMode = _mode;
    _mode = TtsMode.local;
    
    try {
      if (!_isLocalTtsInitialized()) {
        await _initializeLocalTts();
      }
      await _speakLocal(text);
    } catch (e) {
      Logger.error('Fallback to local TTS also failed', e);
      _mode = originalMode;
      rethrow;
    }
  }

  bool _isLocalTtsInitialized() {
    try {
      return _flutterTts != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() async {
    Logger.audio('Stopping TTS in ${_mode.name} mode');
    
    if (_mode == TtsMode.local) {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
    } else {
      await _audioPlayer?.stop();
      _isPlaying = false;
    }
    onPlayingChanged?.call();
  }

  Future<void> pause() async {
    Logger.audio('Pausing TTS in ${_mode.name} mode');
    
    if (_mode == TtsMode.local) {
      await _flutterTts.pause();
      _ttsState = TtsState.paused;
    } else {
      await _audioPlayer?.pause();
      _isPlaying = false;
    }
    onPlayingChanged?.call();
  }

  Future<void> resume() async {
    Logger.audio('Resuming TTS in ${_mode.name} mode');
    
    if (_mode == TtsMode.local) {
      if (_lastSpokenText != null) {
        await speak(_lastSpokenText!);
      }
    } else {
      await _audioPlayer?.play();
    }
  }

  Future<void> switchMode(TtsMode newMode) async {
    if (_mode == newMode) return;
    
    Logger.info('Switching TTS mode from ${_mode.name} to ${newMode.name}');
    await stop();
    await initialize(mode: newMode);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    if (_mode == TtsMode.local) {
      await _flutterTts.setLanguage(language);
    }
    Logger.audio('Language set to $_language');
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_mode == TtsMode.local) {
      await _flutterTts.setVolume(_volume);
    }
    Logger.audio('Volume set to $_volume');
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_mode == TtsMode.local) {
      await _flutterTts.setPitch(_pitch);
    }
    Logger.audio('Pitch set to $_pitch');
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_mode == TtsMode.local) {
      await _flutterTts.setSpeechRate(_speechRate);
    }
    Logger.audio('Speech rate set to $_speechRate');
  }

  void setVoice(String voice) {
    _voice = voice;
    Logger.audio('Voice set to $_voice');
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.25, 4.0);
    Logger.audio('Speed set to $_speed');
  }

  void setAutoPlayEnabled(bool enabled) {
    _autoPlayEnabled = enabled;
    Logger.audio('Auto-play set to $_autoPlayEnabled');
  }

  Future<void> autoSpeak(String text) async {
    if (_autoPlayEnabled && text.isNotEmpty) {
      await speak(text);
    }
  }

  Future<void> _getAvailableVoices() async {
    if (_mode == TtsMode.local) {
      try {
        List<dynamic> voices = await _flutterTts.getVoices;
        _availableVoices = voices
            .where((voice) => voice['locale'].toString().startsWith('ja'))
            .map((voice) => voice['name'].toString())
            .toList();
        Logger.audio('Found ${_availableVoices.length} Japanese voices');
      } catch (e) {
        Logger.error('Error getting local voices', e);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCloudVoices() async {
    try {
      Logger.network('Fetching cloud voices from server');
      final response = await DioClient.instance.dio.get(
        '${Constants.apiBaseUrl}/tts/voices',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final voices = List<Map<String, dynamic>>.from(responseData['voices'] ?? []);
        Logger.audio('Retrieved ${voices.length} cloud voices');
        return voices;
      } else {
        throw Exception('Failed to fetch voices: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching cloud voices', e);
      return [];
    }
  }

  void setAudioPlayer(AudioPlayer player) {
    _audioPlayer = player;
    _setupCloudTtsHandlers();
    Logger.audio('External AudioPlayer set for cloud TTS');
  }

  Future<AudioSource?> generateAudioSource(String text) async {
    if (text.isEmpty || _mode != TtsMode.cloud) {
      Logger.warning('Cannot generate audio source: empty text or not in cloud mode');
      return null;
    }

    try {
      final requestData = {
        'text': text,
        'language': _language,
        'voice': _voice,
        'speed': _speed,
      };

      Logger.network('Generating audio source for text');
      final response = await DioClient.instance.dio.post(
        '${Constants.apiBaseUrl}/tts/synthesize',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final audioBase64 = responseData['audio_content'];
        final audioBytes = base64Decode(audioBase64);
        
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        final audioSource = AudioSource.file(
          tempFile.path,
          tag: MediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: text.substring(0, text.length > 50 ? 50 : text.length),
            artist: 'Cloud TTS',
            album: 'roudoku',
          ),
        );

        Logger.audio('Generated audio source for text');
        return audioSource;
      } else {
        throw Exception('TTS API returned status ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error generating audio source', e);
      return null;
    }
  }

  void dispose() {
    Logger.audio('Disposing unified TTS service');
    _flutterTts.stop();
    _audioPlayer?.dispose();
    _cleanupTempFiles();
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      final files = dir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('tts_') && file.path.endsWith('.mp3')) {
          file.deleteSync();
          Logger.debug('Deleted temp TTS file: ${file.path}');
        }
      }
    } catch (e) {
      Logger.error('Error cleaning up TTS temp files', e);
    }
  }
}