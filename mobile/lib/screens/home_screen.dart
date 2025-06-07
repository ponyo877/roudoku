import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/recommendation_card.dart';
import '../providers/book_provider.dart';
import '../models/swipe.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'context_setting_screen.dart';
import 'swipe_screen.dart';
import 'pair_comparison_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load recommendations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadRecommendations();
    });
  }

  final List<Widget> _screens = [
    const _HomeContent(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'roudoku',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContextSettingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Swipe mode selection cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover with Swipe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SwipeModeCard(
                        mode: SwipeMode.tinder,
                        title: 'Swipe Mode',
                        description: 'Swipe through quotes to find your favorites',
                        icon: Icons.swipe,
                        color: Colors.purple,
                        onTap: () => _navigateToSwipeMode(context, SwipeMode.tinder),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SwipeModeCard(
                        mode: SwipeMode.facemash,
                        title: 'Compare Mode',
                        description: 'Choose between two quotes',
                        icon: Icons.compare_arrows,
                        color: Colors.orange,
                        onTap: () => _navigateToSwipeMode(context, SwipeMode.facemash),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'あなたへのおすすめ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<BookProvider>(
              builder: (context, bookProvider, child) {
                if (bookProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (bookProvider.recommendations.isEmpty) {
                  return const Center(
                    child: Text('おすすめの本が見つかりません'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookProvider.recommendations.length,
                  itemBuilder: (context, index) {
                    final book = bookProvider.recommendations[index];
                    return RecommendationCard(book: book);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSwipeMode(BuildContext context, SwipeMode mode) {
    switch (mode) {
      case SwipeMode.tinder:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SwipeScreen(mode: mode),
          ),
        );
        break;
      case SwipeMode.facemash:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PairComparisonScreen(),
          ),
        );
        break;
    }
  }
}

class _SwipeModeCard extends StatelessWidget {
  final SwipeMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SwipeModeCard({
    Key? key,
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Start',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}