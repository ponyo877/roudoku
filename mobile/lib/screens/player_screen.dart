import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../providers/audio_player_provider.dart';
import 'voice_settings_screen.dart';

class PlayerScreen extends StatefulWidget {
  final Book book;

  const PlayerScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: Consumer<AudioPlayerProvider>(
        builder: (context, audioProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.book.coverUrl,
                          width: 280,
                          height: 280,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.author,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        audioProvider.currentChapter != null
                            ? '第${audioProvider.currentChapterIndex + 1}章: ${audioProvider.currentChapter!.title}'
                            : '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    StreamBuilder<Duration>(
                      stream: audioProvider.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = audioProvider.duration ?? Duration.zero;
                        
                        return Column(
                          children: [
                            Slider(
                              value: position.inSeconds.toDouble(),
                              max: duration.inSeconds.toDouble(),
                              onChanged: (value) {
                                audioProvider.seek(Duration(seconds: value.toInt()));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position)),
                                  Text(_formatDuration(duration)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_30),
                          iconSize: 32,
                          onPressed: () {
                            audioProvider.rewind();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 40,
                          onPressed: audioProvider.hasPreviousChapter
                              ? () => audioProvider.previousChapter()
                              : null,
                        ),
                        StreamBuilder<bool>(
                          stream: audioProvider.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                iconSize: 36,
                                onPressed: () {
                                  if (isPlaying) {
                                    audioProvider.pause();
                                  } else {
                                    audioProvider.play();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 40,
                          onPressed: audioProvider.hasNextChapter
                              ? () => audioProvider.nextChapter()
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_30),
                          iconSize: 32,
                          onPressed: () {
                            audioProvider.fastForward();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            _showSpeedDialog();
                          },
                          child: Text('${_playbackSpeed}x'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer),
                          onPressed: () {
                            _showSleepTimerDialog();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          onPressed: () {
                            _showChapterList();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('再生速度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speedOptions.map((speed) {
              return RadioListTile<double>(
                title: Text('${speed}x'),
                value: speed,
                groupValue: _playbackSpeed,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _playbackSpeed = value;
                    });
                    context.read<AudioPlayerProvider>().setSpeed(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('スリープタイマー'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('15分'),
                onTap: () {
                  context.read<AudioPlayerProvider>().setSleepTimer(15);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('30分'),
                onTap: () {
                  context.read<AudioPlayerProvider>().setSleepTimer(30);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('45分'),
                onTap: () {
                  context.read<AudioPlayerProvider>().setSleepTimer(45);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('60分'),
                onTap: () {
                  context.read<AudioPlayerProvider>().setSleepTimer(60);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('オフ'),
                onTap: () {
                  context.read<AudioPlayerProvider>().cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final audioProvider = context.read<AudioPlayerProvider>();
        return ListView.builder(
          itemCount: widget.book.chapters.length,
          itemBuilder: (context, index) {
            final chapter = widget.book.chapters[index];
            final isCurrentChapter = audioProvider.currentChapterIndex == index;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCurrentChapter 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[300],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrentChapter ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              title: Text(
                chapter.title,
                style: TextStyle(
                  fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text('${chapter.duration}分'),
              trailing: isCurrentChapter 
                  ? const Icon(Icons.play_arrow, color: Colors.blue)
                  : null,
              onTap: () {
                audioProvider.seekToChapter(index);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}