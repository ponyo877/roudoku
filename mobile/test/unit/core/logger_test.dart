import 'package:flutter_test/flutter_test.dart';
import 'package:roudoku/core/logging/logger.dart';

void main() {
  group('Logger', () {
    setUp(() {
      Logger.setDebugMode(true);
    });

    test('should log debug messages when debug mode is enabled', () {
      expect(() => Logger.debug('Debug message'), returnsNormally);
    });

    test('should log info messages', () {
      expect(() => Logger.info('Info message'), returnsNormally);
    });

    test('should log warning messages', () {
      expect(() => Logger.warning('Warning message'), returnsNormally);
    });

    test('should log error messages', () {
      expect(() => Logger.error('Error message'), returnsNormally);
    });

    test('should log error messages with exception', () {
      final exception = Exception('Test exception');
      expect(
        () => Logger.error('Error with exception', exception),
        returnsNormally,
      );
    });

    group('Feature-specific logging', () {
      test('should log network messages', () {
        expect(() => Logger.network('Network request'), returnsNormally);
      });

      test('should log audio messages', () {
        expect(() => Logger.audio('Audio playback'), returnsNormally);
      });

      test('should log UI messages', () {
        expect(() => Logger.ui('UI update'), returnsNormally);
      });

      test('should log auth messages', () {
        expect(() => Logger.auth('User login'), returnsNormally);
      });

      test('should log book messages', () {
        expect(() => Logger.book('Book loaded'), returnsNormally);
      });
    });

    group('Debug mode control', () {
      test('should respect debug mode setting', () {
        Logger.setDebugMode(false);
        expect(() => Logger.debug('Should not appear'), returnsNormally);

        Logger.setDebugMode(true);
        expect(() => Logger.debug('Should appear'), returnsNormally);
      });
    });
  });
}
