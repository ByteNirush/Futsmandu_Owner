import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_extended_action_button.dart';
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
  bool _isPreviewing = false;
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
    return days
        .map((day) => labels[day] ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  String _formatPrice(int? pricePaisa) =>
      'NPR ${((pricePaisa ?? 0) / 100).toStringAsFixed(0)}';

  Future<void> _openRuleForm([OwnerPricingRule? rule]) async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) return;

    final result = await Navigator.of(context).push<OwnerPricingRule>(
      MaterialPageRoute(
        builder: (_) => CreatePricingRuleScreen(courtId: courtId, rule: rule),
      ),
    );

    if (result != null) {
      await _loadRules();
    }
  }

  Future<void> _deleteRule(OwnerPricingRule rule) async {
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Pricing rule deleted')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to delete the pricing rule.')),
      );
    }
  }

  Future<void> _openPricingPreview() async {
    final courtId = _selectedCourtId;
    if (courtId == null || courtId.isEmpty) {
      return;
    }

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final dateTextController = TextEditingController(
      text:
          '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
    );
    final timeTextController = TextEditingController(
      text: selectedTime.format(context),
    );

    Future<void> pickDate(StateSetter setModalState) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (picked == null) {
        return;
      }
      selectedDate = picked;
      setModalState(() {
        dateTextController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }

    Future<void> pickTime(StateSetter setModalState) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked == null) {
        return;
      }
      selectedTime = picked;
      setModalState(() {
        timeTextController.text = selectedTime.format(context);
      });
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Preview Pricing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    readOnly: true,
                    controller: dateTextController,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                    onTap: () => pickDate(setModalState),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    readOnly: true,
                    controller: timeTextController,
                    decoration: const InputDecoration(labelText: 'Time'),
                    onTap: () => pickTime(setModalState),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Preview'),
                ),
              ],
            );
          },
        );
      },
    );

    dateTextController.dispose();
    timeTextController.dispose();

    if (confirmed != true) {
      return;
    }

    setState(() => _isPreviewing = true);
    try {
      final time =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      final preview = await _pricingApi.previewPrice(
        courtId: courtId,
        date: selectedDate,
        time: time,
      );
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pricing Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${preview.date}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Time: ${preview.time}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Price: ${preview.displayPrice}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Applied rule: ${preview.ruleType ?? 'none'}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to preview pricing.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
    }
  }

  Widget _buildCourtSelector() {
    if (_courts.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
            child: Text(
              'Select Court',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppSpacing.xs,
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
        ],
      ),
    );
  }

  Widget _buildRuleCard(OwnerPricingRule rule) {
    final colorScheme = Theme.of(context).colorScheme;

    Color getRuleTypeColor() {
      switch (rule.ruleType.toLowerCase()) {
        case 'surge':
          return AppColors.warning;
        case 'discount':
          return AppColors.success;
        case 'peak':
          return colorScheme.primary;
        default:
          return colorScheme.secondary;
      }
    }

    final ruleColor = getRuleTypeColor();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ruleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rule.ruleType.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ruleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatPrice(rule.pricePaisa),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(rule.startTime)} - ${_formatTime(rule.endTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatDays(rule.daysOfWeek),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          _buildCourtSelector(),
          if (_isRefreshing) ...[
            const SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
          ],
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rule_folder_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No pricing rules yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Create your first rule for this court',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _rules.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourtSelector(),
              if (_isRefreshing) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(),
              ],
            ],
          );
        }

        final rule = _rules[index - 1];
        return _buildRuleCard(rule);
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
            icon: _isPreviewing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            onPressed: _isPreviewing ? null : _openPricingPreview,
            tooltip: 'Preview price',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _bootstrap,
          ),
        ],
      ),
      floatingActionButton: AppExtendedActionButton(
        heroTag: 'pricing_new_rule_fab',
        onPressed: () {
          if (_selectedCourtId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a court first')),
            );
            return;
          }
          _openRuleForm();
        },
        icon: Icons.add_rounded,
        label: 'New Rule',
        tooltip: 'Create a new pricing rule',
      ),
      body: body,
    );
  }
}
