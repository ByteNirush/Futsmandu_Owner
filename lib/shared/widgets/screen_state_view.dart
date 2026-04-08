import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import 'app_card.dart';
import 'empty_state.dart';
import 'loading_skeleton.dart';

enum ScreenUiState { content, loading, empty, error }

class ScreenStateView extends StatelessWidget {
  const ScreenStateView({
    super.key,
    required this.state,
    required this.content,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onRetry,
  });

  final ScreenUiState state;
  final Widget content;
  final String emptyTitle;
  final String emptySubtitle;

  /// Optional callback shown as a "Try Again" button in the error state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ScreenUiState.loading:
        return const LoadingSkeleton();
      case ScreenUiState.empty:
        return EmptyState(title: emptyTitle, subtitle: emptySubtitle);
      case ScreenUiState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(emptySubtitle),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      case ScreenUiState.content:
        return content;
    }
  }
}
