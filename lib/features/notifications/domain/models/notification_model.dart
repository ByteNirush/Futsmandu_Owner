import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';

/// Owner notification model
/// Maps to the notification types defined in the backend
enum OwnerNotificationType {
  newBooking,
  bookingCancelled,
  paymentReceived,
  newReview,
  verificationApproved,
  verificationRejected,
  unknown,
}

class OwnerNotification {
  final String id;
  final OwnerNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const OwnerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory OwnerNotification.fromJson(Map<String, dynamic> json) {
    return OwnerNotification(
      id: json['id'] as String,
      type: _parseType(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  static OwnerNotificationType _parseType(String? type) {
    return switch (type) {
      'NEW_BOOKING' => OwnerNotificationType.newBooking,
      'BOOKING_CANCELLED' => OwnerNotificationType.bookingCancelled,
      'PAYMENT_RECEIVED' => OwnerNotificationType.paymentReceived,
      'NEW_REVIEW' => OwnerNotificationType.newReview,
      'VERIFICATION_APPROVED' => OwnerNotificationType.verificationApproved,
      'VERIFICATION_REJECTED' => OwnerNotificationType.verificationRejected,
      _ => OwnerNotificationType.unknown,
    };
  }

  IconData get icon => switch (type) {
    OwnerNotificationType.newBooking => Icons.calendar_today_rounded,
    OwnerNotificationType.bookingCancelled => Icons.cancel_rounded,
    OwnerNotificationType.paymentReceived => Icons.payments_rounded,
    OwnerNotificationType.newReview => Icons.star_rounded,
    OwnerNotificationType.verificationApproved => Icons.verified_rounded,
    OwnerNotificationType.verificationRejected => Icons.error_outline_rounded,
    OwnerNotificationType.unknown => Icons.notifications_outlined,
  };

  Color get iconColor => switch (type) {
    OwnerNotificationType.newBooking => AppColors.info,
    OwnerNotificationType.bookingCancelled => AppColors.danger,
    OwnerNotificationType.paymentReceived => AppColors.success,
    OwnerNotificationType.newReview => AppColors.warning,
    OwnerNotificationType.verificationApproved => AppColors.success,
    OwnerNotificationType.verificationRejected => AppColors.warning,
    OwnerNotificationType.unknown => AppColors.secondary,
  };
}

class NotificationListResponse {
  final List<OwnerNotification> notifications;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasMore;

  const NotificationListResponse({
    required this.notifications,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasMore,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return NotificationListResponse(
      notifications: data
          .map((e) => OwnerNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['page'] as int? ?? 1,
      totalPages: (meta['total'] as int? ?? 0) ~/ 20 + 1,
      totalCount: meta['total'] as int? ?? 0,
      hasMore: (meta['total'] as int? ?? 0) > ((meta['page'] as int? ?? 1) * 20),
    );
  }
}
