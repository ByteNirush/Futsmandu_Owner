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
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _fullRefundHoursController = TextEditingController(text: '24');
  final _partialRefundHoursController = TextEditingController(text: '12');
  final _partialRefundPctController = TextEditingController(text: '50');
  final _customAmenityController = TextEditingController();

  final List<String> _amenities = [];

  // Available cities for dropdown
  static const List<String> _cities = [
    'Kathmandu',
    'Lalitpur',
    'Bhaktapur',
  ];

  String? _selectedCity;

  // Cover image
  bool _isUploadingCoverImage = false;
  double _coverImageUploadProgress = 0;
  String? _coverImageUploadStatusMessage;
  String? _selectedCoverImagePath;
  String? _selectedCoverImageName;
  String? _uploadedCoverImageUrl;

  // Gallery images
  final List<String> _galleryImages = [];
  bool _isUploadingGalleryImage = false;
  String? _galleryImageUploadStatusMessage;

  Venue? _savedVenue;
  bool _isSaveLocked = false;

  @override
  void initState() {
    super.initState();
    final venue = widget.initialVenue;
    if (venue == null) return;

    _savedVenue = venue;
    _nameController.text = venue.name;
    _descriptionController.text = venue.description;
    _streetController.text = venue.address.street;
    _selectedCity = venue.address.city.isNotEmpty ? venue.address.city : null;
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
        onProgress: (_) {},
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

  bool get _hasUnsavedChanges {
    final isEditMode = widget.isEditMode;
    if (!isEditMode) {
      return _nameController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty ||
          _streetController.text.trim().isNotEmpty ||
          _selectedCity != null ||
          _districtController.text.trim().isNotEmpty ||
          _latitudeController.text.trim().isNotEmpty ||
          _longitudeController.text.trim().isNotEmpty ||
          _amenities.isNotEmpty ||
          _fullRefundHoursController.text.trim() != '24' ||
          _partialRefundHoursController.text.trim() != '12' ||
          _partialRefundPctController.text.trim() != '50' ||
          _selectedCoverImagePath != null ||
          _uploadedCoverImageUrl != null ||
          _galleryImages.isNotEmpty;
    }

    final initialVenue = widget.initialVenue;
    if (initialVenue == null) {
      return false;
    }

    return _nameController.text.trim() != initialVenue.name ||
        _descriptionController.text.trim() != initialVenue.description ||
        _streetController.text.trim() != initialVenue.address.street ||
        (_selectedCity ?? '') != initialVenue.address.city ||
        _districtController.text.trim() != initialVenue.address.district ||
        _latitudeController.text.trim() != initialVenue.latitude.toString() ||
        _longitudeController.text.trim() != initialVenue.longitude.toString() ||
        _fullRefundHoursController.text.trim() !=
            initialVenue.fullRefundHours.toString() ||
        _partialRefundHoursController.text.trim() !=
            initialVenue.partialRefundHours.toString() ||
        _partialRefundPctController.text.trim() !=
            initialVenue.partialRefundPct.toString() ||
        _amenities.join('|') != initialVenue.amenities.join('|') ||
        _selectedCoverImagePath != null ||
        _galleryImages.isNotEmpty;
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

  Future<void> _confirmAndSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.isEditMode ? 'Save venue changes?' : 'Create venue?'),
        content: Text(
          widget.isEditMode
              ? 'This will update the venue details and publish the changes.'
              : 'This will create the venue record and make it available in the owner panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(widget.isEditMode ? 'Save' : 'Create Venue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _submit();
  }

  VenueUpsertRequest _buildRequest() {
    return VenueUpsertRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: VenueAddress(
        street: _streetController.text.trim(),
        city: _selectedCity ?? '',
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

    if (mounted) {
      setState(() => _isSaveLocked = true);
    } else {
      _isSaveLocked = true;
    }

    try {
      final request = _buildRequest();

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
    } finally {
      if (mounted) {
        setState(() => _isSaveLocked = false);
      } else {
        _isSaveLocked = false;
      }
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
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            hint: const Text('Select City'),
            decoration: InputDecoration(
              labelText: 'City',
              prefixIcon: const Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _cities.map((city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'City is required';
              }
              return null;
            },
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

  Future<void> _addGalleryImageFromPicker() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      await _pickGalleryImage(picked);
    }
  }

  Widget _galleryImagesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSaved = _savedVenue != null;
    final atMax = _galleryImages.length >= 10;
    final canAdd = isSaved && !_isUploadingGalleryImage && !atMax;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: title + add button ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _sectionHeader(context, 'Gallery Images')),
              if (isSaved)
                Tooltip(
                  message: atMax
                      ? 'Maximum 10 images reached'
                      : _isUploadingGalleryImage
                          ? 'Upload in progress…'
                          : 'Add a photo',
                  child: FilledButton.tonal(
                    onPressed: canAdd ? _addGalleryImageFromPicker : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          atMax
                              ? Icons.photo_library_outlined
                              : Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(atMax ? 'Gallery full' : 'Add Photo'),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Locked state (venue not yet saved) ──────────────────────
          if (!isSaved) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Save your venue first',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gallery photos can be added after the venue is created.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // ── Active gallery ─────────────────────────────────────────
          if (isSaved) ...[
            const SizedBox(height: AppSpacing.sm),
            VenueImageGalleryWidget(
              label: 'Uploaded Images',
              galleryImages: _galleryImages,
              isUploading: _isUploadingGalleryImage,
              uploadStatusMessage: _galleryImageUploadStatusMessage,
              maxImages: 10,
              onAddImage: canAdd ? _addGalleryImageFromPicker : null,
              onImageTap: (index, imageUrl) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                );
              },
              onDeleteImage: (index) {
                setState(() => _galleryImages.removeAt(index));
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
          _isSaveLocked ||
            _isUploadingCoverImage ||
            _isUploadingGalleryImage;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            
            // If already uploading/submitting, prevent pop to avoid ghost requests
            if (busy) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please wait for the current operation to finish.')),
              );
              return;
            }

            if (!_hasUnsavedChanges) {
              Navigator.of(context).pop();
              return;
            }

            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            );

            if (shouldPop == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
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
                _galleryImagesSection(context),
                const SizedBox(height: AppSpacing.md),

                // ── Submit button ─────────────────────────────────────────
                AppButton(
                  label: widget.isEditMode ? 'Update Venue' : 'Create Venue',
                  icon: widget.isEditMode
                      ? Icons.save_outlined
                      : Icons.add_circle_outline,
                  isLoading: _formController.isSubmitting,
                  onPressed: busy ? null : _confirmAndSubmit,
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}
