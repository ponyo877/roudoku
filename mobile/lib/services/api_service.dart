import 'package:dio/dio.dart';

abstract class ApiService {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data});
  Future<void> delete(String path);
}

class HttpApiService implements ApiService {
  final Dio _dio;
  final String _baseUrl;

  HttpApiService({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  @override
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get('$_baseUrl$path');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post('$_baseUrl$path', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put('$_baseUrl$path', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _dio.delete('$_baseUrl$path');
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }
}