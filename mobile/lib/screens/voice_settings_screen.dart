import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';
import '../models/session_models.dart' as session_models;
import '../services/audio_service.dart' as audio_service;

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  late audio_service.VoiceSettings _currentSettings;
  List<audio_service.AvailableVoice> _availableVoices = [];
  bool _isLoadingVoices = false;
  bool _isPlayingPreview = false;
  AudioPlayer? _previewPlayer;
  String? _loadingError;

  // Conversion methods between VoiceSettings types
  static audio_service.VoiceSettings sessionToAudioSettings(session_models.VoiceSettings sessionSettings) {
    return audio_service.VoiceSettings(
      voice: sessionSettings.voiceId ?? 'ja-JP-Wavenet-A',
      gender: 'FEMALE', // Default, will be overridden by voice selection
      language: sessionSettings.language ?? 'ja-JP',
      speed: sessionSettings.rate,
      pitch: (sessionSettings.pitch - 1.0) * 20.0, // Convert from 0-2 range (center 1.0) to -20 to +20
      volumeGain: (sessionSettings.volume - 1.0) * 10.0, // Convert from 0-2 range (center 1.0) to -10 to +10
    );
  }

  static session_models.VoiceSettings audioToSessionSettings(audio_service.VoiceSettings audioSettings) {
    return session_models.VoiceSettings(
      pitch: (audioSettings.pitch / 20.0) + 1.0, // Convert from -20 to +20 range to 0-2 (center 1.0)
      rate: audioSettings.speed,
      volume: (audioSettings.volumeGain / 10.0) + 1.0, // Convert from -10 to +10 range to 0-2 (center 1.0)
      voiceId: audioSettings.voice,
      language: audioSettings.language,
    );
  }

  // Predefined Japanese voices with user-friendly names
  final List<VoiceOption> _voiceOptions = [
    VoiceOption(
      name: 'ja-JP-Wavenet-A',
      displayName: '女性の声 (A)',
      gender: 'FEMALE',
      description: '自然で落ち着いた女性の声',
    ),
    VoiceOption(
      name: 'ja-JP-Wavenet-B',
      displayName: '男性の声 (B)',
      gender: 'MALE',
      description: '深みのある男性の声',
    ),
    VoiceOption(
      name: 'ja-JP-Wavenet-C',
      displayName: '男性の声 (C)',
      gender: 'MALE',
      description: '明るい男性の声',
    ),
    VoiceOption(
      name: 'ja-JP-Wavenet-D',
      displayName: '男性の声 (D)',
      gender: 'MALE',
      description: '重厚な男性の声',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    _currentSettings = sessionToAudioSettings(audioProvider.voiceSettings);
    _loadAvailableVoices();
  }

  @override
  void dispose() {
    _previewPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableVoices() async {
    setState(() {
      _isLoadingVoices = true;
      _loadingError = null;
    });

    try {
      final audioService = Provider.of<audio_service.AudioService>(context, listen: false);
      _availableVoices = await audioService.getAvailableVoices();
    } catch (e) {
      setState(() {
        _loadingError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingVoices = false;
      });
    }
  }

  Future<void> _playVoicePreview(audio_service.VoiceSettings settings) async {
    if (_isPlayingPreview) {
      await _previewPlayer?.stop();
      setState(() {
        _isPlayingPreview = false;
      });
      return;
    }

    setState(() {
      _isPlayingPreview = true;
    });

    try {
      final audioService = Provider.of<audio_service.AudioService>(context, listen: false);
      final previewRequest = audio_service.AudioPreviewRequest(
        voiceSettings: settings,
        sampleText: 'こんにちは。これは音声のプレビューです。この声と速度はいかがでしょうか。',
      );

      final response = await audioService.generatePreview(previewRequest);
      await _previewPlayer?.setUrl(response.audioUrl);
      await _previewPlayer?.play();

      // Auto-stop preview after it finishes
      _previewPlayer?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlayingPreview = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isPlayingPreview = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プレビューの再生に失敗しました: $e')),
        );
      }
    }
  }

  void _applySettings() {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final sessionSettings = audioToSessionSettings(_currentSettings);
    audioProvider.setVoiceSettings(sessionSettings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音声設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _applySettings,
            child: const Text(
              '適用',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Selection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.record_voice_over),
                        const SizedBox(width: 8),
                        Text(
                          '声の種類',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingVoices)
                      const Center(child: CircularProgressIndicator())
                    else if (_loadingError != null)
                      Column(
                        children: [
                          Text(
                            'エラー: $_loadingError',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadAvailableVoices,
                            child: const Text('再試行'),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: _voiceOptions.map((voiceOption) {
                          final isSelected = _currentSettings.voice == voiceOption.name;
                          return Card(
                            elevation: isSelected ? 4 : 1,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: ListTile(
                              leading: Icon(
                                voiceOption.gender == 'FEMALE'
                                    ? Icons.face_3
                                    : Icons.face,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              title: Text(
                                voiceOption.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              subtitle: Text(voiceOption.description),
                              trailing: IconButton(
                                icon: Icon(
                                  _isPlayingPreview ? Icons.stop : Icons.play_arrow,
                                ),
                                onPressed: () => _playVoicePreview(
                                  audio_service.VoiceSettings(
                                    voice: voiceOption.name,
                                    gender: voiceOption.gender,
                                    language: 'ja-JP',
                                    speed: _currentSettings.speed,
                                    pitch: _currentSettings.pitch,
                                    volumeGain: _currentSettings.volumeGain,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _currentSettings = audio_service.VoiceSettings(
                                    voice: voiceOption.name,
                                    gender: voiceOption.gender,
                                    language: 'ja-JP',
                                    speed: _currentSettings.speed,
                                    pitch: _currentSettings.pitch,
                                    volumeGain: _currentSettings.volumeGain,
                                  );
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Speed Control Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed),
                        const SizedBox(width: 8),
                        Text(
                          '再生速度',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('${_currentSettings.speed.toStringAsFixed(1)}x'),
                        Expanded(
                          child: Slider(
                            value: _currentSettings.speed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: '${_currentSettings.speed.toStringAsFixed(1)}x',
                            onChanged: (value) {
                              setState(() {
                                _currentSettings = audio_service.VoiceSettings(
                                  voice: _currentSettings.voice,
                                  gender: _currentSettings.gender,
                                  language: _currentSettings.language,
                                  speed: value,
                                  pitch: _currentSettings.pitch,
                                  volumeGain: _currentSettings.volumeGain,
                                );
                              });
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _playVoicePreview(_currentSettings),
                          child: Text(_isPlayingPreview ? '停止' : 'プレビュー'),
                        ),
                      ],
                    ),
                    const Text(
                      '0.5倍速（ゆっくり）から2.0倍速（早い）まで調整できます',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Advanced Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune),
                        const SizedBox(width: 8),
                        Text(
                          '詳細設定',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Pitch Control
                    Text('音の高さ: ${_currentSettings.pitch.toStringAsFixed(1)}'),
                    Slider(
                      value: _currentSettings.pitch,
                      min: -20.0,
                      max: 20.0,
                      divisions: 40,
                      label: _currentSettings.pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _currentSettings = audio_service.VoiceSettings(
                            voice: _currentSettings.voice,
                            gender: _currentSettings.gender,
                            language: _currentSettings.language,
                            speed: _currentSettings.speed,
                            pitch: value,
                            volumeGain: _currentSettings.volumeGain,
                          );
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Volume Gain Control
                    Text('音量調整: ${_currentSettings.volumeGain.toStringAsFixed(1)} dB'),
                    Slider(
                      value: _currentSettings.volumeGain,
                      min: -10.0,
                      max: 10.0,
                      divisions: 20,
                      label: '${_currentSettings.volumeGain.toStringAsFixed(1)} dB',
                      onChanged: (value) {
                        setState(() {
                          _currentSettings = audio_service.VoiceSettings(
                            voice: _currentSettings.voice,
                            gender: _currentSettings.gender,
                            language: _currentSettings.language,
                            speed: _currentSettings.speed,
                            pitch: _currentSettings.pitch,
                            volumeGain: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reset to Default Button
            Center(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentSettings = audio_service.VoiceSettings.defaultSettings;
                  });
                },
                child: const Text('デフォルトに戻す'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceOption {
  final String name;
  final String displayName;
  final String gender;
  final String description;

  VoiceOption({
    required this.name,
    required this.displayName,
    required this.gender,
    required this.description,
  });
}