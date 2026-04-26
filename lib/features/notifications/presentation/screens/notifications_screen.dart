import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/components/empty_state/empty_state.dart';
import 'package:futsmandu_design_system/core/theme/app_radius.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../bookings/presentation/screens/booking_details_screen.dart';
import '../../domain/models/notification_model.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsController _controller = NotificationsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadNotifications();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  ScreenUiState get _screenState {
    switch (_controller.loadState) {
      case NotificationsLoadState.idle:
      case NotificationsLoadState.loading:
        return ScreenUiState.loading;
      case NotificationsLoadState.error:
        return ScreenUiState.error;
      case NotificationsLoadState.loaded:
        return _controller.notifications.isEmpty
            ? ScreenUiState.empty
            : ScreenUiState.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _controller.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _controller.markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: ScreenStateView(
        state: _screenState,
        content: RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: _controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = _controller.notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _onNotificationTap(notification),
              );
            },
          ),
        ),
        emptyTitle: 'No notifications',
        emptySubtitle: 'You\'ll see booking updates, payments, and reviews here.',
        emptyStateType: EmptyStateType.noNotifications,
        onRetry: _controller.refresh,
      ),
    );
  }

  void _onNotificationTap(OwnerNotification notification) {
    if (!notification.isRead) {
      _controller.markAsRead(notification.id);
    }

    // Navigate based on notification type and data
    final data = notification.data;
    if (data == null) return;

    final screen = data['screen'] as String?;
    switch (screen) {
      case 'BookingDetail':
        final bookingId = data['bookingId'] as String?;
        final bookingDate = data['bookingDate'] as String?;
        if (bookingId != null) {
          final date = bookingDate != null
              ? DateTime.tryParse(bookingDate) ?? DateTime.now()
              : DateTime.now();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingDetailsScreen(
                bookingId: bookingId,
                date: date,
              ),
            ),
          );
        }
        break;
      case 'Analytics':
        // TODO: Navigate to analytics/revenue screen
        // Navigator.of(context).pushNamed('/analytics');
        break;
      case 'Reviews':
        final venueId = data['venueId'] as String?;
        if (venueId != null) {
          // TODO: Navigate to reviews screen
          // Navigator.of(context).pushNamed('/venues/$venueId/reviews');
        }
        break;
      case 'VenueDetail':
        final venueId = data['venueId'] as String?;
        final venueData = data['venue'] as Map<String, dynamic>?;
        if (venueId != null && venueData != null) {
          // TODO: Parse venue data and navigate to VenueDetailsScreen
          // Requires: Venue venue = Venue.fromJson(venueData);
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (_) => VenueDetailsScreen(venue: venue),
          // ));
        }
        break;
      case 'VerificationDocs':
        Navigator.of(context).pushNamed('/upload-documents');
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final OwnerNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: AppSpacing.xl + 4,
                height: AppSpacing.xl + 4,
                decoration: BoxDecoration(
                  color: notification.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.iconColor,
                  size: AppSpacing.md - 2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? AppFontWeights.medium
                                  : AppFontWeights.semiBold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: AppSpacing.sm - 8,
                            height: AppSpacing.sm - 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      notification.body,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
