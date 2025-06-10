import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Consumer2<AuthProvider, UserProvider>(
          builder: (context, authProvider, userProvider, child) {
            final user = authProvider.currentUser;
            
            if (user == null) {
              return _buildLoginPrompt(context, authProvider);
            }
            
            return Column(
              children: [
                _buildHeader(context, user, userProvider),
                const SizedBox(height: 24),
                _buildStats(userProvider),
                const SizedBox(height: 24),
                _buildMenuItems(context, authProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.person_outline,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'アカウントにログインしてください',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '進捗を保存し、複数のデバイスで同期します',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await authProvider.signInWithGoogle();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Googleでログイン'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await authProvider.signInAnonymously();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('ゲストとして続ける'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoUrl != null 
                ? NetworkImage(user.photoUrl!) 
                : null,
            child: user.photoUrl == null 
                ? const Icon(Icons.person, size: 50) 
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'ゲストユーザー',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email ?? '',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userProvider.subscriptionType == 'premium' ? 'プレミアム会員' : 'フリー会員',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '聴いた本',
            '${userProvider.listenedBooksCount}',
            Icons.headphones,
          ),
          _buildStatItem(
            '総再生時間',
            '${userProvider.totalListeningHours}時間',
            Icons.timer,
          ),
          _buildStatItem(
            '連続日数',
            '${userProvider.streakDays}日',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
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

  Widget _buildMenuItems(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bookmark),
          title: const Text('ブックマーク'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to bookmarks
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('再生履歴'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to history
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('ダウンロード'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to downloads
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('プレミアムにアップグレード'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Show premium upgrade
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('設定'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('ヘルプ & フィードバック'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Show help
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          onTap: () async {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ログアウト'),
                content: const Text('本当にログアウトしますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await authProvider.signOut();
                    },
                    child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}