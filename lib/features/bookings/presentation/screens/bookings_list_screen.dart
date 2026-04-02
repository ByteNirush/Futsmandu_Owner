import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import 'booking_details_screen.dart';
import 'create_offline_booking_screen.dart';
import '../widgets/add_custom_slot_bottom_sheet.dart';
import '../widgets/manage_slot_bottom_sheet.dart';
import '../widgets/time_slot_item.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _selectedCourt = 'Court A';
  final _courts = const ['Court A', 'Court B', 'Court C'];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;



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
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // ── Header ───────────────────────────────────────────────────
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surface,
          ),
        ),
        // ── Day-of-week row ──────────────────────────────────────────
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: textTheme.labelSmall!.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        // ── Day cells ────────────────────────────────────────────────
        calendarStyle: CalendarStyle(
          // Selected day
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
          // Today
          todayDecoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.secondary, width: 1.5),
          ),
          todayTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w700,
          ),
          // Regular days
          defaultTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface,
          ),
          // Days outside current month (greyed-out)
          outsideDaysVisible: true,
          outsideTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.28),
          ),
          // Weekends
          weekendTextStyle: textTheme.bodyMedium!.copyWith(
            color: colorScheme.error.withValues(alpha: 0.8),
          ),
          // Disable inner table padding so AppCard handles spacing
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No bookings found',
        emptySubtitle: 'Bookings will appear here based on your filters.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            _buildCalendar(context),
            const SizedBox(height: AppSpacing.md),
            // Court Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  for (final court in _courts)
                    ChoiceChip(
                      label: Text(court),
                      selected: _selectedCourt == court,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCourt = court);
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Daily Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                // On narrow screens, avoid any horizontal overflow by stacking.
                final isNarrow = constraints.maxWidth < 360;
                if (isNarrow) {
                  return Column(
                    children: [
                      AppButton(
                        label: 'Add Slot',
                        icon: Icons.add,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => AddCustomSlotBottomSheet.show(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Offline Booking',
                        icon: Icons.calendar_month_outlined,
                        variant: AppButtonVariant.filled,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateOfflineBookingScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Add Slot',
                        icon: Icons.add,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            AddCustomSlotBottomSheet.show(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs2),
                    Expanded(
                      child: AppButton(
                        label: 'Offline Booking',
                        icon: Icons.calendar_month_outlined,
                        variant: AppButtonVariant.filled,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateOfflineBookingScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            
            TimeSlotItem(
              startTime: '06:00 AM',
              endTime: '07:00 AM',
              status: SlotStatus.booked,
              teamName: 'Team Everest',
              bookingStatus: 'Confirmed',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
              ),
            ),
            TimeSlotItem(
              startTime: '07:00 AM',
              endTime: '08:00 AM',
              status: SlotStatus.booked,
              teamName: 'FC Thunder',
              bookingStatus: 'Pending',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingDetailsScreen()),
              ),
            ),
            TimeSlotItem(
              startTime: '08:00 AM',
              endTime: '09:00 AM',
              status: SlotStatus.available,
              price: 'NPR 1,500',
              onTap: () => ManageSlotBottomSheet.show(
                context,
                startTime: '08:00 AM',
                endTime: '09:00 AM',
                initialStatus: SlotStatus.available,
                initialPrice: '1500',
              ),
            ),
            TimeSlotItem(
              startTime: '09:00 AM',
              endTime: '10:00 AM',
              status: SlotStatus.available,
              price: 'NPR 1,200',
              onTap: () => ManageSlotBottomSheet.show(
                context,
                startTime: '09:00 AM',
                endTime: '10:00 AM',
                initialStatus: SlotStatus.available,
                initialPrice: '1200',
              ),
            ),
            TimeSlotItem(
              startTime: '10:00 AM',
              endTime: '11:00 AM',
              status: SlotStatus.blocked,
              onTap: () => ManageSlotBottomSheet.show(
                context,
                startTime: '10:00 AM',
                endTime: '11:00 AM',
                initialStatus: SlotStatus.blocked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

