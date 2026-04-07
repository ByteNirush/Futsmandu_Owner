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
    this.title = 'Add Staff',
    this.description = 'Fill in the details to add a new staff member.',
    this.nameLabel = 'Staff name',
    this.nameHint = 'Enter full name',
    this.phoneLabel = 'Phone number',
    this.phoneHint = 'Enter phone number',
    this.roleSectionTitle = 'Role',
    this.roleSectionDescription = 'Select the staff role and permissions',
    this.primaryActionLabel = 'Save Staff',
    this.successMessage = 'Staff added successfully',
    this.roles = const ['Owner Staff', 'Owner Admin'],
    this.initialRole,
  });

  final ScreenUiState state;
  final String title;
  final String description;
  final String nameLabel;
  final String nameHint;
  final String phoneLabel;
  final String phoneHint;
  final String roleSectionTitle;
  final String roleSectionDescription;
  final String primaryActionLabel;
  final String successMessage;
  final List<String> roles;
  final String? initialRole;

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole =
        widget.initialRole != null && widget.roles.contains(widget.initialRole)
        ? widget.initialRole!
        : widget.roles.first;
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.successMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No ${widget.title.toLowerCase()} form',
        emptySubtitle: widget.description,
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  children: [
                    AppInputField(
                      label: widget.nameLabel,
                      hint: widget.nameHint,
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: widget.phoneLabel,
                      hint: widget.phoneHint,
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
              label: widget.primaryActionLabel,
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
          widget.roleSectionTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.roleSectionDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: widget.roles.map((role) {
            final isAdmin = role.toLowerCase().contains('admin');
            final isAnalyst = role.toLowerCase().contains('analyst');
            final label = isAnalyst
                ? 'Analyst'
                : isAdmin
                ? 'Admin'
                : 'Staff';

            return ButtonSegment<String>(
              value: role,
              label: Text(label),
              icon: Icon(
                isAnalyst
                    ? Icons.analytics_outlined
                    : isAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline,
              ),
            );
          }).toList(),
          selected: {_selectedRole},
          onSelectionChanged: (selection) {
            setState(() => _selectedRole = selection.first);
          },
        ),
      ],
    );
  }
}
