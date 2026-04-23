import 'dart:async';

import '../model/media_upload_models.dart';
import 'owner_media_api.dart';

// ============================================================================
// MediaStatusPoller
//
// Correctness guarantees:
//  1. One polling loop per assetId — no duplicate parallel requests.
//  2. First check fires immediately (no dead window at startup).
//  3. Exactly 2.5 s gap *between* responses (sequential, not concurrent).
//  4. Hard timeout: 120 attempts × 2.5 s ≈ 5 min, then emits 'timeout'.
//  5. Duplicate-status suppression — only emits when status changes.
//  6. Auto-cleanup when the stream closes or the final status is reached.
//  7. Broadcast stream — multiple listeners may attach safely.
// ============================================================================

class MediaStatusPoller {
  MediaStatusPoller({OwnerMediaApi? mediaApi})
      : _mediaApi = mediaApi ?? OwnerMediaApi();

  final OwnerMediaApi _mediaApi;

  // One StreamController per active assetId
  final Map<String, StreamController<MediaAssetStatusResponse>>
      _controllers = {};

  // One polling Future per active assetId (replaces Timer to guarantee
  // sequential requests with a fixed *inter-response* delay)
  final Map<String, bool> _active = {};

  // Last emitted status per assetId (for dedup)
  final Map<String, MediaAssetStatusResponse> _lastStatus = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a broadcast stream for [assetId].
  ///
  /// Polling starts immediately on the first listener and stops automatically
  /// when status is `ready` or `failed`, or after the timeout is reached.
  Stream<MediaAssetStatusResponse> pollStatus(String assetId) {
    if (_controllers.containsKey(assetId)) {
      return _controllers[assetId]!.stream;
    }

    final controller = StreamController<MediaAssetStatusResponse>.broadcast(
      onCancel: () => _teardown(assetId),
    );
    _controllers[assetId] = controller;

    // Start polling loop as soon as the controller is wired up.
    // We do not wait for `onListen` because broadcast streams may already
    // have listeners attached synchronously by the caller.
    _startLoop(assetId);

    return controller.stream;
  }

  /// Cancel and clean up a specific asset poll.
  void cancel(String assetId) => _teardown(assetId);

  /// Cancel all active polls (call on app suspend / logout).
  void dispose() {
    final ids = List<String>.from(_active.keys);
    for (final id in ids) {
      _teardown(id);
    }
  }

  // ── Polling loop ──────────────────────────────────────────────────────────

  static const int _maxAttempts = 120;         // 5 min cap
  static const Duration _delay = Duration(milliseconds: 2500);

  Future<void> _startLoop(String assetId) async {
    _active[assetId] = true;

    int attempt = 0;

    while (_active[assetId] == true) {
      attempt++;

      // Hard timeout guard
      if (attempt > _maxAttempts) {
        _emit(
          assetId,
          const MediaAssetStatusResponse(status: 'timeout'),
        );
        break;
      }

      // ── Poll ───────────────────────────────────────────────────────────
      try {
        final status = await _mediaApi.getUploadStatus(assetId);

        if (!(_active[assetId] ?? false)) break; // cancelled during await

        _emit(assetId, status);

        if (status.isReady || status.isFailed) break;
      } catch (_) {
        // Network hiccup — log silently, keep polling.
        // Errors on individual requests should not break the polling loop.
      }

      // ── Inter-request delay (only if still active) ─────────────────────
      if (_active[assetId] == true) {
        await Future<void>.delayed(_delay);
      }
    }

    // Loop exited — perform final cleanup if not already done by teardown.
    _teardown(assetId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emit(String assetId, MediaAssetStatusResponse status) {
    final controller = _controllers[assetId];
    if (controller == null || controller.isClosed) return;

    // Suppress duplicate emissions
    final last = _lastStatus[assetId];
    if (last != null && last.status == status.status) return;

    _lastStatus[assetId] = status;
    controller.add(status);
  }

  void _teardown(String assetId) {
    _active.remove(assetId);
    _lastStatus.remove(assetId);

    final controller = _controllers.remove(assetId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }
}
