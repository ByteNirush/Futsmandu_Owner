import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/components/empty_state/empty_state.dart';

import '../../core/design_system/app_spacing.dart';
import 'app_card.dart';
import 'loading_skeleton.dart';

enum ScreenUiState { content, loading, empty, error }

/// A widget that displays different UI states (loading, empty, error, content).
///
/// Now supports enhanced empty states with built-in illustrations via [emptyStateType].
/// If [emptyStateType] is provided, it will use the design system's [EmptyStateWidget]
/// with the corresponding illustration. Otherwise, a basic empty state is shown.
///
/// Example with enhanced illustration:
/// ```dart
/// ScreenStateView(
///   state: _screenState,
///   content: MyContent(),
///   emptyTitle: 'No Notifications',
///   emptySubtitle: 'You\'ll see updates here.',
///   emptyStateType: EmptyStateType.noNotifications,
///   onRetry: _refresh,
/// )
/// ```
class ScreenStateView extends StatelessWidget {
  const ScreenStateView({
    super.key,
    required this.state,
    required this.content,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onRetry,
    this.emptyStateType,
  });

  final ScreenUiState state;
  final Widget content;
  final String emptyTitle;
  final String emptySubtitle;

  /// Optional callback shown as a "Try Again" button in the error state.
  final VoidCallback? onRetry;

  /// Optional predefined empty state type with illustration.
  /// If provided, uses the enhanced [EmptyStateWidget] from design system.
  final EmptyStateType? emptyStateType;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ScreenUiState.loading:
        return const LoadingSkeleton();
      case ScreenUiState.empty:
        // Use enhanced empty state with illustration if type is provided
        if (emptyStateType != null) {
          return EmptyStateWidget(
            type: emptyStateType,
            action: onRetry != null
                ? TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  )
                : null,
          );
        }
        // Fallback to basic empty state
        return _BasicEmptyState(
          title: emptyTitle,
          subtitle: emptySubtitle,
        );
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

/// Basic empty state fallback without illustrations.
class _BasicEmptyState extends StatelessWidget {
  const _BasicEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
