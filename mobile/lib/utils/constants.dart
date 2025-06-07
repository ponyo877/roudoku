class Constants {
  // ローカル開発用設定
  static const String baseUrl = 'http://localhost:8080';
  static const String baseUrlAndroid = 'http://10.0.2.2:8080'; // Android Emulator用
  
  static const bool isProduction = false;
  static const bool enableLogging = true;
  static const bool enableTTS = false; // 開発時はTTS無効
  
  // Firebase設定（開発用）
  static const String firebaseProjectId = 'roudoku-dev';
  
  // デバッグ用設定
  static const bool enableNetworkLogging = true;
  static const int connectionTimeout = 30; // seconds
  
  // API エンドポイント
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // アプリ設定
  static const String appName = 'Roudoku Dev';
  static const String appVersion = '1.0.0-dev';
  
  // UI設定
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 音声設定
  static const double defaultSpeed = 1.0;
  static const double defaultPitch = 0.5;
  static const String defaultGender = 'female';
  
  // キャッシュ設定
  static const int maxCachedBooks = 10;
  static const int cacheExpirationDays = 7;
}