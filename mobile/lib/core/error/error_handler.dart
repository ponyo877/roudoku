import 'package:dio/dio.dart';
import 'app_exceptions.dart';
import '../logging/logger.dart';

class ErrorHandler {
  static AppException handleError(dynamic error) {
    Logger.error('Handling error: ${error.runtimeType}', error);

    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return ValidationException(
        message: 'Invalid data format: ${error.message}',
        code: 'FORMAT_ERROR',
        originalException: error,
      );
    }

    // Generic error
    return AppException(
      message: error.toString(),
      originalException: error,
    ) as AppException;
  }

  static NetworkException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException.connectionTimeout();

      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.requestTimeout();

      case DioExceptionType.connectionError:
        return NetworkException.noInternet();

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request was cancelled.',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: 'Unknown network error: ${error.message}',
          code: 'UNKNOWN_ERROR',
          originalException: error,
        );

      default:
        return NetworkException(
          message: 'Network error occurred.',
          originalException: error,
        );
    }
  }

  static NetworkException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'Network error occurred.';
    String? code;

    switch (statusCode) {
      case 400:
        message = _extractErrorMessage(responseData) ?? 'Bad request.';
        code = 'BAD_REQUEST';
        break;

      case 401:
        return NetworkException.unauthorizedAccess();

      case 403:
        return NetworkException.forbidden();

      case 404:
        return NetworkException.notFound();

      case 422:
        message = _extractErrorMessage(responseData) ?? 'Validation failed.';
        code = 'VALIDATION_ERROR';
        break;

      case 429:
        message = 'Too many requests. Please try again later.';
        code = 'RATE_LIMIT';
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        return NetworkException.serverError();

      default:
        message = 'HTTP error $statusCode';
        code = 'HTTP_ERROR';
    }

    return NetworkException(
      message: message,
      code: code,
      originalException: error,
    );
  }

  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Try common error message fields
      return responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          responseData['msg'];
    }

    if (responseData is String) {
      return responseData;
    }

    return null;
  }

  static String getDisplayMessage(AppException exception) {
    // Return user-friendly messages based on exception type and code
    switch (exception.runtimeType) {
      case NetworkException:
        final networkException = exception as NetworkException;
        return _getNetworkDisplayMessage(networkException);

      case ValidationException:
        return exception.message;

      case AudioException:
        return exception.message;

      case TtsException:
        return exception.message;

      case StorageException:
        return exception.message;

      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static String _getNetworkDisplayMessage(NetworkException exception) {
    switch (exception.code) {
      case 'NO_INTERNET':
        return 'Please check your internet connection and try again.';

      case 'CONNECTION_TIMEOUT':
      case 'REQUEST_TIMEOUT':
        return 'Connection timed out. Please try again.';

      case 'SERVER_ERROR':
        return 'Server is temporarily unavailable. Please try again later.';

      case 'UNAUTHORIZED':
        return 'Please log in to continue.';

      case 'FORBIDDEN':
        return 'You do not have permission to perform this action.';

      case 'NOT_FOUND':
        return 'The requested content was not found.';

      case 'RATE_LIMIT':
        return 'Too many requests. Please wait a moment and try again.';

      default:
        return exception.message;
    }
  }

  static bool isRetryable(AppException exception) {
    if (exception is NetworkException) {
      switch (exception.code) {
        case 'CONNECTION_TIMEOUT':
        case 'REQUEST_TIMEOUT':
        case 'NO_INTERNET':
        case 'SERVER_ERROR':
          return true;

        case 'UNAUTHORIZED':
        case 'FORBIDDEN':
        case 'NOT_FOUND':
        case 'VALIDATION_ERROR':
          return false;

        default:
          return true;
      }
    }

    if (exception is CacheException) {
      return true;
    }

    return false;
  }
}