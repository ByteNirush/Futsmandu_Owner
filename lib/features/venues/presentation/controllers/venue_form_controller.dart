import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/venues_repository_impl.dart';
import '../../domain/models/venue_models.dart';
import '../../domain/repositories/venues_repository.dart';

enum VenueFormMode { create, edit }

class VenueFormController extends ChangeNotifier {
  VenueFormController({VenuesRepository? repository})
    : _repository = repository ?? VenuesRepositoryImpl();

  final VenuesRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<Venue?> submit({
    required VenueFormMode mode,
    required VenueUpsertRequest request,
    String? venueId,
  }) async {
    if (_isSubmitting) {
      throw AppFailure('A venue save is already in progress.');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (mode == VenueFormMode.edit) {
        if (venueId == null || venueId.isEmpty) {
          throw AppFailure('Missing venue ID for update.');
        }
        return await _repository.updateVenue(
          venueId: venueId,
          request: request,
        );
      }
      return await _repository.createVenue(request);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
