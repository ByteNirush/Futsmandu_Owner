import 'package:flutter/foundation.dart';

import '../../../../shared/widgets/screen_state_view.dart';
import '../../data/repositories/venues_repository_impl.dart';
import '../../domain/models/venue_models.dart';
import '../../domain/repositories/venues_repository.dart';

class VenuesListController extends ChangeNotifier {
  VenuesListController({VenuesRepository? repository})
    : _repository = repository ?? VenuesRepositoryImpl();

  final VenuesRepository _repository;

  ScreenUiState _state = ScreenUiState.loading;
  List<Venue> _venues = const [];
  String? _errorMessage;
  bool _isRefreshing = false;

  ScreenUiState get state => _state;
  List<Venue> get venues => _venues;
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;

  Future<void> loadVenues() async {
    _setState(ScreenUiState.loading);
    try {
      final venues = await _repository.listVenues();
      _venues = venues;
      _errorMessage = null;
      _setState(_venues.isEmpty ? ScreenUiState.empty : ScreenUiState.content);
    } catch (error) {
      _venues = const [];
      _errorMessage = error.toString();
      _setState(ScreenUiState.error);
    }
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await loadVenues();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> reloadAfterMutation() async {
    await loadVenues();
  }

  void _setState(ScreenUiState nextState) {
    if (_state == nextState) {
      notifyListeners();
      return;
    }
    _state = nextState;
    notifyListeners();
  }
}
