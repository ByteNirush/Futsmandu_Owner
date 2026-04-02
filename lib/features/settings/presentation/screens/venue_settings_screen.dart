import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class VenueSettingsScreen extends StatefulWidget {
  const VenueSettingsScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  State<VenueSettingsScreen> createState() => _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends State<VenueSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _venueNameController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Save venue settings logic here
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue settings updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venue Settings')),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No venue settings data',
        emptySubtitle: 'Update venue details and preferences here.',
        content: ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            Form(
              key: _formKey,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Venue name',
                      hint: 'Enter venue name',
                      prefixIcon: Icons.storefront_outlined,
                      controller: _venueNameController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Address',
                      hint: 'Enter venue address',
                      prefixIcon: Icons.location_on_outlined,
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Contact phone',
                      hint: 'Enter contact phone',
                      prefixIcon: Icons.phone_outlined,
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
