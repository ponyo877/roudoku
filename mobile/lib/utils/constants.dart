class Constants {
  // Environment detection
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  // 本番環境と開発環境の設定
  static const String baseUrl = isProduction 
    ? 'https://YOUR_CLOUD_RUN_URL' // Will be updated after deployment
    : 'http://localhost:8080';
  static const String baseUrlAndroid = isProduction
    ? 'https://YOUR_CLOUD_RUN_URL' // Will be updated after deployment  
    : 'http://10.0.2.2:8080'; // Android Emulator用
  
  static const bool enableLogging = !isProduction;
  static const bool enableTTS = isProduction; // 本番環境ではTTS有効
  
  // Firebase設定
  static const String firebaseProjectId = isProduction ? 'gke-test-287910' : 'roudoku-dev';
  
  // デバッグ用設定
  static const bool enableNetworkLogging = !isProduction;
  static const int connectionTimeout = 30; // seconds
  
  // API エンドポイント
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // アプリ設定
  static const String appName = isProduction ? 'Aozora StoryWalk' : 'Roudoku Dev';
  static const String appVersion = isProduction ? '1.0.0' : '1.0.0-dev';
  
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

// Alias for backward compatibility
class ApiConstants {
  static String get baseUrl => Constants.baseUrl;
  static String get baseUrlAndroid => Constants.baseUrlAndroid;
  static String get apiVersion => Constants.apiVersion;
  static String get apiBaseUrl => Constants.apiBaseUrl;
}