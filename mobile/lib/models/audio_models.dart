// Phase 7: Advanced Audio Models for Mobile

class VoicePreset {
  final String id;
  final String userId;
  final String name;
  final String description;
  final bool isDefault;
  final String presetType;
  final VoiceSettings voiceSettings;
  final EmotionSettings emotionSettings;
  final SpeakingStyleSettings speakingStyleSettings;
  final ContextSettings contextSettings;
  final List<String> tags;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoicePreset({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.isDefault,
    required this.presetType,
    required this.voiceSettings,
    required this.emotionSettings,
    required this.speakingStyleSettings,
    required this.contextSettings,
    required this.tags,
    required this.usageCount,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoicePreset.fromJson(Map<String, dynamic> json) {
    return VoicePreset(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      isDefault: json['is_default'],
      presetType: json['preset_type'],
      voiceSettings: VoiceSettings.fromJson(json['voice_settings']),
      emotionSettings: EmotionSettings.fromJson(json['emotion_settings']),
      speakingStyleSettings: SpeakingStyleSettings.fromJson(json['speaking_style_settings']),
      contextSettings: ContextSettings.fromJson(json['context_settings']),
      tags: List<String>.from(json['tags']),
      usageCount: json['usage_count'],
      lastUsedAt: json['last_used_at'] != null ? DateTime.parse(json['last_used_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'is_default': isDefault,
      'preset_type': presetType,
      'voice_settings': voiceSettings.toJson(),
      'emotion_settings': emotionSettings.toJson(),
      'speaking_style_settings': speakingStyleSettings.toJson(),
      'context_settings': contextSettings.toJson(),
      'tags': tags,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VoicePreset copyWith({
    String? name,
    String? description,
    bool? isDefault,
    VoiceSettings? voiceSettings,
    EmotionSettings? emotionSettings,
    SpeakingStyleSettings? speakingStyleSettings,
    ContextSettings? contextSettings,
    List<String>? tags,
  }) {
    return VoicePreset(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      presetType: presetType,
      voiceSettings: voiceSettings ?? this.voiceSettings,
      emotionSettings: emotionSettings ?? this.emotionSettings,
      speakingStyleSettings: speakingStyleSettings ?? this.speakingStyleSettings,
      contextSettings: contextSettings ?? this.contextSettings,
      tags: tags ?? this.tags,
      usageCount: usageCount,
      lastUsedAt: lastUsedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class VoiceSettings {
  final String voice;
  final String gender;
  final String language;
  final double speed;
  final double pitch;
  final double volumeGain;

  VoiceSettings({
    required this.voice,
    required this.gender,
    required this.language,
    required this.speed,
    required this.pitch,
    required this.volumeGain,
  });

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      voice: json['voice'],
      gender: json['gender'],
      language: json['language'],
      speed: json['speed'].toDouble(),
      pitch: json['pitch'].toDouble(),
      volumeGain: json['volume_gain'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice': voice,
      'gender': gender,
      'language': language,
      'speed': speed,
      'pitch': pitch,
      'volume_gain': volumeGain,
    };
  }

  VoiceSettings copyWith({
    String? voice,
    String? gender,
    String? language,
    double? speed,
    double? pitch,
    double? volumeGain,
  }) {
    return VoiceSettings(
      voice: voice ?? this.voice,
      gender: gender ?? this.gender,
      language: language ?? this.language,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volumeGain: volumeGain ?? this.volumeGain,
    );
  }
}

class EmotionSettings {
  final String emotion;
  final double intensity;
  final double warmth;
  final double energy;
  final double expressiveness;

  EmotionSettings({
    required this.emotion,
    required this.intensity,
    required this.warmth,
    required this.energy,
    required this.expressiveness,
  });

  factory EmotionSettings.fromJson(Map<String, dynamic> json) {
    return EmotionSettings(
      emotion: json['emotion'],
      intensity: json['intensity'].toDouble(),
      warmth: json['warmth'].toDouble(),
      energy: json['energy'].toDouble(),
      expressiveness: json['expressiveness'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'intensity': intensity,
      'warmth': warmth,
      'energy': energy,
      'expressiveness': expressiveness,
    };
  }

  EmotionSettings copyWith({
    String? emotion,
    double? intensity,
    double? warmth,
    double? energy,
    double? expressiveness,
  }) {
    return EmotionSettings(
      emotion: emotion ?? this.emotion,
      intensity: intensity ?? this.intensity,
      warmth: warmth ?? this.warmth,
      energy: energy ?? this.energy,
      expressiveness: expressiveness ?? this.expressiveness,
    );
  }
}

class SpeakingStyleSettings {
  final String style;
  final String pace;
  final double emphasis;
  final double pause;
  final double inflectionVariety;

  SpeakingStyleSettings({
    required this.style,
    required this.pace,
    required this.emphasis,
    required this.pause,
    required this.inflectionVariety,
  });

  factory SpeakingStyleSettings.fromJson(Map<String, dynamic> json) {
    return SpeakingStyleSettings(
      style: json['style'],
      pace: json['pace'],
      emphasis: json['emphasis'].toDouble(),
      pause: json['pause'].toDouble(),
      inflectionVariety: json['inflection_variety'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style,
      'pace': pace,
      'emphasis': emphasis,
      'pause': pause,
      'inflection_variety': inflectionVariety,
    };
  }

  SpeakingStyleSettings copyWith({
    String? style,
    String? pace,
    double? emphasis,
    double? pause,
    double? inflectionVariety,
  }) {
    return SpeakingStyleSettings(
      style: style ?? this.style,
      pace: pace ?? this.pace,
      emphasis: emphasis ?? this.emphasis,
      pause: pause ?? this.pause,
      inflectionVariety: inflectionVariety ?? this.inflectionVariety,
    );
  }
}

class ContextSettings {
  final List<String> timeOfDay;
  final List<String> environment;
  final List<String> activity;
  final List<String> contentType;
  final bool autoAdjust;
  final Map<String, double> adjustmentRules;

  ContextSettings({
    required this.timeOfDay,
    required this.environment,
    required this.activity,
    required this.contentType,
    required this.autoAdjust,
    required this.adjustmentRules,
  });

  factory ContextSettings.fromJson(Map<String, dynamic> json) {
    return ContextSettings(
      timeOfDay: List<String>.from(json['time_of_day']),
      environment: List<String>.from(json['environment']),
      activity: List<String>.from(json['activity']),
      contentType: List<String>.from(json['content_type']),
      autoAdjust: json['auto_adjust'],
      adjustmentRules: Map<String, double>.from(json['adjustment_rules']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_of_day': timeOfDay,
      'environment': environment,
      'activity': activity,
      'content_type': contentType,
      'auto_adjust': autoAdjust,
      'adjustment_rules': adjustmentRules,
    };
  }
}

class BGMTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final String fileUrl;
  final int duration;
  final String genre;
  final List<String> mood;
  final List<String> atmosphere;
  final List<String> instrument;
  final String tempo;
  final String licenseType;
  final String licenseInfo;
  final double volumeLevel;
  final int fadeInDuration;
  final int fadeOutDuration;
  final bool isActive;
  final int downloadCount;
  final double rating;
  final List<String> tags;

  BGMTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.fileUrl,
    required this.duration,
    required this.genre,
    required this.mood,
    required this.atmosphere,
    required this.instrument,
    required this.tempo,
    required this.licenseType,
    required this.licenseInfo,
    required this.volumeLevel,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    required this.isActive,
    required this.downloadCount,
    required this.rating,
    required this.tags,
  });

  factory BGMTrack.fromJson(Map<String, dynamic> json) {
    return BGMTrack(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      duration: json['duration'],
      genre: json['genre'],
      mood: List<String>.from(json['mood']),
      atmosphere: List<String>.from(json['atmosphere']),
      instrument: List<String>.from(json['instrument']),
      tempo: json['tempo'],
      licenseType: json['license_type'],
      licenseInfo: json['license_info'],
      volumeLevel: json['volume_level'].toDouble(),
      fadeInDuration: json['fade_in_duration'],
      fadeOutDuration: json['fade_out_duration'],
      isActive: json['is_active'],
      downloadCount: json['download_count'],
      rating: json['rating'].toDouble(),
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'file_path': filePath,
      'file_url': fileUrl,
      'duration': duration,
      'genre': genre,
      'mood': mood,
      'atmosphere': atmosphere,
      'instrument': instrument,
      'tempo': tempo,
      'license_type': licenseType,
      'license_info': licenseInfo,
      'volume_level': volumeLevel,
      'fade_in_duration': fadeInDuration,
      'fade_out_duration': fadeOutDuration,
      'is_active': isActive,
      'download_count': downloadCount,
      'rating': rating,
      'tags': tags,
    };
  }
}

class EnvironmentalSound {
  final String id;
  final String name;
  final String description;
  final String filePath;
  final String fileUrl;
  final int duration;
  final String category;
  final String environment;
  final String intensity;
  final bool isLoopable;
  final double volumeLevel;
  final int fadeInDuration;
  final int fadeOutDuration;
  final String licenseType;
  final String licenseInfo;
  final bool isActive;
  final int usageCount;
  final double rating;
  final List<String> tags;

  EnvironmentalSound({
    required this.id,
    required this.name,
    required this.description,
    required this.filePath,
    required this.fileUrl,
    required this.duration,
    required this.category,
    required this.environment,
    required this.intensity,
    required this.isLoopable,
    required this.volumeLevel,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    required this.licenseType,
    required this.licenseInfo,
    required this.isActive,
    required this.usageCount,
    required this.rating,
    required this.tags,
  });

  factory EnvironmentalSound.fromJson(Map<String, dynamic> json) {
    return EnvironmentalSound(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      duration: json['duration'],
      category: json['category'],
      environment: json['environment'],
      intensity: json['intensity'],
      isLoopable: json['is_loopable'],
      volumeLevel: json['volume_level'].toDouble(),
      fadeInDuration: json['fade_in_duration'],
      fadeOutDuration: json['fade_out_duration'],
      licenseType: json['license_type'],
      licenseInfo: json['license_info'],
      isActive: json['is_active'],
      usageCount: json['usage_count'],
      rating: json['rating'].toDouble(),
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'file_path': filePath,
      'file_url': fileUrl,
      'duration': duration,
      'category': category,
      'environment': environment,
      'intensity': intensity,
      'is_loopable': isLoopable,
      'volume_level': volumeLevel,
      'fade_in_duration': fadeInDuration,
      'fade_out_duration': fadeOutDuration,
      'license_type': licenseType,
      'license_info': licenseInfo,
      'is_active': isActive,
      'usage_count': usageCount,
      'rating': rating,
      'tags': tags,
    };
  }
}

class AudioScene {
  final String id;
  final String? userId;
  final String name;
  final String description;
  final bool isSystemPreset;
  final String? voicePresetId;
  final List<AudioSceneTrack> bgmTracks;
  final List<AudioSceneEnvironment> environmentalSounds;
  final AudioMixingSettings mixingSettings;
  final List<String> contentTypes;
  final List<String> moods;
  final List<String> contexts;
  final List<AutoTriggerRule> autoTriggerRules;
  final int usageCount;
  final double rating;
  final bool isActive;
  final List<String> tags;

  AudioScene({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.isSystemPreset,
    this.voicePresetId,
    required this.bgmTracks,
    required this.environmentalSounds,
    required this.mixingSettings,
    required this.contentTypes,
    required this.moods,
    required this.contexts,
    required this.autoTriggerRules,
    required this.usageCount,
    required this.rating,
    required this.isActive,
    required this.tags,
  });

  factory AudioScene.fromJson(Map<String, dynamic> json) {
    return AudioScene(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      isSystemPreset: json['is_system_preset'],
      voicePresetId: json['voice_preset_id'],
      bgmTracks: (json['bgm_tracks'] as List)
          .map((track) => AudioSceneTrack.fromJson(track))
          .toList(),
      environmentalSounds: (json['environmental_sounds'] as List)
          .map((sound) => AudioSceneEnvironment.fromJson(sound))
          .toList(),
      mixingSettings: AudioMixingSettings.fromJson(json['mixing_settings']),
      contentTypes: List<String>.from(json['content_types']),
      moods: List<String>.from(json['moods']),
      contexts: List<String>.from(json['contexts']),
      autoTriggerRules: (json['auto_trigger_rules'] as List)
          .map((rule) => AutoTriggerRule.fromJson(rule))
          .toList(),
      usageCount: json['usage_count'],
      rating: json['rating'].toDouble(),
      isActive: json['is_active'],
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'is_system_preset': isSystemPreset,
      'voice_preset_id': voicePresetId,
      'bgm_tracks': bgmTracks.map((track) => track.toJson()).toList(),
      'environmental_sounds':
          environmentalSounds.map((sound) => sound.toJson()).toList(),
      'mixing_settings': mixingSettings.toJson(),
      'content_types': contentTypes,
      'moods': moods,
      'contexts': contexts,
      'auto_trigger_rules':
          autoTriggerRules.map((rule) => rule.toJson()).toList(),
      'usage_count': usageCount,
      'rating': rating,
      'is_active': isActive,
      'tags': tags,
    };
  }
}

class AudioSceneTrack {
  final String bgmTrackId;
  final double volume;
  final int startTime;
  final int duration;
  final int fadeIn;
  final int fadeOut;
  final bool loop;
  final int priority;

  AudioSceneTrack({
    required this.bgmTrackId,
    required this.volume,
    required this.startTime,
    required this.duration,
    required this.fadeIn,
    required this.fadeOut,
    required this.loop,
    required this.priority,
  });

  factory AudioSceneTrack.fromJson(Map<String, dynamic> json) {
    return AudioSceneTrack(
      bgmTrackId: json['bgm_track_id'],
      volume: json['volume'].toDouble(),
      startTime: json['start_time'],
      duration: json['duration'],
      fadeIn: json['fade_in'],
      fadeOut: json['fade_out'],
      loop: json['loop'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bgm_track_id': bgmTrackId,
      'volume': volume,
      'start_time': startTime,
      'duration': duration,
      'fade_in': fadeIn,
      'fade_out': fadeOut,
      'loop': loop,
      'priority': priority,
    };
  }
}

class AudioSceneEnvironment {
  final String environmentalSoundId;
  final double volume;
  final int startTime;
  final int duration;
  final int fadeIn;
  final int fadeOut;
  final bool loop;
  final int priority;

  AudioSceneEnvironment({
    required this.environmentalSoundId,
    required this.volume,
    required this.startTime,
    required this.duration,
    required this.fadeIn,
    required this.fadeOut,
    required this.loop,
    required this.priority,
  });

  factory AudioSceneEnvironment.fromJson(Map<String, dynamic> json) {
    return AudioSceneEnvironment(
      environmentalSoundId: json['environmental_sound_id'],
      volume: json['volume'].toDouble(),
      startTime: json['start_time'],
      duration: json['duration'],
      fadeIn: json['fade_in'],
      fadeOut: json['fade_out'],
      loop: json['loop'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'environmental_sound_id': environmentalSoundId,
      'volume': volume,
      'start_time': startTime,
      'duration': duration,
      'fade_in': fadeIn,
      'fade_out': fadeOut,
      'loop': loop,
      'priority': priority,
    };
  }
}

class AudioMixingSettings {
  final double voiceVolume;
  final double bgmVolume;
  final double environmentalVolume;
  final bool duckingEnabled;
  final double duckingLevel;
  final int duckingFadeTime;
  final int crossfadeTime;
  final EQSettings eqSettings;
  final bool spatialAudioEnabled;
  final SpatialAudioConfig spatialConfig;
  final bool dynamicRangeCompression;
  final bool noiseReduction;
  final AudioEnhancementSettings audioEnhancement;

  AudioMixingSettings({
    required this.voiceVolume,
    required this.bgmVolume,
    required this.environmentalVolume,
    required this.duckingEnabled,
    required this.duckingLevel,
    required this.duckingFadeTime,
    required this.crossfadeTime,
    required this.eqSettings,
    required this.spatialAudioEnabled,
    required this.spatialConfig,
    required this.dynamicRangeCompression,
    required this.noiseReduction,
    required this.audioEnhancement,
  });

  factory AudioMixingSettings.fromJson(Map<String, dynamic> json) {
    return AudioMixingSettings(
      voiceVolume: json['voice_volume'].toDouble(),
      bgmVolume: json['bgm_volume'].toDouble(),
      environmentalVolume: json['environmental_volume'].toDouble(),
      duckingEnabled: json['ducking_enabled'],
      duckingLevel: json['ducking_level'].toDouble(),
      duckingFadeTime: json['ducking_fade_time'],
      crossfadeTime: json['crossfade_time'],
      eqSettings: EQSettings.fromJson(json['eq_settings']),
      spatialAudioEnabled: json['spatial_audio_enabled'],
      spatialConfig: SpatialAudioConfig.fromJson(json['spatial_config']),
      dynamicRangeCompression: json['dynamic_range_compression'],
      noiseReduction: json['noise_reduction'],
      audioEnhancement: AudioEnhancementSettings.fromJson(json['audio_enhancement']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_volume': voiceVolume,
      'bgm_volume': bgmVolume,
      'environmental_volume': environmentalVolume,
      'ducking_enabled': duckingEnabled,
      'ducking_level': duckingLevel,
      'ducking_fade_time': duckingFadeTime,
      'crossfade_time': crossfadeTime,
      'eq_settings': eqSettings.toJson(),
      'spatial_audio_enabled': spatialAudioEnabled,
      'spatial_config': spatialConfig.toJson(),
      'dynamic_range_compression': dynamicRangeCompression,
      'noise_reduction': noiseReduction,
      'audio_enhancement': audioEnhancement.toJson(),
    };
  }
}

class EQSettings {
  final bool enabled;
  final String preset;
  final List<EQBand> bands;
  final double bassBoost;
  final double trebleBoost;
  final double voiceClarity;

  EQSettings({
    required this.enabled,
    required this.preset,
    required this.bands,
    required this.bassBoost,
    required this.trebleBoost,
    required this.voiceClarity,
  });

  factory EQSettings.fromJson(Map<String, dynamic> json) {
    return EQSettings(
      enabled: json['enabled'],
      preset: json['preset'],
      bands: (json['bands'] as List?)
              ?.map((band) => EQBand.fromJson(band))
              .toList() ??
          [],
      bassBoost: json['bass_boost'].toDouble(),
      trebleBoost: json['treble_boost'].toDouble(),
      voiceClarity: json['voice_clarity'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'preset': preset,
      'bands': bands.map((band) => band.toJson()).toList(),
      'bass_boost': bassBoost,
      'treble_boost': trebleBoost,
      'voice_clarity': voiceClarity,
    };
  }

  EQSettings copyWith({
    bool? enabled,
    String? preset,
    List<EQBand>? bands,
    double? bassBoost,
    double? trebleBoost,
    double? voiceClarity,
  }) {
    return EQSettings(
      enabled: enabled ?? this.enabled,
      preset: preset ?? this.preset,
      bands: bands ?? this.bands,
      bassBoost: bassBoost ?? this.bassBoost,
      trebleBoost: trebleBoost ?? this.trebleBoost,
      voiceClarity: voiceClarity ?? this.voiceClarity,
    );
  }
}

class EQBand {
  final double frequency;
  final double gain;
  final double q;

  EQBand({
    required this.frequency,
    required this.gain,
    required this.q,
  });

  factory EQBand.fromJson(Map<String, dynamic> json) {
    return EQBand(
      frequency: json['frequency'].toDouble(),
      gain: json['gain'].toDouble(),
      q: json['q'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'gain': gain,
      'q': q,
    };
  }
}

class SpatialAudioConfig {
  final Position3D voicePosition;
  final Position3D bgmPosition;
  final double environmentalSpread;
  final String roomSize;
  final double reverb;
  final double distance;

  SpatialAudioConfig({
    required this.voicePosition,
    required this.bgmPosition,
    required this.environmentalSpread,
    required this.roomSize,
    required this.reverb,
    required this.distance,
  });

  factory SpatialAudioConfig.fromJson(Map<String, dynamic> json) {
    return SpatialAudioConfig(
      voicePosition: Position3D.fromJson(json['voice_position']),
      bgmPosition: Position3D.fromJson(json['bgm_position']),
      environmentalSpread: json['environmental_spread'].toDouble(),
      roomSize: json['room_size'],
      reverb: json['reverb'].toDouble(),
      distance: json['distance'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_position': voicePosition.toJson(),
      'bgm_position': bgmPosition.toJson(),
      'environmental_spread': environmentalSpread,
      'room_size': roomSize,
      'reverb': reverb,
      'distance': distance,
    };
  }
}

class Position3D {
  final double x;
  final double y;
  final double z;

  Position3D({
    required this.x,
    required this.y,
    required this.z,
  });

  factory Position3D.fromJson(Map<String, dynamic> json) {
    return Position3D(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      z: json['z'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }
}

class AudioEnhancementSettings {
  final bool voiceIsolation;
  final bool noiseReduction;
  final bool volumeNormalization;
  final double stereoWidening;
  final double bassEnhancement;
  final double clarityBoost;

  AudioEnhancementSettings({
    required this.voiceIsolation,
    required this.noiseReduction,
    required this.volumeNormalization,
    required this.stereoWidening,
    required this.bassEnhancement,
    required this.clarityBoost,
  });

  factory AudioEnhancementSettings.fromJson(Map<String, dynamic> json) {
    return AudioEnhancementSettings(
      voiceIsolation: json['voice_isolation'],
      noiseReduction: json['noise_reduction'],
      volumeNormalization: json['volume_normalization'],
      stereoWidening: json['stereo_widening'].toDouble(),
      bassEnhancement: json['bass_enhancement'].toDouble(),
      clarityBoost: json['clarity_boost'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_isolation': voiceIsolation,
      'noise_reduction': noiseReduction,
      'volume_normalization': volumeNormalization,
      'stereo_widening': stereoWidening,
      'bass_enhancement': bassEnhancement,
      'clarity_boost': clarityBoost,
    };
  }

  AudioEnhancementSettings copyWith({
    bool? voiceIsolation,
    bool? noiseReduction,
    bool? volumeNormalization,
    double? stereoWidening,
    double? bassEnhancement,
    double? clarityBoost,
  }) {
    return AudioEnhancementSettings(
      voiceIsolation: voiceIsolation ?? this.voiceIsolation,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      volumeNormalization: volumeNormalization ?? this.volumeNormalization,
      stereoWidening: stereoWidening ?? this.stereoWidening,
      bassEnhancement: bassEnhancement ?? this.bassEnhancement,
      clarityBoost: clarityBoost ?? this.clarityBoost,
    );
  }
}

class AutoTriggerRule {
  final String condition;
  final Map<String, dynamic> parameters;
  final int priority;
  final bool enabled;
  final int activationCount;

  AutoTriggerRule({
    required this.condition,
    required this.parameters,
    required this.priority,
    required this.enabled,
    required this.activationCount,
  });

  factory AutoTriggerRule.fromJson(Map<String, dynamic> json) {
    return AutoTriggerRule(
      condition: json['condition'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      priority: json['priority'],
      enabled: json['enabled'],
      activationCount: json['activation_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'parameters': parameters,
      'priority': priority,
      'enabled': enabled,
      'activation_count': activationCount,
    };
  }
}

class UserAudioProfile {
  final String userId;
  final String? defaultVoicePresetId;
  final String? defaultAudioSceneId;
  final List<ListeningEnvironment> listeningEnvironments;
  final AccessibilitySettings accessibilitySettings;
  final AdaptiveSettings adaptiveSettings;
  final List<String> preferredGenres;
  final List<String> preferredMoods;
  final VolumePreferences volumePreferences;
  final List<ListeningSession> listeningHistory;
  final List<String> customPresets;
  final List<String> blacklistedTracks;
  final List<String> favoriteTracks;
  final bool optimizationEnabled;
  final DateTime? lastOptimizationRun;

  UserAudioProfile({
    required this.userId,
    this.defaultVoicePresetId,
    this.defaultAudioSceneId,
    required this.listeningEnvironments,
    required this.accessibilitySettings,
    required this.adaptiveSettings,
    required this.preferredGenres,
    required this.preferredMoods,
    required this.volumePreferences,
    required this.listeningHistory,
    required this.customPresets,
    required this.blacklistedTracks,
    required this.favoriteTracks,
    required this.optimizationEnabled,
    this.lastOptimizationRun,
  });

  factory UserAudioProfile.fromJson(Map<String, dynamic> json) {
    return UserAudioProfile(
      userId: json['user_id'],
      defaultVoicePresetId: json['default_voice_preset_id'],
      defaultAudioSceneId: json['default_audio_scene_id'],
      listeningEnvironments: (json['listening_environments'] as List)
          .map((env) => ListeningEnvironment.fromJson(env))
          .toList(),
      accessibilitySettings: AccessibilitySettings.fromJson(json['accessibility_settings']),
      adaptiveSettings: AdaptiveSettings.fromJson(json['adaptive_settings']),
      preferredGenres: List<String>.from(json['preferred_genres']),
      preferredMoods: List<String>.from(json['preferred_moods']),
      volumePreferences: VolumePreferences.fromJson(json['volume_preferences']),
      listeningHistory: (json['listening_history'] as List)
          .map((session) => ListeningSession.fromJson(session))
          .toList(),
      customPresets: List<String>.from(json['custom_presets']),
      blacklistedTracks: List<String>.from(json['blacklisted_tracks']),
      favoriteTracks: List<String>.from(json['favorite_tracks']),
      optimizationEnabled: json['optimization_enabled'],
      lastOptimizationRun: json['last_optimization_run'] != null
          ? DateTime.parse(json['last_optimization_run'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'default_voice_preset_id': defaultVoicePresetId,
      'default_audio_scene_id': defaultAudioSceneId,
      'listening_environments': listeningEnvironments.map((env) => env.toJson()).toList(),
      'accessibility_settings': accessibilitySettings.toJson(),
      'adaptive_settings': adaptiveSettings.toJson(),
      'preferred_genres': preferredGenres,
      'preferred_moods': preferredMoods,
      'volume_preferences': volumePreferences.toJson(),
      'listening_history': listeningHistory.map((session) => session.toJson()).toList(),
      'custom_presets': customPresets,
      'blacklisted_tracks': blacklistedTracks,
      'favorite_tracks': favoriteTracks,
      'optimization_enabled': optimizationEnabled,
      'last_optimization_run': lastOptimizationRun?.toIso8601String(),
    };
  }
}

class ListeningEnvironment {
  final String name;
  final String description;
  final String? voicePresetId;
  final String? audioSceneId;
  final List<AutoTriggerRule> autoTriggerRules;
  final List<TimeRange> timeRanges;
  final List<LocationTrigger> locationTriggers;
  final List<ActivityTrigger> activityTriggers;
  final VolumePreferences volumeAdjustments;
  final bool isActive;
  final int usageCount;
  final DateTime? lastUsedAt;

  ListeningEnvironment({
    required this.name,
    required this.description,
    this.voicePresetId,
    this.audioSceneId,
    required this.autoTriggerRules,
    required this.timeRanges,
    required this.locationTriggers,
    required this.activityTriggers,
    required this.volumeAdjustments,
    required this.isActive,
    required this.usageCount,
    this.lastUsedAt,
  });

  factory ListeningEnvironment.fromJson(Map<String, dynamic> json) {
    return ListeningEnvironment(
      name: json['name'],
      description: json['description'],
      voicePresetId: json['voice_preset_id'],
      audioSceneId: json['audio_scene_id'],
      autoTriggerRules: (json['auto_trigger_rules'] as List)
          .map((rule) => AutoTriggerRule.fromJson(rule))
          .toList(),
      timeRanges: (json['time_ranges'] as List)
          .map((range) => TimeRange.fromJson(range))
          .toList(),
      locationTriggers: (json['location_triggers'] as List)
          .map((trigger) => LocationTrigger.fromJson(trigger))
          .toList(),
      activityTriggers: (json['activity_triggers'] as List)
          .map((trigger) => ActivityTrigger.fromJson(trigger))
          .toList(),
      volumeAdjustments: VolumePreferences.fromJson(json['volume_adjustments']),
      isActive: json['is_active'],
      usageCount: json['usage_count'],
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'voice_preset_id': voicePresetId,
      'audio_scene_id': audioSceneId,
      'auto_trigger_rules': autoTriggerRules.map((rule) => rule.toJson()).toList(),
      'time_ranges': timeRanges.map((range) => range.toJson()).toList(),
      'location_triggers': locationTriggers.map((trigger) => trigger.toJson()).toList(),
      'activity_triggers': activityTriggers.map((trigger) => trigger.toJson()).toList(),
      'volume_adjustments': volumeAdjustments.toJson(),
      'is_active': isActive,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }
}

class TimeRange {
  final String startTime;
  final String endTime;
  final List<String> days;
  final String timezone;

  TimeRange({
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.timezone,
  });

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      startTime: json['start_time'],
      endTime: json['end_time'],
      days: List<String>.from(json['days']),
      timezone: json['timezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'days': days,
      'timezone': timezone,
    };
  }
}

class LocationTrigger {
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String triggerType;

  LocationTrigger({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.triggerType,
  });

  factory LocationTrigger.fromJson(Map<String, dynamic> json) {
    return LocationTrigger(
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radius: json['radius'].toDouble(),
      triggerType: json['trigger_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'trigger_type': triggerType,
    };
  }
}

class ActivityTrigger {
  final String activityType;
  final double confidence;
  final int duration;
  final Map<String, dynamic> parameters;

  ActivityTrigger({
    required this.activityType,
    required this.confidence,
    required this.duration,
    required this.parameters,
  });

  factory ActivityTrigger.fromJson(Map<String, dynamic> json) {
    return ActivityTrigger(
      activityType: json['activity_type'],
      confidence: json['confidence'].toDouble(),
      duration: json['duration'],
      parameters: Map<String, dynamic>.from(json['parameters']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      'confidence': confidence,
      'duration': duration,
      'parameters': parameters,
    };
  }
}

class AccessibilitySettings {
  final bool hearingImpaired;
  final double voiceSpeedAdjustment;
  final double voicePitchAdjustment;
  final double volumeBoost;
  final bool highContrastAudio;
  final bool monoAudioEnabled;
  final double leftRightBalance;
  final String frequencyFilter;
  final double filterFrequency;
  final bool vibrationEnabled;
  final bool visualIndicatorsEnabled;
  final bool captionsEnabled;
  final bool highlightCurrentSentence;
  final bool wordByWordHighlight;

  AccessibilitySettings({
    required this.hearingImpaired,
    required this.voiceSpeedAdjustment,
    required this.voicePitchAdjustment,
    required this.volumeBoost,
    required this.highContrastAudio,
    required this.monoAudioEnabled,
    required this.leftRightBalance,
    required this.frequencyFilter,
    required this.filterFrequency,
    required this.vibrationEnabled,
    required this.visualIndicatorsEnabled,
    required this.captionsEnabled,
    required this.highlightCurrentSentence,
    required this.wordByWordHighlight,
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      hearingImpaired: json['hearing_impaired'],
      voiceSpeedAdjustment: json['voice_speed_adjustment'].toDouble(),
      voicePitchAdjustment: json['voice_pitch_adjustment'].toDouble(),
      volumeBoost: json['volume_boost'].toDouble(),
      highContrastAudio: json['high_contrast_audio'],
      monoAudioEnabled: json['mono_audio_enabled'],
      leftRightBalance: json['left_right_balance'].toDouble(),
      frequencyFilter: json['frequency_filter'],
      filterFrequency: json['filter_frequency'].toDouble(),
      vibrationEnabled: json['vibration_enabled'],
      visualIndicatorsEnabled: json['visual_indicators_enabled'],
      captionsEnabled: json['captions_enabled'],
      highlightCurrentSentence: json['highlight_current_sentence'],
      wordByWordHighlight: json['word_by_word_highlight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hearing_impaired': hearingImpaired,
      'voice_speed_adjustment': voiceSpeedAdjustment,
      'voice_pitch_adjustment': voicePitchAdjustment,
      'volume_boost': volumeBoost,
      'high_contrast_audio': highContrastAudio,
      'mono_audio_enabled': monoAudioEnabled,
      'left_right_balance': leftRightBalance,
      'frequency_filter': frequencyFilter,
      'filter_frequency': filterFrequency,
      'vibration_enabled': vibrationEnabled,
      'visual_indicators_enabled': visualIndicatorsEnabled,
      'captions_enabled': captionsEnabled,
      'highlight_current_sentence': highlightCurrentSentence,
      'word_by_word_highlight': wordByWordHighlight,
    };
  }
}

class AdaptiveSettings {
  final bool enabled;
  final bool learnFromUsage;
  final bool autoAdjustVolume;
  final bool autoAdjustSpeed;
  final bool autoSelectBGM;
  final bool autoSelectVoice;
  final bool environmentDetection;
  final bool noiseAdaptation;
  final bool timeOfDayAdjustment;
  final bool contentAwareAdjustment;
  final bool emotionMatching;
  final double learningRate;
  final double adaptationSensitivity;
  final int minimumLearningPeriod;
  final double maximumAdjustmentRange;

  AdaptiveSettings({
    required this.enabled,
    required this.learnFromUsage,
    required this.autoAdjustVolume,
    required this.autoAdjustSpeed,
    required this.autoSelectBGM,
    required this.autoSelectVoice,
    required this.environmentDetection,
    required this.noiseAdaptation,
    required this.timeOfDayAdjustment,
    required this.contentAwareAdjustment,
    required this.emotionMatching,
    required this.learningRate,
    required this.adaptationSensitivity,
    required this.minimumLearningPeriod,
    required this.maximumAdjustmentRange,
  });

  factory AdaptiveSettings.fromJson(Map<String, dynamic> json) {
    return AdaptiveSettings(
      enabled: json['enabled'],
      learnFromUsage: json['learn_from_usage'],
      autoAdjustVolume: json['auto_adjust_volume'],
      autoAdjustSpeed: json['auto_adjust_speed'],
      autoSelectBGM: json['auto_select_bgm'],
      autoSelectVoice: json['auto_select_voice'],
      environmentDetection: json['environment_detection'],
      noiseAdaptation: json['noise_adaptation'],
      timeOfDayAdjustment: json['time_of_day_adjustment'],
      contentAwareAdjustment: json['content_aware_adjustment'],
      emotionMatching: json['emotion_matching'],
      learningRate: json['learning_rate'].toDouble(),
      adaptationSensitivity: json['adaptation_sensitivity'].toDouble(),
      minimumLearningPeriod: json['minimum_learning_period'],
      maximumAdjustmentRange: json['maximum_adjustment_range'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'learn_from_usage': learnFromUsage,
      'auto_adjust_volume': autoAdjustVolume,
      'auto_adjust_speed': autoAdjustSpeed,
      'auto_select_bgm': autoSelectBGM,
      'auto_select_voice': autoSelectVoice,
      'environment_detection': environmentDetection,
      'noise_adaptation': noiseAdaptation,
      'time_of_day_adjustment': timeOfDayAdjustment,
      'content_aware_adjustment': contentAwareAdjustment,
      'emotion_matching': emotionMatching,
      'learning_rate': learningRate,
      'adaptation_sensitivity': adaptationSensitivity,
      'minimum_learning_period': minimumLearningPeriod,
      'maximum_adjustment_range': maximumAdjustmentRange,
    };
  }
}

class VolumePreferences {
  final double masterVolume;
  final double voiceVolume;
  final double bgmVolume;
  final double environmentalVolume;
  final double effectsVolume;
  final String duckingPreference;
  final String fadePreference;
  final bool autoVolumeEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final double quietHoursVolume;

  VolumePreferences({
    required this.masterVolume,
    required this.voiceVolume,
    required this.bgmVolume,
    required this.environmentalVolume,
    required this.effectsVolume,
    required this.duckingPreference,
    required this.fadePreference,
    required this.autoVolumeEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.quietHoursVolume,
  });

  factory VolumePreferences.fromJson(Map<String, dynamic> json) {
    return VolumePreferences(
      masterVolume: json['master_volume'].toDouble(),
      voiceVolume: json['voice_volume'].toDouble(),
      bgmVolume: json['bgm_volume'].toDouble(),
      environmentalVolume: json['environmental_volume'].toDouble(),
      effectsVolume: json['effects_volume'].toDouble(),
      duckingPreference: json['ducking_preference'],
      fadePreference: json['fade_preference'],
      autoVolumeEnabled: json['auto_volume_enabled'],
      quietHoursEnabled: json['quiet_hours_enabled'],
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      quietHoursVolume: json['quiet_hours_volume'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master_volume': masterVolume,
      'voice_volume': voiceVolume,
      'bgm_volume': bgmVolume,
      'environmental_volume': environmentalVolume,
      'effects_volume': effectsVolume,
      'ducking_preference': duckingPreference,
      'fade_preference': fadePreference,
      'auto_volume_enabled': autoVolumeEnabled,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'quiet_hours_volume': quietHoursVolume,
    };
  }
}

class ListeningSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int bookId;
  final String? voicePresetId;
  final String? audioSceneId;
  final String environment;
  final List<String> context;
  final int volumeAdjustments;
  final int voiceChanges;
  final int bgmChanges;
  final int skipCount;
  final int pauseCount;
  final double averageVolume;
  final double completionPercentage;
  final int? qualityRating;
  final List<String> audioQualityIssues;

  ListeningSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.bookId,
    this.voicePresetId,
    this.audioSceneId,
    required this.environment,
    required this.context,
    required this.volumeAdjustments,
    required this.voiceChanges,
    required this.bgmChanges,
    required this.skipCount,
    required this.pauseCount,
    required this.averageVolume,
    required this.completionPercentage,
    this.qualityRating,
    required this.audioQualityIssues,
  });

  factory ListeningSession.fromJson(Map<String, dynamic> json) {
    return ListeningSession(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      bookId: json['book_id'],
      voicePresetId: json['voice_preset_id'],
      audioSceneId: json['audio_scene_id'],
      environment: json['environment'],
      context: List<String>.from(json['context']),
      volumeAdjustments: json['volume_adjustments'],
      voiceChanges: json['voice_changes'],
      bgmChanges: json['bgm_changes'],
      skipCount: json['skip_count'],
      pauseCount: json['pause_count'],
      averageVolume: json['average_volume'].toDouble(),
      completionPercentage: json['completion_percentage'].toDouble(),
      qualityRating: json['quality_rating'],
      audioQualityIssues: List<String>.from(json['audio_quality_issues']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'book_id': bookId,
      'voice_preset_id': voicePresetId,
      'audio_scene_id': audioSceneId,
      'environment': environment,
      'context': context,
      'volume_adjustments': volumeAdjustments,
      'voice_changes': voiceChanges,
      'bgm_changes': bgmChanges,
      'skip_count': skipCount,
      'pause_count': pauseCount,
      'average_volume': averageVolume,
      'completion_percentage': completionPercentage,
      'quality_rating': qualityRating,
      'audio_quality_issues': audioQualityIssues,
    };
  }
}

class AudioMixRequest {
  final String voicePresetId;
  final String? audioSceneId;
  final String text;
  final int bookId;
  final int? chapterId;
  final ContextSettings? contextOverride;
  final AudioMixingSettings? mixingOverride;
  final String outputFormat;
  final String quality;
  final bool enableCaching;
  final bool streamingEnabled;
  final bool previewMode;
  final bool adaptiveOptimization;

  AudioMixRequest({
    required this.voicePresetId,
    this.audioSceneId,
    required this.text,
    required this.bookId,
    this.chapterId,
    this.contextOverride,
    this.mixingOverride,
    required this.outputFormat,
    required this.quality,
    required this.enableCaching,
    required this.streamingEnabled,
    this.previewMode = false,
    this.adaptiveOptimization = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'voice_preset_id': voicePresetId,
      'audio_scene_id': audioSceneId,
      'text': text,
      'book_id': bookId,
      'chapter_id': chapterId,
      'context_override': contextOverride?.toJson(),
      'mixing_override': mixingOverride?.toJson(),
      'output_format': outputFormat,
      'quality': quality,
      'enable_caching': enableCaching,
      'streaming_enabled': streamingEnabled,
      'preview_mode': previewMode,
      'adaptive_optimization': adaptiveOptimization,
    };
  }
}

class AudioMixResponse {
  final String mixedAudioUrl;
  final Map<String, String> componentUrls;
  final String cacheId;
  final int durationSeconds;
  final int fileSizeBytes;
  final AudioMixingSettings appliedSettings;
  final int processingTimeMs;
  final AudioQualityMetrics qualityMetrics;
  final StreamingInfo? streamingInfo;
  final bool optimizationApplied;
  final AudioMixingSettings? recommendedSettings;

  AudioMixResponse({
    required this.mixedAudioUrl,
    required this.componentUrls,
    required this.cacheId,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.appliedSettings,
    required this.processingTimeMs,
    required this.qualityMetrics,
    this.streamingInfo,
    required this.optimizationApplied,
    this.recommendedSettings,
  });

  factory AudioMixResponse.fromJson(Map<String, dynamic> json) {
    return AudioMixResponse(
      mixedAudioUrl: json['mixed_audio_url'],
      componentUrls: Map<String, String>.from(json['component_urls']),
      cacheId: json['cache_id'],
      durationSeconds: json['duration_seconds'],
      fileSizeBytes: json['file_size_bytes'],
      appliedSettings: AudioMixingSettings.fromJson(json['applied_settings']),
      processingTimeMs: json['processing_time_ms'],
      qualityMetrics: AudioQualityMetrics.fromJson(json['quality_metrics']),
      streamingInfo: json['streaming_info'] != null
          ? StreamingInfo.fromJson(json['streaming_info'])
          : null,
      optimizationApplied: json['optimization_applied'],
      recommendedSettings: json['recommended_settings'] != null
          ? AudioMixingSettings.fromJson(json['recommended_settings'])
          : null,
    );
  }
}

class AudioQualityMetrics {
  final double voiceClarity;
  final double backgroundBalance;
  final double volumeConsistency;
  final double frequencyBalance;
  final double dynamicRange;
  final double signalToNoiseRatio;
  final double overallQualityScore;
  final List<String> potentialIssues;
  final List<String> optimizationSuggestions;

  AudioQualityMetrics({
    required this.voiceClarity,
    required this.backgroundBalance,
    required this.volumeConsistency,
    required this.frequencyBalance,
    required this.dynamicRange,
    required this.signalToNoiseRatio,
    required this.overallQualityScore,
    required this.potentialIssues,
    required this.optimizationSuggestions,
  });

  factory AudioQualityMetrics.fromJson(Map<String, dynamic> json) {
    return AudioQualityMetrics(
      voiceClarity: json['voice_clarity'].toDouble(),
      backgroundBalance: json['background_balance'].toDouble(),
      volumeConsistency: json['volume_consistency'].toDouble(),
      frequencyBalance: json['frequency_balance'].toDouble(),
      dynamicRange: json['dynamic_range'].toDouble(),
      signalToNoiseRatio: json['signal_to_noise_ratio'].toDouble(),
      overallQualityScore: json['overall_quality_score'].toDouble(),
      potentialIssues: List<String>.from(json['potential_issues']),
      optimizationSuggestions: List<String>.from(json['optimization_suggestions']),
    );
  }
}

class StreamingInfo {
  final int chunkDurationMs;
  final List<String> chunkUrls;
  final List<int> chunkSizes;
  final int bufferSize;
  final int preloadChunks;
  final String streamingProtocol;

  StreamingInfo({
    required this.chunkDurationMs,
    required this.chunkUrls,
    required this.chunkSizes,
    required this.bufferSize,
    required this.preloadChunks,
    required this.streamingProtocol,
  });

  factory StreamingInfo.fromJson(Map<String, dynamic> json) {
    return StreamingInfo(
      chunkDurationMs: json['chunk_duration_ms'],
      chunkUrls: List<String>.from(json['chunk_urls']),
      chunkSizes: List<int>.from(json['chunk_sizes']),
      bufferSize: json['buffer_size'],
      preloadChunks: json['preload_chunks'],
      streamingProtocol: json['streaming_protocol'],
    );
  }
}

class ContentAnalysisResult {
  final int bookId;
  final int? chapterId;
  final List<String> detectedMood;
  final List<String> detectedGenre;
  final List<String> detectedAtmosphere;
  final EmotionSettings emotionalTone;
  final SpeakingStyleSettings speakingStyle;
  final List<BGMRecommendation> recommendedBGM;
  final List<EnvironmentalRecommendation> recommendedEnvironmental;
  final List<CharacterVoiceMapping> characterVoices;
  final NarrativeStructure narrativeStructure;
  final String complexityLevel;
  final double readingDifficulty;
  final double confidenceScore;
  final int processingTimeMs;
  final String analysisVersion;

  ContentAnalysisResult({
    required this.bookId,
    this.chapterId,
    required this.detectedMood,
    required this.detectedGenre,
    required this.detectedAtmosphere,
    required this.emotionalTone,
    required this.speakingStyle,
    required this.recommendedBGM,
    required this.recommendedEnvironmental,
    required this.characterVoices,
    required this.narrativeStructure,
    required this.complexityLevel,
    required this.readingDifficulty,
    required this.confidenceScore,
    required this.processingTimeMs,
    required this.analysisVersion,
  });

  factory ContentAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ContentAnalysisResult(
      bookId: json['book_id'],
      chapterId: json['chapter_id'],
      detectedMood: List<String>.from(json['detected_mood']),
      detectedGenre: List<String>.from(json['detected_genre']),
      detectedAtmosphere: List<String>.from(json['detected_atmosphere']),
      emotionalTone: EmotionSettings.fromJson(json['emotional_tone']),
      speakingStyle: SpeakingStyleSettings.fromJson(json['speaking_style']),
      recommendedBGM: (json['recommended_bgm'] as List)
          .map((rec) => BGMRecommendation.fromJson(rec))
          .toList(),
      recommendedEnvironmental: (json['recommended_environmental'] as List)
          .map((rec) => EnvironmentalRecommendation.fromJson(rec))
          .toList(),
      characterVoices: (json['character_voices'] as List)
          .map((voice) => CharacterVoiceMapping.fromJson(voice))
          .toList(),
      narrativeStructure: NarrativeStructure.fromJson(json['narrative_structure']),
      complexityLevel: json['complexity_level'],
      readingDifficulty: json['reading_difficulty'].toDouble(),
      confidenceScore: json['confidence_score'].toDouble(),
      processingTimeMs: json['processing_time_ms'],
      analysisVersion: json['analysis_version'],
    );
  }
}

class BGMRecommendation {
  final String bgmTrackId;
  final double matchScore;
  final List<String> reasonCodes;
  final int? startTime;
  final int? duration;
  final double? volume;
  final int priority;

  BGMRecommendation({
    required this.bgmTrackId,
    required this.matchScore,
    required this.reasonCodes,
    this.startTime,
    this.duration,
    this.volume,
    required this.priority,
  });

  factory BGMRecommendation.fromJson(Map<String, dynamic> json) {
    return BGMRecommendation(
      bgmTrackId: json['bgm_track_id'],
      matchScore: json['match_score'].toDouble(),
      reasonCodes: List<String>.from(json['reason_codes']),
      startTime: json['start_time'],
      duration: json['duration'],
      volume: json['volume']?.toDouble(),
      priority: json['priority'],
    );
  }
}

class EnvironmentalRecommendation {
  final String environmentalSoundId;
  final double matchScore;
  final List<String> reasonCodes;
  final int? startTime;
  final int? duration;
  final double? volume;
  final int priority;

  EnvironmentalRecommendation({
    required this.environmentalSoundId,
    required this.matchScore,
    required this.reasonCodes,
    this.startTime,
    this.duration,
    this.volume,
    required this.priority,
  });

  factory EnvironmentalRecommendation.fromJson(Map<String, dynamic> json) {
    return EnvironmentalRecommendation(
      environmentalSoundId: json['environmental_sound_id'],
      matchScore: json['match_score'].toDouble(),
      reasonCodes: List<String>.from(json['reason_codes']),
      startTime: json['start_time'],
      duration: json['duration'],
      volume: json['volume']?.toDouble(),
      priority: json['priority'],
    );
  }
}

class CharacterVoiceMapping {
  final String characterName;
  final VoiceSettings voiceSettings;
  final EmotionSettings emotionSettings;
  final double confidence;
  final int occurrenceCount;
  final List<String> dialogueExamples;

  CharacterVoiceMapping({
    required this.characterName,
    required this.voiceSettings,
    required this.emotionSettings,
    required this.confidence,
    required this.occurrenceCount,
    required this.dialogueExamples,
  });

  factory CharacterVoiceMapping.fromJson(Map<String, dynamic> json) {
    return CharacterVoiceMapping(
      characterName: json['character_name'],
      voiceSettings: VoiceSettings.fromJson(json['voice_settings']),
      emotionSettings: EmotionSettings.fromJson(json['emotion_settings']),
      confidence: json['confidence'].toDouble(),
      occurrenceCount: json['occurrence_count'],
      dialogueExamples: List<String>.from(json['dialogue_examples']),
    );
  }
}

class NarrativeStructure {
  final String type;
  final String perspective;
  final String tense;
  final double dialoguePercentage;
  final double narrationPercentage;
  final List<ChapterStructure> chapters;
  final List<TransitionPoint> transitionPoints;
  final List<ClimaxPoint> climaxPoints;
  final PacingProfile pacingProfile;

  NarrativeStructure({
    required this.type,
    required this.perspective,
    required this.tense,
    required this.dialoguePercentage,
    required this.narrationPercentage,
    required this.chapters,
    required this.transitionPoints,
    required this.climaxPoints,
    required this.pacingProfile,
  });

  factory NarrativeStructure.fromJson(Map<String, dynamic> json) {
    return NarrativeStructure(
      type: json['type'],
      perspective: json['perspective'],
      tense: json['tense'],
      dialoguePercentage: json['dialogue_percentage'].toDouble(),
      narrationPercentage: json['narration_percentage'].toDouble(),
      chapters: (json['chapters'] as List)
          .map((chapter) => ChapterStructure.fromJson(chapter))
          .toList(),
      transitionPoints: (json['transition_points'] as List)
          .map((point) => TransitionPoint.fromJson(point))
          .toList(),
      climaxPoints: (json['climax_points'] as List)
          .map((point) => ClimaxPoint.fromJson(point))
          .toList(),
      pacingProfile: PacingProfile.fromJson(json['pacing_profile']),
    );
  }
}

class ChapterStructure {
  final int chapterId;
  final String title;
  final List<String> mood;
  final List<String> atmosphere;
  final List<String> primaryCharacters;
  final List<String> sceneSetting;
  final EmotionalArc emotionalArc;
  final double dialogueDensity;
  final double actionLevel;
  final double complexityLevel;
  final int readingTime;

  ChapterStructure({
    required this.chapterId,
    required this.title,
    required this.mood,
    required this.atmosphere,
    required this.primaryCharacters,
    required this.sceneSetting,
    required this.emotionalArc,
    required this.dialogueDensity,
    required this.actionLevel,
    required this.complexityLevel,
    required this.readingTime,
  });

  factory ChapterStructure.fromJson(Map<String, dynamic> json) {
    return ChapterStructure(
      chapterId: json['chapter_id'],
      title: json['title'],
      mood: List<String>.from(json['mood']),
      atmosphere: List<String>.from(json['atmosphere']),
      primaryCharacters: List<String>.from(json['primary_characters']),
      sceneSetting: List<String>.from(json['scene_setting']),
      emotionalArc: EmotionalArc.fromJson(json['emotional_arc']),
      dialogueDensity: json['dialogue_density'].toDouble(),
      actionLevel: json['action_level'].toDouble(),
      complexityLevel: json['complexity_level'].toDouble(),
      readingTime: json['reading_time'],
    );
  }
}

class TransitionPoint {
  final int position;
  final String transitionType;
  final String description;
  final int recommendedFade;
  final List<String>? newMood;
  final List<String>? newAtmosphere;

  TransitionPoint({
    required this.position,
    required this.transitionType,
    required this.description,
    required this.recommendedFade,
    this.newMood,
    this.newAtmosphere,
  });

  factory TransitionPoint.fromJson(Map<String, dynamic> json) {
    return TransitionPoint(
      position: json['position'],
      transitionType: json['transition_type'],
      description: json['description'],
      recommendedFade: json['recommended_fade'],
      newMood: json['new_mood'] != null ? List<String>.from(json['new_mood']) : null,
      newAtmosphere: json['new_atmosphere'] != null ? List<String>.from(json['new_atmosphere']) : null,
    );
  }
}

class ClimaxPoint {
  final int position;
  final double intensity;
  final String type;
  final String description;

  ClimaxPoint({
    required this.position,
    required this.intensity,
    required this.type,
    required this.description,
  });

  factory ClimaxPoint.fromJson(Map<String, dynamic> json) {
    return ClimaxPoint(
      position: json['position'],
      intensity: json['intensity'].toDouble(),
      type: json['type'],
      description: json['description'],
    );
  }
}

class EmotionalArc {
  final String startEmotion;
  final String endEmotion;
  final List<EmotionPoint> emotionPoints;
  final String overallTone;
  final double emotionalRange;

  EmotionalArc({
    required this.startEmotion,
    required this.endEmotion,
    required this.emotionPoints,
    required this.overallTone,
    required this.emotionalRange,
  });

  factory EmotionalArc.fromJson(Map<String, dynamic> json) {
    return EmotionalArc(
      startEmotion: json['start_emotion'],
      endEmotion: json['end_emotion'],
      emotionPoints: (json['emotion_points'] as List)
          .map((point) => EmotionPoint.fromJson(point))
          .toList(),
      overallTone: json['overall_tone'],
      emotionalRange: json['emotional_range'].toDouble(),
    );
  }
}

class EmotionPoint {
  final int position;
  final String emotion;
  final double intensity;
  final double confidence;

  EmotionPoint({
    required this.position,
    required this.emotion,
    required this.intensity,
    required this.confidence,
  });

  factory EmotionPoint.fromJson(Map<String, dynamic> json) {
    return EmotionPoint(
      position: json['position'],
      emotion: json['emotion'],
      intensity: json['intensity'].toDouble(),
      confidence: json['confidence'].toDouble(),
    );
  }
}

class PacingProfile {
  final String overallPace;
  final List<PaceChange> paceChanges;
  final double averagePace;
  final List<TensionPoint> tensionCurve;

  PacingProfile({
    required this.overallPace,
    required this.paceChanges,
    required this.averagePace,
    required this.tensionCurve,
  });

  factory PacingProfile.fromJson(Map<String, dynamic> json) {
    return PacingProfile(
      overallPace: json['overall_pace'],
      paceChanges: (json['pace_changes'] as List)
          .map((change) => PaceChange.fromJson(change))
          .toList(),
      averagePace: json['average_pace'].toDouble(),
      tensionCurve: (json['tension_curve'] as List)
          .map((point) => TensionPoint.fromJson(point))
          .toList(),
    );
  }
}

class PaceChange {
  final int position;
  final String newPace;
  final String reason;
  final double speedAdjust;

  PaceChange({
    required this.position,
    required this.newPace,
    required this.reason,
    required this.speedAdjust,
  });

  factory PaceChange.fromJson(Map<String, dynamic> json) {
    return PaceChange(
      position: json['position'],
      newPace: json['new_pace'],
      reason: json['reason'],
      speedAdjust: json['speed_adjust'].toDouble(),
    );
  }
}

class TensionPoint {
  final int position;
  final double tension;

  TensionPoint({
    required this.position,
    required this.tension,
  });

  factory TensionPoint.fromJson(Map<String, dynamic> json) {
    return TensionPoint(
      position: json['position'],
      tension: json['tension'].toDouble(),
    );
  }
}