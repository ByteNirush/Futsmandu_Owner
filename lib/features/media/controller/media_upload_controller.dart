import 'package:flutter/foundation.dart';

import '../model/media_upload_models.dart';
import '../service/media_upload_service.dart';

// ============================================================================
// MediaUploadController
// ChangeNotifier that wraps MediaUploadService with upload state (progress,
// error, result). UI binds to this via Provider / Riverpod / etc.
// ============================================================================

class MediaUploadController extends ChangeNotifier {
  MediaUploadController({MediaUploadService? service})
      : _service = service ?? MediaUploadService();

  final MediaUploadService _service;

  bool _isUploading = false;
  double _progress = 0;
  String? _statusMessage;
  String? _errorMessage;
  MediaUploadResult? _lastUpload;
  bool _disposed = false;

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  MediaUploadResult? get lastUpload => _lastUpload;

  // --------------------------------------------------------------------------
  // Typed upload methods — call the matching service method per asset type.
  // --------------------------------------------------------------------------

  Future<MediaUploadResult> uploadKycDocument({
    required OwnerKycDocType docType,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = false,
  }) {
    return _run(
      () => _service.uploadKycDocument(
        docType: docType,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onStatusMessage: _setStatus,
        onUploadProgress: _setProgress,
      ),
    );
  }

  Future<MediaUploadResult> uploadOwnerAvatar({
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
  }) {
    return _run(
      () => _service.uploadOwnerAvatar(
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onStatusMessage: _setStatus,
        onUploadProgress: _setProgress,
      ),
    );
  }

  Future<MediaUploadResult> uploadVenueCover({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
  }) {
    return _run(
      () => _service.uploadVenueCover(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onStatusMessage: _setStatus,
        onUploadProgress: _setProgress,
      ),
    );
  }

  Future<MediaUploadResult> uploadVenueGalleryImage({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = true,
  }) {
    return _run(
      () => _service.uploadVenueGalleryImage(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onStatusMessage: _setStatus,
        onUploadProgress: _setProgress,
      ),
    );
  }

  Future<MediaUploadResult> uploadVenueVerification({
    required String venueId,
    required List<int> bytes,
    required String contentType,
    bool pollUntilReady = false,
  }) {
    return _run(
      () => _service.uploadVenueVerification(
        venueId: venueId,
        bytes: bytes,
        contentType: contentType,
        pollUntilReady: pollUntilReady,
        onStatusMessage: _setStatus,
        onUploadProgress: _setProgress,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Utility
  // --------------------------------------------------------------------------

  Future<String> getPrivateDownloadUrl(String key) =>
      _service.getPrivateDownloadUrl(key);

  Future<FetchKycDocumentsResponse> fetchAllKycDocuments() =>
      _service.fetchAllKycDocuments();

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Internals
  // --------------------------------------------------------------------------

  /// Safely notify listeners without throwing if controller is disposed
  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e) {
        // Silently ignore if already disposed
      }
    }
  }

  Future<MediaUploadResult> _run(
    Future<MediaUploadResult> Function() task,
  ) async {
    _isUploading = true;
    _progress = 0;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotifyListeners();

    try {
      final result = await task();
      _lastUpload = result;
      return result;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploading = false;
      _statusMessage = null;
      _safeNotifyListeners();
    }
  }

  void _setProgress(double progress) {
    _progress = progress;
    _safeNotifyListeners();
  }

  void _setStatus(String message) {
    _statusMessage = message;
    _safeNotifyListeners();
  }
}
