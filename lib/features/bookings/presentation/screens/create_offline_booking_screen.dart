import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class CreateOfflineBookingScreen extends StatefulWidget {
  const CreateOfflineBookingScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  State<CreateOfflineBookingScreen> createState() =>
      _CreateOfflineBookingScreenState();
}

class _CreateOfflineBookingScreenState
    extends State<CreateOfflineBookingScreen> {
  final _teamNameController = TextEditingController();
  final _courtNameController = TextEditingController();
  DateTime? _bookingDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _status = 'Confirmed';

  static const _statuses = ['Confirmed', 'Pending', 'Cancelled'];
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
  void dispose() {
    _teamNameController.dispose();
    _courtNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthAbbr[d.month - 1]} ${d.year}';

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _bookingDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Offline Booking')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No offline booking form',
        emptySubtitle: 'UI placeholder for offline booking creation form.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _teamNameController,
                    decoration: const InputDecoration(labelText: 'Team name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _courtNameController,
                    decoration: const InputDecoration(labelText: 'Court name'),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildPickerRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Booking date',
                    value: _bookingDate != null
                        ? _formatDate(_bookingDate!)
                        : null,
                    onTap: _pickDate,
                  ),
                  const Divider(height: 1),
                  _buildPickerRow(
                    icon: Icons.access_time_outlined,
                    label: 'Start time',
                    value: _startTime != null ? _formatTime(_startTime!) : null,
                    onTap: _pickStartTime,
                  ),
                  const Divider(height: 1),
                  _buildPickerRow(
                    icon: Icons.access_time_filled_outlined,
                    label: 'End time',
                    value: _endTime != null ? _formatTime(_endTime!) : null,
                    onTap: _pickEndTime,
                  ),
                  const Divider(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Create Booking',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
