import 'package:flutter/foundation.dart';

import '../model/media_upload_models.dart';
import '../service/media_upload_service.dart';

class MediaUploadController extends ChangeNotifier {
  MediaUploadController({MediaUploadService? service})
    : _service = service ?? MediaUploadService();

  final MediaUploadService _service;

  bool _isUploading = false;
  double _progress = 0;
  String? _errorMessage;
  MediaUploadResult? _lastUpload;

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  MediaUploadResult? get lastUpload => _lastUpload;

  Future<MediaUploadResult> uploadAsset({
    required OwnerMediaAssetType assetType,
    required String entityId,
    required List<int> bytes,
    required String contentType,
    OwnerKycDocType? docType,
  }) async {
    _isUploading = true;
    _progress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.uploadAndConfirm(
        assetType: assetType,
        entityId: entityId,
        docType: docType,
        bytes: bytes,
        contentType: contentType,
        onUploadProgress: (progress) {
          _progress = progress;
          notifyListeners();
        },
      );
      _lastUpload = result;
      return result;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }
}
