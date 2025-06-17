import 'package:flutter/material.dart';
import '../state/base_state.dart';
import 'loading_widgets.dart';
import 'error_widgets.dart';

class StateBuilder<T> extends StatelessWidget {
  final BaseState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final bool showLoadingOverlay;

  const StateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.showLoadingOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isError) {
      return errorBuilder?.call(context, state.errorMessage ?? 'An error occurred') ??
          ErrorDisplay(
            message: state.errorMessage ?? 'An error occurred',
            onRetry: onRetry,
          );
    }

    if (state.isLoading && !state.hasData) {
      return loadingBuilder?.call(context) ?? const Center(child: LoadingSpinner());
    }

    if (!state.hasData) {
      return emptyBuilder?.call(context) ??
          const EmptyState(
            title: 'No Data',
            message: 'No data available to display',
          );
    }

    final content = builder(context, state.data!);

    if (showLoadingOverlay && state.isLoading) {
      return LoadingOverlay(
        isLoading: true,
        child: content,
      );
    }

    return content;
  }
}

class ListStateBuilder<T> extends StatelessWidget {
  final ListState<T> state;
  final Widget Function(BuildContext context, List<T> items) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final bool showLoadingOverlay;

  const ListStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onRetry,
    this.onLoadMore,
    this.showLoadingOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isError && !state.hasData) {
      return errorBuilder?.call(context, state.errorMessage ?? 'An error occurred') ??
          ErrorDisplay(
            message: state.errorMessage ?? 'An error occurred',
            onRetry: onRetry,
          );
    }

    if (state.isLoading && !state.hasData) {
      return loadingBuilder?.call(context) ?? 
          ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const LoadingListTile(),
          );
    }

    final items = state.data ?? [];

    if (items.isEmpty && !state.isLoading) {
      return emptyBuilder?.call(context) ??
          const EmptyState(
            title: 'No Items',
            message: 'No items available to display',
          );
    }

    Widget content = builder(context, items);

    // Add load more functionality for lists
    if (onLoadMore != null && state.hasMore) {
      content = NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !state.isLoading) {
            onLoadMore!();
          }
          return false;
        },
        child: content,
      );
    }

    if (showLoadingOverlay && state.isRefreshing) {
      return LoadingOverlay(
        isLoading: true,
        loadingMessage: 'Refreshing...',
        child: content,
      );
    }

    return content;
  }
}

class RefreshableStateBuilder<T> extends StatelessWidget {
  final BaseState<T> state;
  final Widget Function(BuildContext context, T data) builder;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  const RefreshableStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    required this.onRefresh,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: StateBuilder<T>(
        state: state,
        builder: builder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        emptyBuilder: emptyBuilder,
        onRetry: () => onRefresh(),
      ),
    );
  }
}