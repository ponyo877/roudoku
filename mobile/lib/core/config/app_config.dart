import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance!;

  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final String appVersion;
  final bool enableLogging;
  final bool enableCrashReporting;
  final bool enableAnalytics;
  final Map<String, dynamic> features;

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.appVersion,
    required this.enableLogging,
    required this.enableCrashReporting,
    required this.enableAnalytics,
    required this.features,
  });

  static void initialize({
    Environment? environment,
    String? apiBaseUrl,
    String? appName,
    String? appVersion,
    bool? enableLogging,
    bool? enableCrashReporting,
    bool? enableAnalytics,
    Map<String, dynamic>? features,
  }) {
    final env = environment ?? _getEnvironmentFromFlavor();
    
    _instance = AppConfig._(
      environment: env,
      apiBaseUrl: apiBaseUrl ?? _getApiBaseUrl(env),
      appName: appName ?? 'Roudoku',
      appVersion: appVersion ?? '1.0.0',
      enableLogging: enableLogging ?? (env != Environment.production),
      enableCrashReporting: enableCrashReporting ?? (env == Environment.production),
      enableAnalytics: enableAnalytics ?? (env == Environment.production),
      features: features ?? _getDefaultFeatures(env),
    );
  }

  static Environment _getEnvironmentFromFlavor() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    switch (flavor.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static String _getApiBaseUrl(Environment env) {
    switch (env) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.roudoku.com';
      case Environment.production:
        return 'https://api.roudoku.com';
    }
  }

  static Map<String, dynamic> _getDefaultFeatures(Environment env) {
    return {
      'offline_mode': true,
      'cloud_tts': env != Environment.development,
      'advanced_audio': true,
      'social_features': env == Environment.production,
      'beta_features': env == Environment.development,
      'debug_menu': env != Environment.production,
    };
  }

  bool isFeatureEnabled(String featureName) {
    return features[featureName] == true;
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
  bool get isDebugMode => kDebugMode || isDevelopment;

  @override
  String toString() {
    return 'AppConfig(environment: $environment, apiBaseUrl: $apiBaseUrl, appName: $appName, appVersion: $appVersion)';
  }
}

class FeatureFlags {
  static bool get offlineMode => AppConfig.instance.isFeatureEnabled('offline_mode');
  static bool get cloudTts => AppConfig.instance.isFeatureEnabled('cloud_tts');
  static bool get advancedAudio => AppConfig.instance.isFeatureEnabled('advanced_audio');
  static bool get socialFeatures => AppConfig.instance.isFeatureEnabled('social_features');
  static bool get betaFeatures => AppConfig.instance.isFeatureEnabled('beta_features');
  static bool get debugMenu => AppConfig.instance.isFeatureEnabled('debug_menu');
}