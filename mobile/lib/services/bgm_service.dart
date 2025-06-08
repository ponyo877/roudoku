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
    final tracksData = _prefs!.getStringList(_tracksKey) ?? [];
    final tracks = <BGMTrack>[];
    
    for (final trackData in tracksData) {
      try {
        final trackJson = jsonDecode(trackData);
        tracks.add(BGMTrack.fromJson(trackJson));
      } catch (e) {
        print('Error parsing track data: $e');
      }
    }
    
    return tracks;
  }

  /// Add a new BGM track
  Future<void> addTrack(BGMTrack track) async {
    await _ensureInitialized();
    final tracks = await getTracks();
    
    // Remove existing track with same ID if it exists
    tracks.removeWhere((t) => t.id == track.id);
    
    // Add the new track
    tracks.add(track);
    
    // Save to preferences
    final tracksData = tracks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs!.setStringList(_tracksKey, tracksData);
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
      final audioSource = track.filePath.isNotEmpty
          ? AudioSource.file(track.filePath)
          : AudioSource.uri(Uri.parse(track.fileUrl));
      
      await _bgmPlayer!.setAudioSource(audioSource);
      await _bgmPlayer!.setVolume(track.volumeLevel);
      await _bgmPlayer!.setLoopMode(LoopMode.off); // BGM tracks don't have loop property
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
        title: _currentTrack!.title,
        artist: _currentTrack!.artist,
        album: _currentTrack!.album,
        filePath: _currentTrack!.filePath,
        fileUrl: _currentTrack!.fileUrl,
        duration: _currentTrack!.duration,
        genre: _currentTrack!.genre,
        mood: _currentTrack!.mood,
        atmosphere: _currentTrack!.atmosphere,
        instrument: _currentTrack!.instrument,
        tempo: _currentTrack!.tempo,
        licenseType: _currentTrack!.licenseType,
        licenseInfo: _currentTrack!.licenseInfo,
        volumeLevel: volume,
        fadeInDuration: _currentTrack!.fadeInDuration,
        fadeOutDuration: _currentTrack!.fadeOutDuration,
        isActive: _currentTrack!.isActive,
        downloadCount: _currentTrack!.downloadCount,
        rating: _currentTrack!.rating,
        tags: _currentTrack!.tags,
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
          title: 'Rain Sounds',
          artist: 'Nature Sounds',
          album: 'Ambient Collection',
          filePath: '', // Empty for remote files
          fileUrl: 'https://example.com/rain.mp3', // Replace with actual URL
          duration: 300, // 5 minutes in seconds
          genre: 'Ambient',
          mood: ['relaxing', 'peaceful'],
          atmosphere: ['nature', 'rain'],
          instrument: ['environmental'],
          tempo: 'slow',
          licenseType: 'royalty_free',
          licenseInfo: 'Free for personal use',
          volumeLevel: 0.3,
          fadeInDuration: 2000, // 2 seconds
          fadeOutDuration: 2000, // 2 seconds
          isActive: true,
          downloadCount: 0,
          rating: 4.5,
          tags: ['rain', 'nature', 'ambient', 'sleep'],
        ),
        BGMTrack(
          id: 'forest',
          title: 'Forest Ambiance',
          artist: 'Nature Sounds',
          album: 'Ambient Collection',
          filePath: '', // Empty for remote files
          fileUrl: 'https://example.com/forest.mp3', // Replace with actual URL
          duration: 480, // 8 minutes in seconds
          genre: 'Ambient',
          mood: ['calming', 'natural'],
          atmosphere: ['forest', 'birds'],
          instrument: ['environmental'],
          tempo: 'slow',
          licenseType: 'royalty_free',
          licenseInfo: 'Free for personal use',
          volumeLevel: 0.3,
          fadeInDuration: 3000, // 3 seconds
          fadeOutDuration: 3000, // 3 seconds
          isActive: true,
          downloadCount: 0,
          rating: 4.7,
          tags: ['forest', 'birds', 'nature', 'meditation'],
        ),
        BGMTrack(
          id: 'piano',
          title: 'Soft Piano',
          artist: 'Classical Ensemble',
          album: 'Reading Companion',
          filePath: '', // Empty for remote files
          fileUrl: 'https://example.com/piano.mp3', // Replace with actual URL
          duration: 420, // 7 minutes in seconds
          genre: 'Classical',
          mood: ['peaceful', 'contemplative'],
          atmosphere: ['elegant', 'soft'],
          instrument: ['piano'],
          tempo: 'moderate',
          licenseType: 'royalty_free',
          licenseInfo: 'Free for personal use',
          volumeLevel: 0.2,
          fadeInDuration: 1500, // 1.5 seconds
          fadeOutDuration: 1500, // 1.5 seconds
          isActive: true,
          downloadCount: 0,
          rating: 4.8,
          tags: ['piano', 'classical', 'soft', 'reading'],
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