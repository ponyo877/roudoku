import 'dart:async';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_models.dart';

// Using BGMTrack from models/audio_models.dart

/// Service for managing background music
class BGMService {
  static const String _tracksKey = 'bgm_tracks';
  static const String _currentTrackKey = 'current_bgm_track';
  static const String _bgmEnabledKey = 'bgm_enabled';
  
  SharedPreferences? _prefs;
  AudioPlayer? _bgmPlayer;
  BGMTrack? _currentTrack;
  bool _isEnabled = false;

  BGMService();

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _bgmPlayer = AudioPlayer();
    _isEnabled = _prefs!.getBool(_bgmEnabledKey) ?? false;
    
    await _ensureDefaultTracks();
    await _loadCurrentTrack();
  }

  /// Get all available BGM tracks
  Future<List<BGMTrack>> getTracks() async {
    await _ensureInitialized();
    // Placeholder implementation - would need to work with BGMTrack from audio_models.dart
    return [];
  }

  /// Add a new BGM track
  Future<void> addTrack(BGMTrack track) async {
    await _ensureInitialized();
    // Placeholder implementation
  }

  /// Remove a BGM track
  Future<void> removeTrack(String trackId) async {
    await _ensureInitialized();
    final tracks = await getTracks();
    tracks.removeWhere((t) => t.id == trackId);
    
    final tracksData = tracks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs!.setStringList(_tracksKey, tracksData);
  }

  /// Play background music
  Future<void> playBGM(BGMTrack track) async {
    await _ensureInitialized();
    
    if (!_isEnabled) return;
    
    try {
      await _bgmPlayer!.stop();
      
      // Use local path if available, otherwise use URL
      final audioSource = track.localPath != null
          ? AudioSource.file(track.localPath!)
          : AudioSource.uri(Uri.parse(track.url));
      
      await _bgmPlayer!.setAudioSource(audioSource);
      await _bgmPlayer!.setVolume(track.volume);
      await _bgmPlayer!.setLoopMode(track.isLoop ? LoopMode.one : LoopMode.off);
      await _bgmPlayer!.play();
      
      _currentTrack = track;
      await _prefs!.setString(_currentTrackKey, jsonEncode(track.toJson()));
    } catch (e) {
      print('Error playing BGM: $e');
    }
  }

  /// Stop background music
  Future<void> stopBGM() async {
    await _bgmPlayer?.stop();
    _currentTrack = null;
    await _prefs?.remove(_currentTrackKey);
  }

  /// Pause background music
  Future<void> pauseBGM() async {
    await _bgmPlayer?.pause();
  }

  /// Resume background music
  Future<void> resumeBGM() async {
    if (_isEnabled) {
      await _bgmPlayer?.play();
    }
  }

  /// Set BGM volume
  Future<void> setVolume(double volume) async {
    await _bgmPlayer?.setVolume(volume);
    
    if (_currentTrack != null) {
      final updatedTrack = BGMTrack(
        id: _currentTrack!.id,
        name: _currentTrack!.name,
        url: _currentTrack!.url,
        localPath: _currentTrack!.localPath,
        volume: volume,
        isLoop: _currentTrack!.isLoop,
      );
      _currentTrack = updatedTrack;
      await _prefs!.setString(_currentTrackKey, jsonEncode(updatedTrack.toJson()));
    }
  }

  /// Enable or disable BGM
  Future<void> setBGMEnabled(bool enabled) async {
    await _ensureInitialized();
    _isEnabled = enabled;
    await _prefs!.setBool(_bgmEnabledKey, enabled);
    
    if (!enabled) {
      await stopBGM();
    } else if (_currentTrack != null) {
      await playBGM(_currentTrack!);
    }
  }

  /// Check if BGM is enabled
  bool get isEnabled => _isEnabled;

  /// Get current playing track
  BGMTrack? get currentTrack => _currentTrack;

  /// Get BGM player state
  PlayerState? get playerState => _bgmPlayer?.playerState;

  /// Ensure default tracks exist
  Future<void> _ensureDefaultTracks() async {
    final tracks = await getTracks();
    if (tracks.isEmpty) {
      // Add some default ambient tracks (these would need to be actual URLs or local files)
      final defaultTracks = [
        BGMTrack(
          id: 'rain',
          name: 'Rain Sounds',
          url: 'https://example.com/rain.mp3', // Replace with actual URL
          volume: 0.3,
        ),
        BGMTrack(
          id: 'forest',
          name: 'Forest Ambiance',
          url: 'https://example.com/forest.mp3', // Replace with actual URL
          volume: 0.3,
        ),
        BGMTrack(
          id: 'piano',
          name: 'Soft Piano',
          url: 'https://example.com/piano.mp3', // Replace with actual URL
          volume: 0.2,
        ),
      ];
      
      for (final track in defaultTracks) {
        await addTrack(track);
      }
    }
  }

  /// Load the current track from preferences
  Future<void> _loadCurrentTrack() async {
    final trackData = _prefs!.getString(_currentTrackKey);
    if (trackData != null) {
      _currentTrack = BGMTrack.fromJson(jsonDecode(trackData));
    }
  }

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    _bgmPlayer ??= AudioPlayer();
  }

  /// Dispose of resources
  void dispose() {
    _bgmPlayer?.dispose();
  }
}