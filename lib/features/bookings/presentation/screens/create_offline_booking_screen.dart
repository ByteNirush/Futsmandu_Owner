import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_bookings_api.dart';
import '../../data/owner_courts_api.dart';

class CreateOfflineBookingScreen extends StatefulWidget {
  const CreateOfflineBookingScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.initialCourtId,
    this.initialDate,
    this.initialStartTime,
  });

  final ScreenUiState state;
  final String? initialCourtId;
  final DateTime? initialDate;
  final String? initialStartTime;

  @override
  State<CreateOfflineBookingScreen> createState() =>
      _CreateOfflineBookingScreenState();
}

class _CreateOfflineBookingScreenState extends State<CreateOfflineBookingScreen> {
  final OwnerCourtsApi _courtsApi = OwnerCourtsApi();
  final OwnerBookingsApi _bookingsApi = OwnerBookingsApi();
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  List<OwnerCourtOption> _courts = const [];
  DateTime? _bookingDate;
  TimeOfDay? _startTime;
  String? _selectedCourtId;
  String _bookingType = 'offline_paid';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _bookingTypes = [
    'offline_cash',
    'offline_paid',
    'offline_reserved',
  ];

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _bookingDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialStartTime != null
        ? _timeFromApi(widget.initialStartTime!)
        : TimeOfDay.now();
    _selectedCourtId = widget.initialCourtId;
    _bootstrap();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final courts = await _courtsApi.listOwnerCourts();
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _selectedCourtId = _selectedCourtId ??
            (courts.isNotEmpty ? courts.first.id : null);
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
        _errorMessage = 'Failed to load courts.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthAbbr[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _timeFromApi(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return TimeOfDay.now();
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return TimeOfDay.now();
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _toApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _bookingDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _saveBooking() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final courtId = _selectedCourtId;
    final bookingDate = _bookingDate;
    final startTime = _startTime;
    if (courtId == null || bookingDate == null || startTime == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final calendar = await _bookingsApi.getBookingsCourtCalendar(
        courtId: courtId,
        date: bookingDate,
      );

      final apiStartTime = _toApiTime(startTime);
      CourtCalendarSlot? selectedSlot;
      for (final slot in calendar.slots) {
        if (slot.startTime == apiStartTime) {
          selectedSlot = slot;
          break;
        }
      }
      if (selectedSlot == null) {
        throw ApiException('Selected slot is not within the court schedule.');
      }

      if (selectedSlot.status.toUpperCase() != 'AVAILABLE') {
        throw ApiException(
          'Selected slot is already ${selectedSlot.status.toLowerCase()}.',
        );
      }

      final result = await _bookingsApi.createOfflineBooking(
        courtId: courtId,
        bookingDate: bookingDate,
        startTime: apiStartTime,
        bookingType: _bookingType,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to create booking right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs / 2),
                  Text(
                    value ?? 'Tap to select',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: value != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Offline Booking')),
        body: const Center(child: AppLoader()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Offline Booking')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No offline booking form',
        emptySubtitle:
            _errorMessage ?? 'Create a walk-in booking for a selected court.',
        onRetry: _bootstrap,
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Customer phone',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) {
                          return 'Phone number is required';
                        }
                        final nepaliPhone = RegExp(r'^\+?977\d{9,10}$|^\d{9,10}$');
                        if (!nepaliPhone.hasMatch(raw)) {
                          return 'Enter a valid Nepal phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourtId,
                      decoration: const InputDecoration(labelText: 'Court'),
                      items: _courts
                          .map(
                            (court) => DropdownMenuItem(
                              value: court.id,
                              child: Text(court.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _selectedCourtId = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a court';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildPickerRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Booking date',
                      value: _bookingDate != null ? _formatDate(_bookingDate!) : null,
                      onTap: _pickDate,
                    ),
                    const Divider(height: 1),
                    _buildPickerRow(
                      icon: Icons.access_time_outlined,
                      label: 'Start time',
                      value: _startTime != null ? _formatTime(_startTime!) : null,
                      onTap: _pickTime,
                    ),
                    const Divider(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      initialValue: _bookingType,
                      decoration: const InputDecoration(labelText: 'Booking type'),
                      items: _bookingTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _bookingType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _isSubmitting ? 'Creating...' : 'Create Booking',
              onPressed: _isSubmitting ? null : _saveBooking,
            ),
          ],
        ),
      ),
    );
  }
}
