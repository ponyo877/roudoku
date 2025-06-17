class AuthResult {
  final String userId;
  final String email;
  final String? displayName;
  final String? accessToken;
  final bool isEmailVerified;

  AuthResult({
    required this.userId,
    required this.email,
    this.displayName,
    this.accessToken,
    this.isEmailVerified = false,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      userId: json['user_id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['displayName'],
      accessToken: json['access_token'] ?? json['accessToken'],
      isEmailVerified: json['email_verified'] ?? json['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'access_token': accessToken,
      'email_verified': isEmailVerified,
    };
  }

  AuthResult copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? accessToken,
    bool? isEmailVerified,
  }) {
    return AuthResult(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      accessToken: accessToken ?? this.accessToken,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  String toString() {
    return 'AuthResult(userId: $userId, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.userId == userId &&
        other.email == email &&
        other.displayName == displayName &&
        other.accessToken == accessToken &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        email.hashCode ^
        (displayName?.hashCode ?? 0) ^
        (accessToken?.hashCode ?? 0) ^
        isEmailVerified.hashCode;
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AuthException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthStateData {
  final AuthState state;
  final AuthResult? user;
  final String? errorMessage;

  AuthStateData({
    required this.state,
    this.user,
    this.errorMessage,
  });

  AuthStateData copyWith({
    AuthState? state,
    AuthResult? user,
    String? errorMessage,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthStateData(state: $state, user: $user, errorMessage: $errorMessage)';
  }
}