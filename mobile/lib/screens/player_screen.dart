import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../providers/audio_player_provider.dart';
import '../services/cloud_tts_service.dart';
import '../services/book_service.dart';
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
  late CloudTtsService _ttsService;
  late BookService _bookService;
  bool _isSpeaking = false;
  String? _currentChapterContent;
  bool _isLoadingContent = false;
  List<Chapter> _bookChapters = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize TTS and load chapters
    _initializeTts();
    _loadBookChapters();
  }

  Future<void> _loadBookChapters() async {
    try {
      final chapters = await _bookService.getBookChapters(widget.book.id);
      
      // Store chapters in local state
      if (chapters.isNotEmpty) {
        final updatedChapters = chapters.map((chapterData) => Chapter(
          id: chapterData['ID'] ?? '',
          title: chapterData['Title'] ?? '章タイトル',
          duration: 0, // We'll calculate this later
          startTime: 0,
          endTime: 0,
        )).toList();
        
        setState(() {
          _bookChapters = updatedChapters;
        });
      } else {
        // Create a fallback chapter if no chapters are available
        final fallbackChapter = Chapter(
          id: 'fallback-${widget.book.id}',
          title: '全文',
          duration: widget.book.duration,
          startTime: 0,
          endTime: widget.book.duration * 60, // Convert minutes to seconds
        );
        
        setState(() {
          _bookChapters = [fallbackChapter];
        });
      }
    } catch (e) {
      // Create fallback chapter on error
      final fallbackChapter = Chapter(
        id: 'fallback-${widget.book.id}',
        title: '全文',
        duration: widget.book.duration,
        startTime: 0,
        endTime: widget.book.duration * 60,
      );
      
      setState(() {
        _bookChapters = [fallbackChapter];
      });
    }
  }
  
  void _initializeTts() {
    _ttsService = Provider.of<CloudTtsService>(context, listen: false);
    _bookService = BookService();
    
    // Share the audio player with TTS service
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    _ttsService.setAudioPlayer(audioProvider.audioPlayer);
    
    // Setup TTS callbacks
    _ttsService.onPlayingChanged = () {
      if (mounted) {
        setState(() {
          _isSpeaking = _ttsService.isPlaying;
        });
      }
    };
  }

  Future<void> _loadChapterContent(String chapterId) async {
    if (_isLoadingContent) return;
    
    setState(() {
      _isLoadingContent = true;
    });

    try {
      // Check if this is a fallback chapter
      if (chapterId.startsWith('fallback-')) {
        // For fallback chapters, try to load the first available chapter content
        final chapters = await _bookService.getBookChapters(widget.book.id);
        if (chapters.isNotEmpty) {
          final firstChapter = chapters[0];
          final chapterData = await _bookService.getChapterContent(widget.book.id, firstChapter['ID'] ?? '');
          setState(() {
            _currentChapterContent = chapterData['content'] ?? chapterData['Content'] ?? '''${widget.book.title}

著者: ${widget.book.author}

${widget.book.description}

申し訳ありませんが、この作品のコンテンツを読み込むことができませんでした。''';
            _isLoadingContent = false;
          });
        } else {
          setState(() {
            _currentChapterContent = '''${widget.book.title}

著者: ${widget.book.author}

この作品は青空文庫から取得されており、現在サーバーでテキスト処理中です。

${widget.book.description}

今後のアップデートで、作品の全文を音声で読み上げる機能が追加される予定です。現在は作品の説明を読み上げています。''';
            _isLoadingContent = false;
          });
        }
      } else {
        final chapterData = await _bookService.getChapterContent(widget.book.id, chapterId);
        setState(() {
          _currentChapterContent = chapterData['content'] ?? chapterData['Content'] ?? '';
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      // Set fallback content
      setState(() {
        _currentChapterContent = '''${widget.book.title}の内容を読み込めませんでした。

著者: ${widget.book.author}

${widget.book.description}''';
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _speakCurrentChapter() async {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final chapters = _bookChapters.isNotEmpty ? _bookChapters : widget.book.chapters;
    
    if (chapters.isEmpty || audioProvider.currentChapterIndex >= chapters.length) {
      return;
    }
    
    final currentChapter = chapters[audioProvider.currentChapterIndex];
    
    // Load chapter content if not already loaded
    if (_currentChapterContent == null) {
      await _loadChapterContent(currentChapter.id);
    }
    
    if (_currentChapterContent != null && _currentChapterContent!.isNotEmpty) {
      if (_isSpeaking) {
        await _ttsService.stop();
      } else {
        await _ttsService.speak(_currentChapterContent!);
      }
    } else {
      // Fallback to chapter title if content is not available
      final chapterTitle = currentChapter.title;
      if (_isSpeaking) {
        await _ttsService.stop();
      } else {
        await _ttsService.speak('第${audioProvider.currentChapterIndex + 1}章: $chapterTitle');
      }
    }
  }

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
                        child: widget.book.coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.book.coverUrl,
                                width: 280,
                                height: 280,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 280,
                                  height: 280,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 280,
                                  height: 280,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.menu_book, size: 80),
                                ),
                              )
                            : Container(
                                width: 280,
                                height: 280,
                                color: Colors.grey[300],
                                child: const Icon(Icons.menu_book, size: 80),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              () {
                                final chapters = _bookChapters.isNotEmpty ? _bookChapters : widget.book.chapters;
                                if (chapters.isNotEmpty && audioProvider.currentChapterIndex < chapters.length) {
                                  final currentChapter = chapters[audioProvider.currentChapterIndex];
                                  return '第${audioProvider.currentChapterIndex + 1}章: ${currentChapter.title}';
                                }
                                return '';
                              }(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if ((() {
                            final chapters = _bookChapters.isNotEmpty ? _bookChapters : widget.book.chapters;
                            return chapters.isNotEmpty && audioProvider.currentChapterIndex < chapters.length;
                          })())
                            IconButton(
                              icon: Icon(
                                _isSpeaking ? Icons.stop : Icons.volume_up,
                                color: _isSpeaking 
                                    ? Colors.red 
                                    : Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              onPressed: _isLoadingContent ? null : _speakCurrentChapter,
                              tooltip: _isSpeaking ? '読み上げを停止' : (_isLoadingContent ? '章を読み込み中...' : '章の内容を読み上げ'),
                            ),
                        ],
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
                              ? () {
                                  audioProvider.previousChapter();
                                  setState(() {
                                    _currentChapterContent = null; // Reset content for new chapter
                                  });
                                }
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
                                onPressed: () async {
                                  if (isPlaying || _isSpeaking) {
                                    // Stop both audio and TTS
                                    audioProvider.pause();
                                    await _ttsService.stop();
                                  } else {
                                    // Start playing chapter content via TTS
                                    await _speakCurrentChapter();
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
                              ? () {
                                  audioProvider.nextChapter();
                                  setState(() {
                                    _currentChapterContent = null; // Reset content for new chapter
                                  });
                                }
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
        final chapters = _bookChapters.isNotEmpty ? _bookChapters : widget.book.chapters;
        return ListView.builder(
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
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
                setState(() {
                  _currentChapterContent = null; // Reset content for new chapter
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}