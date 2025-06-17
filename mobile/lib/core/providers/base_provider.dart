import 'package:flutter/material.dart';
import '../state/base_state.dart';
import '../logging/logger.dart';

abstract class BaseProvider<T> extends ChangeNotifier {
  BaseState<T> _state;

  BaseProvider(BaseState<T> initialState) : _state = initialState;

  BaseState<T> get state => _state;
  bool get isLoading => _state.isLoading;
  bool get isError => _state.isError;
  bool get hasData => _state.hasData;
  T? get data => _state.data;
  String? get errorMessage => _state.errorMessage;

  void updateState(BaseState<T> newState) {
    final oldState = _state.loadingState;
    _state = newState;
    
    if (oldState != newState.loadingState) {
      Logger.ui('State changed in ${runtimeType}: ${oldState.name} -> ${newState.loadingState.name}');
    }
    
    notifyListeners();
  }

  void clearError() {
    if (_state.isError) {
      updateState(_state.copyWith(
        loadingState: LoadingState.initial,
        errorMessage: null,
      ));
    }
  }

  Future<void> executeAsync<R>(
    Future<R> Function() operation, {
    required BaseState<T> Function(R result) onSuccess,
    BaseState<T> Function(String error)? onError,
    bool keepCurrentData = true,
  }) async {
    try {
      // Set loading state
      if (keepCurrentData) {
        updateState(_state.copyWith(loadingState: LoadingState.loading));
      } else {
        updateState(_createLoadingState());
      }

      // Execute operation
      final result = await operation();
      
      // Set success state
      updateState(onSuccess(result));
    } catch (e) {
      Logger.error('Operation failed in ${runtimeType}', e);
      
      // Set error state
      if (onError != null) {
        updateState(onError(e.toString()));
      } else {
        updateState(_createErrorState(e.toString()));
      }
    }
  }

  BaseState<T> _createLoadingState() {
    if (_state is ListState<dynamic>) {
      return ListState<dynamic>.loading() as BaseState<T>;
    } else {
      return DataState<T>.loading();
    }
  }

  BaseState<T> _createErrorState(String error) {
    if (_state is ListState<dynamic>) {
      return ListState<dynamic>.error(error, _state.data) as BaseState<T>;
    } else {
      return DataState<T>.error(error, _state.data);
    }
  }

  @override
  void dispose() {
    Logger.ui('Disposing ${runtimeType}');
    super.dispose();
  }
}

abstract class ListProvider<T> extends BaseProvider<List<T>> {
  ListProvider() : super(ListState<T>.initial());

  ListState<T> get listState => _state as ListState<T>;
  List<T> get items => _state.data ?? [];
  bool get hasMore => listState.hasMore;
  bool get isRefreshing => listState.isRefreshing;
  int get currentPage => listState.currentPage;

  Future<void> loadData({bool refresh = false}) async {
    if (refresh) {
      updateState(ListState<T>.refreshing(items));
    }
    
    await executeAsync(
      () => fetchData(page: refresh ? 0 : currentPage + 1),
      onSuccess: (result) {
        final newItems = refresh ? result.items : [...items, ...result.items];
        return ListState<T>.success(
          newItems,
          hasMore: result.hasMore,
          currentPage: result.page,
        );
      },
    );
  }

  Future<void> refresh() async {
    await loadData(refresh: true);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;
    await loadData();
  }

  Future<ListResult<T>> fetchData({required int page});
}

class ListResult<T> {
  final List<T> items;
  final bool hasMore;
  final int page;

  ListResult({
    required this.items,
    required this.hasMore,
    required this.page,
  });
}