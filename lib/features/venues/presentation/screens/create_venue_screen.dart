import 'dart:io';

import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_input_field.dart';
import '../../../media/presentation/widgets/venue_image_upload_widget.dart';
import '../../../media/presentation/widgets/venue_image_gallery_widget.dart';
import '../../data/venue_image_upload_service.dart';
import '../../domain/models/venue_models.dart';
import '../controllers/venue_form_controller.dart';
import '../validators/owner_form_validators.dart';

class CreateVenueScreen extends StatefulWidget {
  const CreateVenueScreen({
    super.key,
    this.isEditMode = false,
    this.initialVenue,
  });

  final bool isEditMode;
  final Venue? initialVenue;

  @override
  State<CreateVenueScreen> createState() => _CreateVenueScreenState();
}

class _CreateVenueScreenState extends State<CreateVenueScreen> {
  final VenueFormController _formController = VenueFormController();
  final VenueImageUploadService _imageUploadService =
      OwnerVenueImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _fullRefundHoursController = TextEditingController(text: '24');
  final _partialRefundHoursController = TextEditingController(text: '12');
  final _partialRefundPctController = TextEditingController(text: '50');
  final _customAmenityController = TextEditingController();

  final List<String> _amenities = [];

  // Cover image
  bool _isUploadingCoverImage = false;
  double _coverImageUploadProgress = 0;
  String? _coverImageUploadStatusMessage;
  String? _uploadedCoverImageAssetId;
  String? _selectedCoverImagePath;
  String? _selectedCoverImageName;
  String? _uploadedCoverImageUrl;

  // Gallery images
  final List<String> _galleryImages = [];
  bool _isUploadingGalleryImage = false;
  double _galleryImageUploadProgress = 0;
  String? _galleryImageUploadStatusMessage;

  Venue? _savedVenue;

  @override
  void initState() {
    super.initState();
    final venue = widget.initialVenue;
    if (venue == null) return;

    _savedVenue = venue;
    _nameController.text = venue.name;
    _descriptionController.text = venue.description;
    _streetController.text = venue.address.street;
    _cityController.text = venue.address.city;
    _districtController.text = venue.address.district;
    _latitudeController.text = venue.latitude.toString();
    _longitudeController.text = venue.longitude.toString();
    _fullRefundHoursController.text = venue.fullRefundHours.toString();
    _partialRefundHoursController.text = venue.partialRefundHours.toString();
    _partialRefundPctController.text = venue.partialRefundPct.toString();
    _amenities.addAll(venue.amenities);
    
    // Set cover image if exists
    if (venue.imageUrl != null && venue.imageUrl!.isNotEmpty) {
      _uploadedCoverImageUrl = venue.imageUrl;
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _fullRefundHoursController.dispose();
    _partialRefundHoursController.dispose();
    _partialRefundPctController.dispose();
    _customAmenityController.dispose();
    super.dispose();
  }

  void _addAmenity() {
    final amenity = _customAmenityController.text.trim();
    if (amenity.isEmpty) return;
    setState(() {
      if (!_amenities.contains(amenity)) {
        _amenities.add(amenity);
      }
      _customAmenityController.clear();
    });
  }

  void _removeAmenity(String amenity) {
    setState(() => _amenities.remove(amenity));
  }

  Future<void> _pickCoverImage(XFile pickedFile) async {
    setState(() {
      _selectedCoverImagePath = pickedFile.path;
      _selectedCoverImageName = pickedFile.name;
      _coverImageUploadProgress = 0;
      _coverImageUploadStatusMessage = null;
    });
  }

  Future<void> _pickGalleryImage(XFile pickedFile) async {
    if (_galleryImages.length >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 gallery images allowed'),
        ),
      );
      return;
    }

    final imageFile = File(pickedFile.path);
    if (!await imageFile.exists()) {
      throw AppFailure('Selected image file does not exist.');
    }

    final bytes = await imageFile.readAsBytes();
    final contentType = _guessContentType(pickedFile.name);

    setState(() {
      _isUploadingGalleryImage = true;
      _galleryImageUploadProgress = 0;
      _galleryImageUploadStatusMessage = 'Uploading gallery image...';
    });

