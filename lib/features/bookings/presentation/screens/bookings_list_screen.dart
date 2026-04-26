import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_bookings_api.dart';
import '../../data/owner_courts_api.dart';
import '../widgets/time_slot_item.dart';
import 'booking_details_screen.dart';
import 'create_offline_booking_screen.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  final OwnerCourtsApi _courtsApi = OwnerCourtsApi();
  final OwnerBookingsApi _bookingsApi = OwnerBookingsApi();
  late final TabController _tabController;
  List<_CourtOption> _courts = const [];
  final Map<String, String> _attendanceBadgeOverrides = {};

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String? _selectedCourtId;
  String? _selectedListStatus;
  ScreenUiState _uiState = ScreenUiState.loading;
  ScreenUiState _listUiState = ScreenUiState.loading;
  List<CourtCalendarSlot> _slots = const [];
  List<BookingListItem> _bookings = const [];
  String? _errorMessage;
  String? _listErrorMessage;
  bool _isRefreshingCalendar = false;
  bool _isRefreshingList = false;
  int _listPage = 1;
  int _listTotalPages = 1;
  int _listTotalItems = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _bootstrap() async {
    setState(() {
      _uiState = ScreenUiState.loading;
      _errorMessage = null;
    });

    try {
      final ownerCourts = await _courtsApi.listOwnerCourts();
      if (!mounted) return;

      if (ownerCourts.isEmpty) {
        setState(() {
          _courts = const [];
          _selectedCourtId = null;
          _slots = const [];
          _uiState = ScreenUiState.empty;
          _errorMessage =
              'No courts found. Add at least one court in Venue Management.';
        });
        return;
      }

      setState(() {
        _courts = ownerCourts
            .map((court) => _CourtOption(id: court.id, name: court.name))
            .toList(growable: false);
        _selectedCourtId = _courts.first.id;
      });

      await Future.wait([
        _loadCalendar(showLoading: true),
        _loadBookingsList(showLoading: true),
      ]);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _uiState = ScreenUiState.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load your courts.';
        _uiState = ScreenUiState.error;
      });
    }
  }

  Future<void> _loadCalendar({bool showLoading = false}) async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) {
      setState(() {
        _slots = const [];
        _uiState = ScreenUiState.empty;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      if (showLoading || _slots.isEmpty) {
        _uiState = ScreenUiState.loading;
      } else {
        _isRefreshingCalendar = true;
      }
    });

    try {
      final response = await _bookingsApi.getCourtCalendar(
        courtId: courtId,
        date: _selectedDay,
      );

      if (!mounted) return;
      setState(() {
        _slots = response.slots;
        _isRefreshingCalendar = false;
        _uiState = response.slots.isEmpty
            ? ScreenUiState.empty
            : ScreenUiState.content;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshingCalendar = false;
        _errorMessage = error.message;
        _uiState = ScreenUiState.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRefreshingCalendar = false;
        _errorMessage = 'Failed to load court calendar.';
        _uiState = ScreenUiState.error;
      });
    }
  }

  Future<void> _loadBookingsList({
    bool showLoading = false,
    int page = 1,
  }) async {
    setState(() {
      _listErrorMessage = null;
      if (showLoading || _bookings.isEmpty) {
        _listUiState = ScreenUiState.loading;
      } else {
        _isRefreshingList = true;
      }
    });

    try {
      final bookingsPage = await _bookingsApi.listBookings(
        date: _selectedDay,
        courtId: _selectedCourtId,
        status: _selectedListStatus,
        page: page,
      );

      if (!mounted) return;
      setState(() {
        _bookings = bookingsPage.items;
        _listPage = bookingsPage.page;
        _listTotalPages = bookingsPage.totalPages;
        _listTotalItems = bookingsPage.total;
        _isRefreshingList = false;
        _listUiState =
            bookingsPage.items.isEmpty ? ScreenUiState.empty : ScreenUiState.content;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshingList = false;
        _listErrorMessage = error.message;
        _listUiState = ScreenUiState.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRefreshingList = false;
        _listErrorMessage = 'Failed to load bookings list.';
        _listUiState = ScreenUiState.error;
      });
    }
  }

  String _to12Hour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;

    final period = hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _onSlotTap(CourtCalendarSlot slot, SlotStatus status) async {
    if (status == SlotStatus.booked) {
      if (slot.bookingId == null || slot.bookingId!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking identifier not available.')),
        );
        return;
      }

      if (!mounted) return;
      final changed = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            bookingId: slot.bookingId!,
            date: _selectedDay,
            courtId: _selectedCourtId,
          ),
        ),
      );

      if (changed is BookingAttendanceUpdate) {
        setState(() {
          _attendanceBadgeOverrides[changed.bookingId] =
              changed.isNoShow ? 'No-Show' : 'Attended';
        });
      }

      if (changed == true || changed is BookingAttendanceUpdate) {
        await _loadCalendar();
        await _loadBookingsList(page: _listPage);
      }
      return;
    }

    if (status == SlotStatus.available) {
      final action = await _showAvailableSlotActions(slot);
      if (action == null) {
        return;
      }

      if (action == _AvailableSlotAction.block) {
        await _blockSlot(slot);
        return;
      }

      final courtId = _selectedCourtId;
      if (courtId == null || courtId.isEmpty) return;
      if (!mounted) return;
      final created = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateOfflineBookingScreen(
            initialCourtId: courtId,
            initialDate: _selectedDay,
            initialStartTime: slot.startTime,
          ),
        ),
      );
      if (created != null) {
        await _loadCalendar();
        await _loadBookingsList(page: 1);
      }
      return;
    }

    if (status == SlotStatus.blocked) {
      await _unblockSlot(slot);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This slot is already reserved.')),
    );
  }

  Future<_AvailableSlotAction?> _showAvailableSlotActions(
    CourtCalendarSlot slot,
  ) {
    return showModalBottomSheet<_AvailableSlotAction>(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Create Offline Booking'),
              subtitle: Text(
                '${_to12Hour(slot.startTime)} - ${_to12Hour(slot.endTime)}',
              ),
              onTap: () {
                Navigator.of(
                  bottomSheetContext,
                ).pop(_AvailableSlotAction.book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Block Slot'),
              subtitle: const Text('Mark this time as unavailable'),
              onTap: () {
                Navigator.of(
                  bottomSheetContext,
                ).pop(_AvailableSlotAction.block);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  Future<_BlockSlotResult?> _promptBlockDetails() async {
    return showDialog<_BlockSlotResult>(
      context: context,
      builder: (_) => const _BlockSlotDialog(),
    );
  }

  Future<void> _blockSlot(CourtCalendarSlot slot) async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) {
      return;
    }

    final result = await _promptBlockDetails();
    if (!mounted || result == null) {
      return;
    }

    try {
      await _bookingsApi.blockCourtSlot(
        courtId: courtId,
        date: _selectedDay,
        startTime: slot.startTime,
        blockType: result.blockType,
        note: result.note,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Slot ${_to12Hour(slot.startTime)} blocked successfully.',
          ),
        ),
      );
      await _loadCalendar();
      await _loadBookingsList(page: 1);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('Block slot API error: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.message}')),
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      debugPrint('Block slot error: $error');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block slot: $error')),
      );
    }
  }

  Future<void> _unblockSlot(CourtCalendarSlot slot) async {
    final blockId = slot.idForUnblock;
    if (blockId == null || blockId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Block identifier is not available.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unblock Slot?'),
        content: Text(
          'This will reopen ${_to12Hour(slot.startTime)} - ${_to12Hour(slot.endTime)} for booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _bookingsApi.unblockCourtSlot(blockId: blockId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot ${_to12Hour(slot.startTime)} is now available.'),
        ),
      );
      await _loadCalendar();
      await _loadBookingsList(page: 1);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unblock slot.')),
      );
    }
  }

  SlotStatus _mapSlotStatus(CourtCalendarSlot slot) {
    final normalizedStatus = slot.status.toUpperCase();
    if (normalizedStatus == 'AVAILABLE') {
      return SlotStatus.available;
    }
    if (slot.isBlocked) {
      return SlotStatus.blocked;
    }
    return SlotStatus.booked;
  }

  String? _displayPrice(CourtCalendarSlot slot) {
    if (slot.displayPrice != null && slot.displayPrice!.isNotEmpty) {
      return slot.displayPrice;
    }
    if (slot.price != null) {
      return 'NPR ${slot.price}';
    }
    return null;
  }

  List<Widget> _buildSlots() {
    return _slots.map((slot) {
      final status = _mapSlotStatus(slot);
      final normalizedBookingStatus = _displayBookingStatus(slot.status);
      final attendanceBadge = _attendanceBadgeForSlot(slot);
      return TimeSlotItem(
        startTime: _to12Hour(slot.startTime),
        endTime: _to12Hour(slot.endTime),
        status: status,
        teamName: slot.playerName,
        bookingStatus: normalizedBookingStatus,
        attendanceBadge: attendanceBadge,
        price: _displayPrice(slot),
        onTap: () => _onSlotTap(slot, status),
      );
    }).toList(growable: false);
  }

  String? _attendanceBadgeForSlot(CourtCalendarSlot slot) {
    final bookingId = slot.bookingId;
    if (bookingId != null && _attendanceBadgeOverrides.containsKey(bookingId)) {
      return _attendanceBadgeOverrides[bookingId];
    }

    final normalized = slot.status.toUpperCase();
    if (normalized == 'NO_SHOW' || normalized == 'NO-SHOW') {
      return 'No-Show';
    }
    if (normalized == 'COMPLETED' || normalized == 'ATTENDED') {
      return 'Attended';
    }
    return null;
  }

  String _displayBookingStatus(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    switch (normalized) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'COMPLETED':
        return 'Completed';
      case 'NO_SHOW':
      case 'NO-SHOW':
        return 'No-Show';
      default:
        return rawStatus;
    }
  }

  Widget _buildCalendar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2035),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        weekendDays: const [DateTime.saturday],
        selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadCalendar();
          _loadBookingsList(page: 1);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadCalendar();
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textTheme.titleMedium!,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(color: colorScheme.surface),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: AppFontWeights.semiBold,
          ),
          weekendStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.error,
            fontWeight: AppFontWeights.semiBold,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: textTheme.titleSmall!.copyWith(
            color: colorScheme.onPrimary,
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.secondary, width: 1.5),
          ),
          todayTextStyle: textTheme.titleSmall!.copyWith(
            color: colorScheme.secondary,
          ),
          defaultTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface,
          ),
          outsideDaysVisible: true,
          outsideTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.28),
          ),
          weekendTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          tablePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          rowDecoration: const BoxDecoration(),
          markerDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatListStatus(String rawStatus) {
    return rawStatus
        .toLowerCase()
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _bookingCardTitle(BookingListItem item) {
    return item.offlineCustomerName ?? item.playerName ?? 'Customer';
  }

  Future<void> _openBookingFromList(BookingListItem item) async {
    final changed = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(
          bookingId: item.id,
          date: item.bookingDate ?? _selectedDay,
        ),
      ),
    );

    if (changed is BookingAttendanceUpdate) {
      setState(() {
        _attendanceBadgeOverrides[changed.bookingId] =
            changed.isNoShow ? 'No-Show' : 'Attended';
      });
    }

    if (changed == true || changed is BookingAttendanceUpdate) {
      await _loadBookingsList(page: _listPage);
      await _loadCalendar();
    }
  }

  Widget _buildCourtFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          for (final court in _courts)
            ChoiceChip(
              label: Text(court.name),
              selected: _selectedCourtId == court.id,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCourtId = court.id);
                  _loadCalendar();
                  _loadBookingsList(page: 1);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final calendarState =
        widget.state == ScreenUiState.content ? _uiState : widget.state;

    return ScreenStateView(
      state: calendarState,
      emptyTitle: 'No slots found',
      emptySubtitle:
          _errorMessage ?? 'Calendar slots will appear here for the selected day.',
      onRetry: _bootstrap,
      content: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          Stack(
            children: [
              _buildCalendar(context),
              if (_isRefreshingCalendar)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.transparent,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildCourtFilterChips(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Daily Schedule',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  children: [
                    AppButton(
                      label: 'New Booking',
                      icon: Icons.event_available_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () async {
                        final created = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateOfflineBookingScreen(
                              initialCourtId: _selectedCourtId,
                              initialDate: _selectedDay,
                            ),
                          ),
                        );
                        if (created != null) {
                          await _loadCalendar();
                          await _loadBookingsList(page: 1);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Offline Booking',
                      icon: Icons.calendar_month_outlined,
                      variant: AppButtonVariant.filled,
                      onPressed: () async {
                        final created = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateOfflineBookingScreen(),
                          ),
                        );
                        if (created != null) {
                          await _loadCalendar();
                          await _loadBookingsList(page: 1);
                        }
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'New Booking',
                      icon: Icons.event_available_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () async {
                        final created = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateOfflineBookingScreen(
                              initialCourtId: _selectedCourtId,
                              initialDate: _selectedDay,
                            ),
                          ),
                        );
                        if (created != null) {
                          await _loadCalendar();
                          await _loadBookingsList(page: 1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs2),
                  Expanded(
                    child: AppButton(
                      label: 'Offline Booking',
                      icon: Icons.calendar_month_outlined,
                      variant: AppButtonVariant.filled,
                      onPressed: () async {
                        final created = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateOfflineBookingScreen(),
                          ),
                        );
                        if (created != null) {
                          await _loadCalendar();
                          await _loadBookingsList(page: 1);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._buildSlots(),
        ],
      ),
    );
  }

  Widget _buildBookingsListTab() {
    final listState =
        widget.state == ScreenUiState.content ? _listUiState : widget.state;
    const statusOptions = <String?>[
      null,
      'CONFIRMED',
      'COMPLETED',
      'CANCELLED',
      'NO_SHOW',
    ];

    Widget buildFiltersSection() {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDay,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    setState(() {
                      _selectedDay = picked;
                      _focusedDay = picked;
                    });
                    await _loadBookingsList(page: 1);
                    await _loadCalendar();
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_formatDate(_selectedDay)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            _buildCourtFilterChips(),
            const SizedBox(height: AppSpacing.xxs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.xxs,
                children: [
                  for (final status in statusOptions)
                    ChoiceChip(
                      label: Text(status == null
                          ? 'All Statuses'
                          : _formatListStatus(status)),
                      selected: _selectedListStatus == status,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() => _selectedListStatus = status);
                        _loadBookingsList(page: 1);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBookingsContent() {
      if (listState == ScreenUiState.loading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (listState == ScreenUiState.error) {
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
                  Text(_listErrorMessage ?? 'Failed to load bookings list.'),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => _loadBookingsList(page: _listPage),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (listState == ScreenUiState.empty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No bookings found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _listErrorMessage ??
                      'Bookings matching the selected filters will appear here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      }

      // Content state
      return Column(
        children: [
          if (_isRefreshingList)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          for (final booking in _bookings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: InkWell(
                  onTap: () => _openBookingFromList(booking),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _bookingCardTitle(booking),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatListStatus(booking.status),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_to12Hour(booking.startTime)} - ${_to12Hour(booking.endTime)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${booking.venueName ?? '-'} / ${booking.courtName ?? '-'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Amount: NPR ${(booking.totalAmount / 100).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _listPage > 1
                      ? () => _loadBookingsList(page: _listPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs2),
              Text('$_listPage / $_listTotalPages'),
              const SizedBox(width: AppSpacing.xs2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _listPage < _listTotalPages
                      ? () => _loadBookingsList(page: _listPage + 1)
                      : null,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Page $_listPage of $_listTotalPages | $_listTotalItems bookings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        buildFiltersSection(),
        const SizedBox(height: AppSpacing.xs),
        buildBookingsContent(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Slot Calendar'),
            Tab(text: 'Bookings List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildBookingsListTab(),
        ],
      ),
    );
  }
}

enum _AvailableSlotAction {
  book,
  block,
}

class _CourtOption {
  const _CourtOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _BlockSlotResult {
  final BlockType blockType;
  final String? note;

  const _BlockSlotResult({required this.blockType, this.note});
}

class _BlockSlotDialog extends StatefulWidget {
  const _BlockSlotDialog();

  @override
  State<_BlockSlotDialog> createState() => _BlockSlotDialogState();
}

class _BlockSlotDialogState extends State<_BlockSlotDialog> {
  late final TextEditingController _noteController;
  BlockType _selectedBlockType = BlockType.maintenance;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _blockTypeLabel(BlockType type) {
    return switch (type) {
      BlockType.maintenance => 'Maintenance',
      BlockType.privateReservation => 'Private Reservation',
      BlockType.event => 'Event',
      BlockType.personal => 'Personal',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Block Time Slot'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<BlockType>(
              groupValue: _selectedBlockType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedBlockType = value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: BlockType.values.map((type) => RadioListTile<BlockType>(
                  title: Text(_blockTypeLabel(type)),
                  value: type,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Additional details...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _BlockSlotResult(
              blockType: _selectedBlockType,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            ),
          ),
          child: const Text('Block'),
        ),
      ],
    );
  }
}
