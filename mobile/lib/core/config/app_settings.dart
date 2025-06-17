import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger.dart';

class AppSettings {
  static AppSettings? _instance;
  static AppSettings get instance => _instance!;

  final SharedPreferences _prefs;

  AppSettings._(this._prefs);

  static Future<void> initialize() async {
    Logger.info('Initializing app settings');
    final prefs = await SharedPreferences.getInstance();
    _instance = AppSettings._(prefs);
  }

  // Audio Settings
  double get volume => _prefs.getDouble(_SettingsKeys.volume) ?? 1.0;
  set volume(double value) => _prefs.setDouble(_SettingsKeys.volume, value.clamp(0.0, 1.0));

  double get speechRate => _prefs.getDouble(_SettingsKeys.speechRate) ?? 0.5;
  set speechRate(double value) => _prefs.setDouble(_SettingsKeys.speechRate, value.clamp(0.0, 1.0));

  double get pitch => _prefs.getDouble(_SettingsKeys.pitch) ?? 1.0;
  set pitch(double value) => _prefs.setDouble(_SettingsKeys.pitch, value.clamp(0.5, 2.0));

  String get ttsLanguage => _prefs.getString(_SettingsKeys.ttsLanguage) ?? 'ja-JP';
  set ttsLanguage(String value) => _prefs.setString(_SettingsKeys.ttsLanguage, value);

  String get ttsVoice => _prefs.getString(_SettingsKeys.ttsVoice) ?? 'ja-JP-Wavenet-A';
  set ttsVoice(String value) => _prefs.setString(_SettingsKeys.ttsVoice, value);

  bool get autoPlay => _prefs.getBool(_SettingsKeys.autoPlay) ?? false;
  set autoPlay(bool value) => _prefs.setBool(_SettingsKeys.autoPlay, value);

  // Reading Settings
  double get fontSize => _prefs.getDouble(_SettingsKeys.fontSize) ?? 16.0;
  set fontSize(double value) => _prefs.setDouble(_SettingsKeys.fontSize, value.clamp(12.0, 24.0));

  String get fontFamily => _prefs.getString(_SettingsKeys.fontFamily) ?? 'Default';
  set fontFamily(String value) => _prefs.setString(_SettingsKeys.fontFamily, value);

  bool get darkMode => _prefs.getBool(_SettingsKeys.darkMode) ?? false;
  set darkMode(bool value) => _prefs.setBool(_SettingsKeys.darkMode, value);

  double get lineHeight => _prefs.getDouble(_SettingsKeys.lineHeight) ?? 1.5;
  set lineHeight(double value) => _prefs.setDouble(_SettingsKeys.lineHeight, value.clamp(1.0, 2.0));

  // App Settings
  bool get notifications => _prefs.getBool(_SettingsKeys.notifications) ?? true;
  set notifications(bool value) => _prefs.setBool(_SettingsKeys.notifications, value);

  bool get offlineMode => _prefs.getBool(_SettingsKeys.offlineMode) ?? true;
  set offlineMode(bool value) => _prefs.setBool(_SettingsKeys.offlineMode, value);

  bool get analyticsEnabled => _prefs.getBool(_SettingsKeys.analyticsEnabled) ?? true;
  set analyticsEnabled(bool value) => _prefs.setBool(_SettingsKeys.analyticsEnabled, value);

  String get preferredLanguage => _prefs.getString(_SettingsKeys.preferredLanguage) ?? 'ja';
  set preferredLanguage(String value) => _prefs.setString(_SettingsKeys.preferredLanguage, value);

  // Reading Progress
  int get dailyReadingGoal => _prefs.getInt(_SettingsKeys.dailyReadingGoal) ?? 30; // minutes
  set dailyReadingGoal(int value) => _prefs.setInt(_SettingsKeys.dailyReadingGoal, value.clamp(5, 300));

  bool get readingReminders => _prefs.getBool(_SettingsKeys.readingReminders) ?? false;
  set readingReminders(bool value) => _prefs.setBool(_SettingsKeys.readingReminders, value);

  String get reminderTime => _prefs.getString(_SettingsKeys.reminderTime) ?? '19:00';
  set reminderTime(String value) => _prefs.setString(_SettingsKeys.reminderTime, value);

  // Cache Settings
  int get maxCacheSize => _prefs.getInt(_SettingsKeys.maxCacheSize) ?? 100; // MB
  set maxCacheSize(int value) => _prefs.setInt(_SettingsKeys.maxCacheSize, value.clamp(50, 1000));

