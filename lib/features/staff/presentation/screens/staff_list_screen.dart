import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_staff_api.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key, this.state = ScreenUiState.content});

  final ScreenUiState state;

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final OwnerStaffApi _staffApi = OwnerStaffApi();
  bool _isLoading = true;
  String? _errorMessage;
  List<OwnerStaffMember> _staff = const [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staff = await _staffApi.listStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load staff.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addStaff() async {
    final result = await Navigator.of(context).push<OwnerStaffMember>(
      MaterialPageRoute(
        builder: (_) => const AddStaffScreen(),
      ),
    );

    if (result != null) {
      await _loadStaff();
    }
  }

  Future<void> _changeRole(OwnerStaffMember member) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in const ['OWNER_ADMIN', 'OWNER_STAFF'])
              RadioListTile<String>(
                value: role,
                groupValue: member.role,
                onChanged: (value) => Navigator.of(context).pop(value),
                title: Text(role),
              ),
          ],
        ),
      ),
    );

    if (selected == null || selected.isEmpty || selected == member.role) {
      return;
    }

    try {
      await _staffApi.updateRole(staffId: member.id, role: selected);
      if (!mounted) return;
      await _loadStaff();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update staff role.')),
      );
    }
  }

  Future<void> _deactivate(OwnerStaffMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate staff member'),
        content: Text('Deactivate ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _staffApi.deactivate(member.id);
      if (!mounted) return;
      await _loadStaff();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff member deactivated')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to deactivate staff member.')),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_staff.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('No staff members yet.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final member = _staff[index];
        return AppCard(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
              ),
            ),
            title: Text(member.name),
            subtitle: Text('${member.roleLabel} - ${member.phone}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'role') {
                  _changeRole(member);
                } else if (value == 'deactivate') {
                  _deactivate(member);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'role', child: Text('Change role')),
                PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStaff,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Staff'),
      ),
      body: _buildBody(),
    );
  }
}
