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
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      audioUrl: json['audioUrl'],
      duration: json['duration'],
      category: json['category'],
      chapters: (json['chapters'] as List)
          .map((chapter) => Chapter.fromJson(chapter))
          .toList(),
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      isPremium: json['isPremium'] ?? false,
    );
  }

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
      bookId: json['book_id'],
      text: json['text'],
      position: json['position'],
      chapterTitle: json['chapter_title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

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
}