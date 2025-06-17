# Clean Architecture Documentation

## Architecture Overview

This application follows Clean Architecture principles with a feature-based modular structure.

## Directory Structure

```
lib/
├── core/                    # Shared infrastructure
│   ├── config/             # Configuration management
│   ├── di/                 # Dependency injection
│   ├── logging/            # Logging infrastructure
│   ├── network/            # HTTP client
│   ├── providers/          # Base providers
│   ├── state/              # State management
│   ├── debug/              # Development tools
│   ├── monitoring/         # Performance monitoring
│   └── tools/              # Code generation tools
├── features/               # Feature modules
│   ├── auth/              # Authentication feature
│   │   ├── data/          # Data layer
│   │   ├── domain/        # Business logic
│   │   └── presentation/  # UI layer
│   └── books/             # Books feature
│       ├── data/          # Data layer
│       ├── domain/        # Business logic
│       └── presentation/  # UI layer
├── shared/                # Shared UI components
│   ├── widgets/           # Reusable widgets
│   └── themes/            # App themes
└── main.dart              # Application entry point
```

## Layers Explanation

### Core Layer
- **Configuration**: App settings and environment management
- **DI Container**: Dependency injection for loose coupling
- **Network**: Centralized HTTP client with logging
- **Logging**: Structured logging system
- **State Management**: Base classes for consistent state handling

### Feature Layers

#### Domain Layer (Business Logic)
- **Entities**: Core business objects
- **Repositories**: Interfaces for data access
- **Use Cases**: Business logic implementation

#### Data Layer
- **Models**: Data transfer objects
- **Data Sources**: API and local data access
- **Repository Implementations**: Concrete data access

#### Presentation Layer
- **Providers**: State management with business logic
- **Screens**: Full-screen UI components
- **Widgets**: Feature-specific UI components

## Design Patterns

### Repository Pattern
Abstracts data access to provide a consistent API regardless of data source.

```dart
abstract class BookRepositoryInterface {
  Future<List<BookEntity>> getAll();
  Future<BookEntity?> getById(String id);
}
```

### Provider Pattern
Manages application state and business logic.

```dart
class BooksProvider extends ListProvider<BookEntity> {
  // Implementation with BaseProvider
}
```

### Dependency Injection
Manages object creation and dependencies.

```dart
class ServiceLocator {
  static T get<T>() => _container.get<T>();
}
```

## Data Flow

1. **User Action** → UI Widget
2. **Widget** → Provider method call
3. **Provider** → Use Case execution
4. **Use Case** → Repository interface
5. **Repository** → Data Source (API/Local)
6. **Data Source** → HTTP Client/Database
7. **Response** flows back through the layers
8. **Provider** updates state
9. **UI** rebuilds with new state

## Error Handling

### Centralized Error Management
```dart
class BaseProvider<T> {
  Future<void> executeAsync<R>(
    Future<R> Function() operation, {
    BaseState<T> Function(R)? onSuccess,
  }) async {
    try {
      final result = await operation();
      if (onSuccess != null) {
        updateState(onSuccess(result));
      }
    } catch (e) {
      Logger.error('Operation failed', e);
      updateState(BaseState.error(e.toString()));
    }
  }
}
```

## Testing Strategy

### Unit Tests
- Test all use cases
- Test repository implementations
- Test provider logic

### Widget Tests
- Test UI components
- Test user interactions
- Test state changes

### Integration Tests
- Test complete user flows
- Test API integration
- Test data persistence

## Performance Considerations

### Optimization Techniques
1. **Lazy Loading**: Load data only when needed
2. **Caching**: Cache frequently accessed data
3. **Pagination**: Load data in chunks
4. **State Management**: Minimize unnecessary rebuilds

### Monitoring
- Use PerformanceMonitor for metrics
- Track memory usage
- Monitor network requests
- Analyze startup time

## Code Generation

### Automatic Feature Generation
```dart
await CodeGenerator.generateFeatureModule('newFeature');
```

This generates:
- Complete clean architecture structure
- Repository interfaces and implementations
- Use cases with error handling
- Providers with state management
- Data models with JSON serialization

## Best Practices

### Code Style
- Follow Dart style guidelines
- Use meaningful variable names
- Keep functions small and focused
- Add documentation for public APIs

### Architecture Rules
- Dependencies flow inward (toward domain)
- Domain layer has no external dependencies
- Use interfaces for abstraction
- Implement proper error handling

### State Management
- Use BaseProvider for consistency
- Handle loading states properly
- Implement proper error boundaries
- Avoid direct state mutations