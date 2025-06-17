import 'dart:io';
import '../logging/logger.dart';

class CodeGenerator {
  static Future<void> generateFeatureModule(String featureName) async {
    Logger.info('Generating feature module: $featureName');
    
    final featureDir = 'lib/features/${featureName.toLowerCase()}';
    
    // Create directory structure
    await _createDirectories([
      '$featureDir/data/datasources',
      '$featureDir/data/models',
      '$featureDir/data/repositories',
      '$featureDir/domain/entities',
      '$featureDir/domain/repositories',
      '$featureDir/domain/usecases',
      '$featureDir/presentation/providers',
      '$featureDir/presentation/screens',
      '$featureDir/presentation/widgets',
    ]);

    // Generate files
    await _generateEntityFile(featureName, featureDir);
    await _generateRepositoryInterface(featureName, featureDir);
    await _generateRepositoryImplementation(featureName, featureDir);
    await _generateDataSource(featureName, featureDir);
    await _generateModel(featureName, featureDir);
    await _generateUseCase(featureName, featureDir);
    await _generateProvider(featureName, featureDir);

    Logger.info('Feature module $featureName generated successfully');
  }

  static Future<void> _createDirectories(List<String> directories) async {
    for (final dir in directories) {
      await Directory(dir).create(recursive: true);
    }
  }

  static Future<void> _generateEntityFile(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
class ${className}Entity {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  ${className}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  ${className}Entity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ${className}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ${className}Entity &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode;
  }

  @override
  String toString() {
    return '${className}Entity(id: \$id, name: \$name)';
  }
}
''';

    await _writeFile('$featureDir/domain/entities/${featureName.toLowerCase()}_entity.dart', content);
  }

  static Future<void> _generateRepositoryInterface(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
import '../entities/${featureName.toLowerCase()}_entity.dart';

abstract class ${className}RepositoryInterface {
  Future<List<${className}Entity>> getAll();
  Future<${className}Entity?> getById(String id);
  Future<${className}Entity> create(${className}Entity entity);
  Future<${className}Entity> update(${className}Entity entity);
  Future<void> delete(String id);
}
''';

