import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/reading_analytics.dart';
import '../providers/reading_analytics_provider.dart';
import '../widgets/reading_stats_card.dart';
import '../widgets/chart_widgets.dart';

class ReadingStatsScreen extends StatefulWidget {
  const ReadingStatsScreen({Key? key}) : super(key: key);

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Provider.of<ReadingAnalyticsProvider>(context, listen: false)
          .loadReadingStatistics();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('読書統計'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '概要'),
            Tab(text: '目標'),
            Tab(text: '実績'),
            Tab(text: '詳細'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ReadingAnalyticsProvider>(
              builder: (context, provider, child) {
                if (provider.statistics == null) {
                  return const Center(
                    child: Text('統計データを読み込めませんでした'),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(provider.statistics!),
                    _buildGoalsTab(provider.statistics!),
                    _buildAchievementsTab(provider.statistics!),
                    _buildDetailsTab(provider.statistics!),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalCreateDialog(),
        child: const Icon(Icons.add),
        tooltip: '新しい目標を設定',
      ),
    );
  }

  Widget _buildOverviewTab(ReadingStatistics stats) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今月の読書サマリー
            _buildMonthlySummaryCard(stats.monthlyProgress),
            const SizedBox(height: 16),

            // 主要指標
            Row(
              children: [
                Expanded(
                  child: ReadingStatsCard(
                    title: '総読書時間',
                    value: stats.formattedReadingTime,
                    icon: Icons.access_time,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadingStatsCard(
                    title: '読了冊数',
                    value: '${stats.totalBooksRead}冊',
                    icon: Icons.book,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ReadingStatsCard(
                    title: '現在の連続日数',
                    value: '${stats.currentStreak?.streakDays ?? 0}日',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadingStatsCard(
                    title: '読書速度',
                    value: '${stats.averageReadingSpeedWpm.toInt()}語/分',
                    icon: Icons.speed,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 週間読書時間グラフ
            _buildWeeklyChart(stats.weeklyReadingTime),
            const SizedBox(height: 24),

            // ジャンル分布
            if (stats.favoriteGenres.isNotEmpty) ...[
              const Text(
                'よく読むジャンル',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildGenreChart(stats.favoriteGenres),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(MonthlyReadingSummary summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${summary.year}年${summary.monthName}の読書',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('読了', '${summary.totalBooksRead}冊'),
                _buildSummaryItem('読書時間', '${summary.totalReadingTimeMinutes ~/ 60}h'),
                _buildSummaryItem('連続日数', '${summary.readingStreakDays}日'),
                _buildSummaryItem('実績獲得', '${summary.newAchievementsCount}個'),
              ],
            ),
            if (summary.favoriteGenre != null) ...[
              const SizedBox(height: 12),
              Text(
                '今月のお気に入りジャンル: ${summary.favoriteGenre}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<DailyReadingStats> weeklyStats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '週間読書時間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: WeeklyReadingChart(weeklyStats: weeklyStats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChart(List<GenreStats> genreStats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: GenreDistributionChart(genreStats: genreStats),
        ),
      ),
    );
  }

  Widget _buildGoalsTab(ReadingStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '読書目標',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showGoalCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('目標追加'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (stats.activeGoals.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  Icon(
                    Icons.flag,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '読書目標を設定しましょう',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '目標を設定することで読書習慣を\n身につけやすくなります',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...stats.activeGoals.map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ReadingGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.goalTypeDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleGoalAction(value, goal),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('編集'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('削除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.progressText,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.progressPercentage >= 100 ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progressPercentage.toInt()}% 達成',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(ReadingStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近の実績',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (stats.recentAchievements.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'まだ実績がありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '読書を続けて実績を獲得しましょう',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...stats.recentAchievements.map((achievement) => 
              _buildAchievementCard(achievement)),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAllAchievements(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('すべての実績を見る'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.emoji_events, color: Colors.white),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(achievement.description),
        trailing: achievement.earnedAt != null
            ? Text(
                '${achievement.earnedAt!.month}/${achievement.earnedAt!.day}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDetailsTab(ReadingStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '詳細統計',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 読書ストリーク詳細
          _buildStreakDetails(stats),
          const SizedBox(height: 16),

          // ジャンル別詳細
          _buildGenreDetails(stats.favoriteGenres),
          const SizedBox(height: 16),

          // 読書速度詳細
          _buildSpeedDetails(stats),
        ],
      ),
    );
  }

  Widget _buildStreakDetails(ReadingStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '読書ストリーク',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem(
                  '現在',
                  '${stats.currentStreak?.streakDays ?? 0}日',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStreakItem(
                  '最長記録',
                  '${stats.longestStreak?.streakDays ?? 0}日',
                  Icons.emoji_events,
                  Colors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGenreDetails(List<GenreStats> genres) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ジャンル別読書記録',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (genres.isEmpty)
              const Text('まだデータがありません')
            else
              ...genres.take(5).map((genre) => _buildGenreItem(genre)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreItem(GenreStats genre) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(genre.genre),
          Text(
            '${genre.booksReadCount}冊 (${genre.totalReadingTimeMinutes ~/ 60}h)',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDetails(ReadingStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '読書速度',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSpeedItem(
                  '平均速度',
                  '${stats.averageReadingSpeedWpm.toInt()}語/分',
                ),
                _buildSpeedItem(
                  '平均セッション',
                  '${stats.averageSessionLength.toInt()}分',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showGoalCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const GoalCreateDialog(),
    );
  }

  void _handleGoalAction(String action, ReadingGoal goal) {
    switch (action) {
      case 'edit':
        _showGoalEditDialog(goal);
        break;
      case 'delete':
        _showGoalDeleteDialog(goal);
        break;
    }
  }

  void _showGoalEditDialog(ReadingGoal goal) {
    showDialog(
      context: context,
      builder: (context) => GoalEditDialog(goal: goal),
    );
  }

  void _showGoalDeleteDialog(ReadingGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標を削除'),
        content: Text('「${goal.goalTypeDisplayName}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGoal(goal);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(ReadingGoal goal) async {
    try {
      await Provider.of<ReadingAnalyticsProvider>(context, listen: false)
          .deleteReadingGoal(goal.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標の削除に失敗しました')),
        );
      }
    }
  }

  void _showAllAchievements() {
    Navigator.pushNamed(context, '/achievements');
  }
}

class GoalCreateDialog extends StatefulWidget {
  const GoalCreateDialog({Key? key}) : super(key: key);

  @override
  State<GoalCreateDialog> createState() => _GoalCreateDialogState();
}

class _GoalCreateDialogState extends State<GoalCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  String _goalType = 'daily_minutes';
  int _targetValue = 30;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しい目標を設定'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _goalType,
              decoration: const InputDecoration(labelText: '目標の種類'),
              items: const [
                DropdownMenuItem(value: 'daily_minutes', child: Text('1日の読書時間')),
                DropdownMenuItem(value: 'weekly_books', child: Text('週間読書冊数')),
                DropdownMenuItem(value: 'monthly_chapters', child: Text('月間読書章数')),
                DropdownMenuItem(value: 'yearly_books', child: Text('年間読書冊数')),
              ],
              onChanged: (value) {
                setState(() {
                  _goalType = value!;
                  _targetValue = _getDefaultTargetValue(value);
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _targetValue.toString(),
              decoration: InputDecoration(
                labelText: '目標値',
                suffix: Text(_getUnit(_goalType)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '目標値を入力してください';
                }
                final intValue = int.tryParse(value);
                if (intValue == null || intValue <= 0) {
                  return '正の数値を入力してください';
                }
                return null;
              },
              onChanged: (value) {
                _targetValue = int.tryParse(value) ?? _targetValue;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _createGoal,
          child: const Text('作成'),
        ),
      ],
    );
  }

  int _getDefaultTargetValue(String goalType) {
    switch (goalType) {
      case 'daily_minutes':
        return 30;
      case 'weekly_books':
        return 1;
      case 'monthly_chapters':
        return 10;
      case 'yearly_books':
        return 12;
      default:
        return 1;
    }
  }

  String _getUnit(String goalType) {
    switch (goalType) {
      case 'daily_minutes':
        return '分';
      case 'weekly_books':
      case 'yearly_books':
        return '冊';
      case 'monthly_chapters':
        return '章';
      default:
        return '';
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = CreateReadingGoalRequest(
        goalType: _goalType,
        targetValue: _targetValue,
        startDate: DateTime.now(),
        endDate: _endDate,
      );

      await Provider.of<ReadingAnalyticsProvider>(context, listen: false)
          .createReadingGoal(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標を作成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標の作成に失敗しました')),
        );
      }
    }
  }
}

class GoalEditDialog extends StatefulWidget {
  final ReadingGoal goal;

  const GoalEditDialog({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<GoalEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _targetValue;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _targetValue = widget.goal.targetValue;
    _isActive = widget.goal.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('目標を編集'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _targetValue.toString(),
              decoration: InputDecoration(
                labelText: '目標値',
                suffix: Text(_getUnit(widget.goal.goalType)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '目標値を入力してください';
                }
                final intValue = int.tryParse(value);
                if (intValue == null || intValue <= 0) {
                  return '正の数値を入力してください';
                }
                return null;
              },
              onChanged: (value) {
                _targetValue = int.tryParse(value) ?? _targetValue;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('目標を有効にする'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _updateGoal,
          child: const Text('更新'),
        ),
      ],
    );
  }

  String _getUnit(String goalType) {
    switch (goalType) {
      case 'daily_minutes':
        return '分';
      case 'weekly_books':
      case 'yearly_books':
        return '冊';
      case 'monthly_chapters':
        return '章';
      default:
        return '';
    }
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = UpdateReadingGoalRequest(
        targetValue: _targetValue,
        isActive: _isActive,
      );

      await Provider.of<ReadingAnalyticsProvider>(context, listen: false)
          .updateReadingGoal(widget.goal.id, request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標の更新に失敗しました')),
        );
      }
    }
  }
}