import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  static const _roles = ['Owner Staff', 'Owner Admin'];
  String _selectedRole = _roles[0];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveStaff() {
    if (_formKey.currentState!.validate()) {
      // Save staff logic here
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No staff form',
        emptySubtitle: 'Fill in the details to add a new staff member.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  children: [
                    AppInputField(
                      label: 'Staff name',
                      hint: 'Enter full name',
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Phone number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRoleSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save Staff',
              icon: Icons.person_add,
              onPressed: _saveStaff,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the staff role and permissions',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'Owner Staff',
              label: Text('Staff'),
              icon: Icon(Icons.person_outline),
            ),
            ButtonSegment(
              value: 'Owner Admin',
              label: Text('Admin'),
              icon: Icon(Icons.admin_panel_settings_outlined),
            ),
          ],
          selected: {_selectedRole},
          onSelectionChanged: (selection) {
            setState(() => _selectedRole = selection.first);
          },
        ),
      ],
    );
  }
}
