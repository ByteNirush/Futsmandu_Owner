import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/data/owner_auth_session_store.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/repositories/venues_repository_impl.dart';
import '../../domain/models/court_models.dart';
import '../../domain/repositories/venues_repository.dart';

class VenueCourtsController extends ChangeNotifier {
  VenueCourtsController({
    VenuesRepository? repository,
    OwnerAuthSessionStore? sessionStore,
  }) : _repository = repository ?? VenuesRepositoryImpl(),
       _sessionStore = sessionStore ?? OwnerAuthSessionStore() {
    _loadOwnerRole();
  }

  final VenuesRepository _repository;
  final OwnerAuthSessionStore _sessionStore;

  ScreenUiState _state = ScreenUiState.loading;
  List<Court> _courts = const [];
  String? _errorMessage;
  bool _isBusy = false;
  String? _ownerRole;
  bool _isDisposed = false;

  ScreenUiState get state => _state;
  List<Court> get courts => _courts;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get canDeleteCourt => (_ownerRole ?? '').toUpperCase() == 'OWNER_ADMIN';

  Future<void> _loadOwnerRole() async {
    if (_isDisposed) {
      return;
    }
    _ownerRole = await _sessionStore.getOwnerRole();
    _notifyIfMounted();
  }

  Future<void> loadCourts(String venueId) async {
    if (_isDisposed) {
      return;
    }

    _setState(ScreenUiState.loading);
    try {
      final courts = await _repository.listCourts(venueId);
      if (_isDisposed) {
        return;
      }

      _courts = courts;
      _errorMessage = null;
      _setState(_courts.isEmpty ? ScreenUiState.empty : ScreenUiState.content);
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _courts = const [];
      _errorMessage = error.toString();
      _setState(ScreenUiState.error);
    }
  }

  Future<void> saveCourt({
    required String venueId,
    required CourtUpsertRequest request,
    String? courtId,
  }) async {
    if (_isDisposed) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _notifyIfMounted();
    try {
      if (courtId == null || courtId.isEmpty) {
        await _repository.createCourt(venueId: venueId, request: request);
      } else {
        await _repository.updateCourt(courtId: courtId, request: request);
      }
      if (_isDisposed) {
        return;
      }

      await loadCourts(venueId);
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isDisposed) {
        return;
      }

      _isBusy = false;
      _notifyIfMounted();
    }
  }

  Future<void> deleteCourt({
    required String venueId,
    required String courtId,
  }) async {
    if (_isDisposed) {
      return;
    }

    if (!canDeleteCourt) {
      throw AppFailure('Only OWNER_ADMIN can delete courts.');
    }

    final previousCourts = _courts;
    _courts = _courts.where((court) => court.id != courtId).toList(growable: false);
    if (_courts.isEmpty) {
      _state = ScreenUiState.empty;
    }

    _isBusy = true;
    _errorMessage = null;
    _notifyIfMounted();
    try {
      await _repository.deleteCourt(courtId);
      if (_isDisposed) {
        return;
      }

      await loadCourts(venueId);
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      _courts = previousCourts;
      _state = _courts.isEmpty ? ScreenUiState.empty : ScreenUiState.content;
      _errorMessage = error.toString();
      _notifyIfMounted();
      rethrow;
    } finally {
      if (_isDisposed) {
        return;
      }

      _isBusy = false;
      _notifyIfMounted();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _setState(ScreenUiState nextState) {
    if (_isDisposed) {
      return;
    }

    if (_state == nextState) {
      _notifyIfMounted();
      return;
    }
    _state = nextState;
    _notifyIfMounted();
  }

  void _notifyIfMounted() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
