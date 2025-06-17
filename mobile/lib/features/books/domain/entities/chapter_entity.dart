class ChapterEntity {
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

  ChapterEntity({
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

  ChapterEntity copyWith({
    String? id,
    String? bookId,
    String? title,
    String? content,
    int? position,
    int? wordCount,
    String? audioUrl,
    Duration? audioDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChapterEntity(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      position: position ?? this.position,
      wordCount: wordCount ?? this.wordCount,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChapterEntity(id: $id, title: $title, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterEntity &&
        other.id == id &&
        other.bookId == bookId &&
        other.title == title &&
        other.position == position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bookId.hashCode ^
        title.hashCode ^
        position.hashCode;
  }
}