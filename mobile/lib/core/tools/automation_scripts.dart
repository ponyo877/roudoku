import 'dart:io';
import '../logging/logger.dart';
import 'code_generator.dart';
import 'migration_helper.dart';

class AutomationScripts {
  /// Runs the complete setup for a new clean architecture project
  static Future<void> setupCleanArchitecture() async {
    Logger.info('Starting clean architecture setup');
    
    try {
      // Generate core documentation
      await MigrationHelper.generateMigrationGuide();
      await MigrationHelper.generateDeploymentGuide();
      await MigrationHelper.generateArchitectureDocumentation();
      
      // Create common feature modules
      await CodeGenerator.generateFeatureModule('notifications');
      await CodeGenerator.generateFeatureModule('settings');
      await CodeGenerator.generateFeatureModule('analytics');
      
      Logger.info('Clean architecture setup completed successfully');
      
      // Generate summary report
      await _generateSetupReport();
      
    } catch (e) {
      Logger.error('Setup failed', e);
      rethrow;
    }
  }
  
  /// Validates the current project structure
  static Future<ValidationReport> validateProjectStructure() async {
    Logger.info('Validating project structure');
    
    final report = ValidationReport();
    
    // Check core directories
    final coreDirectories = [
      'lib/core/config',
      'lib/core/di',
      'lib/core/logging',
      'lib/core/network',
      'lib/core/providers',
      'lib/core/state',
    ];
    
    for (final dir in coreDirectories) {
      if (await Directory(dir).exists()) {
        report.validDirectories.add(dir);
      } else {
        report.missingDirectories.add(dir);
      }
    }
    
    // Check core files
    final coreFiles = [
      'lib/core/config/app_config.dart',
      'lib/core/di/service_locator.dart',
      'lib/core/logging/logger.dart',
      'lib/core/network/dio_client.dart',
      'lib/core/providers/base_provider.dart',
      'lib/core/state/base_state.dart',
    ];
    
    for (final file in coreFiles) {
      if (await File(file).exists()) {
        report.validFiles.add(file);
      } else {
        report.missingFiles.add(file);
      }
    }
    
    // Check feature structure
    final featuresDir = Directory('lib/features');
    if (await featuresDir.exists()) {
      await for (final entity in featuresDir.list()) {
        if (entity is Directory) {
          final featureName = entity.path.split('/').last;
          final featureValid = await _validateFeatureStructure(featureName);
          if (featureValid) {
            report.validFeatures.add(featureName);
          } else {
            report.invalidFeatures.add(featureName);
          }
        }
      }
    }
    
    Logger.info('Project validation completed');
    return report;
  }
  
  /// Runs quality checks on the codebase
  static Future<QualityReport> runQualityCheck() async {
    Logger.info('Running quality checks');
    
    final report = QualityReport();
    
    try {
      // Run dart analyze
      final analyzeResult = await Process.run('dart', ['analyze', '.']);
      report.analyzeExitCode = analyzeResult.exitCode;
      report.analyzeOutput = analyzeResult.stdout.toString();
      
      if (analyzeResult.exitCode == 0) {
        report.analyzeSuccess = true;
        Logger.info('Dart analyze: PASSED');
      } else {
        report.analyzeSuccess = false;
        Logger.warning('Dart analyze: FAILED');
      }
      
      // Run dart format check
      final formatResult = await Process.run('dart', ['format', '--set-exit-if-changed', '.']);
      report.formatExitCode = formatResult.exitCode;
      
      if (formatResult.exitCode == 0) {
        report.formatSuccess = true;
        Logger.info('Dart format: PASSED');
      } else {
        report.formatSuccess = false;
        Logger.warning('Dart format: FAILED');
      }
      
      // Check for TODO comments
      await _checkTodoComments(report);
      
      // Check import organization
      await _checkImportOrganization(report);
      
    } catch (e) {
      Logger.error('Quality check failed', e);
      report.error = e.toString();
    }
    
    Logger.info('Quality check completed');
    return report;
  }
  
  /// Generates a new feature module with all necessary files
  static Future<void> createFeature(String featureName) async {
    Logger.info('Creating feature: $featureName');
    
    try {
      await CodeGenerator.generateFeatureModule(featureName);
      
      // Validate the generated feature
      final isValid = await _validateFeatureStructure(featureName);
      if (isValid) {
        Logger.info('Feature $featureName created and validated successfully');
      } else {
        Logger.warning('Feature $featureName created but validation failed');
      }
      
    } catch (e) {
      Logger.error('Failed to create feature: $featureName', e);
      rethrow;
    }
  }
  
  /// Cleans up temporary files and optimizes the project
  static Future<void> cleanupProject() async {
    Logger.info('Cleaning up project');
    
    try {
      // Remove common temporary files
      final tempPaths = [
        '.dart_tool/build/',
        'build/',
        '.flutter-plugins-dependencies',
      ];
      
      for (final path in tempPaths) {
        final entity = FileSystemEntity.isDirectorySync(path) 
            ? Directory(path) 
            : File(path);
        
        if (await entity.exists()) {
          await entity.delete(recursive: true);
          Logger.debug('Deleted: $path');
        }
      }
      
      // Run flutter clean
      final cleanResult = await Process.run('flutter', ['clean']);
      if (cleanResult.exitCode == 0) {
        Logger.info('Flutter clean: SUCCESS');
      } else {
        Logger.warning('Flutter clean: FAILED');
      }
      
      // Run flutter pub get
      final pubGetResult = await Process.run('flutter', ['pub', 'get']);
      if (pubGetResult.exitCode == 0) {
        Logger.info('Flutter pub get: SUCCESS');
      } else {
        Logger.warning('Flutter pub get: FAILED');
      }
      
      Logger.info('Project cleanup completed');
      
    } catch (e) {
      Logger.error('Cleanup failed', e);
      rethrow;
    }
  }
  
