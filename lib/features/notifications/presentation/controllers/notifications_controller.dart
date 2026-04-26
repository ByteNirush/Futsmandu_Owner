import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/notification_model.dart';
import '../../service/notifications_api.dart';

enum NotificationsLoadState { idle, loading, loaded, error }

class NotificationsController extends ChangeNotifier {
  final NotificationsApi _api = NotificationsApi();

  NotificationsLoadState _loadState = NotificationsLoadState.idle;
  List<OwnerNotification> _notifications = [];
  int _currentPage = 1;
  bool _hasMore = false;
  String? _errorMessage;

  // Getters
  NotificationsLoadState get loadState => _loadState;
  List<OwnerNotification> get notifications => List.unmodifiable(_notifications);
  List<OwnerNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get hasMore => _hasMore;
  bool get isLoading => _loadState == NotificationsLoadState.loading;
  String? get errorMessage => _errorMessage;

  /// Load notifications (first page or refresh)
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_loadState == NotificationsLoadState.loading) return;

    _loadState = NotificationsLoadState.loading;
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.getNotifications(page: _currentPage);
      _notifications = refresh
          ? response.notifications
          : [..._notifications, ...response.notifications];
      _hasMore = response.hasMore;
      _loadState = NotificationsLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = NotificationsLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;

    _currentPage++;
    await loadNotifications();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = OwnerNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          data: _notifications[index].data,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;

    try {
      await _api.markAllAsRead();
      _notifications = _notifications
          .map((n) => OwnerNotification(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                isRead: true,
                data: n.data,
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh() => loadNotifications(refresh: true);
}