    try {
      final venueId = _savedVenue?.id;
      if (venueId == null || venueId.isEmpty) {
        throw AppFailure('Please save venue first before adding gallery images');
      }

      final result = await _imageUploadService.uploadVenueGalleryImage(
        venueId: venueId,
        contentType: contentType,
        bytes: bytes,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _galleryImageUploadProgress = progress);
        },
        onStatusMessage: (message) {
          if (!mounted) return;
          setState(() => _galleryImageUploadStatusMessage = message);
        },
        pollUntilReady: true,
      );

      final uploadedUrl = result.imageUrl;
      if (uploadedUrl != null && uploadedUrl.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _galleryImages.add(uploadedUrl);
          _galleryImageUploadStatusMessage = 'Gallery image added successfully!';
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _galleryImageUploadStatusMessage = null);
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      final normalizedError = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _galleryImageUploadStatusMessage = normalizedError.isNotEmpty
            ? normalizedError
            : 'Failed to upload gallery image';
      });
    } finally {
      if (mounted) {
        setState(() => _isUploadingGalleryImage = false);
      }
    }
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _uploadCoverImageForVenue(String venueId) async {
    if (_selectedCoverImagePath == null || _selectedCoverImageName == null) {
      return;
    }

    final imageFile = File(_selectedCoverImagePath!);
    if (!await imageFile.exists()) {
      throw AppFailure('Selected image file does not exist.');
    }

    final bytes = await imageFile.readAsBytes();
    final contentType = _guessContentType(_selectedCoverImageName!);

    setState(() {
      _isUploadingCoverImage = true;
      _coverImageUploadProgress = 0;
      _coverImageUploadStatusMessage = 'Preparing cover image upload...';
    });

    try {
      final result = await _imageUploadService.uploadVenueCoverImage(
        venueId: venueId,
        contentType: contentType,
        bytes: bytes,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _coverImageUploadProgress = progress);
        },
        onStatusMessage: (message) {
          if (!mounted) return;
          setState(() => _coverImageUploadStatusMessage = message);
        },
        pollUntilReady: true,
      );

      final currentVenue = _savedVenue;
      _uploadedCoverImageAssetId = result.assetId;

      final uploadedUrl = result.imageUrl;
      if (uploadedUrl != null && uploadedUrl.trim().isNotEmpty &&
          currentVenue != null) {
        _savedVenue = Venue(
          id: currentVenue.id,
          name: currentVenue.name,
          description: currentVenue.description,
          address: currentVenue.address,
          latitude: currentVenue.latitude,
          longitude: currentVenue.longitude,
          amenities: currentVenue.amenities,
          fullRefundHours: currentVenue.fullRefundHours,
          partialRefundHours: currentVenue.partialRefundHours,
          partialRefundPct: currentVenue.partialRefundPct,
          imageUrl: uploadedUrl,
          courtsCount: currentVenue.courtsCount,
          isVerified: currentVenue.isVerified,
          isActive: currentVenue.isActive,
        );

        if (!mounted) return;
        setState(() {
          _uploadedCoverImageUrl = uploadedUrl;
          _selectedCoverImagePath = null;
          _selectedCoverImageName = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCoverImage = false);
      }
    }
  }

  VenueUpsertRequest _buildRequest() {
    return VenueUpsertRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: VenueAddress(
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
      ),
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      amenities: List<String>.from(_amenities),
      fullRefundHours: int.parse(_fullRefundHoursController.text.trim()),
      partialRefundHours: int.parse(_partialRefundHoursController.text.trim()),
      partialRefundPct: int.parse(_partialRefundPctController.text.trim()),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final request = _buildRequest();

    try {
      final result = await _formController.submit(
        mode: widget.isEditMode ? VenueFormMode.edit : VenueFormMode.create,
        request: request,
        venueId: widget.initialVenue?.id,
      );

      _savedVenue = result;

      if (result != null && _selectedCoverImagePath != null) {
        await _uploadCoverImageForVenue(result.id);
      }

      if (!mounted) return;

      final pendingText =
          result?.isVerified == false ? ' Pending verification by admin.' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Venue updated successfully.$pendingText'
                : 'Venue created successfully.$pendingText',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final normalizedError = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _formController.errorMessage ??
                (normalizedError.isNotEmpty
                    ? normalizedError
                    : 'Failed to save venue. Please try again.'),
          ),
        ),
      );
    }
  }

  // ── Section helpers ──────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: AppFontWeights.bold),
      ),
    );
  }

  // ── Basics ───────────────────────────────────────────────────────────────

  Widget _basicInfoSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Basic Information'),
          AppInputField(
            label: 'Venue Name',
            hint: 'Enter venue name',
            prefixIcon: Icons.storefront_outlined,
            controller: _nameController,
            validator: (value) =>
                OwnerFormValidators.requiredText(value, 'Venue name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInputField(
            label: 'Description',
            hint: 'Describe the venue',
            prefixIcon: Icons.notes_outlined,
            controller: _descriptionController,
            validator: (value) =>
                OwnerFormValidators.requiredText(value, 'Description'),
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  // ── Address ──────────────────────────────────────────────────────────────

  Widget _addressSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Address & Coordinates'),
          AppInputField(
            label: 'Street',
            hint: 'Street address',
            prefixIcon: Icons.location_on_outlined,
            controller: _streetController,
            validator: (value) =>
                OwnerFormValidators.requiredText(value, 'Street'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInputField(
            label: 'City',
            hint: 'City',
            prefixIcon: Icons.location_city_outlined,
            controller: _cityController,
            validator: (value) =>
                OwnerFormValidators.requiredText(value, 'City'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInputField(
            label: 'District',
            hint: 'District',
            prefixIcon: Icons.map_outlined,
            controller: _districtController,
            validator: (value) =>
                OwnerFormValidators.requiredText(value, 'District'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppInputField(
                  label: 'Latitude',
                  hint: 'e.g. 27.7172',
                  controller: _latitudeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => OwnerFormValidators.doubleInRange(
                    value,
                    label: 'Latitude',
                    min: -90,
                    max: 90,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppInputField(
                  label: 'Longitude',
                  hint: 'e.g. 85.3240',
                  controller: _longitudeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => OwnerFormValidators.doubleInRange(
                    value,
                    label: 'Longitude',
                    min: -180,
                    max: 180,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Amenities ────────────────────────────────────────────────────────────

  Widget _amenitiesSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Amenities'),
          Text(
            'Type an amenity and tap Add to include it.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppInputField(
                  label: 'Amenity',
                  hint: 'e.g. Parking, WiFi, Shower…',
                  prefixIcon: Icons.local_offer_outlined,
                  controller: _customAmenityController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 92,
                height: 48,
                child: OutlinedButton(
                  onPressed: _addAmenity,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          if (_amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: _amenities
                  .map(
                    (a) => InputChip(
                      label: Text(a),
                      onDeleted: () => _removeAmenity(a),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  // ── Policy & Media ───────────────────────────────────────────────────────

  Widget _refundSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Refund Settings'),
          Row(
            children: [
              Expanded(
                child: AppInputField(
                  label: 'Full refund hours',
                  hint: '24',
                  controller: _fullRefundHoursController,
                  keyboardType: TextInputType.number,
                  validator: (value) => OwnerFormValidators.intInRange(
                    value,
                    label: 'Full refund hours',
                    min: 0,
                    max: 168,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppInputField(
                  label: 'Partial refund hours',
                  hint: '12',
                  controller: _partialRefundHoursController,
                  keyboardType: TextInputType.number,
                  validator: (value) => OwnerFormValidators.intInRange(
                    value,
                    label: 'Partial refund hours',
                    min: 0,
                    max: 72,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInputField(
            label: 'Partial refund percentage',
            hint: '50',
            controller: _partialRefundPctController,
            keyboardType: TextInputType.number,
            validator: (value) => OwnerFormValidators.intInRange(
              value,
              label: 'Partial refund percentage',
              min: 0,
              max: 100,
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _coverImageSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Cover Image'),
          VenueImageUploadWidget(
            label: 'Venue Cover Image',
            hint: 'Upload a high-quality cover image for your venue',
            selectedImagePath: _selectedCoverImagePath,
            uploadedImageUrl: _uploadedCoverImageUrl,
            isUploading: _isUploadingCoverImage,
            uploadProgress: _coverImageUploadProgress,
            uploadStatusMessage: _coverImageUploadStatusMessage,
            onImageSelected: (file) => _pickCoverImage(file),
          ),
        ],
      ),
    );
  }

  Widget _galleryImagesSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Gallery Images'),
          Text(
            'Add up to 10 images to showcase your venue (${_galleryImages.length}/10)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _savedVenue == null || _isUploadingGalleryImage
                ? null
                : () async {
                    final picked = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      await _pickGalleryImage(picked);
                    }
                  },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Gallery Image'),
          ),
          if (_galleryImageUploadStatusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _galleryImageUploadStatusMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_galleryImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            VenueImageGalleryWidget(
              label: 'Uploaded Images',
              galleryImages: _galleryImages,
              onImageTap: (index, imageUrl) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: InteractiveViewer(
                        child: Image.network(imageUrl),
                      ),
                    ),
                  ),
                );
              },
              onDeleteImage: (index) {
                setState(() => _galleryImages.removeAt(index));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gallery image removed')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final venueForStatus = _savedVenue ?? widget.initialVenue;

    return AnimatedBuilder(
      animation: _formController,
      builder: (context, _) {
        final busy = _formController.isSubmitting ||
            _isUploadingCoverImage ||
            _isUploadingGalleryImage;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isEditMode ? 'Edit Venue' : 'Create Venue'),
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                // Pending-verification banner
                if (venueForStatus != null && !venueForStatus.isVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Pending Verification: this venue is awaiting admin approval.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // ── All sections on one page ──────────────────────────────
                _basicInfoSection(context),
                const SizedBox(height: AppSpacing.md),
                _addressSection(context),
                const SizedBox(height: AppSpacing.md),
                _amenitiesSection(context),
                const SizedBox(height: AppSpacing.md),
                _refundSection(context),
                const SizedBox(height: AppSpacing.md),
                _coverImageSection(context),
                const SizedBox(height: AppSpacing.md),
                if (_savedVenue != null) _galleryImagesSection(context),
                if (_savedVenue != null) const SizedBox(height: AppSpacing.md),
                const SizedBox(height: AppSpacing.md),

                // ── Submit button ─────────────────────────────────────────
                AppButton(
                  label: widget.isEditMode ? 'Update Venue' : 'Create Venue',
                  icon: widget.isEditMode
                      ? Icons.save_outlined
                      : Icons.add_circle_outline,
                  isLoading: _formController.isSubmitting,
                  onPressed: busy ? null : _submit,
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
