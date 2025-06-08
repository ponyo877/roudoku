import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  
  // Voice preferences
  String _language = 'ja-JP';
  double _volume = 0.8;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String _engine = '';
  List<String> _availableVoices = [];

  // Callbacks
  Function? onPlayingChanged;
  Function? onError;
  Function? onComplete;
  
  // Track last spoken text for resume functionality
  String? _lastSpokenText;

  TtsState get ttsState => _ttsState;
  String get language => _language;
  double get volume => _volume;
  double get pitch => _pitch;
  double get speechRate => _speechRate;
  List<String> get availableVoices => _availableVoices;

  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    await _setAwaitOptions();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _getDefaultEngine();
      await _getDefaultVoice();
    }

    await _getAvailableVoices();

    _flutterTts.setStartHandler(() {
      if (kDebugMode) {
        print("TTS Playing");
      }
      _ttsState = TtsState.playing;
      onPlayingChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      if (kDebugMode) {
        print("TTS Complete");
      }
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
      onComplete?.call();
    });

    _flutterTts.setCancelHandler(() {
      if (kDebugMode) {
        print("TTS Cancelled");
      }
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
    });

    _flutterTts.setPauseHandler(() {
      if (kDebugMode) {
        print("TTS Paused");
      }
      _ttsState = TtsState.paused;
      onPlayingChanged?.call();
    });

    _flutterTts.setContinueHandler(() {
      if (kDebugMode) {
        print("TTS Continued");
      }
      _ttsState = TtsState.continued;
      onPlayingChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      if (kDebugMode) {
        print("TTS Error: $msg");
      }
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
      onError?.call(msg);
    });
  }

  Future<void> _setAwaitOptions() async {
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _getDefaultEngine() async {
    var engine = await _flutterTts.getDefaultEngine;
    if (engine != null) {
      if (kDebugMode) {
        print("Default TTS engine: $engine");
      }
      _engine = engine;
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await _flutterTts.getDefaultVoice;
    if (voice != null) {
      if (kDebugMode) {
        print("Default voice: $voice");
      }
    }
  }

  Future<void> _getAvailableVoices() async {
    List<dynamic> voices = await _flutterTts.getVoices;
    _availableVoices = voices
        .where((voice) => voice['locale'].toString().startsWith('ja'))
        .map((voice) => voice['name'].toString())
        .toList();
    
    if (kDebugMode) {
      print("Available Japanese voices: $_availableVoices");
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setLanguage(_language);

    if (text.isNotEmpty) {
      _lastSpokenText = text;
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    var result = await _flutterTts.stop();
    if (result == 1) {
      _ttsState = TtsState.stopped;
      onPlayingChanged?.call();
    }
  }

  Future<void> pause() async {
    var result = await _flutterTts.pause();
    if (result == 1) {
      _ttsState = TtsState.paused;
      onPlayingChanged?.call();
    }
  }

  Future<void> resume() async {
    // FlutterTts doesn't have a resume method, use speak to continue
    if (_lastSpokenText != null) {
      await speak(_lastSpokenText!);
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> setVoice(String voiceName) async {
    await _flutterTts.setVoice({"name": voiceName, "locale": _language});
  }

  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isStopped => _ttsState == TtsState.stopped;

  void dispose() {
    _flutterTts.stop();
  }
}