import 'package:dio/dio.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<User?> getUser(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return User.fromJson(response.data);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> createUser(User user) async {
    try {
      await _dio.post('/users', data: user.toJson());
    } catch (e) {
      print('Error creating user: $e');
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
      // Return mock data for development
      return {
        'subscriptionType': 'free',
        'listenedBooksCount': 12,
        'totalListeningHours': 48,
        'streakDays': 7,
      };
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