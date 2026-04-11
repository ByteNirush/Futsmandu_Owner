import 'dart:async';

import '../model/media_upload_models.dart';
import 'owner_media_api.dart';

// ============================================================================
// MediaStatusPoller
// Eliminates duplicate polling by maintaining ONE polling stream per assetId
// ============================================================================

class MediaStatusPoller {
  MediaStatusPoller({OwnerMediaApi? mediaApi})
      : _mediaApi = mediaApi ?? OwnerMediaApi();

  final OwnerMediaApi _mediaApi;

  // Map<assetId, StreamController> — one stream controller per asset
  final Map<String, StreamController<MediaAssetStatusResponse>> _streamControllers =
      <String, StreamController<MediaAssetStatusResponse>>{};

  // Map<assetId, Timer> — one timer per asset to prevent multiple polling
  final Map<String, Timer> _timers = <String, Timer>{};

  // Map<assetId, lastStatus> — cache last status to avoid duplicate emissions
  final Map<String, MediaAssetStatusResponse> _lastStatus =
      <String, MediaAssetStatusResponse>{};

  /// Returns a broadcast stream for the given assetId.
  /// Multiple listeners can subscribe.
  /// Polling stops automatically when status becomes "ready" or "failed".
  Stream<MediaAssetStatusResponse> pollStatus(String assetId) {
    // Return existing stream if already polling
    if (_streamControllers.containsKey(assetId)) {
      return _streamControllers[assetId]!.stream;
    }

    // Create new stream controller (broadcast so multiple listeners can attach)
    final controller =
        StreamController<MediaAssetStatusResponse>.broadcast(
      onListen: () => _startPolling(assetId),
      onCancel: () => _checkAndStopPolling(assetId),
    );

    _streamControllers[assetId] = controller;
    return controller.stream;
  }

  /// Start polling for an assetId (interval: 2.5 seconds, max attempts: 120 = 5 minutes)
  void _startPolling(String assetId) {
    if (_timers.containsKey(assetId)) {
      return; // Already polling
    }

    int attempt = 0;
    const maxAttempts = 120; // ~5 minutes max
    const interval = Duration(seconds: 2);

    _timers[assetId] = Timer.periodic(interval, (_) async {
      if (attempt >= maxAttempts) {
        _emitAndStop(
          assetId,
          const MediaAssetStatusResponse(status: 'processing'),
        );
        return;
      }

      try {
        final status = await _mediaApi.getUploadStatus(assetId);
        attempt++;

        // Only emit if status changed (avoid duplicate events)
        final last = _lastStatus[assetId];
        if (last == null || last.status != status.status) {
          _lastStatus[assetId] = status;
          _streamControllers[assetId]?.add(status);
        }

        // Stop polling if ready or failed
        if (status.isReady || status.isFailed) {
          _emitAndStop(assetId, status);
        }
      } catch (e) {
        // Do not emit error, just log and continue polling
        // This keeps the stream alive even if one request fails
      }
    });
  }

  /// Emit final status and stop polling
  void _emitAndStop(String assetId, MediaAssetStatusResponse status) {
    _lastStatus[assetId] = status;
    _streamControllers[assetId]?.add(status);
    _stopPolling(assetId);
  }

  /// Stop polling and check if we can clean up
  void _stopPolling(String assetId) {
    _timers[assetId]?.cancel();
    _timers.remove(assetId);

    // Clean up if no listeners
    _checkAndStopPolling(assetId);
  }

  /// Check if stream has listeners; if not, close and cleanup
  void _checkAndStopPolling(String assetId) {
    final controller = _streamControllers[assetId];
    if (controller != null && !controller.hasListener) {
      _timers[assetId]?.cancel();
      _timers.remove(assetId);
      controller.close();
      _streamControllers.remove(assetId);
      _lastStatus.remove(assetId);
    }
  }

  /// Cleanup all active polls (call on app shutdown)
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _lastStatus.clear();
  }
}
