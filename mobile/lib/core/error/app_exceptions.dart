abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    return '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory NetworkException.connectionTimeout() {
    return const NetworkException(
      message: 'Connection timeout. Please check your internet connection.',
      code: 'CONNECTION_TIMEOUT',
    );
  }

  factory NetworkException.noInternet() {
    return const NetworkException(
      message: 'No internet connection available.',
      code: 'NO_INTERNET',
    );
  }

  factory NetworkException.serverError([String? details]) {
    return NetworkException(
      message: details ?? 'Server error occurred. Please try again later.',
      code: 'SERVER_ERROR',
    );
  }

  factory NetworkException.unauthorizedAccess() {
    return const NetworkException(
      message: 'Unauthorized access. Please log in again.',
      code: 'UNAUTHORIZED',
    );
  }

  factory NetworkException.forbidden() {
    return const NetworkException(
      message: 'Access forbidden. You do not have permission to perform this action.',
      code: 'FORBIDDEN',
    );
  }

  factory NetworkException.notFound([String? resource]) {
    return NetworkException(
      message: resource != null 
          ? '$resource not found.' 
          : 'The requested resource was not found.',
      code: 'NOT_FOUND',
    );
  }

  factory NetworkException.requestTimeout() {
    return const NetworkException(
      message: 'Request timeout. Please try again.',
      code: 'REQUEST_TIMEOUT',
    );
  }
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory CacheException.readError() {
    return const CacheException(
      message: 'Failed to read from cache.',
      code: 'CACHE_READ_ERROR',
    );
  }

  factory CacheException.writeError() {
    return const CacheException(
      message: 'Failed to write to cache.',
      code: 'CACHE_WRITE_ERROR',
    );
  }

  factory CacheException.notFound() {
    return const CacheException(
      message: 'Data not found in cache.',
      code: 'CACHE_NOT_FOUND',
    );
  }
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory ValidationException.invalidInput(String field) {
    return ValidationException(
      message: 'Invalid input for $field.',
      code: 'INVALID_INPUT',
    );
  }

  factory ValidationException.requiredField(String field) {
    return ValidationException(
      message: '$field is required.',
      code: 'REQUIRED_FIELD',
    );
  }

  factory ValidationException.invalidFormat(String field) {
    return ValidationException(
      message: 'Invalid format for $field.',
      code: 'INVALID_FORMAT',
    );
  }
}

class AudioException extends AppException {
  const AudioException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory AudioException.loadFailed() {
    return const AudioException(
      message: 'Failed to load audio file.',
      code: 'AUDIO_LOAD_FAILED',
    );
  }

  factory AudioException.playbackFailed() {
    return const AudioException(
      message: 'Audio playback failed.',
      code: 'AUDIO_PLAYBACK_FAILED',
    );
  }

  factory AudioException.unsupportedFormat() {
    return const AudioException(
      message: 'Unsupported audio format.',
      code: 'UNSUPPORTED_FORMAT',
    );
  }
}

class TtsException extends AppException {
  const TtsException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory TtsException.initializationFailed() {
    return const TtsException(
      message: 'Failed to initialize text-to-speech engine.',
      code: 'TTS_INIT_FAILED',
    );
  }

  factory TtsException.synthesisFailed() {
    return const TtsException(
      message: 'Text-to-speech synthesis failed.',
      code: 'TTS_SYNTHESIS_FAILED',
    );
  }

  factory TtsException.languageNotSupported() {
    return const TtsException(
      message: 'Selected language is not supported.',
      code: 'TTS_LANGUAGE_NOT_SUPPORTED',
    );
  }
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });

  factory StorageException.insufficientSpace() {
    return const StorageException(
      message: 'Insufficient storage space.',
      code: 'INSUFFICIENT_SPACE',
    );
  }

  factory StorageException.permissionDenied() {
    return const StorageException(
      message: 'Storage permission denied.',
      code: 'PERMISSION_DENIED',
    );
  }

  factory StorageException.fileNotFound() {
    return const StorageException(
      message: 'File not found.',
      code: 'FILE_NOT_FOUND',
    );
  }
}