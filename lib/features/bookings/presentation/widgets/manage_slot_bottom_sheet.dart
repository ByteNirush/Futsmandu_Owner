import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import 'time_slot_item.dart';

class ManageSlotBottomSheet extends StatefulWidget {
  const ManageSlotBottomSheet({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.initialStatus,
    this.initialPrice,
  });

  final String startTime;
  final String endTime;
  final SlotStatus initialStatus;
  final String? initialPrice;

  static Future<void> show(
    BuildContext context, {
    required String startTime,
    required String endTime,
    required SlotStatus initialStatus,
    String? initialPrice,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageSlotBottomSheet(
        startTime: startTime,
        endTime: endTime,
        initialStatus: initialStatus,
        initialPrice: initialPrice,
      ),
    );
  }

  @override
  State<ManageSlotBottomSheet> createState() => _ManageSlotBottomSheetState();
}

class _ManageSlotBottomSheetState extends State<ManageSlotBottomSheet> {
  late SlotStatus _currentStatus;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _priceController = TextEditingController(
      text: widget.initialPrice?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
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
                'Manage Slot',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.startTime} - ${widget.endTime}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Status Toggle
              Text(
                'Slot Status',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<SlotStatus>(
                segments: const [
                  ButtonSegment<SlotStatus>(
                    value: SlotStatus.available,
                    label: Text('Open'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment<SlotStatus>(
                    value: SlotStatus.blocked,
                    label: Text('Blocked'),
                    icon: Icon(Icons.block),
                  ),
                ],
                selected: {_currentStatus},
                onSelectionChanged: (selection) {
                  setState(() => _currentStatus = selection.first);
                },
              ),
              
              if (_currentStatus == SlotStatus.available) ...[
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to Create Offline Booking specifically for this slot
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Booking for this Slot'),
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
              Row(
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
                      label: 'Save Changes',
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Slot updated successfully')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
