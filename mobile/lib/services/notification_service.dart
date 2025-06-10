import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_models.dart';

class NotificationService {
  final Dio _dio;
  final String _baseUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationService({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  // Get user notification preferences
  Future<NotificationPreferences> getNotificationPreferences(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$userId/notifications/preferences');
      
      if (response.statusCode == 200) {
        return NotificationPreferences.fromJson(response.data);
      } else {
        throw Exception('Failed to get notification preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  // Update user notification preferences
  Future<NotificationPreferences> updateNotificationPreferences(
    String userId, 
    UpdateNotificationPreferencesRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$userId/notifications/preferences',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200) {
        return NotificationPreferences.fromJson(response.data);
      } else {
        throw Exception('Failed to update notification preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // Get user notifications
  Future<List<InAppNotification>> getUserNotifications({
    required String userId,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/$userId/notifications',
        queryParameters: {
          'limit': limit,
          if (unreadOnly) 'unread_only': true,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> notificationsData = response.data['notifications'] ?? [];
        return notificationsData
            .map((notification) => InAppNotification.fromJson(notification))
            .toList();
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$userId/notifications/$notificationId/read',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$userId/notifications/read-all',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Get notification summary
  Future<NotificationSummary> getNotificationSummary(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$userId/notifications/summary');
      
      if (response.statusCode == 200) {
        return NotificationSummary.fromJson(response.data);
      } else {
        throw Exception('Failed to get notification summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get notification summary: $e');
    }
  }

  // Send push notification to user
  Future<void> sendPushNotification({
    required String userId,
    required PushNotificationPayload payload,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/notifications/send',
        data: {
          'user_id': userId,
          'payload': payload.toJson(),
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send push notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send push notification: $e');
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$userId/fcm-token',
        data: {'fcm_token': fcmToken},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update FCM token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required String userId,
    required PushNotificationPayload payload,
    required DateTime scheduledTime,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/notifications/schedule',
        data: {
          'user_id': userId,
          'payload': payload.toJson(),
          'scheduled_time': scheduledTime.toIso8601String(),
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to schedule notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to schedule notification: $e');
    }
  }

  // Real-time notifications stream from Firestore
  Stream<List<InAppNotification>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InAppNotification.fromJson(doc.data()))
            .toList());
  }

  // Listen to notification preferences changes
  Stream<NotificationPreferences?> getNotificationPreferencesStream(String userId) {
    return _firestore
        .collection('notification_preferences')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return NotificationPreferences.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // Local notification helpers
  Future<void> saveNotificationLocally(InAppNotification notification) async {
    try {
      await _firestore
          .collection('local_notifications')
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      print('Error saving notification locally: $e');
    }
  }

  // Clear expired notifications
  Future<void> clearExpiredNotifications(String userId) async {
    try {
      final now = DateTime.now();
      final expiredQuery = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('expires_at', isLessThan: now.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing expired notifications: $e');
    }
  }

  // Get in-app notification settings
  Future<InAppNotificationSettings> getInAppNotificationSettings(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$userId/notifications/in-app-settings');
      
      if (response.statusCode == 200) {
        return InAppNotificationSettings.fromJson(response.data);
      } else {
        // Return default settings if not found
        return InAppNotificationSettings(
          enabled: true,
          soundEnabled: true,
          vibrationEnabled: true,
          displayDuration: 5000,
          position: 'top',
        );
      }
    } catch (e) {
      // Return default settings on error
      return InAppNotificationSettings(
        enabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        displayDuration: 5000,
        position: 'top',
      );
    }
  }

  // Update in-app notification settings
  Future<InAppNotificationSettings> updateInAppNotificationSettings(
    String userId, 
    InAppNotificationSettings settings,
  ) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$userId/notifications/in-app-settings',
        data: settings.toJson(),
      );
      
      if (response.statusCode == 200) {
        return InAppNotificationSettings.fromJson(response.data);
      } else {
        throw Exception('Failed to update in-app notification settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update in-app notification settings: $e');
    }
  }

  // Schedule reading reminder
  Future<void> scheduleReadingReminder(String userId, DateTime time) async {
    final reminderPayload = PushNotificationPayload(
      title: '読書の時間です',
      body: '今日の読書を始めませんか？',
      type: 'reading_reminder',
      data: {'reminder_time': time.toIso8601String()},
    );

    await scheduleNotification(
      userId: userId,
      payload: reminderPayload,
      scheduledTime: time,
    );
  }

  // Test notification functionality
  Future<void> sendTestNotification(String userId) async {
    final testPayload = PushNotificationPayload(
      title: 'テスト通知',
      body: 'これはテスト通知です。通知が正常に動作しています。',
      type: 'test',
      data: {'test': 'true'},
    );

    await sendPushNotification(
      userId: userId,
      payload: testPayload,
    );
  }
}