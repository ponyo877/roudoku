import 'package:flutter/material.dart';

class ReadingStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ReadingStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReadingProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressText;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ReadingProgressCard({
    Key? key,
    required this.title,
    required this.progress,
    required this.progressText,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 100 ? Colors.green : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.toInt()}% 達成',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String name;
  final String description;
  final String? iconUrl;
  final DateTime? earnedAt;
  final bool isEarned;
  final VoidCallback? onTap;

  const AchievementCard({
    Key? key,
    required this.name,
    required this.description,
    this.iconUrl,
    this.earnedAt,
    this.isEarned = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isEarned ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isEarned ? null : Colors.grey[100],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarned ? Colors.orange : Colors.grey[400],
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEarned ? null : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEarned ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (earnedAt != null) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      '${earnedAt!.month}/${earnedAt!.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '獲得',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ] else if (!isEarned) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final VoidCallback? onTap;

  const StreakCard({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.1),
                Colors.red.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              const Text(
                '読書ストリーク',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakItem(
                    Icons.local_fire_department,
                    Colors.orange,
                    '現在',
                    '$currentStreak日',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStreakItem(
                    Icons.emoji_events,
                    Colors.amber,
                    '最長記録',
                    '$longestStreak日',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakItem(IconData icon, Color color, String label, String value) {
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
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class ReadingInsightCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final String priority;
  final VoidCallback? onTap;

  const ReadingInsightCard({
    Key? key,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.left(
              width: 4,
              color: color,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (priority == 'high')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '重要',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'achievement':
        return Colors.orange;
      case 'improvement':
        return Colors.blue;
      case 'trend':
        return Colors.green;
      case 'recommendation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'improvement':
        return Icons.trending_up;
      case 'trend':
        return Icons.analytics;
      case 'recommendation':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }
}