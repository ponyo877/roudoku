import 'package:dio/dio.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Constants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    validateStatus: (status) => status != null && status < 500, // Accept client errors but not server errors
  ));

  Future<User?> getUser(String userId) async {
    // For now, always return null since user lookup is disabled
    return null;
  }

  Future<void> createUser(User user) async {
    try {
      // Create request in the format expected by server
      final requestData = {
        'firebase_uid': user.id,
        'display_name': user.displayName ?? '',
        'email': user.email,
        'voice_preset': {
          'gender': 'female',
          'pitch': 0.5,
          'speed': 1.0,
        }
      };
      
      await _dio.post('/users', data: requestData);
    } catch (e) {
      // Silently fail user creation - app can work without backend user
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _dio.put('/users/${user.id}', data: user.toJson());
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/stats');
      return response.data;
    } catch (e) {
      print('Error fetching user stats: $e');
      rethrow;
    }
  }

  Future<void> updateBookProgress(String userId, String bookId, double progress) async {
    try {
      await _dio.post('/users/$userId/progress', data: {
        'bookId': bookId,
        'progress': progress,
      });
    } catch (e) {
      print('Error updating book progress: $e');
    }
  }

  Future<void> markBookAsFinished(String userId, String bookId) async {
    try {
      await _dio.post('/users/$userId/finished-books/$bookId');
    } catch (e) {
      print('Error marking book as finished: $e');
    }
  }

  Future<void> updateSubscription(String userId, String subscriptionType) async {
    try {
      await _dio.post('/users/$userId/subscription', data: {
        'type': subscriptionType,
      });
    } catch (e) {
      print('Error updating subscription: $e');
    }
  }
}