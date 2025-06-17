import 'package:dio/dio.dart';
import '../logging/logger.dart';

class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._internal() {
    _dio = Dio();
    _setupInterceptors();
  }

  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Logger.network('🚀 Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            Logger.network('📦 Data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.network(
            '✅ Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          Logger.error(
            '❌ Error: ${error.response?.statusCode} ${error.requestOptions.uri}',
          );
          handler.next(error);
        },
      ),
    );

    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    Logger.info('📡 Base URL updated: $baseUrl');
  }

  void updateHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
    Logger.info('🔧 Headers updated');
  }
}