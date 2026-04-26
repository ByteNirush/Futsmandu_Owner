import 'dart:async';
import 'dart:math' as math;

import '../model/media_upload_models.dart';
import 'owner_media_api.dart';

// ============================================================================
// MediaStatusPoller
//
// Correctness guarantees:
//  1. One polling loop per assetId — no duplicate parallel requests.
//  2. First check fires immediately (no dead window at startup).
//  3. Adaptive delay based on progress and state transitions.
//  4. Exponential backoff for stalled processing (caps at 15s).
//  5. Hard timeout: 5 minutes total elapsed time.
//  6. Duplicate-status suppression — only emits when status/progress changes.
//  7. Broadcast stream — multiple listeners may attach safely.
// ============================================================================

class MediaStatusPoller {
  MediaStatusPoller({OwnerMediaApi? mediaApi})
      : _mediaApi = mediaApi ?? OwnerMediaApi();

  final OwnerMediaApi _mediaApi;

  // One StreamController per active assetId
  final Map<String, StreamController<MediaAssetStatusResponse>>
      _controllers = {};

  // One polling Future per active assetId
  final Map<String, bool> _active = {};

  // Last emitted status per assetId (for dedup and backoff calculation)
  final Map<String, MediaAssetStatusResponse> _lastStatus = {};

  // Track consecutive attempts with same state to apply backoff
  final Map<String, int> _consecutiveSameState = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a broadcast stream for [assetId].
  Stream<MediaAssetStatusResponse> pollStatus(String assetId) {
    if (_controllers.containsKey(assetId)) {
      return _controllers[assetId]!.stream;
    }

    final controller = StreamController<MediaAssetStatusResponse>.broadcast(
      onCancel: () => _teardown(assetId),
    );
    _controllers[assetId] = controller;

    _startLoop(assetId);

    return controller.stream;
  }

  /// Cancel and clean up a specific asset poll.
  void cancel(String assetId) => _teardown(assetId);

  /// Cancel all active polls.
  void dispose() {
    final ids = List<String>.from(_active.keys);
    for (final id in ids) {
      _teardown(id);
    }
  }

  // ── Polling loop ──────────────────────────────────────────────────────────

  static const Duration _maxTotalDuration = Duration(minutes: 5);

  Future<void> _startLoop(String assetId) async {
    _active[assetId] = true;
    _consecutiveSameState[assetId] = 0;

    final startTime = DateTime.now();

    while (_active[assetId] == true) {
      // Hard timeout guard
      if (DateTime.now().difference(startTime) > _maxTotalDuration) {
        _emit(
          assetId,
          const MediaAssetStatusResponse(status: 'timeout'),
        );
        break;
      }

      try {
        final status = await _mediaApi.getUploadStatus(assetId);

        if (!(_active[assetId] ?? false)) break;

        _updateBackoffState(assetId, status);
        _emit(assetId, status);

        if (status.isReady || status.isFailed) break;
      } catch (_) {
        // Network hiccup — increment backoff count to slow down.
        _consecutiveSameState[assetId] = (_consecutiveSameState[assetId] ?? 0) + 1;
      }

      if (_active[assetId] == true) {
        final delay = _calculateDelay(assetId);
        await Future<void>.delayed(delay);
      }
    }

    _teardown(assetId);
  }

  // ── Backoff & Delay Logic ──────────────────────────────────────────────────

  void _updateBackoffState(String assetId, MediaAssetStatusResponse newStatus) {
    final last = _lastStatus[assetId];
    
    // Reset backoff if status changed or progress moved forward
    final statusChanged = last?.status != newStatus.status;
    final progressAdvanced = (newStatus.progress ?? 0) > (last?.progress ?? 0);

    if (statusChanged || progressAdvanced) {
      _consecutiveSameState[assetId] = 0;
    } else {
      _consecutiveSameState[assetId] = (_consecutiveSameState[assetId] ?? 0) + 1;
    }
  }

  Duration _calculateDelay(String assetId) {
    const int baseMs = 2000;
    const int maxMs = 15000;
    
    final status = _lastStatus[assetId];
    final progress = status?.progress ?? 0;
    final consecutiveCount = _consecutiveSameState[assetId] ?? 0;

    // 1. Adaptive progress weight
    // Slow down early (processing overhead), speed up near end (snappy UX)
    double progressWeight = 1.0;
    if (progress < 30) {
      progressWeight = 2.5; 
    } else if (progress > 85) {
      progressWeight = 0.75;
    }

    // 2. Exponential backoff for stalled progress
    // Factor: 1.25, 1.56, 1.95, 2.44...
    double backoff = math.pow(1.25, consecutiveCount).toDouble();
    
    double targetMs = baseMs * progressWeight * backoff;

    // 3. Jitter (±10%) to prevent synchronized polling spikes
    final jitter = (math.Random().nextDouble() * 0.2) - 0.1;
    targetMs = targetMs * (1.0 + jitter);

    return Duration(milliseconds: targetMs.toInt().clamp(baseMs, maxMs));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emit(String assetId, MediaAssetStatusResponse status) {
    final controller = _controllers[assetId];
    if (controller == null || controller.isClosed) return;

    // Suppress duplicate emissions (only if status AND progress are identical)
    final last = _lastStatus[assetId];
    if (last != null && 
        last.status == status.status && 
        last.progress == status.progress) {
      return;
    }

    _lastStatus[assetId] = status;
    controller.add(status);
  }

  void _teardown(String assetId) {
    _active.remove(assetId);
    _lastStatus.remove(assetId);
    _consecutiveSameState.remove(assetId);

    final controller = _controllers.remove(assetId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }
}
