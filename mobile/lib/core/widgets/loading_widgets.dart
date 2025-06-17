import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingSpinner({
    super.key,
    this.size = 24.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return spinner;
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(AppSpacing.xl),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: LoadingSpinner(
                    size: 32.0,
                    message: loadingMessage,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingListTile extends StatelessWidget {
  const LoadingListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: const LoadingSpinner(size: 20),
      ),
      title: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  final double? height;
  final double? width;

  const LoadingCard({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height ?? 200,
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}