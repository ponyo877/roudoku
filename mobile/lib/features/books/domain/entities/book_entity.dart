import 'chapter_entity.dart';

class BookEntity {
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
  final List<ChapterEntity> chapters;

  BookEntity({
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

  BookEntity copyWith({
    String? id,
    String? title,
    String? author,
    String? summary,
    String? genre,
    String? epoch,
    int? wordCount,
    String? contentUrl,
    String? audioUrl,
    int? difficultyLevel,
    int? estimatedReadingMinutes,
    int? downloadCount,
    double? ratingAverage,
    int? ratingCount,
    bool? isPremium,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChapterEntity>? chapters,
  }) {
    return BookEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      summary: summary ?? this.summary,
      genre: genre ?? this.genre,
      epoch: epoch ?? this.epoch,
      wordCount: wordCount ?? this.wordCount,
      contentUrl: contentUrl ?? this.contentUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedReadingMinutes: estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      downloadCount: downloadCount ?? this.downloadCount,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chapters: chapters ?? this.chapters,
    );
  }

  @override
  String toString() {
    return 'BookEntity(id: $id, title: $title, author: $author, genre: $genre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookEntity &&
        other.id == id &&
        other.title == title &&
        other.author == author;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ author.hashCode;
  }
}