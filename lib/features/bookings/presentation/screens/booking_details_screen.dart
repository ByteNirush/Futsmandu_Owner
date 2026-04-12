import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_bookings_api.dart';

class BookingAttendanceUpdate {
  const BookingAttendanceUpdate({
    required this.bookingId,
    required this.isNoShow,
  });

  final String bookingId;
  final bool isNoShow;
}

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.date,
    this.courtId,
    this.state = ScreenUiState.content,
  });

  final String bookingId;
  final DateTime date;
  final String? courtId;
  final ScreenUiState state;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final OwnerBookingsApi _bookingsApi = OwnerBookingsApi();
  bool _isLoading = true;
  bool _isSavingAttendance = false;
  String? _errorMessage;
  BookingListItem? _booking;
  bool _markNoShow = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await _bookingsApi.listBookings(
        date: widget.date,
        courtId: widget.courtId,
      );
      final booking = page.items.where((item) => item.id == widget.bookingId).firstOrNull;

      if (!mounted) return;
      if (booking == null) {
        setState(() {
          _errorMessage = 'Booking not found for the selected date.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _booking = booking;
        _markNoShow = booking.status.toUpperCase() == 'NO_SHOW';
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load booking details.';
        _isLoading = false;
      });
    }
  }

  String _toDate(DateTime? date) {
    if (date == null) return '--';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _to12Hour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    final period = hour >= 12 ? 'PM' : 'AM';
    final adjusted = hour % 12 == 0 ? 12 : hour % 12;
    return '${adjusted.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _toAmount(int amount) => 'NPR ${(amount / 100).toStringAsFixed(0)}';

  Future<void> _saveAttendance() async {
    final booking = _booking;
    if (booking == null || _isSavingAttendance) return;

    final noShowIds = <String>[];
    if (_markNoShow && booking.playerId != null && booking.playerId!.isNotEmpty) {
      noShowIds.add(booking.playerId!);
    }

    setState(() => _isSavingAttendance = true);

    try {
      final result = await _bookingsApi.markAttendance(
        bookingId: booking.id,
        noShowIds: noShowIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.of(context).pop(
        BookingAttendanceUpdate(
          bookingId: booking.id,
          isNoShow: _markNoShow,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save attendance.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingAttendance = false);
      }
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: AppLoader()),
      );
    }

    final booking = _booking;
    final state = widget.state == ScreenUiState.content
        ? (_errorMessage != null || booking == null ? ScreenUiState.error : ScreenUiState.content)
        : widget.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ScreenStateView(
        state: state,
        emptyTitle: 'No booking details',
        emptySubtitle: _errorMessage ?? 'Booking details will appear here.',
        onRetry: _loadBooking,
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.sports_soccer, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking?.offlineCustomerName ?? booking?.playerName ?? 'Customer',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              booking?.status ?? '-',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: AppFontWeights.semiBold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _toDate(booking?.bookingDate),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value: '${_to12Hour(booking?.startTime ?? '--')} - ${_to12Hour(booking?.endTime ?? '--')}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Court',
                    value: booking?.courtName ?? '-',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(
                    icon: Icons.payments_outlined,
                    label: 'Amount',
                    value: _toAmount(booking?.totalAmount ?? 0),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: booking?.offlineCustomerPhone ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (booking?.playerId != null && booking!.playerId!.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: AppFontWeights.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      value: _markNoShow,
                      onChanged: (value) => setState(() => _markNoShow = value),
                      title: Text(
                        _markNoShow ? 'Mark as no-show' : 'Marked as attended',
                      ),
                      subtitle: Text(booking.playerName ?? 'Player'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _isSavingAttendance ? 'Saving...' : 'Save Attendance',
              icon: Icons.verified_outlined,
              onPressed: _isSavingAttendance ? null : _saveAttendance,
            ),
          ],
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
