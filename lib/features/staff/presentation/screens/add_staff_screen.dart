import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/network/owner_api_client.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/owner_staff_api.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({
    super.key,
    this.initialRole = 'OWNER_STAFF',
    this.title = 'Add Staff',
    this.nameLabel = 'Full name',
    this.nameHint,
    this.emailLabel = 'Email',
    this.phoneLabel = 'Phone number',
    this.phoneHint,
    this.passwordLabel = 'Temporary password',
    this.roleLabel = 'Role',
    this.roles,
    this.primaryActionLabel = 'Save Staff',
    this.submittingLabel = 'Inviting...',
  });

  final String initialRole;
  final String title;
  final String nameLabel;
  final String? nameHint;
  final String emailLabel;
  final String phoneLabel;
  final String? phoneHint;
  final String passwordLabel;
  final String roleLabel;
  final List<String>? roles;
  final String primaryActionLabel;
  final String submittingLabel;

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final OwnerStaffApi _staffApi = OwnerStaffApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'OWNER_STAFF';
  bool _isSubmitting = false;
  String? _errorMessage;

  List<String> get _roles => widget.roles ?? const ['OWNER_ADMIN', 'OWNER_STAFF'];

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _staffApi.inviteStaff(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to add staff right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ScreenStateView(
        state: ScreenUiState.content,
        emptyTitle: 'No staff form',
        emptySubtitle: 'Invite a new staff member to the owner account.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: widget.nameLabel,
                        hintText: widget.nameHint,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: widget.emailLabel),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: widget.phoneLabel,
                        hintText: widget.phoneHint,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: widget.passwordLabel),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: InputDecoration(labelText: widget.roleLabel),
                      items: _roles
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _role = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _isSubmitting ? widget.submittingLabel : widget.primaryActionLabel,
              onPressed: _isSubmitting ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
