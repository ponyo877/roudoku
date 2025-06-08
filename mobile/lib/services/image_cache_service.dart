import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// Advanced image caching service for optimal performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, ImageCacheEntry> _memoryCache = {};
  final Map<String, Future<ui.Image?>> _loadingImages = {};
  Directory? _cacheDirectory;
  bool _initialized = false;

  // Cache configuration
  static const int maxMemoryCacheSize = 50; // Maximum images in memory
  static const int maxDiskCacheSize = 200; // Maximum images on disk
  static const Duration defaultCacheExpiry = Duration(days: 7);
  static const int compressionQuality = 85;
  static const int maxImageDimension = 1024;

  /// Initialize the image cache service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/image_cache');
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      // Clean up expired cache entries on startup
      await _cleanupExpiredEntries();
      
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize image cache: $e');
    }
  }

  /// Load and cache an image with optimization
  Future<ui.Image?> loadImage(
    String imageUrl, {
    Size? targetSize,
    BoxFit fit = BoxFit.cover,
    Duration? cacheExpiry,
  }) async {
    if (!_initialized) await initialize();

    final cacheKey = _generateCacheKey(imageUrl, targetSize);
    
    // Check memory cache first
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      memoryEntry.lastAccessed = DateTime.now();
      return memoryEntry.image;
    }

    // Check if already loading
    if (_loadingImages.containsKey(cacheKey)) {
      return await _loadingImages[cacheKey];
    }

    // Start loading process
    final future = _loadImageFromCacheOrNetwork(
      imageUrl,
      cacheKey,
      targetSize,
      fit,
      cacheExpiry ?? defaultCacheExpiry,
    );
    
    _loadingImages[cacheKey] = future;
    
    try {
      final image = await future;
      return image;
    } finally {
      _loadingImages.remove(cacheKey);
    }
  }

  /// Load image from cache or network
  Future<ui.Image?> _loadImageFromCacheOrNetwork(
    String imageUrl,
    String cacheKey,
    Size? targetSize,
    BoxFit fit,
    Duration cacheExpiry,
  ) async {
    try {
      // Try disk cache first
      final diskImage = await _loadFromDiskCache(cacheKey);
      if (diskImage != null) {
        _addToMemoryCache(cacheKey, diskImage, cacheExpiry);
        return diskImage;
      }

      // Load from network
      final networkImage = await _loadFromNetwork(imageUrl, targetSize, fit);
      if (networkImage != null) {
        // Cache both in memory and disk
        _addToMemoryCache(cacheKey, networkImage, cacheExpiry);
        unawaited(_saveToDiskCache(cacheKey, networkImage, cacheExpiry));
      }

      return networkImage;
    } catch (e) {
      debugPrint('Failed to load image $imageUrl: $e');
      return null;
    }
  }

  /// Load image from network with optimization
  Future<ui.Image?> _loadFromNetwork(
    String imageUrl,
    Size? targetSize,
    BoxFit fit,
  ) async {
    try {
      final uri = Uri.parse(imageUrl);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      
      // Optimize image before decoding
      final optimizedBytes = await _optimizeImageBytes(bytes, targetSize);
      
      final codec = await ui.instantiateImageCodec(
        optimizedBytes,
        targetWidth: targetSize?.width.round(),
        targetHeight: targetSize?.height.round(),
      );
      
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Network image load failed: $e');
      return null;
    }
  }

  /// Optimize image bytes for performance
  Future<Uint8List> _optimizeImageBytes(
    Uint8List originalBytes,
    Size? targetSize,
  ) async {
    try {
      // If no target size, return original with some compression
      if (targetSize == null) {
        return originalBytes;
      }

      // Decode image to get dimensions
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;

      // Calculate optimal dimensions
      final targetWidth = targetSize.width.round();
      final targetHeight = targetSize.height.round();

      // If image is already smaller than target, return original
      if (originalWidth <= targetWidth && originalHeight <= targetHeight) {
        return originalBytes;
      }

      // Calculate scale factor to maintain aspect ratio
      final scaleX = targetWidth / originalWidth;
      final scaleY = targetHeight / originalHeight;
      final scale = math.min(scaleX, scaleY);

      final newWidth = (originalWidth * scale).round();
      final newHeight = (originalHeight * scale).round();

      // Create optimized image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      canvas.scale(scale);
      canvas.drawImage(originalImage, Offset.zero, Paint());
      
      final picture = recorder.endRecording();
      final optimizedImage = await picture.toImage(newWidth, newHeight);
      
      // Convert back to bytes
      final byteData = await optimizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      originalImage.dispose();
      optimizedImage.dispose();
      picture.dispose();
      
      return byteData?.buffer.asUint8List() ?? originalBytes;
    } catch (e) {
      debugPrint('Image optimization failed: $e');
      return originalBytes;
    }
  }

  /// Load image from disk cache
  Future<ui.Image?> _loadFromDiskCache(String cacheKey) async {
    if (_cacheDirectory == null) return null;

    try {
      final file = File('${_cacheDirectory!.path}/$cacheKey.cache');
      final metaFile = File('${_cacheDirectory!.path}/$cacheKey.meta');

      if (!await file.exists() || !await metaFile.exists()) {
        return null;
      }

      // Check if cache entry is expired
      final metaData = await metaFile.readAsString();
      final meta = ImageCacheMeta.fromJson(metaData);
      
      if (meta.isExpired) {
        // Clean up expired files
        unawaited(file.delete());
        unawaited(metaFile.delete());
        return null;
      }

      // Load image from disk
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      // Update access time
      meta.lastAccessed = DateTime.now();
      await metaFile.writeAsString(meta.toJson());

      return frame.image;
    } catch (e) {
      debugPrint('Disk cache load failed: $e');
      return null;
    }
  }

  /// Save image to disk cache
  Future<void> _saveToDiskCache(
    String cacheKey,
    ui.Image image,
    Duration expiry,
  ) async {
    if (_cacheDirectory == null) return;

    try {
      // Check disk cache size and clean up if needed
      await _manageDiskCacheSize();

      final file = File('${_cacheDirectory!.path}/$cacheKey.cache');
      final metaFile = File('${_cacheDirectory!.path}/$cacheKey.meta');

      // Convert image to bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      
      // Save image data
      await file.writeAsBytes(bytes);

      // Save metadata
      final meta = ImageCacheMeta(
        cacheKey: cacheKey,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        expiresAt: DateTime.now().add(expiry),
        size: bytes.length,
      );
      
      await metaFile.writeAsString(meta.toJson());
    } catch (e) {
      debugPrint('Disk cache save failed: $e');
    }
  }

  /// Add image to memory cache
  void _addToMemoryCache(String cacheKey, ui.Image image, Duration expiry) {
    // Remove oldest entry if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      _evictLeastRecentlyUsed();
    }

    _memoryCache[cacheKey] = ImageCacheEntry(
      image: image,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
      expiresAt: DateTime.now().add(expiry),
    );
  }

  /// Evict least recently used memory cache entry
  void _evictLeastRecentlyUsed() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      final entry = _memoryCache.remove(oldestKey);
      entry?.image.dispose();
    }
  }

  /// Manage disk cache size
  Future<void> _manageDiskCacheSize() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      final cacheFiles = files
          .where((file) => file.path.endsWith('.cache'))
          .cast<File>()
          .toList();

      if (cacheFiles.length <= maxDiskCacheSize) return;

      // Sort by last accessed time and remove oldest
      final metaData = <String, ImageCacheMeta>{};
      
      for (final file in cacheFiles) {
        final baseName = file.path.split('/').last.replaceAll('.cache', '');
        final metaFile = File('${_cacheDirectory!.path}/$baseName.meta');
        
        if (await metaFile.exists()) {
          try {
            final metaContent = await metaFile.readAsString();
            metaData[baseName] = ImageCacheMeta.fromJson(metaContent);
          } catch (e) {
            // Invalid meta file, mark for deletion
            unawaited(file.delete());
            unawaited(metaFile.delete());
          }
        }
      }

      // Sort by last accessed and remove oldest
      final sortedEntries = metaData.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove = sortedEntries.take(cacheFiles.length - maxDiskCacheSize);
      
      for (final entry in toRemove) {
        final cacheFile = File('${_cacheDirectory!.path}/${entry.key}.cache');
        final metaFile = File('${_cacheDirectory!.path}/${entry.key}.meta');
        
        unawaited(cacheFile.delete());
        unawaited(metaFile.delete());
      }
    } catch (e) {
      debugPrint('Disk cache management failed: $e');
    }
  }

  /// Clean up expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    if (_cacheDirectory == null) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      final metaFiles = files
          .where((file) => file.path.endsWith('.meta'))
          .cast<File>()
          .toList();

      for (final metaFile in metaFiles) {
        try {
          final metaContent = await metaFile.readAsString();
          final meta = ImageCacheMeta.fromJson(metaContent);
          
          if (meta.isExpired) {
            final baseName = metaFile.path.split('/').last.replaceAll('.meta', '');
            final cacheFile = File('${_cacheDirectory!.path}/$baseName.cache');
            
            unawaited(metaFile.delete());
            unawaited(cacheFile.delete());
          }
        } catch (e) {
          // Invalid meta file, delete it
          unawaited(metaFile.delete());
        }
      }
    } catch (e) {
      debugPrint('Cache cleanup failed: $e');
    }
  }

  /// Generate cache key for image
  String _generateCacheKey(String imageUrl, Size? targetSize) {
    final sizeString = targetSize != null 
        ? '${targetSize.width.round()}x${targetSize.height.round()}'
        : 'original';
    
    final input = '$imageUrl:$sizeString';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls, {Size? targetSize}) async {
    final futures = imageUrls.map((url) => loadImage(url, targetSize: targetSize));
    await Future.wait(futures, eagerError: false);
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    // Clear memory cache
    for (final entry in _memoryCache.values) {
      entry.image.dispose();
    }
    _memoryCache.clear();

    // Clear disk cache
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      try {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      } catch (e) {
        debugPrint('Failed to clear disk cache: $e');
      }
    }
  }

  /// Get cache statistics
  Future<ImageCacheStats> getCacheStats() async {
    final memorySizeBytes = _memoryCache.values
        .map((entry) => entry.estimatedSize)
        .fold<int>(0, (sum, size) => sum + size);

    int diskSizeBytes = 0;
    int diskEntryCount = 0;

    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      try {
        final files = await _cacheDirectory!.list().toList();
        final cacheFiles = files.where((file) => file.path.endsWith('.cache'));
        
        diskEntryCount = cacheFiles.length;
        
        for (final file in cacheFiles.cast<File>()) {
          final stat = await file.stat();
          diskSizeBytes += stat.size;
        }
      } catch (e) {
        debugPrint('Failed to calculate disk cache stats: $e');
      }
    }

    return ImageCacheStats(
      memoryEntryCount: _memoryCache.length,
      memorySizeBytes: memorySizeBytes,
      diskEntryCount: diskEntryCount,
      diskSizeBytes: diskSizeBytes,
      maxMemoryEntries: maxMemoryCacheSize,
      maxDiskEntries: maxDiskCacheSize,
    );
  }

  /// Dispose resources
  void dispose() {
    for (final entry in _memoryCache.values) {
      entry.image.dispose();
    }
    _memoryCache.clear();
    _loadingImages.clear();
  }
}

