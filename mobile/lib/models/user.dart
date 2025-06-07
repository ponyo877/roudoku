class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String subscriptionType; // 'free' or 'premium'
  final DateTime createdAt;
  final DateTime? subscriptionExpiresAt;
  final List<String> bookmarks;
  final List<String> finishedBooks;
  final Map<String, double> bookProgress; // bookId -> progress (0.0 - 1.0)

  User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.subscriptionType = 'free',
    required this.createdAt,
    this.subscriptionExpiresAt,
    List<String>? bookmarks,
    List<String>? finishedBooks,
    Map<String, double>? bookProgress,
  })  : bookmarks = bookmarks ?? [],
        finishedBooks = finishedBooks ?? [],
        bookProgress = bookProgress ?? {};

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      subscriptionType: json['subscriptionType'] ?? 'free',
      createdAt: DateTime.parse(json['createdAt']),
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.parse(json['subscriptionExpiresAt'])
          : null,
      bookmarks: List<String>.from(json['bookmarks'] ?? []),
      finishedBooks: List<String>.from(json['finishedBooks'] ?? []),
      bookProgress: Map<String, double>.from(json['bookProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'subscriptionType': subscriptionType,
      'createdAt': createdAt.toIso8601String(),
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'bookmarks': bookmarks,
      'finishedBooks': finishedBooks,
      'bookProgress': bookProgress,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? subscriptionType,
    DateTime? createdAt,
    DateTime? subscriptionExpiresAt,
    List<String>? bookmarks,
    List<String>? finishedBooks,
    Map<String, double>? bookProgress,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      createdAt: createdAt ?? this.createdAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      bookmarks: bookmarks ?? this.bookmarks,
      finishedBooks: finishedBooks ?? this.finishedBooks,
      bookProgress: bookProgress ?? this.bookProgress,
    );
  }
}