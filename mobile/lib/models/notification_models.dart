class NotificationPreferences {
  final String id;
  final String userId;
  final bool dailyRemindersEnabled;
  final String dailyReminderTime;
  final bool weeklyReportsEnabled;
  final int weeklyReportDay;
  final bool achievementNotificationsEnabled;
  final bool goalMilestoneNotificationsEnabled;
  final bool recommendationNotificationsEnabled;
  final bool subscriptionNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String timezone;
  final String? fcmToken;

  NotificationPreferences({
    required this.id,
    required this.userId,
    required this.dailyRemindersEnabled,
    required this.dailyReminderTime,
    required this.weeklyReportsEnabled,
    required this.weeklyReportDay,
    required this.achievementNotificationsEnabled,
    required this.goalMilestoneNotificationsEnabled,
    required this.recommendationNotificationsEnabled,
    required this.subscriptionNotificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.timezone,
    this.fcmToken,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      dailyRemindersEnabled: json['daily_reminders_enabled'] ?? true,
      dailyReminderTime: json['daily_reminder_time'] ?? '19:00:00',
      weeklyReportsEnabled: json['weekly_reports_enabled'] ?? true,
      weeklyReportDay: json['weekly_report_day'] ?? 0,
      achievementNotificationsEnabled: json['achievement_notifications_enabled'] ?? true,
      goalMilestoneNotificationsEnabled: json['goal_milestone_notifications_enabled'] ?? true,
      recommendationNotificationsEnabled: json['recommendation_notifications_enabled'] ?? true,
      subscriptionNotificationsEnabled: json['subscription_notifications_enabled'] ?? true,
      pushNotificationsEnabled: json['push_notifications_enabled'] ?? true,
      emailNotificationsEnabled: json['email_notifications_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '08:00:00',
      timezone: json['timezone'] ?? 'Asia/Tokyo',
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_reminders_enabled': dailyRemindersEnabled,
      'daily_reminder_time': dailyReminderTime,
      'weekly_reports_enabled': weeklyReportsEnabled,
      'weekly_report_day': weeklyReportDay,
      'achievement_notifications_enabled': achievementNotificationsEnabled,
      'goal_milestone_notifications_enabled': goalMilestoneNotificationsEnabled,
      'recommendation_notifications_enabled': recommendationNotificationsEnabled,
      'subscription_notifications_enabled': subscriptionNotificationsEnabled,
      'push_notifications_enabled': pushNotificationsEnabled,
      'email_notifications_enabled': emailNotificationsEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
      if (fcmToken != null) 'fcm_token': fcmToken,
    };
  }

  NotificationPreferences copyWith({
    String? id,
    String? userId,
    bool? dailyRemindersEnabled,
    String? dailyReminderTime,
    bool? weeklyReportsEnabled,
    int? weeklyReportDay,
    bool? achievementNotificationsEnabled,
    bool? goalMilestoneNotificationsEnabled,
    bool? recommendationNotificationsEnabled,
    bool? subscriptionNotificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    String? fcmToken,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyRemindersEnabled: dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      weeklyReportsEnabled: weeklyReportsEnabled ?? this.weeklyReportsEnabled,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      achievementNotificationsEnabled: achievementNotificationsEnabled ?? this.achievementNotificationsEnabled,
      goalMilestoneNotificationsEnabled: goalMilestoneNotificationsEnabled ?? this.goalMilestoneNotificationsEnabled,
      recommendationNotificationsEnabled: recommendationNotificationsEnabled ?? this.recommendationNotificationsEnabled,
      subscriptionNotificationsEnabled: subscriptionNotificationsEnabled ?? this.subscriptionNotificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  String get dailyReminderTimeFormatted {
    try {
      final parts = dailyReminderTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '19:00';
    }
  }

  String get quietHoursFormatted {
    return '$quietHoursStartFormatted - $quietHoursEndFormatted';
  }

  String get quietHoursStartFormatted {
    try {
      final parts = quietHoursStart.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '22:00';
    }
  }

  String get quietHoursEndFormatted {
    try {
      final parts = quietHoursEnd.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '08:00';
    }
  }

  String get weeklyReportDayName {
    const days = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
    return weeklyReportDay >= 0 && weeklyReportDay < days.length 
        ? days[weeklyReportDay] 
        : '日曜日';
  }
}

class UpdateNotificationPreferencesRequest {
  final bool? dailyRemindersEnabled;
  final String? dailyReminderTime;
  final bool? weeklyReportsEnabled;
  final int? weeklyReportDay;
  final bool? achievementNotificationsEnabled;
  final bool? goalMilestoneNotificationsEnabled;
  final bool? recommendationNotificationsEnabled;
  final bool? subscriptionNotificationsEnabled;
  final bool? pushNotificationsEnabled;
  final bool? emailNotificationsEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? timezone;
  final String? fcmToken;

  UpdateNotificationPreferencesRequest({
    this.dailyRemindersEnabled,
    this.dailyReminderTime,
    this.weeklyReportsEnabled,
    this.weeklyReportDay,
    this.achievementNotificationsEnabled,
    this.goalMilestoneNotificationsEnabled,
    this.recommendationNotificationsEnabled,
    this.subscriptionNotificationsEnabled,
    this.pushNotificationsEnabled,
    this.emailNotificationsEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (dailyRemindersEnabled != null) json['daily_reminders_enabled'] = dailyRemindersEnabled;
    if (dailyReminderTime != null) json['daily_reminder_time'] = dailyReminderTime;
    if (weeklyReportsEnabled != null) json['weekly_reports_enabled'] = weeklyReportsEnabled;
    if (weeklyReportDay != null) json['weekly_report_day'] = weeklyReportDay;
    if (achievementNotificationsEnabled != null) json['achievement_notifications_enabled'] = achievementNotificationsEnabled;
    if (goalMilestoneNotificationsEnabled != null) json['goal_milestone_notifications_enabled'] = goalMilestoneNotificationsEnabled;
    if (recommendationNotificationsEnabled != null) json['recommendation_notifications_enabled'] = recommendationNotificationsEnabled;
    if (subscriptionNotificationsEnabled != null) json['subscription_notifications_enabled'] = subscriptionNotificationsEnabled;
    if (pushNotificationsEnabled != null) json['push_notifications_enabled'] = pushNotificationsEnabled;
    if (emailNotificationsEnabled != null) json['email_notifications_enabled'] = emailNotificationsEnabled;
    if (quietHoursStart != null) json['quiet_hours_start'] = quietHoursStart;
    if (quietHoursEnd != null) json['quiet_hours_end'] = quietHoursEnd;
    if (timezone != null) json['timezone'] = timezone;
    if (fcmToken != null) json['fcm_token'] = fcmToken;
    return json;
  }
}

class InAppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? actionUrl;
  final String? iconUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  InAppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.actionUrl,
    this.iconUrl,
    required this.isRead,
    this.readAt,
    this.expiresAt,
    this.metadata,
    required this.createdAt,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      actionUrl: json['action_url'],
      iconUrl: json['icon_url'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      if (actionUrl != null) 'action_url': actionUrl,
      if (iconUrl != null) 'icon_url': iconUrl,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InAppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? actionUrl,
    String? iconUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class NotificationSummary {
  final String userId;
  final int unreadCount;
  final List<InAppNotification> recentNotifications;
  final DateTime? nextScheduledReminder;
  final NotificationPreferences preferences;

  NotificationSummary({
    required this.userId,
    required this.unreadCount,
    required this.recentNotifications,
    this.nextScheduledReminder,
    required this.preferences,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      userId: json['user_id'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      recentNotifications: (json['recent_notifications'] as List? ?? [])
          .map((item) => InAppNotification.fromJson(item))
          .toList(),
      nextScheduledReminder: json['next_scheduled_reminder'] != null
          ? DateTime.parse(json['next_scheduled_reminder'])
          : null,
      preferences: NotificationPreferences.fromJson(json['preferences'] ?? {}),
    );
  }
}

class InAppNotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? soundFile;
  final int displayDuration;
  final String position;

  InAppNotificationSettings({
    required this.enabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    this.soundFile,
    required this.displayDuration,
    required this.position,
  });

  factory InAppNotificationSettings.fromJson(Map<String, dynamic> json) {
    return InAppNotificationSettings(
      enabled: json['enabled'] ?? true,
      soundEnabled: json['sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
      soundFile: json['sound_file'],
      displayDuration: json['display_duration'] ?? 5000,
      position: json['position'] ?? 'top',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      if (soundFile != null) 'sound_file': soundFile,
      'display_duration': displayDuration,
      'position': position,
    };
  }

  InAppNotificationSettings copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? soundFile,
    int? displayDuration,
    String? position,
  }) {
    return InAppNotificationSettings(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundFile: soundFile ?? this.soundFile,
      displayDuration: displayDuration ?? this.displayDuration,
      position: position ?? this.position,
    );
  }
}

class PushNotificationPayload {
  final String title;
  final String body;
  final String? actionUrl;
  final String? iconUrl;
  final String? imageUrl;
  final String type;
  final Map<String, String>? data;

  PushNotificationPayload({
    required this.title,
    required this.body,
    this.actionUrl,
    this.iconUrl,
    this.imageUrl,
    required this.type,
    this.data,
  });

  factory PushNotificationPayload.fromJson(Map<String, dynamic> json) {
    return PushNotificationPayload(
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      actionUrl: json['action_url'],
      iconUrl: json['icon_url'],
      imageUrl: json['image_url'],
      type: json['type'] ?? '',
      data: json['data'] != null ? Map<String, String>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      if (actionUrl != null) 'action_url': actionUrl,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      'type': type,
      if (data != null) 'data': data,
    };
  }
}