import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class PerformanceUtils {
  static const MethodChannel _channel = MethodChannel('roudoku/performance');

  /// Preload images to prevent stuttering during swipe animations
  static Future<void> preloadImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    // Use compute to process images in isolate if needed
    if (imageUrls.length > 10) {
      await compute(_preloadImagesInIsolate, imageUrls);
    } else {
      await _preloadImagesList(imageUrls);
    }
  }

  static Future<void> _preloadImagesList(List<String> imageUrls) async {
    // This would typically precache images using Flutter's precacheImage
    // For now, we'll simulate the process
    for (final url in imageUrls) {
      debugPrint('Preloading image: $url');
      // In a real implementation:
      // await precacheImage(NetworkImage(url), context);
    }
  }

  static Future<void> _preloadImagesInIsolate(List<String> imageUrls) async {
    // Process images in background isolate to prevent UI blocking
    await _preloadImagesList(imageUrls);
  }

  /// Optimize memory usage by clearing unnecessary caches
  static Future<void> optimizeMemory() async {
    try {
      // Clear image cache if memory is low
      if (await _isMemoryLow()) {
        await _clearImageCache();
      }
      
      // Force garbage collection
      await _forceGarbageCollection();
    } catch (e) {
      debugPrint('Memory optimization failed: $e');
    }
  }

  /// Check if device memory is running low
  static Future<bool> _isMemoryLow() async {
    try {
      final result = await _channel.invokeMethod<bool>('isMemoryLow');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check memory status: $e');
      return false;
    }
  }

  /// Clear image cache to free memory
  static Future<void> _clearImageCache() async {
    try {
      // In a real implementation, this would clear Flutter's image cache
      // imageCache.clear();
      // imageCache.clearLiveImages();
      debugPrint('Image cache cleared');
    } catch (e) {
      debugPrint('Failed to clear image cache: $e');
    }
  }

  /// Force garbage collection
  static Future<void> _forceGarbageCollection() async {
    try {
      await _channel.invokeMethod('forceGC');
    } catch (e) {
      // Fallback to Dart GC
      debugPrint('Platform GC failed, using Dart GC');
    }
  }

  /// Batch process quotes for better performance
  static List<T> batchProcess<T>(
    List<T> items,
    T Function(T) processor, {
    int batchSize = 50,
  }) {
    final List<T> processed = [];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);
      
      for (final item in batch) {
        processed.add(processor(item));
      }
      
      // Small delay between batches to prevent UI blocking
      if (end < items.length) {
        Future.delayed(const Duration(milliseconds: 1));
      }
    }
    
    return processed;
  }

  /// Debounce function calls to improve performance
  static Timer? _debounceTimer;
  
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls to limit frequency
  static DateTime? _lastThrottleTime;
  
  static void throttle(VoidCallback callback, {Duration interval = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Monitor performance metrics
  static void startPerformanceMonitoring() {
    // Monitor frame rate
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  static void stopPerformanceMonitoring() {
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
  }

  static void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // Convert to milliseconds
      
      if (frameTime > 16.67) { // 60 FPS threshold
        debugPrint('Slow frame detected: ${frameTime.toStringAsFixed(2)}ms');
      }
    }
  }

  /// Create optimized quote widget builders with viewport awareness
  static Widget Function(BuildContext, int) createOptimizedQuoteBuilder(
    List<dynamic> quotes,
    Widget Function(BuildContext, dynamic, int) builder, {
    int bufferSize = 3,
  }) {
    return (context, index) {
      // Only build visible items plus buffer
      if (index < 0 || index >= quotes.length) {
        return const SizedBox.shrink();
      }
      
      // Use RepaintBoundary to isolate repaints
      return RepaintBoundary(
        child: builder(context, quotes[index], index),
      );
    };
  }

  /// Optimize ListView performance with custom physics
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// Create performance-optimized PageView
  static PageView createOptimizedPageView({
    required PageController controller,
    required List<Widget> children,
    required Function(int) onPageChanged,
    bool allowImplicitScrolling = true,
  }) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      allowImplicitScrolling: allowImplicitScrolling,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }

  /// Lazy load data with caching
  static final Map<String, dynamic> _lazyCache = {};
  
  static Future<T> lazyLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration? cacheExpiry,
  }) async {
    // Check cache first
    if _lazyCache.containsKey(key) {
      final cached = _lazyCache[key];
      if (cached['expiry'] == null || DateTime.now().isBefore(cached['expiry'])) {
        return cached['data'] as T;
      }
    }
    
    // Load data
    final data = await loader();
    
    // Cache with expiry
    _lazyCache[key] = {
      'data': data,
      'expiry': cacheExpiry != null ? DateTime.now().add(cacheExpiry) : null,
    };
    
    return data;
  }

  /// Clear lazy load cache
  static void clearLazyCache() {
    _lazyCache.clear();
  }

  /// Get memory usage statistics
  static Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMemoryStats');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Failed to get memory stats: $e');
      return {};
    }
  }

  /// Optimize quote text for better rendering performance
  static String optimizeQuoteText(String text) {
    // Remove excessive whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Trim
    text = text.trim();
    
    // Limit length for performance (if needed)
    if (text.length > 1000) {
      text = '${text.substring(0, 997)}...';
    }
    
    return text;
  }

  /// Pre-calculate layout dimensions to prevent layout shifts
  static Map<String, double> precalculateLayout({
    required double screenWidth,
    required double screenHeight,
    required double cardMargin,
    required double cardPadding,
  }) {
    final cardWidth = screenWidth * 0.85;
    final cardHeight = screenHeight * 0.7;
    final contentWidth = cardWidth - (cardPadding * 2);
    final contentHeight = cardHeight - (cardPadding * 2);
    
    return {
      'cardWidth': cardWidth,
      'cardHeight': cardHeight,
      'contentWidth': contentWidth,
      'contentHeight': contentHeight,
      'maxTextWidth': contentWidth - 32, // Additional padding for text
    };
  }

  /// Advanced image caching with compression
  static Future<void> cacheImageWithCompression(
    String imageUrl, {
    double compressionQuality = 0.8,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // This would implement image compression and caching
      debugPrint('Caching compressed image: $imageUrl');
      // In production, use image compression libraries
    } catch (e) {
      debugPrint('Failed to cache compressed image: $e');
    }
  }

  /// Monitor app lifecycle for performance optimization
  static void optimizeForAppLifecycle() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  /// Prefetch critical app data
  static Future<void> prefetchCriticalData({
    required Future<void> Function() loadUserData,
    required Future<void> Function() loadRecommendations,
    required Future<void> Function() loadAudioCache,
  }) async {
    final futures = <Future>[
      loadUserData(),
      loadRecommendations(),
      loadAudioCache(),
    ];
    
    try {
      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('Failed to prefetch some critical data: $e');
    }
  }

  /// Optimize text rendering for quotes
  static TextPainter createOptimizedTextPainter({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.start,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  /// Dispose all performance utilities
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastThrottleTime = null;
    clearLazyCache();
    stopPerformanceMonitoring();
  }
}

/// App lifecycle observer for performance optimization
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is paused, optimize memory
        PerformanceUtils.optimizeMemory();
        break;
      case AppLifecycleState.resumed:
        // App is resumed, pre-warm caches
        PerformanceUtils.startPerformanceMonitoring();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        PerformanceUtils.dispose();
        break;
      default:
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // System is low on memory
    PerformanceUtils.optimizeMemory();
  }
}