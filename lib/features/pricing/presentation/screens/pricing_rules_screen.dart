import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../../../shared/models/pricing_rule.dart';
import 'create_pricing_rule_screen.dart';

class PricingRulesScreen extends StatefulWidget {
  const PricingRulesScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  State<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends State<PricingRulesScreen> {
  final List<PricingRule> _rules = [
    PricingRule(
      id: '1',
      courtId: 'court_1',
      ruleType: PricingRuleType.peak,
      priority: 1,
      daysOfWeek: [5, 6], // Fri, Sat
      timeFrom: DateTime(2025, 1, 1, 18, 0),
      timeTo: DateTime(2025, 1, 1, 22, 0),
      dateFrom: DateTime(2025, 1, 1),
      dateTo: DateTime(2025, 12, 31),
      priceNpr: 2500,
    ),
  ];

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  String _getDaysString(List<int> days) {
    const dayNames = {
      1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'
    };
    if (days.length == 7) return 'Everyday';
    return days.map((d) => dayNames[d] ?? '').join(', ');
  }

  void _navigateAndHandleRule(PricingRule? ruleToEdit) async {
    final returnedRule = await Navigator.of(context).push<PricingRule>(
      MaterialPageRoute(
        builder: (_) => CreatePricingRuleScreen(rule: ruleToEdit),
      ),
    );

    if (returnedRule != null) {
      setState(() {
        if (ruleToEdit != null) {
          final index = _rules.indexWhere((r) => r.id == ruleToEdit.id);
          if (index != -1) {
            _rules[index] = returnedRule;
          }
        } else {
          _rules.add(returnedRule);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Rules')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _navigateAndHandleRule(null),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
      body: ScreenStateView(
        state: _rules.isEmpty ? ScreenUiState.empty : widget.state,
        emptyTitle: 'No pricing rules',
        emptySubtitle: 'Create custom pricing by day and time.',
        content: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemCount: _rules.length,
          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final rule = _rules[index];
            final titleStr = rule.ruleType.name.toUpperCase();
            final subtitleStr = '${_getDaysString(rule.daysOfWeek)} • '
                '${_formatTime(rule.timeFrom)} - ${_formatTime(rule.timeTo)} • '
                'NPR ${rule.priceNpr.toInt()}';
            
            return AppCard(
              child: ListTile(
                title: Text('$titleStr HOURS'),
                subtitle: Text(subtitleStr),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(label: Text('Priority ${rule.priority}')),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _navigateAndHandleRule(rule),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
