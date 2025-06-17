import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../logging/logger.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository_interface.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider_new.dart';
import '../../features/books/data/datasources/book_remote_datasource.dart';
import '../../features/books/data/repositories/book_repository.dart';
import '../../features/books/domain/repositories/book_repository_interface.dart';
import '../../features/books/domain/usecases/get_books_usecase.dart';
import '../../features/books/presentation/providers/books_provider.dart';
import '../../services/unified_tts_service.dart';
import '../../services/unified_swipe_service.dart';

class _SimpleDI {
  final Map<Type, dynamic> _singletons = {};
  final Map<Type, Function> _factories = {};

  T get<T>() {
    final type = T;
    
    // Check singletons first
    if (_singletons.containsKey(type)) {
      return _singletons[type] as T;
    }
    
    // Check factories
    if (_factories.containsKey(type)) {
      return _factories[type]!() as T;
    }
    
    throw Exception('Type $type not registered in DI container');
  }

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T];
    };
  }

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  bool isRegistered<T>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  void reset() {
    _singletons.clear();
    _factories.clear();
  }
}

final _SimpleDI sl = _SimpleDI();

class ServiceLocator {
  static Future<void> init() async {
    Logger.info('Initializing Service Locator');

    // Core
    await _initCore();
    
    // External
    await _initExternal();
    
    // Data Sources
    _initDataSources();
    
    // Repositories
    _initRepositories();
    
    // Use Cases
    _initUseCases();
    
    // Providers
    _initProviders();
    
    Logger.info('Service Locator initialization completed');
  }

  static Future<void> _initCore() async {
    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);

    // DioClient
    sl.registerLazySingleton(() => DioClient.instance);
    
    // Configure base URL
    DioClient.instance.updateBaseUrl(AppConfig.instance.apiBaseUrl);
  }

  static Future<void> _initExternal() async {
    // Services
    sl.registerLazySingleton(() => UnifiedTtsService());
    sl.registerFactory(() => UnifiedSwipeService.full(sl<SharedPreferences>()));
  }

  static void _initDataSources() {
    // Auth
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(),
    );

    // Books
    sl.registerLazySingleton<BookRemoteDataSource>(
      () => BookRemoteDataSource(),
    );
  }

  static void _initRepositories() {
    // Auth
    sl.registerLazySingleton<AuthRepositoryInterface>(
      () => AuthRepository(
        remoteDataSource: sl<AuthRemoteDataSource>(),
      ),
    );

    // Books
    sl.registerLazySingleton<BookRepositoryInterface>(
      () => BookRepository(
        remoteDataSource: sl<BookRemoteDataSource>(),
      ),
    );
  }

  static void _initUseCases() {
    // Auth Use Cases
    sl.registerLazySingleton(() => SignInUseCase(
      repository: sl<AuthRepositoryInterface>(),
    ));

    sl.registerLazySingleton(() => SignUpUseCase(
      repository: sl<AuthRepositoryInterface>(),
    ));

    sl.registerLazySingleton(() => SignOutUseCase(
      repository: sl<AuthRepositoryInterface>(),
    ));

    // Books Use Cases
    sl.registerLazySingleton(() => GetBooksUseCase(
      repository: sl<BookRepositoryInterface>(),
    ));

    sl.registerLazySingleton(() => GetRecommendationsUseCase(
      repository: sl<BookRepositoryInterface>(),
    ));

    sl.registerLazySingleton(() => SearchBooksUseCase(
      repository: sl<BookRepositoryInterface>(),
    ));

    sl.registerLazySingleton(() => GetBookByIdUseCase(
      repository: sl<BookRepositoryInterface>(),
    ));
  }

  static void _initProviders() {
    // Auth Provider
    sl.registerFactory(() => AuthProviderNew(
      signInUseCase: sl<SignInUseCase>(),
      signUpUseCase: sl<SignUpUseCase>(),
      signOutUseCase: sl<SignOutUseCase>(),
      authDataSource: sl<AuthRemoteDataSource>(),
    ));

    // Books Provider
    sl.registerFactory(() => BooksProvider(
      getBooksUseCase: sl<GetBooksUseCase>(),
      getRecommendationsUseCase: sl<GetRecommendationsUseCase>(),
      searchBooksUseCase: sl<SearchBooksUseCase>(),
    ));

    sl.registerFactory(() => BookDetailProvider(
      getBookByIdUseCase: sl<GetBookByIdUseCase>(),
    ));
  }

  static Future<void> reset() async {
    Logger.warning('Resetting Service Locator');
    await sl.reset();
  }

  static T get<T extends Object>() {
    return sl.get<T>();
  }

  static T call<T extends Object>() {
    return sl<T>();
  }

  static bool isRegistered<T extends Object>() {
    return sl.isRegistered<T>();
  }
}

// 便利なアクセサー
class DI {
  static T get<T extends Object>() => ServiceLocator.get<T>();
  static T call<T extends Object>() => ServiceLocator.call<T>();
}