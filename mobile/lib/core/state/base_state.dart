import '../../core/logging/logger.dart';

enum LoadingState { initial, loading, success, error }

abstract class BaseState<T> {
  final LoadingState loadingState;
  final T? data;
  final String? errorMessage;
  final DateTime lastUpdated;

  const BaseState({
    required this.loadingState,
    this.data,
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated =
           lastUpdated ?? const DateTime.fromMillisecondsSinceEpoch(0);

  bool get isInitial => loadingState == LoadingState.initial;
  bool get isLoading => loadingState == LoadingState.loading;
  bool get isSuccess => loadingState == LoadingState.success;
  bool get isError => loadingState == LoadingState.error;
  bool get hasData => data != null;

  BaseState<T> copyWith({
    LoadingState? loadingState,
    T? data,
    String? errorMessage,
    DateTime? lastUpdated,
  });

  @override
  String toString() {
    return '$runtimeType(loadingState: $loadingState, hasData: $hasData, errorMessage: $errorMessage)';
  }
}

class DataState<T> extends BaseState<T> {
  const DataState({
    required super.loadingState,
    super.data,
    super.errorMessage,
    super.lastUpdated,
  });

  factory DataState.initial() {
    return const DataState(loadingState: LoadingState.initial);
  }

  factory DataState.loading([T? currentData]) {
    return DataState(loadingState: LoadingState.loading, data: currentData);
  }

  factory DataState.success(T data) {
    return DataState(
      loadingState: LoadingState.success,
      data: data,
      lastUpdated: DateTime.now(),
    );
  }

  factory DataState.error(String errorMessage, [T? currentData]) {
    Logger.error('DataState error: $errorMessage');
    return DataState(
      loadingState: LoadingState.error,
      data: currentData,
      errorMessage: errorMessage,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  DataState<T> copyWith({
    LoadingState? loadingState,
    T? data,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return DataState(
      loadingState: loadingState ?? this.loadingState,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ListState<T> extends BaseState<List<T>> {
  final bool hasMore;
  final int currentPage;
  final bool isRefreshing;

  const ListState({
    required super.loadingState,
    super.data,
    super.errorMessage,
    super.lastUpdated,
    this.hasMore = false,
    this.currentPage = 0,
    this.isRefreshing = false,
  });

  factory ListState.initial() {
    return const ListState(loadingState: LoadingState.initial, data: []);
  }

  factory ListState.loading([List<T>? currentData]) {
    return ListState(
      loadingState: LoadingState.loading,
      data: currentData ?? [],
    );
  }

  factory ListState.loadingMore(List<T> currentData, int currentPage) {
    return ListState(
      loadingState: LoadingState.loading,
      data: currentData,
      currentPage: currentPage,
    );
  }

  factory ListState.refreshing(List<T> currentData) {
    return ListState(
      loadingState: LoadingState.loading,
      data: currentData,
      isRefreshing: true,
    );
  }

  factory ListState.success(
    List<T> data, {
    bool hasMore = false,
    int currentPage = 0,
  }) {
    return ListState(
      loadingState: LoadingState.success,
      data: data,
      hasMore: hasMore,
      currentPage: currentPage,
      lastUpdated: DateTime.now(),
    );
  }

  factory ListState.error(String errorMessage, [List<T>? currentData]) {
    Logger.error('ListState error: $errorMessage');
    return ListState(
      loadingState: LoadingState.error,
      data: currentData ?? [],
      errorMessage: errorMessage,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  ListState<T> copyWith({
    LoadingState? loadingState,
    List<T>? data,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? hasMore,
    int? currentPage,
    bool? isRefreshing,
  }) {
    return ListState(
      loadingState: loadingState ?? this.loadingState,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    return 'ListState(loadingState: $loadingState, itemCount: ${data?.length ?? 0}, hasMore: $hasMore, currentPage: $currentPage, isRefreshing: $isRefreshing)';
  }
}
