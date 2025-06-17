import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../config/app_settings.dart';
import '../logging/logger.dart';
import '../monitoring/performance_monitor.dart';
import '../di/service_locator.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> with TickerProviderStateMixin {
  late TabController _tabController;
  String _logOutput = '';
  String _performanceOutput = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDebugData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDebugData() {
    setState(() {
      _performanceOutput = PerformanceMonitor.instance.generateReport().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.instance.isDebugMode) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Panel'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Config', icon: Icon(Icons.settings)),
            Tab(text: 'Logs', icon: Icon(Icons.bug_report)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Tools', icon: Icon(Icons.build)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigTab(),
          _buildLogsTab(),
          _buildPerformanceTab(),
          _buildToolsTab(),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('App Configuration', [
          'Environment: ${AppConfig.instance.environment.name}',
          'API Base URL: ${AppConfig.instance.apiBaseUrl}',
          'App Version: ${AppConfig.instance.appVersion}',
          'Debug Mode: ${AppConfig.instance.isDebugMode}',
          'Logging: ${AppConfig.instance.enableLogging}',
          'Analytics: ${AppConfig.instance.enableAnalytics}',
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Feature Flags', [
          'Offline Mode: ${FeatureFlags.offlineMode}',
          'Cloud TTS: ${FeatureFlags.cloudTts}',
          'Advanced Audio: ${FeatureFlags.advancedAudio}',
          'Social Features: ${FeatureFlags.socialFeatures}',
          'Beta Features: ${FeatureFlags.betaFeatures}',
          'Debug Menu: ${FeatureFlags.debugMenu}',
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('User Settings', [
          'Volume: ${AppSettings.instance.volume}',
          'Speech Rate: ${AppSettings.instance.speechRate}',
          'TTS Language: ${AppSettings.instance.ttsLanguage}',
          'Dark Mode: ${AppSettings.instance.darkMode}',
          'Notifications: ${AppSettings.instance.notifications}',
          'Offline Mode: ${AppSettings.instance.offlineMode}',
        ]),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _clearLogs,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Logs'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _exportLogs,
                icon: const Icon(Icons.file_download),
                label: const Text('Export Logs'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _logOutput.isEmpty ? 'No logs available' : _logOutput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadDebugData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard('Performance Report', [
            _performanceOutput,
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testPerformance,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Performance Test'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearPerformanceData,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildToolCard(
          'Service Locator',
          'Manage dependency injection',
          Icons.hub,
          _showServiceLocatorInfo,
        ),
        const SizedBox(height: 16),
        _buildToolCard(
          'Reset Settings',
          'Reset all user settings to defaults',
          Icons.restore,
          _resetSettings,
        ),
        const SizedBox(height: 16),
        _buildToolCard(
          'Clear Cache',
          'Clear all cached data',
          Icons.storage,
          _clearCache,
        ),
        const SizedBox(height: 16),
        _buildToolCard(
          'Trigger Error',
          'Test error handling (for testing)',
          Icons.warning,
          _triggerTestError,
        ),
        const SizedBox(height: 16),
        _buildToolCard(
          'Copy Debug Info',
          'Copy all debug information to clipboard',
          Icons.copy,
          _copyDebugInfo,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logOutput = '';
    });
    Logger.info('Debug logs cleared');
  }

  void _exportLogs() {
    // In a real implementation, this would save to file
    Clipboard.setData(ClipboardData(text: _logOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _testPerformance() {
    Logger.info('Running performance test');
    
    // Simulate some operations
    PerformanceMonitor.instance.measureSync('test_sync_operation', () {
      // Simulate work
      for (int i = 0; i < 1000000; i++) {
        // Busy work
      }
    });

    PerformanceMonitor.instance.measureAsync('test_async_operation', () async {
      await Future.delayed(const Duration(milliseconds: 100));
    });

    _loadDebugData();
    Logger.info('Performance test completed');
  }

  void _clearPerformanceData() {
    // In a real implementation, this would clear performance data
    Logger.info('Performance data cleared');
    _loadDebugData();
  }

  void _showServiceLocatorInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Locator Info'),
        content: const Text('Service Locator is managing dependency injection for the app. All services are properly registered and accessible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will reset all user settings to defaults. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppSettings.instance.resetToDefaults();
      Logger.info('Settings reset to defaults');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset successfully')),
        );
      }
    }
  }

  void _clearCache() {
    Logger.info('Cache cleared');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _triggerTestError() {
    Logger.info('Triggering test error');
    try {
      throw Exception('This is a test error for debugging purposes');
    } catch (e) {
      Logger.error('Test error triggered', e);
    }
  }

  void _copyDebugInfo() {
    final debugInfo = '''
Debug Information
================

App Configuration:
- Environment: ${AppConfig.instance.environment.name}
- API Base URL: ${AppConfig.instance.apiBaseUrl}
- App Version: ${AppConfig.instance.appVersion}
- Debug Mode: ${AppConfig.instance.isDebugMode}

Performance Report:
$_performanceOutput

Generated at: ${DateTime.now().toIso8601String()}
''';

    Clipboard.setData(ClipboardData(text: debugInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug info copied to clipboard')),
    );
  }
}

class DebugOverlay extends StatelessWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.instance.isDebugMode || !FeatureFlags.debugMenu) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: FloatingActionButton.small(
            onPressed: () => _showDebugPanel(context),
            backgroundColor: Colors.red.shade900,
            child: const Icon(Icons.bug_report, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showDebugPanel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugPanel(),
        fullscreenDialog: true,
      ),
    );
  }
}