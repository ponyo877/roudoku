import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class CloudTtsService {
  static final CloudTtsService _instance = CloudTtsService._internal();
  factory CloudTtsService() => _instance;
  CloudTtsService._internal();

  final Dio _dio = Dio();
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  // Callbacks
  Function? onPlayingChanged;
  Function? onError;
  Function? onComplete;

  // Voice settings
  String _language = 'ja-JP';
  String _voice = 'ja-JP-Wavenet-A';
  double _speed = 1.0;
  
  // Auto-play settings
  bool _autoPlayEnabled = false;

  bool get isPlaying => _isPlaying;
  String get language => _language;
  String get voice => _voice;
  double get speed => _speed;
  bool get autoPlayEnabled => _autoPlayEnabled;

  // Allow external audio player to be set
  void setAudioPlayer(AudioPlayer player) {
    _audioPlayer = player;
    
    // Set up audio player event listeners
    _audioPlayer?.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        _isPlaying = false;
        onPlayingChanged?.call();
        onComplete?.call();
        if (kDebugMode) {
          print("Cloud TTS: Audio playback completed");
        }
      }
    });

    _audioPlayer?.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      
      if (wasPlaying != _isPlaying) {
        onPlayingChanged?.call();
        if (kDebugMode) {
          print("Cloud TTS: Playing state changed to $_isPlaying");
        }
      }
    });

    if (kDebugMode) {
      print("Cloud TTS Service initialized with external AudioPlayer");
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) {
      if (kDebugMode) {
        print("Cloud TTS: Empty text provided");
      }
      return;
    }

    if (_audioPlayer == null) {
      if (kDebugMode) {
        print("Cloud TTS: AudioPlayer not set. Call setAudioPlayer() first.");
      }
      return;
    }

    try {
      if (kDebugMode) {
        print("Cloud TTS: Starting synthesis for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...");
      }

      // Store current text for potential future use

      // Prepare request data
      final requestData = {
        'text': text,
        'language': _language,
        'voice': _voice,
        'speed': _speed,
      };

      if (kDebugMode) {
        print("Cloud TTS: Sending request to ${Constants.apiBaseUrl}/tts/synthesize");
        print("Cloud TTS: Request data: $requestData");
      }

      // Call Google Cloud TTS API through our server
      final response = await _dio.post(
        '${Constants.apiBaseUrl}/tts/synthesize',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      if (kDebugMode) {
        print("Cloud TTS: Received response with status: ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        final audioBase64 = responseData['audio_content'];
        final audioFormat = responseData['audio_format'];

        if (kDebugMode) {
          print("Cloud TTS: Audio format: $audioFormat");
          print("Cloud TTS: Audio data length: ${audioBase64.length} chars");
        }

        // Decode base64 audio data
        final audioBytes = base64Decode(audioBase64);
        
        if (kDebugMode) {
          print("Cloud TTS: Decoded audio bytes: ${audioBytes.length}");
        }

        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        if (kDebugMode) {
          print("Cloud TTS: Saved audio to temporary file: ${tempFile.path}");
        }

        // Create audio source from file with MediaItem tag for background support
        final audioSource = AudioSource.file(
          tempFile.path,
          tag: MediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: text.substring(0, text.length > 50 ? 50 : text.length),
            artist: 'Cloud TTS',
            album: 'roudoku',
          ),
        );

        if (kDebugMode) {
          print("Cloud TTS: Setting audio source...");
        }

        // Set and play audio
        await _audioPlayer?.setAudioSource(audioSource);
        
        if (kDebugMode) {
          print("Cloud TTS: Starting playback...");
        }
        
        await _audioPlayer?.play();

      } else {
        throw Exception('TTS API returned status ${response.statusCode}');
      }

    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS Error: $e");
      }
      _isPlaying = false;
      onPlayingChanged?.call();
      onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer?.stop();
        _isPlaying = false;
        onPlayingChanged?.call();
        if (kDebugMode) {
          print("Cloud TTS: Stopped playback");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS Stop Error: $e");
      }
    }
  }

  Future<void> pause() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer?.pause();
        _isPlaying = false;
        onPlayingChanged?.call();
        if (kDebugMode) {
          print("Cloud TTS: Paused playback");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS Pause Error: $e");
      }
    }
  }

  Future<void> resume() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer?.play();
        if (kDebugMode) {
          print("Cloud TTS: Resumed playback");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS Resume Error: $e");
      }
    }
  }

  // Configuration methods
  void setLanguage(String language) {
    _language = language;
    if (kDebugMode) {
      print("Cloud TTS: Language set to $_language");
    }
  }

  void setVoice(String voice) {
    _voice = voice;
    if (kDebugMode) {
      print("Cloud TTS: Voice set to $_voice");
    }
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.25, 4.0);
    if (kDebugMode) {
      print("Cloud TTS: Speed set to $_speed");
    }
  }
  
  void setAutoPlayEnabled(bool enabled) {
    _autoPlayEnabled = enabled;
    if (kDebugMode) {
      print("Cloud TTS: Auto-play set to $_autoPlayEnabled");
    }
  }
  
  Future<void> autoSpeak(String text) async {
    if (_autoPlayEnabled && text.isNotEmpty) {
      await speak(text);
    }
  }

  // Generate AudioSource for use in other players
  Future<AudioSource?> generateAudioSource(String text) async {
    if (text.isEmpty) {
      if (kDebugMode) {
        print("Cloud TTS: Empty text provided for audio source generation");
      }
      return null;
    }

    try {
      if (kDebugMode) {
        print("Cloud TTS: Generating audio source for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...");
      }

      // Prepare request data
      final requestData = {
        'text': text,
        'language': _language,
        'voice': _voice,
        'speed': _speed,
      };

      // Call Google Cloud TTS API through our server
      final response = await _dio.post(
        '${Constants.apiBaseUrl}/tts/synthesize',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final audioBase64 = responseData['audio_content'];

        // Decode base64 audio data
        final audioBytes = base64Decode(audioBase64);
        
        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        if (kDebugMode) {
          print("Cloud TTS: Generated audio source file: ${tempFile.path}");
        }

        // Create audio source from file with MediaItem tag for background support
        final audioSource = AudioSource.file(
          tempFile.path,
          tag: MediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: text.substring(0, text.length > 50 ? 50 : text.length),
            artist: 'Cloud TTS',
            album: 'roudoku',
          ),
        );

        return audioSource;
      } else {
        throw Exception('TTS API returned status ${response.statusCode}');
      }

    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS Audio Source Generation Error: $e");
      }
      return null;
    }
  }

  // Get available voices from server
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      if (kDebugMode) {
        print("Cloud TTS: Fetching available voices...");
      }

      final response = await _dio.get(
        '${Constants.apiBaseUrl}/tts/voices',
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final voices = List<Map<String, dynamic>>.from(responseData['voices'] ?? []);
        
        if (kDebugMode) {
          print("Cloud TTS: Retrieved ${voices.length} voices");
        }
        
        return voices;
      } else {
        throw Exception('Failed to fetch voices: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS: Error fetching voices: $e");
      }
      return [];
    }
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    
    // Clean up temporary files
    _cleanupTempFiles();
    
    if (kDebugMode) {
      print("Cloud TTS Service disposed");
    }
  }
  
  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      final files = dir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('tts_') && file.path.endsWith('.mp3')) {
          file.deleteSync();
          if (kDebugMode) {
            print("Cloud TTS: Deleted temp file: ${file.path}");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Cloud TTS: Error cleaning up temp files: $e");
      }
    }
  }
}