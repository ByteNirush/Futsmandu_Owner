import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/owner_api_client.dart';
import '../domain/models/notification_model.dart';

/// Notifications API service for owners
/// 
/// Backend endpoints (to be implemented in owner-api):
/// - GET /notifications?page=&limit= - List notifications
/// - PUT /notifications/:id/read - Mark one as read
/// - PUT /notifications/read-all - Mark all as read
///
/// Currently the backend only sends FCM push notifications.
/// This service will work once the backend adds the NotificationController.
class NotificationsApi {
  NotificationsApi({OwnerApiClient? apiClient})
      : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  /// Get owner notifications with pagination
  /// 
  /// Calls: GET /notifications?page=&limit=
  Future<NotificationListResponse> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final result = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      // Handle both wrapped and unwrapped responses
      final data = result['data'] ?? result;
      final meta = result['meta'] ?? {
        'page': page,
        'total': (data is List) ? data.length : 0,
      };

      return NotificationListResponse.fromJson({
        'data': data,
        'meta': meta,
      });
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      // Return empty response - backend endpoint not ready yet
      return const NotificationListResponse(
        notifications: [],
        currentPage: 1,
        totalPages: 0,
        totalCount: 0,
        hasMore: false,
      );
    }
  }

  /// Mark a single notification as read
  /// 
  /// Calls: PUT /notifications/:id/read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.put(
        '/notifications/$notificationId/read',
        data: {},
      );
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      // Silently fail - backend endpoint may not be ready
    }
  }

  /// Mark all notifications as read
  /// 
  /// Calls: PUT /notifications/read-all
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.put(
        '/notifications/read-all',
        data: {},
      );
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      // Silently fail - backend endpoint may not be ready
    }
  }
}
