class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final String audioUrl;
  final int duration; // in minutes
  final String category;
  final List<Chapter> chapters;
  final double rating;
  final int reviewCount;
  final bool isPremium;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    required this.category,
    required this.chapters,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isPremium = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['summary'] ?? json['description'] ?? '',
      coverUrl: json['cover_url'] ?? json['coverUrl'] ?? '',
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? '',
      duration: json['estimated_reading_minutes'] ?? json['duration'] ?? 0,
      category: json['genre'] ?? json['category'] ?? '',
      chapters: json['chapters'] != null
          ? (json['chapters'] as List)
                .map((chapter) => Chapter.fromJson(chapter))
                .toList()
          : [],
      rating: (json['rating_average'] ?? json['rating'] ?? 0).toDouble(),
      reviewCount: json['rating_count'] ?? json['reviewCount'] ?? 0,
      isPremium: json['is_premium'] ?? json['isPremium'] ?? false,
    );
  }

  factory Book.fromMap(Map<String, dynamic> map) => Book.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'category': category,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'isPremium': isPremium,
    };
  }
}

class Chapter {
  final String id;
  final String title;
  final int duration; // in minutes
  final int startTime; // in seconds
  final int endTime; // in seconds

  Chapter({
    required this.id,
    required this.title,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      title: json['title'],
      duration: json['duration'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class Quote {
  final String id;
  final String bookId;
  final String text;
  final int position;
  final String? chapterTitle;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.bookId,
    required this.text,
    required this.position,
    this.chapterTitle,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'],
      bookId: json['book_id'].toString(),
      text: json['text'],
      position: json['position'],
      chapterTitle: json['chapter_title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory Quote.fromMap(Map<String, dynamic> map) => Quote.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'text': text,
      'position': position,
      'chapter_title': chapterTitle,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