    await _writeFile('$featureDir/domain/repositories/${featureName.toLowerCase()}_repository_interface.dart', content);
  }

  static Future<void> _generateRepositoryImplementation(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
import '../../domain/entities/${featureName.toLowerCase()}_entity.dart';
import '../../domain/repositories/${featureName.toLowerCase()}_repository_interface.dart';
import '../datasources/${featureName.toLowerCase()}_remote_datasource.dart';
import '../models/${featureName.toLowerCase()}_models.dart';
import '../../../core/logging/logger.dart';

class ${className}Repository implements ${className}RepositoryInterface {
  final ${className}RemoteDataSource _remoteDataSource;

  ${className}Repository({
    required ${className}RemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<${className}Entity>> getAll() async {
    try {
      Logger.debug('Fetching all ${featureName.toLowerCase()}s from repository');
      final models = await _remoteDataSource.getAll();
      final entities = models.map((model) => _mapModelToEntity(model)).toList();
      Logger.debug('Retrieved \${entities.length} ${featureName.toLowerCase()}s from repository');
      return entities;
    } catch (e) {
      Logger.error('Error getting all ${featureName.toLowerCase()}s from repository', e);
      rethrow;
    }
  }

  @override
  Future<${className}Entity?> getById(String id) async {
    try {
      Logger.debug('Fetching ${featureName.toLowerCase()} by ID: \$id');
      final model = await _remoteDataSource.getById(id);
      if (model == null) return null;
      return _mapModelToEntity(model);
    } catch (e) {
      Logger.error('Error getting ${featureName.toLowerCase()} by ID: \$id', e);
      rethrow;
    }
  }

  @override
  Future<${className}Entity> create(${className}Entity entity) async {
    try {
      Logger.debug('Creating ${featureName.toLowerCase()}: \${entity.name}');
      final model = _mapEntityToModel(entity);
      final createdModel = await _remoteDataSource.create(model);
      return _mapModelToEntity(createdModel);
    } catch (e) {
      Logger.error('Error creating ${featureName.toLowerCase()}', e);
      rethrow;
    }
  }

  @override
  Future<${className}Entity> update(${className}Entity entity) async {
    try {
      Logger.debug('Updating ${featureName.toLowerCase()}: \${entity.id}');
      final model = _mapEntityToModel(entity);
      final updatedModel = await _remoteDataSource.update(model);
      return _mapModelToEntity(updatedModel);
    } catch (e) {
      Logger.error('Error updating ${featureName.toLowerCase()}: \${entity.id}', e);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      Logger.debug('Deleting ${featureName.toLowerCase()}: \$id');
      await _remoteDataSource.delete(id);
    } catch (e) {
      Logger.error('Error deleting ${featureName.toLowerCase()}: \$id', e);
      rethrow;
    }
  }

  ${className}Entity _mapModelToEntity(${className}Model model) {
    return ${className}Entity(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  ${className}Model _mapEntityToModel(${className}Entity entity) {
    return ${className}Model(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
''';

    await _writeFile('$featureDir/data/repositories/${featureName.toLowerCase()}_repository.dart', content);
  }

  static Future<void> _generateDataSource(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
import '../models/${featureName.toLowerCase()}_models.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/logging/logger.dart';

class ${className}RemoteDataSource {
  ${className}RemoteDataSource();

  Future<List<${className}Model>> getAll() async {
    try {
      Logger.network('Fetching all ${featureName.toLowerCase()}s from API');
      final response = await DioClient.instance.dio.get('/${featureName.toLowerCase()}s');
      
      if (response.statusCode == 200 && response.data != null) {
        final items = (response.data['${featureName.toLowerCase()}s'] as List<dynamic>?)
            ?.map((json) => ${className}Model.fromJson(json))
            .toList() ?? [];
        Logger.network('Retrieved \${items.length} ${featureName.toLowerCase()}s from API');
        return items;
      }
      
      throw Exception('Failed to fetch ${featureName.toLowerCase()}s: \${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching ${featureName.toLowerCase()}s from API', e);
      rethrow;
    }
  }

  Future<${className}Model?> getById(String id) async {
    try {
      Logger.network('Fetching ${featureName.toLowerCase()} by ID from API: \$id');
      final response = await DioClient.instance.dio.get('/${featureName.toLowerCase()}s/\$id');
      
      if (response.statusCode == 200 && response.data != null) {
        return ${className}Model.fromJson(response.data);
      }
      
      if (response.statusCode == 404) {
        return null;
      }
      
      throw Exception('Failed to fetch ${featureName.toLowerCase()}: \${response.statusCode}');
    } catch (e) {
      Logger.error('Error fetching ${featureName.toLowerCase()} by ID from API: \$id', e);
      rethrow;
    }
  }

  Future<${className}Model> create(${className}Model model) async {
    try {
      Logger.network('Creating ${featureName.toLowerCase()} in API');
      final response = await DioClient.instance.dio.post(
        '/${featureName.toLowerCase()}s',
        data: model.toJson(),
      );
      
      if (response.statusCode == 201 && response.data != null) {
        return ${className}Model.fromJson(response.data);
      }
      
      throw Exception('Failed to create ${featureName.toLowerCase()}: \${response.statusCode}');
    } catch (e) {
      Logger.error('Error creating ${featureName.toLowerCase()} in API', e);
      rethrow;
    }
  }

  Future<${className}Model> update(${className}Model model) async {
    try {
      Logger.network('Updating ${featureName.toLowerCase()} in API: \${model.id}');
      final response = await DioClient.instance.dio.put(
        '/${featureName.toLowerCase()}s/\${model.id}',
        data: model.toJson(),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return ${className}Model.fromJson(response.data);
      }
      
      throw Exception('Failed to update ${featureName.toLowerCase()}: \${response.statusCode}');
    } catch (e) {
      Logger.error('Error updating ${featureName.toLowerCase()} in API: \${model.id}', e);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      Logger.network('Deleting ${featureName.toLowerCase()} in API: \$id');
      final response = await DioClient.instance.dio.delete('/${featureName.toLowerCase()}s/\$id');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete ${featureName.toLowerCase()}: \${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error deleting ${featureName.toLowerCase()} in API: \$id', e);
      rethrow;
    }
  }
}
''';

    await _writeFile('$featureDir/data/datasources/${featureName.toLowerCase()}_remote_datasource.dart', content);
  }

  static Future<void> _generateModel(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
class ${className}Model {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  ${className}Model({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ${className}Model.fromJson(Map<String, dynamic> json) {
    return ${className}Model(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ${className}Model copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ${className}Model(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ${className}Model &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode;
  }

  @override
  String toString() {
    return '${className}Model(id: \$id, name: \$name)';
  }
}
''';

    await _writeFile('$featureDir/data/models/${featureName.toLowerCase()}_models.dart', content);
  }

  static Future<void> _generateUseCase(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
import '../entities/${featureName.toLowerCase()}_entity.dart';
import '../repositories/${featureName.toLowerCase()}_repository_interface.dart';
import '../../../core/logging/logger.dart';

class Get${className}sUseCase {
  final ${className}RepositoryInterface _repository;

  Get${className}sUseCase({
    required ${className}RepositoryInterface repository,
  }) : _repository = repository;

  Future<List<${className}Entity>> execute() async {
    Logger.debug('Executing get ${featureName.toLowerCase()}s use case');
    return await _repository.getAll();
  }
}

class Get${className}ByIdUseCase {
  final ${className}RepositoryInterface _repository;

  Get${className}ByIdUseCase({
    required ${className}RepositoryInterface repository,
  }) : _repository = repository;

  Future<${className}Entity?> execute(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    Logger.debug('Executing get ${featureName.toLowerCase()} by ID use case: \$id');
    return await _repository.getById(id);
  }
}

class Create${className}UseCase {
  final ${className}RepositoryInterface _repository;

  Create${className}UseCase({
    required ${className}RepositoryInterface repository,
  }) : _repository = repository;

  Future<${className}Entity> execute(${className}Entity entity) async {
    if (entity.name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    Logger.debug('Executing create ${featureName.toLowerCase()} use case');
    return await _repository.create(entity);
  }
}

class Update${className}UseCase {
  final ${className}RepositoryInterface _repository;

  Update${className}UseCase({
    required ${className}RepositoryInterface repository,
  }) : _repository = repository;

  Future<${className}Entity> execute(${className}Entity entity) async {
    if (entity.id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    if (entity.name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    Logger.debug('Executing update ${featureName.toLowerCase()} use case: \${entity.id}');
    return await _repository.update(entity);
  }
}

class Delete${className}UseCase {
  final ${className}RepositoryInterface _repository;

  Delete${className}UseCase({
    required ${className}RepositoryInterface repository,
  }) : _repository = repository;

  Future<void> execute(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    Logger.debug('Executing delete ${featureName.toLowerCase()} use case: \$id');
    await _repository.delete(id);
  }
}
''';

    await _writeFile('$featureDir/domain/usecases/${featureName.toLowerCase()}_usecases.dart', content);
  }

  static Future<void> _generateProvider(String featureName, String featureDir) async {
    final className = _capitalize(featureName);
    final content = '''
import '../../domain/entities/${featureName.toLowerCase()}_entity.dart';
import '../../domain/usecases/${featureName.toLowerCase()}_usecases.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/state/base_state.dart';
import '../../../core/logging/logger.dart';

class ${className}sProvider extends ListProvider<${className}Entity> {
  final Get${className}sUseCase _get${className}sUseCase;
  final Get${className}ByIdUseCase _get${className}ByIdUseCase;
  final Create${className}UseCase _create${className}UseCase;
  final Update${className}UseCase _update${className}UseCase;
  final Delete${className}UseCase _delete${className}UseCase;

  ${className}sProvider({
    required Get${className}sUseCase get${className}sUseCase,
    required Get${className}ByIdUseCase get${className}ByIdUseCase,
    required Create${className}UseCase create${className}UseCase,
    required Update${className}UseCase update${className}UseCase,
    required Delete${className}UseCase delete${className}UseCase,
  })  : _get${className}sUseCase = get${className}sUseCase,
        _get${className}ByIdUseCase = get${className}ByIdUseCase,
        _create${className}UseCase = create${className}UseCase,
        _update${className}UseCase = update${className}UseCase,
        _delete${className}UseCase = delete${className}UseCase;

  @override
  Future<ListResult<${className}Entity>> fetchData({required int page}) async {
    Logger.debug('Fetching ${featureName.toLowerCase()}s for page: \$page');
    final items = await _get${className}sUseCase.execute();
    
    // Simple pagination simulation
    const pageSize = 20;
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, items.length);
    
    if (startIndex >= items.length) {
      return ListResult(items: [], hasMore: false, page: page);
    }
    
    final pageItems = items.sublist(startIndex, endIndex);
    final hasMore = endIndex < items.length;
    
    return ListResult(
      items: pageItems,
      hasMore: hasMore,
      page: page,
    );
  }

  Future<void> create${className}(${className}Entity entity) async {
    Logger.debug('Creating ${featureName.toLowerCase()}: \${entity.name}');
    await executeAsync(
      () => _create${className}UseCase.execute(entity),
      onSuccess: (created) {
        // Add to current list
        final currentItems = items;
        currentItems.add(created);
        return ListState<${className}Entity>.success(currentItems);
      },
    );
  }

  Future<void> update${className}(${className}Entity entity) async {
    Logger.debug('Updating ${featureName.toLowerCase()}: \${entity.id}');
    await executeAsync(
      () => _update${className}UseCase.execute(entity),
      onSuccess: (updated) {
        // Update in current list
        final currentItems = items;
        final index = currentItems.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          currentItems[index] = updated;
        }
        return ListState<${className}Entity>.success(currentItems);
      },
    );
  }

  Future<void> delete${className}(String id) async {
    Logger.debug('Deleting ${featureName.toLowerCase()}: \$id');
    await executeAsync(
      () => _delete${className}UseCase.execute(id),
      onSuccess: (_) {
        // Remove from current list
        final currentItems = items;
        currentItems.removeWhere((item) => item.id == id);
        return ListState<${className}Entity>.success(currentItems);
      },
    );
  }
}

class ${className}DetailProvider extends BaseProvider<${className}Entity> {
  final Get${className}ByIdUseCase _get${className}ByIdUseCase;

  ${className}DetailProvider({
    required Get${className}ByIdUseCase get${className}ByIdUseCase,
  })  : _get${className}ByIdUseCase = get${className}ByIdUseCase,
        super(DataState<${className}Entity>.initial());

  Future<void> load${className}(String id) async {
    Logger.debug('Loading ${featureName.toLowerCase()} detail: \$id');
    await executeAsync(
      () async {
        final entity = await _get${className}ByIdUseCase.execute(id);
        if (entity == null) {
          throw Exception('${className} not found');
        }
        return entity;
      },
      onSuccess: (entity) => DataState<${className}Entity>.success(entity),
    );
  }

  void clear${className}() {
    Logger.debug('Clearing ${featureName.toLowerCase()} detail');
    updateState(DataState<${className}Entity>.initial());
  }
}
''';

    await _writeFile('$featureDir/presentation/providers/${featureName.toLowerCase()}_provider.dart', content);
  }

  static Future<void> _writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    Logger.debug('Generated file: $path');
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}