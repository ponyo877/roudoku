import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_models.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Provider.of<NotificationProvider>(context, listen: false)
          .loadNotificationPreferences();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.preferences == null) {
                  return const Center(
                    child: Text('通知設定を読み込めませんでした'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverallSection(provider.preferences!),
                        const SizedBox(height: 24),
                        _buildReminderSection(provider.preferences!),
                        const SizedBox(height: 24),
                        _buildReportSection(provider.preferences!),
                        const SizedBox(height: 24),
                        _buildNotificationTypesSection(provider.preferences!),
                        const SizedBox(height: 24),
                        _buildQuietHoursSection(provider.preferences!),
                        const SizedBox(height: 24),
                        _buildAdvancedSection(provider.preferences!),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverallSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '通知設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('プッシュ通知'),
              subtitle: const Text('アプリからの通知を受け取る'),
              value: prefs.pushNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                pushNotificationsEnabled: value,
              ),
            ),
            SwitchListTile(
              title: const Text('メール通知'),
              subtitle: const Text('重要な情報をメールで受け取る'),
              value: prefs.emailNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                emailNotificationsEnabled: value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '読書リマインダー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('毎日のリマインダー'),
              subtitle: const Text('読書の時間をお知らせします'),
              value: prefs.dailyRemindersEnabled,
              onChanged: (value) => _updatePreferences(
                dailyRemindersEnabled: value,
              ),
            ),
            if (prefs.dailyRemindersEnabled) ...[
              ListTile(
                title: const Text('リマインダーの時間'),
                subtitle: Text(prefs.dailyReminderTimeFormatted),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTimePickerDialog(
                  title: 'リマインダーの時間',
                  currentTime: prefs.dailyReminderTimeFormatted,
                  onTimeSelected: (time) => _updatePreferences(
                    dailyReminderTime: '$time:00',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '読書レポート',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('週間レポート'),
              subtitle: const Text('読書活動のまとめをお送りします'),
              value: prefs.weeklyReportsEnabled,
              onChanged: (value) => _updatePreferences(
                weeklyReportsEnabled: value,
              ),
            ),
            if (prefs.weeklyReportsEnabled) ...[
              ListTile(
                title: const Text('レポート送信日'),
                subtitle: Text(prefs.weeklyReportDayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWeekdayPickerDialog(
                  currentDay: prefs.weeklyReportDay,
                  onDaySelected: (day) => _updatePreferences(
                    weeklyReportDay: day,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '通知の種類',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('実績獲得通知'),
              subtitle: const Text('新しい実績を獲得した時'),
              value: prefs.achievementNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                achievementNotificationsEnabled: value,
              ),
            ),
            SwitchListTile(
              title: const Text('目標達成通知'),
              subtitle: const Text('読書目標を達成した時'),
              value: prefs.goalMilestoneNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                goalMilestoneNotificationsEnabled: value,
              ),
            ),
            SwitchListTile(
              title: const Text('おすすめ本通知'),
              subtitle: const Text('新しいおすすめの本が見つかった時'),
              value: prefs.recommendationNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                recommendationNotificationsEnabled: value,
              ),
            ),
            SwitchListTile(
              title: const Text('サブスクリプション通知'),
              subtitle: const Text('課金やプラン変更に関する通知'),
              value: prefs.subscriptionNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                subscriptionNotificationsEnabled: value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'サイレント時間',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('開始時間'),
              subtitle: Text(prefs.quietHoursStartFormatted),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTimePickerDialog(
                title: 'サイレント開始時間',
                currentTime: prefs.quietHoursStartFormatted,
                onTimeSelected: (time) => _updatePreferences(
                  quietHoursStart: '$time:00',
                ),
              ),
            ),
            ListTile(
              title: const Text('終了時間'),
              subtitle: Text(prefs.quietHoursEndFormatted),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTimePickerDialog(
                title: 'サイレント終了時間',
                currentTime: prefs.quietHoursEndFormatted,
                onTimeSelected: (time) => _updatePreferences(
                  quietHoursEnd: '$time:00',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'サイレント時間中は通知が送信されません',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(NotificationPreferences prefs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'その他',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('通知をテスト'),
              subtitle: const Text('テスト通知を送信します'),
              trailing: const Icon(Icons.send),
              onTap: _sendTestNotification,
            ),
            ListTile(
              title: const Text('すべての通知を無効にする'),
              subtitle: const Text('すべての通知を一括で無効にします'),
              trailing: const Icon(Icons.notifications_off),
              onTap: _showDisableAllDialog,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'タイムゾーン: ${prefs.timezone}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePreferences({
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
  }) async {
    final request = UpdateNotificationPreferencesRequest(
      dailyRemindersEnabled: dailyRemindersEnabled,
      dailyReminderTime: dailyReminderTime,
      weeklyReportsEnabled: weeklyReportsEnabled,
      weeklyReportDay: weeklyReportDay,
      achievementNotificationsEnabled: achievementNotificationsEnabled,
      goalMilestoneNotificationsEnabled: goalMilestoneNotificationsEnabled,
      recommendationNotificationsEnabled: recommendationNotificationsEnabled,
      subscriptionNotificationsEnabled: subscriptionNotificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
    );

    try {
      await Provider.of<NotificationProvider>(context, listen: false)
          .updateNotificationPreferences(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定の更新に失敗しました')),
        );
      }
    }
  }

  Future<void> _showTimePickerDialog({
    required String title,
    required String currentTime,
    required Function(String) onTimeSelected,
  }) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
    }
  }

  Future<void> _showWeekdayPickerDialog({
    required int currentDay,
    required Function(int) onDaySelected,
  }) async {
    const weekdays = [
      '日曜日',
      '月曜日',
      '火曜日',
      '水曜日',
      '木曜日',
      '金曜日',
      '土曜日',
    ];

    final int? selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レポート送信日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: weekdays.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return RadioListTile<int>(
              title: Text(name),
              value: index,
              groupValue: currentDay,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (selected != null) {
      onDaySelected(selected);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await Provider.of<NotificationProvider>(context, listen: false)
          .sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テスト通知を送信しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テスト通知の送信に失敗しました')),
        );
      }
    }
  }

  Future<void> _showDisableAllDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべての通知を無効にする'),
        content: const Text('すべての通知を無効にしますか？この操作は後から元に戻すことができます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('無効にする'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updatePreferences(
        dailyRemindersEnabled: false,
        weeklyReportsEnabled: false,
        achievementNotificationsEnabled: false,
        goalMilestoneNotificationsEnabled: false,
        recommendationNotificationsEnabled: false,
        subscriptionNotificationsEnabled: false,
        pushNotificationsEnabled: false,
        emailNotificationsEnabled: false,
      );
    }
  }
}

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Provider.of<NotificationProvider>(context, listen: false)
          .loadInAppNotifications();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/notification-settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.inAppNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '通知はありません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '新しい通知があるとここに表示されます',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.inAppNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = provider.inAppNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(InAppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? null : Colors.blue[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (notification.actionUrl != null)
                    Text(
                      'タップして詳細を見る',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'achievement':
        icon = Icons.emoji_events;
        color = Colors.orange;
        break;
      case 'goal_milestone':
        icon = Icons.flag;
        color = Colors.green;
        break;
      case 'recommendation':
        icon = Icons.book;
        color = Colors.blue;
        break;
      case 'daily_reminder':
        icon = Icons.schedule;
        color = Colors.purple;
        break;
      case 'weekly_report':
        icon = Icons.analytics;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _onNotificationTap(InAppNotification notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      try {
        await Provider.of<NotificationProvider>(context, listen: false)
            .markNotificationAsRead(notification.id);
      } catch (e) {
        // Handle error silently
      }
    }

    // Handle action URL if present
    if (notification.actionUrl != null) {
      // Navigate to the appropriate screen based on action URL
      _handleNotificationAction(notification.actionUrl!);
    }
  }

  void _handleNotificationAction(String actionUrl) {
    // Parse action URL and navigate accordingly
    if (actionUrl.startsWith('/')) {
      Navigator.pushNamed(context, actionUrl);
    } else if (actionUrl.contains('book/')) {
      final bookId = actionUrl.split('/').last;
      Navigator.pushNamed(context, '/book-detail', arguments: bookId);
    } else if (actionUrl.contains('achievements')) {
      Navigator.pushNamed(context, '/achievements');
    } else if (actionUrl.contains('goals')) {
      Navigator.pushNamed(context, '/reading-stats');
    }
  }
}