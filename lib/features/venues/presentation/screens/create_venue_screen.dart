import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../../shared/widgets/screen_state_view.dart';

class CreateVenueScreen extends StatefulWidget {
  const CreateVenueScreen({
    super.key,
    this.state = ScreenUiState.content,
    this.isEditMode = false,
  });

  final ScreenUiState state;
  final bool isEditMode;

  @override
  State<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends State<CreateVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amenitiesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  void _saveVenue() {
    if (_formKey.currentState!.validate()) {
      // Save venue logic here
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode ? 'Venue updated successfully' : 'Venue created successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Venue' : 'Create Venue'),
      ),
      body: ScreenStateView(
        state: widget.state,
        emptyTitle: 'No venue form',
        emptySubtitle: 'Fill in the venue details to continue.',
        content: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              AppCard(
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
                      label: 'Venue Name',
                      hint: 'Enter venue name',
                      prefixIcon: Icons.storefront_outlined,
                      controller: _nameController,
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
                      label: 'City',
                      hint: 'Enter city',
                      prefixIcon: Icons.location_city_outlined,
                      controller: _cityController,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Phone Number',
                      hint: 'Enter contact phone',
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Email',
                      hint: 'Enter contact email',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your venue',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppInputField(
                      label: 'Amenities',
                      hint: 'e.g., Parking, WiFi, Showers',
                      prefixIcon: Icons.local_offer_outlined,
                      controller: _amenitiesController,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildMediaUploadRow(
                      context,
                      icon: Icons.image_outlined,
                      title: 'Venue Images',
                      subtitle: 'Add photos of your venue',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildMediaUploadRow(
                      context,
                      icon: Icons.video_collection_outlined,
                      title: 'Venue Video',
                      subtitle: 'Add a promotional video',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: widget.isEditMode ? 'Update Venue' : 'Save Venue',
                icon: widget.isEditMode ? Icons.save_outlined : Icons.add,
                isLoading: false,
                onPressed: _saveVenue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // Upload media
          },
          icon: const Icon(Icons.upload_outlined, size: 18),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}