/// Represents a cached image entry in memory
class ImageCacheEntry {
  final ui.Image image;
  final DateTime createdAt;
  DateTime lastAccessed;
  final DateTime expiresAt;

  ImageCacheEntry({
    required this.image,
    required this.createdAt,
    required this.lastAccessed,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  int get estimatedSize {
    // Rough estimation: width * height * 4 bytes per pixel (RGBA)
    return image.width * image.height * 4;
  }
}

/// Metadata for disk cache entries
class ImageCacheMeta {
  final String cacheKey;
  final DateTime createdAt;
  DateTime lastAccessed;
  final DateTime expiresAt;
  final int size;

  ImageCacheMeta({
    required this.cacheKey,
    required this.createdAt,
    required this.lastAccessed,
    required this.expiresAt,
    required this.size,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String toJson() {
    return jsonEncode({
      'cacheKey': cacheKey,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'size': size,
    });
  }

  factory ImageCacheMeta.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ImageCacheMeta(
      cacheKey: map['cacheKey'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAccessed: DateTime.parse(map['lastAccessed'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      size: map['size'] as int,
    );
  }
}

/// Statistics about image cache usage
class ImageCacheStats {
  final int memoryEntryCount;
  final int memorySizeBytes;
  final int diskEntryCount;
  final int diskSizeBytes;
  final int maxMemoryEntries;
  final int maxDiskEntries;

  ImageCacheStats({
    required this.memoryEntryCount,
    required this.memorySizeBytes,
    required this.diskEntryCount,
    required this.diskSizeBytes,
    required this.maxMemoryEntries,
    required this.maxDiskEntries,
  });

  double get memoryUsageRatio => memoryEntryCount / maxMemoryEntries;
  double get diskUsageRatio => diskEntryCount / maxDiskEntries;
  
  String get memorySizeFormatted => _formatBytes(memorySizeBytes);
  String get diskSizeFormatted => _formatBytes(diskSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}