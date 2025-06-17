class BookModel {
  final String id;
  final String title;
  final String author;
  final String? summary;
  final String? genre;
  final String? epoch;
  final int? wordCount;
  final String? contentUrl;
  final String? audioUrl;
  final int? difficultyLevel;
  final int? estimatedReadingMinutes;
  final int downloadCount;
  final double ratingAverage;
  final int ratingCount;
  final bool isPremium;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChapterModel> chapters;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.summary,
    this.genre,
    this.epoch,
    this.wordCount,
    this.contentUrl,
    this.audioUrl,
    this.difficultyLevel,
    this.estimatedReadingMinutes,
    this.downloadCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.isPremium = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.chapters = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      summary: json['summary'],
      genre: json['genre'],
      epoch: json['epoch'],
      wordCount: json['word_count'],
      contentUrl: json['content_url'],
      audioUrl: json['audio_url'],
      difficultyLevel: json['difficulty_level'],
      estimatedReadingMinutes: json['estimated_reading_minutes'],
      downloadCount: json['download_count'] ?? 0,
      ratingAverage: (json['rating_average'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      isPremium: json['is_premium'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((ch) => ChapterModel.fromJson(ch))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'summary': summary,
      'genre': genre,
      'epoch': epoch,
      'word_count': wordCount,
      'content_url': contentUrl,
      'audio_url': audioUrl,
      'difficulty_level': difficultyLevel,
      'estimated_reading_minutes': estimatedReadingMinutes,
      'download_count': downloadCount,
      'rating_average': ratingAverage,
      'rating_count': ratingCount,
      'is_premium': isPremium,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'chapters': chapters.map((ch) => ch.toJson()).toList(),
    };
  }
}

class ChapterModel {
  final String id;
  final String bookId;
  final String title;
  final String? content;
  final int position;
  final int? wordCount;
  final String? audioUrl;
  final Duration? audioDuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChapterModel({
    required this.id,
    required this.bookId,
    required this.title,
    this.content,
    required this.position,
    this.wordCount,
    this.audioUrl,
    this.audioDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] ?? '',
      bookId: json['book_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'],
      position: json['position'] ?? 0,
      wordCount: json['word_count'],
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'] != null 
          ? Duration(seconds: json['audio_duration']) 
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'title': title,
      'content': content,
      'position': position,
      'word_count': wordCount,
      'audio_url': audioUrl,
      'audio_duration': audioDuration?.inSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}