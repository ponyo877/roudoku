import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/context_provider.dart';

class ContextSettingScreen extends StatefulWidget {
  const ContextSettingScreen({Key? key}) : super(key: key);

  @override
  State<ContextSettingScreen> createState() => _ContextSettingScreenState();
}

class _ContextSettingScreenState extends State<ContextSettingScreen> {
  final TextEditingController _goalController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final contextProvider = context.read<ContextProvider>();
    _goalController.text = contextProvider.currentGoal ?? '';
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コンテキスト設定'),
      ),
      body: Consumer<ContextProvider>(
        builder: (context, contextProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたの興味や目標を教えてください',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'より良い本の推薦のために、あなたの情報を活用します',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 興味のあるカテゴリ
                const Text(
                  '興味のあるカテゴリ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'ビジネス',
                    '自己啓発',
                    '小説',
                    '歴史',
                    '科学',
                    '技術',
                    '健康',
                    '料理',
                    '旅行',
                    '芸術',
                  ].map((category) {
                    final isSelected = contextProvider.selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          contextProvider.addCategory(category);
                        } else {
                          contextProvider.removeCategory(category);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // 読書の目的
                const Text(
                  '読書の目的',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    'スキルアップ',
                    'リラックス',
                    '知識習得',
                    'エンターテイメント',
                    '語学学習',
                  ].map((purpose) {
                    return RadioListTile<String>(
                      title: Text(purpose),
                      value: purpose,
                      groupValue: contextProvider.readingPurpose,
                      onChanged: (value) {
                        if (value != null) {
                          contextProvider.setReadingPurpose(value);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // 現在の目標
                const Text(
                  '現在の目標',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '例: プレゼンテーションスキルを向上させたい',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 読書時間の設定
                const Text(
                  '1日の読書時間目標',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: contextProvider.dailyReadingGoal.toDouble(),
                        min: 15,
                        max: 120,
                        divisions: 7,
                        label: '${contextProvider.dailyReadingGoal}分',
                        onChanged: (value) {
                          contextProvider.setDailyReadingGoal(value.toInt());
                        },
                      ),
                    ),
                    Text(
                      '${contextProvider.dailyReadingGoal}分',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 通知設定
                SwitchListTile(
                  title: const Text('毎日のリマインダー'),
                  subtitle: const Text('読書時間を忘れないように通知します'),
                  value: contextProvider.reminderEnabled,
                  onChanged: (value) {
                    contextProvider.setReminderEnabled(value);
                  },
                ),
                
                if (contextProvider.reminderEnabled) ...[
                  ListTile(
                    title: const Text('リマインダー時刻'),
                    subtitle: Text(contextProvider.reminderTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: contextProvider.reminderTime,
                      );
                      if (time != null) {
                        contextProvider.setReminderTime(time);
                      }
                    },
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      contextProvider.setCurrentGoal(_goalController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('設定を保存しました'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '設定を保存',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}