import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../bookings/data/owner_courts_api.dart';
import '../../data/owner_pricing_api.dart';
import 'create_pricing_rule_screen.dart';

class PricingRulesScreen extends StatefulWidget {
  const PricingRulesScreen({super.key});

  @override
  State<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends State<PricingRulesScreen> {
  final OwnerCourtsApi _courtsApi = OwnerCourtsApi();
  final OwnerPricingApi _pricingApi = OwnerPricingApi();

  List<OwnerCourtOption> _courts = const [];
  List<OwnerPricingRule> _rules = const [];
  String? _selectedCourtId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courts = await _courtsApi.listOwnerCourts();
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _selectedCourtId = courts.isNotEmpty ? courts.first.id : null;
      });
      await _loadRules();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load pricing rules.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRules() async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) {
      setState(() {
        _rules = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      final rules = await _pricingApi.listPricingRules(courtId);
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load pricing rules.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '--:--';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    final period = hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDays(List<int> days) {
    const labels = <int, String>{
      0: 'Sun',
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
    };
    if (days.length == 7) return 'Every day';
    return days.map((day) => labels[day] ?? '').where((value) => value.isNotEmpty).join(', ');
  }

  String _formatPrice(int? pricePaisa) => 'NPR ${((pricePaisa ?? 0) / 100).toStringAsFixed(0)}';

  Future<void> _openRuleForm([OwnerPricingRule? rule]) async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) return;

    final result = await Navigator.of(context).push<OwnerPricingRule>(
      MaterialPageRoute(
        builder: (_) => CreatePricingRuleScreen(
          courtId: courtId,
          rule: rule,
        ),
      ),
    );

    if (result != null) {
      await _loadRules();
    }
  }

  Future<void> _deleteRule(OwnerPricingRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pricing rule'),
        content: Text('Delete ${rule.ruleType} pricing rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _pricingApi.deletePricingRule(rule.id);
      if (!mounted) return;
      await _loadRules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing rule deleted')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the pricing rule.')),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_errorMessage!),
        ),
      );
    }

    if (_rules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('No pricing rules for this court yet.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _rules.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              if (_courts.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final court in _courts)
                        ChoiceChip(
                          label: Text(court.name),
                          selected: _selectedCourtId == court.id,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCourtId = court.id);
                              _loadRules();
                            }
                          },
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (_isRefreshing) const LinearProgressIndicator(),
            ],
          );
        }

        final rule = _rules[index - 1];
        return AppCard(
          child: ListTile(
            title: Text('${rule.ruleType.toUpperCase()} - ${_formatPrice(rule.pricePaisa)}'),
            subtitle: Text(
              '${_formatDays(rule.daysOfWeek)} - ${_formatTime(rule.startTime)} - ${_formatTime(rule.endTime)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openRuleForm(rule);
                } else if (value == 'delete') {
                  _deleteRule(rule);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _bootstrap,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _selectedCourtId == null ? null : () => _openRuleForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
      body: body,
    );
  }
}
