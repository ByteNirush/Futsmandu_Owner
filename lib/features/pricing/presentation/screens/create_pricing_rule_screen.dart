import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../../shared/models/pricing_rule.dart';

class CreatePricingRuleScreen extends StatefulWidget {
  const CreatePricingRuleScreen({
    super.key,
    this.rule,
    this.state = ScreenUiState.content,
  });

  final PricingRule? rule;
  final ScreenUiState state;

  @override
  State<CreatePricingRuleScreen> createState() => _CreatePricingRuleScreenState();
}

class _CreatePricingRuleScreenState extends State<CreatePricingRuleScreen> {
  late PricingRuleType _ruleType;
  late double _price;
  late int _priority;
  late TimeOfDay _timeFrom;
  late TimeOfDay _timeTo;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _ruleType = rule?.ruleType ?? PricingRuleType.base;
    _price = rule?.priceNpr ?? 1000.0;
    _priority = rule?.priority ?? 1;
    _timeFrom = rule != null ? TimeOfDay.fromDateTime(rule.timeFrom) : const TimeOfDay(hour: 6, minute: 0);
    _timeTo = rule != null ? TimeOfDay.fromDateTime(rule.timeTo) : const TimeOfDay(hour: 18, minute: 0);
    _priceController.text = _price.toInt().toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _saveRule() {
    final price = double.tryParse(_priceController.text) ?? _price;
    final id = widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final newRule = PricingRule(
      id: id,
      courtId: widget.rule?.courtId ?? 'court_1',
      ruleType: _ruleType,
      priority: _priority,
      daysOfWeek: widget.rule?.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7], // default everyday
      timeFrom: DateTime(2025, 1, 1, _timeFrom.hour, _timeFrom.minute),
      timeTo: DateTime(2025, 1, 1, _timeTo.hour, _timeTo.minute),
      dateFrom: widget.rule?.dateFrom ?? DateTime.now(),
      dateTo: widget.rule?.dateTo ?? DateTime.now().add(const Duration(days: 365)),
      priceNpr: price,
    );
    Navigator.of(context).pop(newRule);
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _timeFrom : _timeTo;
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _timeFrom = picked;
        } else {
          _timeTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rule != null;
    
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pricing Rule' : 'Create Pricing Rule')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No pricing form',
        emptySubtitle: 'UI placeholder for empty pricing rule form.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<PricingRuleType>(
                    initialValue: _ruleType,
                    decoration: const InputDecoration(labelText: 'Rule Type'),
                    items: PricingRuleType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _ruleType = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Start Time'),
                            child: Text(_timeFrom.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'End Time'),
                            child: Text(_timeTo.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (NPR)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority (Lower is higher priority)'),
                    items: List.generate(5, (i) => i + 1).map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.toString()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save Rule',
              onPressed: _saveRule,
            ),
          ],
        ),
      ),
    );
  }
}
