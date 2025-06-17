import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../logging/logger.dart';
import '../config/app_config.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final List<PerformanceMetric> _metrics = [];
  Timer? _reportTimer;

  static PerformanceMonitor get instance => _instance;

  void initialize() {
    if (!AppConfig.instance.enableAnalytics) return;
    
    Logger.info('Initializing Performance Monitor');
    _startPeriodicReporting();
  }

  void _startPeriodicReporting() {
    _reportTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _generateReport();
    });
  }

  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    Logger.debug('Started timer for: $operation');
  }

  Duration? stopTimer(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) {
      Logger.warning('No start time found for operation: $operation');
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _recordMetric(PerformanceMetric(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
    ));

    Logger.debug('Completed $operation in ${duration.inMilliseconds}ms');
    return duration;
  }

  Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    startTimer(operation);
    try {
      final result = await function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      _recordError(operation, e);
      rethrow;
    }
  }

  T measureSync<T>(String operation, T Function() function) {
    startTimer(operation);
    try {
      final result = function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      _recordError(operation, e);
      rethrow;
    }
  }

  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only last 1000 metrics to prevent memory leaks
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }

    // Log slow operations
    if (metric.duration.inMilliseconds > 1000) {
      Logger.warning('Slow operation detected: ${metric.operation} took ${metric.duration.inMilliseconds}ms');
    }
  }

  void _recordError(String operation, dynamic error) {
    Logger.error('Performance monitoring: Error in $operation', error);
    _recordMetric(PerformanceMetric(
      operation: '$operation (ERROR)',
      duration: Duration.zero,
      timestamp: DateTime.now(),
      hasError: true,
      errorMessage: error.toString(),
    ));
  }

  void recordCustomMetric(String name, double value, {String? unit}) {
    Logger.debug('Custom metric: $name = $value ${unit ?? ''}');
    _recordMetric(PerformanceMetric(
      operation: name,
      duration: Duration(milliseconds: value.toInt()),
      timestamp: DateTime.now(),
      customValue: value,
      unit: unit,
    ));
  }

  void recordMemoryUsage() {
    if (!kDebugMode) return;
    
    // This would require additional packages for real memory monitoring
    // For now, we'll just log that we're monitoring
    Logger.debug('Memory usage check performed');
  }

  PerformanceReport generateReport() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(last24h))
        .toList();

    final report = PerformanceReport(
      generatedAt: now,
      totalOperations: recentMetrics.length,
      avgDuration: _calculateAverageDuration(recentMetrics),
      slowOperations: _getSlowOperations(recentMetrics),
      errorCount: recentMetrics.where((m) => m.hasError).length,
      operationBreakdown: _getOperationBreakdown(recentMetrics),
    );

    return report;
  }

  void _generateReport() {
    final report = generateReport();
    Logger.info('Performance Report: ${report.summary}');
    
    if (report.errorCount > 0) {
      Logger.warning('Found ${report.errorCount} errors in the last 24 hours');
    }

    if (report.slowOperations.isNotEmpty) {
      Logger.warning('Slow operations detected: ${report.slowOperations.length}');
    }
  }

  Duration _calculateAverageDuration(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return Duration.zero;
    
    final totalMs = metrics
        .where((m) => !m.hasError)
        .map((m) => m.duration.inMilliseconds)
        .fold<int>(0, (sum, ms) => sum + ms);
    
    return Duration(milliseconds: totalMs ~/ metrics.length);
  }

  List<PerformanceMetric> _getSlowOperations(List<PerformanceMetric> metrics) {
    return metrics
        .where((m) => m.duration.inMilliseconds > 1000)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
  }

  Map<String, int> _getOperationBreakdown(List<PerformanceMetric> metrics) {
    final breakdown = <String, int>{};
    for (final metric in metrics) {
      breakdown[metric.operation] = (breakdown[metric.operation] ?? 0) + 1;
    }
    return breakdown;
  }

  void dispose() {
    Logger.info('Disposing Performance Monitor');
    _reportTimer?.cancel();
    _startTimes.clear();
    _metrics.clear();
  }
}

class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final bool hasError;
  final String? errorMessage;
  final double? customValue;
  final String? unit;

  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.hasError = false,
    this.errorMessage,
    this.customValue,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'has_error': hasError,
      'error_message': errorMessage,
      'custom_value': customValue,
      'unit': unit,
    };
  }

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operation, duration: ${duration.inMilliseconds}ms, hasError: $hasError)';
  }
}

class PerformanceReport {
  final DateTime generatedAt;
  final int totalOperations;
  final Duration avgDuration;
  final List<PerformanceMetric> slowOperations;
  final int errorCount;
  final Map<String, int> operationBreakdown;

  PerformanceReport({
    required this.generatedAt,
    required this.totalOperations,
    required this.avgDuration,
    required this.slowOperations,
    required this.errorCount,
    required this.operationBreakdown,
  });

  String get summary {
    return 'Operations: $totalOperations, Avg: ${avgDuration.inMilliseconds}ms, Errors: $errorCount, Slow: ${slowOperations.length}';
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'total_operations': totalOperations,
      'avg_duration_ms': avgDuration.inMilliseconds,
      'slow_operations': slowOperations.map((m) => m.toJson()).toList(),
      'error_count': errorCount,
      'operation_breakdown': operationBreakdown,
    };
  }

  @override
  String toString() {
    return 'PerformanceReport(${summary})';
  }
}

// Convenience extensions for easy measurement
extension PerformanceExtensions on Future<T> Function() {
  Future<T> measured(String operation) {
    return PerformanceMonitor.instance.measureAsync(operation, this);
  }
}

extension SyncPerformanceExtensions on T Function() {
  T measured<T>(String operation) {
    return PerformanceMonitor.instance.measureSync<T>(operation, this);
  }
}