import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_pricing_api.dart';

class CreatePricingRuleScreen extends StatefulWidget {
  const CreatePricingRuleScreen({
    super.key,
    required this.courtId,
    this.rule,
    this.state = ScreenUiState.content,
  });

  final String courtId;
  final OwnerPricingRule? rule;
  final ScreenUiState state;

  @override
  State<CreatePricingRuleScreen> createState() =>
      _CreatePricingRuleScreenState();
}

class _CreatePricingRuleScreenState extends State<CreatePricingRuleScreen> {
  final OwnerPricingApi _pricingApi = OwnerPricingApi();
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _priorityController = TextEditingController();
  final _hoursBeforeController = TextEditingController();

  late String _ruleType;
  late String _modifier;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late Set<int> _daysOfWeek;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _ruleTypes = [
    'base',
    'offpeak',
    'weekend',
    'peak',
    'lastminute',
    'custom',
  ];

  static const _modifiers = [
    'fixed',
    'percent_add',
    'percent_off',
  ];

  static const _dayLabels = <int, String>{
    0: 'Sun',
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
  };

  static const Map<String, int> _canonicalPriority = <String, int>{
    'base': 1,
    'offpeak': 5,
    'weekend': 8,
    'peak': 10,
    'lastminute': 15,
    'custom': 20,
  };

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _ruleType = rule?.ruleType ?? 'custom';
    _modifier = rule?.modifier ?? 'fixed';
    _startTime = _timeFromString(rule?.startTime) ?? const TimeOfDay(hour: 6, minute: 0);
    _endTime = _timeFromString(rule?.endTime) ?? const TimeOfDay(hour: 18, minute: 0);
    _dateFrom = rule?.dateFrom;
    _dateTo = rule?.dateTo;
    _daysOfWeek = (rule?.daysOfWeek.isNotEmpty ?? false)
        ? rule!.daysOfWeek.toSet()
        : <int>{0, 1, 2, 3, 4, 5, 6};

    _priceController.text =
        ((rule?.pricePaisa ?? 100000) / 100).toStringAsFixed(0);
    _priorityController.text =
        (rule?.priority ?? _canonicalPriority[_ruleType] ?? 1).toString();
    _hoursBeforeController.text = (rule?.hoursBefore ?? '').toString();

    if (widget.rule == null) {
      _syncPriorityForRuleType();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priorityController.dispose();
    _hoursBeforeController.dispose();
    super.dispose();
  }

  TimeOfDay? _timeFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _toApiTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _toDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickTime({required bool start}) async {
    final initial = start ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickDate({required bool from}) async {
    final current = from ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _syncPriorityForRuleType() {
    final canonical = _canonicalPriority[_ruleType];
    if (canonical == null) {
      return;
    }
    _priorityController.text = canonical.toString();
  }

  Future<void> _saveRule() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final priceNpr = double.tryParse(_priceController.text.trim());
    final priority = int.tryParse(_priorityController.text.trim());
    if (priceNpr == null || priority == null) {
      setState(() => _errorMessage = 'Enter a valid price and priority.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final days = _daysOfWeek.toList()..sort();
      final startTime = _toApiTime(_startTime);
      final endTime = _toApiTime(_endTime);
      final dateFrom = _dateFrom != null ? _toDateOnly(_dateFrom!) : null;
      final dateTo = _dateTo != null ? _toDateOnly(_dateTo!) : null;
      final hoursBefore = int.tryParse(_hoursBeforeController.text.trim());

      final result = widget.rule == null
          ? await _pricingApi.createPricingRule(
              courtId: widget.courtId,
              ruleType: _ruleType,
              priority: priority,
              pricePaisa: (priceNpr * 100).round(),
              modifier: _modifier,
              daysOfWeek: days,
              startTime: startTime,
              endTime: endTime,
              dateFrom: dateFrom,
              dateTo: dateTo,
              hoursBefore: hoursBefore,
            )
          : await _pricingApi.updatePricingRule(
              ruleId: widget.rule!.id,
              pricePaisa: (priceNpr * 100).round(),
              modifier: _modifier,
              daysOfWeek: days,
              startTime: startTime,
              endTime: endTime,
              dateFrom: dateFrom,
              dateTo: dateTo,
              hoursBefore: hoursBefore,
            );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to save the pricing rule.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(time.format(context)),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final text = value == null
        ? 'Optional'
        : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.rule == null ? 'Create Pricing Rule' : 'Edit Pricing Rule'),
        ),
        body: const Center(child: AppLoader()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? 'Create Pricing Rule' : 'Edit Pricing Rule'),
      ),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No pricing form',
        emptySubtitle: 'Configure custom pricing for the selected court.',
        content: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
            children: [
              // Rule Type
              DropdownButtonFormField<String>(
                initialValue: _ruleType,
                decoration: const InputDecoration(
                  labelText: 'Rule type',
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                ),
                items: _ruleTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(growable: false),
                onChanged: widget.rule == null
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _ruleType = value;
                            _syncPriorityForRuleType();
                          });
                        }
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Priority & Price Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.rule == null) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                        ),
                        validator: (value) {
                          if (int.tryParse(value ?? '') == null) {
                            return 'Enter a valid priority';
                          }
                          return null;
                        },
                        enabled: _ruleType == 'custom',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (NPR)',
                        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                      ),
                      validator: (value) {
                        if (double.tryParse(value ?? '') == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Modifier
              DropdownButtonFormField<String>(
                initialValue: _modifier,
                decoration: const InputDecoration(
                  labelText: 'Modifier',
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                ),
                items: _modifiers
                    .map((modifier) => DropdownMenuItem(value: modifier, child: Text(modifier)))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _modifier = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Days of Week
              Text(
                'Days of Week',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: _dayLabels.entries.map((entry) {
                  final selected = _daysOfWeek.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _daysOfWeek.add(entry.key);
                        } else {
                          _daysOfWeek.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.md),

              // Time Range
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'Start time',
                      time: _startTime,
                      onTap: () => _pickTime(start: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTimeSelector(
                      label: 'End time',
                      time: _endTime,
                      onTap: () => _pickTime(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Date Range
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Date from',
                      value: _dateFrom,
                      onTap: () => _pickDate(from: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Date to',
                      value: _dateTo,
                      onTap: () => _pickDate(from: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Hours Before
              TextFormField(
                controller: _hoursBeforeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours before booking',
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: widget.rule == null ? 'Create Rule' : 'Update Rule',
                onPressed: _saveRule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