  bool get autoDownload => _prefs.getBool(_SettingsKeys.autoDownload) ?? false;
  set autoDownload(bool value) => _prefs.setBool(_SettingsKeys.autoDownload, value);

  bool get wifiOnlyDownload => _prefs.getBool(_SettingsKeys.wifiOnlyDownload) ?? true;
  set wifiOnlyDownload(bool value) => _prefs.setBool(_SettingsKeys.wifiOnlyDownload, value);

  // User Preferences
  List<String> get favoriteGenres {
    return _prefs.getStringList(_SettingsKeys.favoriteGenres) ?? [];
  }
  set favoriteGenres(List<String> value) => _prefs.setStringList(_SettingsKeys.favoriteGenres, value);

  String get lastSelectedBook => _prefs.getString(_SettingsKeys.lastSelectedBook) ?? '';
  set lastSelectedBook(String value) => _prefs.setString(_SettingsKeys.lastSelectedBook, value);

  Map<String, int> get bookmarkPositions {
    final jsonString = _prefs.getString(_SettingsKeys.bookmarkPositions) ?? '{}';
    try {
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        Uri.splitQueryString(jsonString),
      );
      return decoded.map((key, value) => MapEntry(key, int.tryParse(value) ?? 0));
    } catch (e) {
      Logger.error('Error parsing bookmark positions', e);
      return {};
    }
  }

  set bookmarkPositions(Map<String, int> value) {
    final encoded = value.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    _prefs.setString(_SettingsKeys.bookmarkPositions, encoded);
  }

  // Utility Methods
  Future<void> clearUserData() async {
    Logger.warning('Clearing user data from settings');
    final keys = [
      _SettingsKeys.favoriteGenres,
      _SettingsKeys.lastSelectedBook,
      _SettingsKeys.bookmarkPositions,
    ];
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Future<void> resetToDefaults() async {
    Logger.warning('Resetting all settings to defaults');
    await _prefs.clear();
  }

  Map<String, dynamic> exportSettings() {
    final settings = <String, dynamic>{};
    for (final key in _SettingsKeys.all) {
      final value = _prefs.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }
    Logger.info('Exported ${settings.length} settings');
    return settings;
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    Logger.info('Importing ${settings.length} settings');
    for (final entry in settings.entries) {
      final value = entry.value;
      if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value is int) {
        await _prefs.setInt(entry.key, value);
      } else if (value is double) {
        await _prefs.setDouble(entry.key, value);
      } else if (value is bool) {
        await _prefs.setBool(entry.key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(entry.key, value);
      }
    }
  }
}

class _SettingsKeys {
  // Audio
  static const String volume = 'audio_volume';
  static const String speechRate = 'audio_speech_rate';
  static const String pitch = 'audio_pitch';
  static const String ttsLanguage = 'tts_language';
  static const String ttsVoice = 'tts_voice';
  static const String autoPlay = 'auto_play';

  // Reading
  static const String fontSize = 'reading_font_size';
  static const String fontFamily = 'reading_font_family';
  static const String darkMode = 'dark_mode';
  static const String lineHeight = 'reading_line_height';

  // App
  static const String notifications = 'notifications_enabled';
  static const String offlineMode = 'offline_mode_enabled';
  static const String analyticsEnabled = 'analytics_enabled';
  static const String preferredLanguage = 'preferred_language';

  // Reading Progress
  static const String dailyReadingGoal = 'daily_reading_goal';
  static const String readingReminders = 'reading_reminders';
  static const String reminderTime = 'reminder_time';

  // Cache
  static const String maxCacheSize = 'max_cache_size';
  static const String autoDownload = 'auto_download';
  static const String wifiOnlyDownload = 'wifi_only_download';

  // User Preferences
  static const String favoriteGenres = 'favorite_genres';
  static const String lastSelectedBook = 'last_selected_book';
  static const String bookmarkPositions = 'bookmark_positions';

  static const List<String> all = [
    volume, speechRate, pitch, ttsLanguage, ttsVoice, autoPlay,
    fontSize, fontFamily, darkMode, lineHeight,
    notifications, offlineMode, analyticsEnabled, preferredLanguage,
    dailyReadingGoal, readingReminders, reminderTime,
    maxCacheSize, autoDownload, wifiOnlyDownload,
    favoriteGenres, lastSelectedBook, bookmarkPositions,
  ];
}