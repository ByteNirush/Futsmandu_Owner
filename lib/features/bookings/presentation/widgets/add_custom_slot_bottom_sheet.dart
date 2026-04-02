import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';

class AddCustomSlotBottomSheet extends StatefulWidget {
  const AddCustomSlotBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCustomSlotBottomSheet(),
    );
  }

  @override
  State<AddCustomSlotBottomSheet> createState() => _AddCustomSlotBottomSheetState();
}

class _AddCustomSlotBottomSheetState extends State<AddCustomSlotBottomSheet> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStartTime) async {
    final initialTime = isStartTime
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? TimeOfDay.now());

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Widget _buildTimePickButton({
    required BuildContext context,
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs / 2),
                  Text(
                    time != null ? time.format(context) : 'Select Time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: textTheme.titleMedium?.copyWith(
                      color: time != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight:
                          time != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time_rounded,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add Custom Slot',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Time Pickers
              LayoutBuilder(
                builder: (context, constraints) {
                  // Avoid tiny horizontal overflow by stacking on very narrow widths.
                  final narrow = constraints.maxWidth < 360;
                  if (narrow) {
                    return Column(
                      children: [
                        _buildTimePickButton(
                          context: context,
                          label: 'Start Time',
                          time: _startTime,
                          onTap: () => _pickTime(true),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTimePickButton(
                          context: context,
                          label: 'End Time',
                          time: _endTime,
                          onTap: () => _pickTime(false),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTimePickButton(
                          context: context,
                          label: 'Start Time',
                          time: _startTime,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildTimePickButton(
                          context: context,
                          label: 'End Time',
                          time: _endTime,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price
              Text(
                'Custom Price (Optional)',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: 'NPR ',
                  hintText: 'Leave empty for default price',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 360;
                  if (narrow) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Add Slot',
                          onPressed: () {
                            if (_startTime == null || _endTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select both start and end time',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Custom slot added successfully!'),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Add Slot',
                          onPressed: () {
                            if (_startTime == null || _endTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select both start and end time',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Custom slot added successfully!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
