import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../venues/domain/models/court_models.dart';
import '../../../venues/presentation/controllers/venue_courts_controller.dart';
import '../../../venues/presentation/validators/owner_form_validators.dart';

class CreateCourtScreen extends StatefulWidget {
  const CreateCourtScreen({
    super.key,
    required this.venueId,
    this.initialCourt,
  });

  final String venueId;
  final Court? initialCourt;

  @override
  State<CreateCourtScreen> createState() => _CreateCourtScreenState();
}

class _CreateCourtScreenState extends State<CreateCourtScreen> {
  final VenueCourtsController _courtsController = VenueCourtsController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courtTypeController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _capacityController = TextEditingController(text: '10');
  final _minPlayersController = TextEditingController(text: '2');
  final _slotDurationController = TextEditingController(text: '60');

  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    final court = widget.initialCourt;
    if (court == null) {
      return;
    }

    _nameController.text = court.name;
    _courtTypeController.text = court.courtType;
    _surfaceController.text = court.surface;
    _capacityController.text = court.capacity.toString();
    _minPlayersController.text = court.minPlayers.toString();
    _slotDurationController.text = court.slotDurationMins.toString();
    _openTime = _parseTime(court.openTime) ?? _openTime;
    _closeTime = _parseTime(court.closeTime) ?? _closeTime;
  }

  @override
  void dispose() {
    _courtsController.dispose();
    _nameController.dispose();
    _courtTypeController.dispose();
    _surfaceController.dispose();
    _capacityController.dispose();
    _minPlayersController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String? get _timeRangeError {
    if (_toMinutes(_closeTime) <= _toMinutes(_openTime)) {
      return 'Close time must be after open time.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _courtsController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.initialCourt == null ? 'Create Court' : 'Edit Court',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Court Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppFontWeights.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppInputField(
                        label: 'Court Name',
                        hint: 'e.g. Court A',
                        prefixIcon: Icons.sports_soccer,
                        controller: _nameController,
                        validator: (value) => OwnerFormValidators.requiredText(
                          value,
                          'Court name',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppInputField(
                        label: 'Court Type',
                        hint: 'e.g. Indoor, Outdoor',
                        prefixIcon: Icons.category_outlined,
                        controller: _courtTypeController,
                        validator: (value) => OwnerFormValidators.requiredText(
                          value,
                          'Court type',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppInputField(
                        label: 'Surface',
                        hint: 'e.g. Artificial Turf',
                        prefixIcon: Icons.grass_outlined,
                        controller: _surfaceController,
                        validator: (value) =>
                            OwnerFormValidators.requiredText(value, 'Surface'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'Capacity',
                              hint: '12',
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  OwnerFormValidators.intInRange(
                                    value,
                                    label: 'Capacity',
                                    min: 2,
                                    max: 30,
                                  ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppInputField(
                              label: 'Min players',
                              hint: '4',
                              controller: _minPlayersController,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  OwnerFormValidators.intInRange(
                                    value,
                                    label: 'Min players',
                                    min: 2,
                                    max: 22,
                                  ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppInputField(
                        label: 'Slot duration mins',
                        hint: '60',
                        prefixIcon: Icons.timer_outlined,
                        controller: _slotDurationController,
                        keyboardType: TextInputType.number,
                        validator: (value) => OwnerFormValidators.intInRange(
                          value,
                          label: 'Slot duration',
                          min: 30,
                          max: 180,
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operating Hours',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppFontWeights.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Set the daily open and close time for this court.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePicker(
                              context,
                              label: 'Open Time',
                              time: _openTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _openTime,
                                );
                                if (picked != null) {
                                  setState(() => _openTime = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildTimePicker(
                              context,
                              label: 'Close Time',
                              time: _closeTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _closeTime,
                                );
                                if (picked != null) {
                                  setState(() => _closeTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_timeRangeError != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _timeRangeError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: widget.initialCourt == null
                      ? 'Create Court'
                      : 'Update Court',
                  icon: widget.initialCourt == null
                      ? Icons.add
                      : Icons.save_outlined,
                  isLoading: _courtsController.isBusy,
                  onPressed: _courtsController.isBusy
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          final timeError = _timeRangeError;
                          if (timeError != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(timeError)));
                            return;
                          }

                          final capacity = int.parse(
                            _capacityController.text.trim(),
                          );
                          final minPlayers = int.parse(
                            _minPlayersController.text.trim(),
                          );
                          if (minPlayers > capacity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Min players cannot exceed court capacity.',
                                ),
                              ),
                            );
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            await _courtsController.saveCourt(
                              venueId: widget.venueId,
                              courtId: widget.initialCourt?.id,
                              request: CourtUpsertRequest(
                                name: _nameController.text,
                                courtType: _courtTypeController.text,
                                surface: _surfaceController.text,
                                capacity: capacity,
                                minPlayers: minPlayers,
                                slotDurationMins: int.parse(
                                  _slotDurationController.text.trim(),
                                ),
                                openTime: _formatTime(_openTime),
                                closeTime: _formatTime(_closeTime),
                              ),
                            );
                            if (!mounted) {
                              return;
                            }
                            navigator.pop(true);
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _courtsController.errorMessage ??
                                      'Failed to save court. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  time.format(context),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: AppFontWeights.semiBold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
