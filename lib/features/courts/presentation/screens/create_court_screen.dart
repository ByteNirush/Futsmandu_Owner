import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class CreateCourtScreen extends StatefulWidget {
  const CreateCourtScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.isEditMode = false,
  });

  final ScreenUiState state;
  final bool isEditMode;

  @override
  State<CreateCourtScreen> createState() => _CreateCourtScreenState();
}

class _CreateCourtScreenState extends State<CreateCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _minPlayersController = TextEditingController();
  final _slotDurationController = TextEditingController();

  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String? get _timeRangeError {
    if (_toMinutes(_closeTime) <= _toMinutes(_openTime)) {
      return 'Close time must be after open time.';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePositiveNumber(String? value, String fieldName) {
    final requiredError = _validateRequired(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surfaceController.dispose();
    _capacityController.dispose();
    _minPlayersController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpenTime) async {
    final initialTime = isOpenTime ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  void _saveCourt() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final timeError = _timeRangeError;
    if (timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeError)),
      );
      return;
    }

    // Save court logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditMode ? 'Court updated successfully' : 'Court created successfully',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Court' : 'Create Court'),
      ),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No court form',
        emptySubtitle: 'Fill in the court details to continue.',
        content: Form(
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Court Name',
                      hint: 'e.g., Court A',
                      prefixIcon: Icons.sports_soccer,
                      controller: _nameController,
                      validator: (value) => _validateRequired(value, 'Court name'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Surface Type',
                      hint: 'e.g., Artificial Turf',
                      prefixIcon: Icons.grass_outlined,
                      controller: _surfaceController,
                      validator: (value) => _validateRequired(value, 'Surface type'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      spacing: AppSpacing.sm,
                      children: [
                        Expanded(
                          child: AppInputField(
                            label: 'Capacity',
                            hint: 'Max players',
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            validator: (value) => _validatePositiveNumber(value, 'Capacity'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        Expanded(
                          child: AppInputField(
                            label: 'Min Players',
                            hint: 'Minimum',
                            controller: _minPlayersController,
                            keyboardType: TextInputType.number,
                            validator: (value) => _validatePositiveNumber(value, 'Min players'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Slot Duration (minutes)',
                      hint: 'e.g., 60',
                      prefixIcon: Icons.timer_outlined,
                      controller: _slotDurationController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _validatePositiveNumber(value, 'Slot duration'),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Operating Hours',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Set opening and closing times for this court.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      spacing: AppSpacing.sm,
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Open Time',
                            time: _openTime,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Close Time',
                            time: _closeTime,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    if (_timeRangeError != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _timeRangeError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: widget.isEditMode ? 'Update Court' : 'Save Court',
                icon: widget.isEditMode ? Icons.save_outlined : Icons.add,
                isLoading: false,
                onPressed: _saveCourt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
