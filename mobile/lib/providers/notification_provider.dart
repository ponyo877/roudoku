import 'package:flutter/material.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  
  NotificationPreferences? _preferences;
  InAppNotificationSettings? _inAppSettings;
  List<InAppNotification> _inAppNotifications = [];
  
  NotificationPreferences? get preferences => _preferences;
  InAppNotificationSettings? get inAppSettings => _inAppSettings;
  List<InAppNotification> get inAppNotifications => _inAppNotifications;
  
  NotificationProvider(this._notificationService);
  
  Future<void> loadPreferences(String userId) async {
    try {
      _preferences = await _notificationService.getNotificationPreferences(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }
  
  Future<void> updatePreferences(String userId, NotificationPreferences preferences) async {
    try {
      // Convert NotificationPreferences to UpdateNotificationPreferencesRequest
      final request = UpdateNotificationPreferencesRequest(
        dailyRemindersEnabled: preferences.dailyRemindersEnabled,
        dailyReminderTime: preferences.dailyReminderTime,
        weeklyReportsEnabled: preferences.weeklyReportsEnabled,
        weeklyReportDay: preferences.weeklyReportDay,
        achievementNotificationsEnabled: preferences.achievementNotificationsEnabled,
        goalMilestoneNotificationsEnabled: preferences.goalMilestoneNotificationsEnabled,
        recommendationNotificationsEnabled: preferences.recommendationNotificationsEnabled,
        subscriptionNotificationsEnabled: preferences.subscriptionNotificationsEnabled,
        pushNotificationsEnabled: preferences.pushNotificationsEnabled,
        emailNotificationsEnabled: preferences.emailNotificationsEnabled,
        quietHoursStart: preferences.quietHoursStart,
        quietHoursEnd: preferences.quietHoursEnd,
        timezone: preferences.timezone,
        fcmToken: preferences.fcmToken,
      );
      
      _preferences = await _notificationService.updateNotificationPreferences(userId, request);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }
  
  Future<void> loadInAppSettings(String userId) async {
    try {
      _inAppSettings = await _notificationService.getInAppNotificationSettings(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading in-app notification settings: $e');
    }
  }
  
  Future<void> updateInAppSettings(String userId, InAppNotificationSettings settings) async {
    try {
      await _notificationService.updateInAppNotificationSettings(userId, settings);
      _inAppSettings = settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating in-app notification settings: $e');
    }
  }
  
  Future<void> loadInAppNotifications(String userId) async {
    try {
      _inAppNotifications = await _notificationService.getUserNotifications(userId: userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading in-app notifications: $e');
    }
  }
  
  Future<void> scheduleReadingReminder(String userId, DateTime time) async {
    try {
      await _notificationService.scheduleReadingReminder(userId, time);
    } catch (e) {
      debugPrint('Error scheduling reading reminder: $e');
    }
  }
  
  Future<void> testNotification(String userId) async {
    try {
      await _notificationService.sendTestNotification(userId);
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
  
  // Aliases for backward compatibility
  Future<void> loadNotificationPreferences(String userId) => loadPreferences(userId);
  Future<void> updateNotificationPreferences(String userId, NotificationPreferences preferences) => updatePreferences(userId, preferences);
  Future<void> sendTestNotification(String userId) => testNotification(userId);
  
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(userId, notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}