import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class Logger {
  static bool _isDebugMode = true;
  static LogLevel _minLevel = LogLevel.debug;

  static void setDebugMode(bool isDebug) {
    _isDebugMode = isDebug;
    _minLevel = isDebug ? LogLevel.debug : LogLevel.info;
  }

  static void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (level.index < _minLevel.index || !_isDebugMode) return;

    final levelIcon = _getLevelIcon(level);
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $levelIcon $message';

    switch (level) {
      case LogLevel.debug:
        developer.log(logMessage, name: 'DEBUG');
        break;
      case LogLevel.info:
        developer.log(logMessage, name: 'INFO');
        break;
      case LogLevel.warning:
        developer.log(logMessage, name: 'WARNING');
        break;
      case LogLevel.error:
        developer.log(
          logMessage,
          name: 'ERROR',
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }
  }

  static String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  static void debug(String message) => _log(LogLevel.debug, message);
  static void info(String message) => _log(LogLevel.info, message);
  static void warning(String message) => _log(LogLevel.warning, message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) => 
      _log(LogLevel.error, message, error, stackTrace);

  static void network(String message) => _log(LogLevel.debug, '🌐 $message');
  static void audio(String message) => _log(LogLevel.debug, '🎵 $message');
  static void ui(String message) => _log(LogLevel.debug, '🎨 $message');
  static void auth(String message) => _log(LogLevel.info, '🔐 $message');
  static void book(String message) => _log(LogLevel.debug, '📚 $message');
}