  static Future<bool> _validateFeatureStructure(String featureName) async {
    final requiredDirs = [
      'lib/features/$featureName/data/datasources',
      'lib/features/$featureName/data/models',
      'lib/features/$featureName/data/repositories',
      'lib/features/$featureName/domain/entities',
      'lib/features/$featureName/domain/repositories',
      'lib/features/$featureName/domain/usecases',
      'lib/features/$featureName/presentation/providers',
    ];
    
    for (final dir in requiredDirs) {
      if (!await Directory(dir).exists()) {
        return false;
      }
    }
    
    return true;
  }
  
  static Future<void> _checkTodoComments(QualityReport report) async {
    final dartFiles = await _getAllDartFiles();
    
    for (final file in dartFiles) {
      final content = await File(file).readAsString();
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().contains('todo')) {
          report.todoComments.add('$file:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }
  
  static Future<void> _checkImportOrganization(QualityReport report) async {
    final dartFiles = await _getAllDartFiles();
    
    for (final file in dartFiles) {
      final content = await File(file).readAsString();
      final lines = content.split('\n');
      
      final imports = lines
          .where((line) => line.startsWith('import '))
          .toList();
      
      if (imports.length > 1) {
        final dartImports = imports.where((imp) => imp.contains('dart:')).toList();
        final flutterImports = imports.where((imp) => imp.contains('package:flutter')).toList();
        final packageImports = imports.where((imp) => 
            imp.contains('package:') && !imp.contains('package:flutter')).toList();
        final relativeImports = imports.where((imp) => 
            !imp.contains('dart:') && !imp.contains('package:')).toList();
        
        // Check if imports are properly organized
        final expectedOrder = [
          ...dartImports,
          ...flutterImports, 
          ...packageImports,
          ...relativeImports,
        ];
        
        if (imports.join('\n') != expectedOrder.join('\n')) {
          report.poorlyOrganizedImports.add(file);
        }
      }
    }
  }
  
  static Future<List<String>> _getAllDartFiles() async {
    final dartFiles = <String>[];
    
    await for (final entity in Directory('lib').list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    }
    
    return dartFiles;
  }
  
  static Future<void> _generateSetupReport() async {
    final timestamp = DateTime.now().toIso8601String();
    final report = '''
# Clean Architecture Setup Report

**Generated:** $timestamp

## Setup Completed Successfully ✅

### Generated Documentation
- ✅ Migration Guide (migration_guide.md)
- ✅ Deployment Guide (deployment_guide.md)  
- ✅ Architecture Documentation (architecture.md)

### Generated Feature Modules
- ✅ Notifications feature
- ✅ Settings feature
- ✅ Analytics feature

### Core Infrastructure
- ✅ Dependency injection container
- ✅ Unified logging system
- ✅ HTTP client with interceptors
- ✅ Base state management
- ✅ Performance monitoring
- ✅ Debug tools and panels

### Next Steps
1. Review generated documentation
2. Run quality checks: `AutomationScripts.runQualityCheck()`
3. Validate project structure: `AutomationScripts.validateProjectStructure()`
4. Begin migrating existing code following migration_guide.md

### Support
- Use the debug panel for runtime debugging
- Check logs for detailed operation information
- Use code generator for additional features
''';
    
    await File('setup_report.md').writeAsString(report);
    Logger.info('Setup report generated: setup_report.md');
  }
}

class ValidationReport {
  final List<String> validDirectories = [];
  final List<String> missingDirectories = [];
  final List<String> validFiles = [];
  final List<String> missingFiles = [];
  final List<String> validFeatures = [];
  final List<String> invalidFeatures = [];
  
  bool get isValid => missingDirectories.isEmpty && missingFiles.isEmpty && invalidFeatures.isEmpty;
  
  @override
  String toString() {
    return '''
Validation Report:
- Valid directories: ${validDirectories.length}
- Missing directories: ${missingDirectories.length}
- Valid files: ${validFiles.length}
- Missing files: ${missingFiles.length}
- Valid features: ${validFeatures.length}
- Invalid features: ${invalidFeatures.length}
- Overall status: ${isValid ? 'VALID' : 'INVALID'}
''';
  }
}

class QualityReport {
  bool analyzeSuccess = false;
  int analyzeExitCode = -1;
  String analyzeOutput = '';
  
  bool formatSuccess = false;
  int formatExitCode = -1;
  
  final List<String> todoComments = [];
  final List<String> poorlyOrganizedImports = [];
  
  String? error;
  
  bool get isHighQuality => analyzeSuccess && formatSuccess && todoComments.isEmpty;
  
  @override
  String toString() {
    return '''
Quality Report:
- Dart analyze: ${analyzeSuccess ? 'PASS' : 'FAIL'}
- Dart format: ${formatSuccess ? 'PASS' : 'FAIL'}
- TODO comments: ${todoComments.length}
- Import issues: ${poorlyOrganizedImports.length}
- Overall quality: ${isHighQuality ? 'HIGH' : 'NEEDS IMPROVEMENT'}
${error != null ? '\nError: $error' : ''}
''';
  }
}