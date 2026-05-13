import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/incident_alert.dart';
import '../models/queued_alert.dart';
import 'alerts_service.dart';
import 'api_client.dart';

/// Offline-first Store & Forward engine for emergency alerts.
///
/// Design goals:
///   1. **Never lose an alert**: writes go to Isar inside a transaction
///      before any network call is attempted.
///   2. **Idempotency**: `clientEventId` is a unique index, so even a
///      panicked caller spamming enqueueAlert() can't create duplicates.
///   3. **Exponential backoff**: failed items are retried with increasing
///      delays (capped), and after [_maxRetries] they are marked as
///      `QueueStatus.failed` and stop consuming budget.
///   4. **Crash safe**: every status mutation is transactional.
class OfflineQueueService {
  static const String _isarName = 'jepo_offline_queue';
  static const int _maxRetries = 5;
  static const int _baseBackoffSec = 5;
  static const int _maxBackoffSec = 300; // 5 min cap

  static Isar? _isar;
  static bool _isSyncing = false;

  final ApiClient _api;

  OfflineQueueService(this._api);

  // ─── Isar bootstrap ───────────────────────────────────────────────────

  /// Open (or reuse) the Isar instance. Call once during app startup.
  static Future<Isar> initialize() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [QueuedAlertSchema],
      directory: dir.path,
      name: _isarName,
      inspector: kDebugMode,
    );
    return _isar!;
  }

  Isar get _db {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError(
        'OfflineQueueService.initialize() must be awaited before use.',
      );
    }
    return isar;
  }

  // ─── Public API ───────────────────────────────────────────────────────

  /// Persist an alert locally. Fast path: writes to Isar and returns — the
  /// sync loop will deliver it to the backend asynchronously.
  ///
  /// If [clientEventId] collides with an existing row (same logical event),
  /// the row is replaced thanks to the unique index with replace=true.
  Future<QueuedAlert> enqueueAlert(CreateIncidentAlertDto payload) async {
    final id = payload.clientEventId ?? _generateEventId();

    final row = QueuedAlert()
      ..clientEventId = id
      ..latitud = payload.latitud
      ..longitud = payload.longitud
      ..urlAudioContexto = payload.urlAudioContexto
      ..fechaHora = payload.fechaHora.toUtc()
      ..esProactiva = payload.esProactiva
      ..status = QueueStatus.pending
      ..retryCount = 0
      ..createdAt = DateTime.now().toUtc();

    await _db.writeTxn(() async {
      await _db.queuedAlerts.put(row);
    });

    debugPrint('OfflineQueue: enqueued id=${row.id} eventId=$id');
    return row;
  }

  /// Drain the pending queue. Safe to call repeatedly (e.g. on connectivity
  /// restore or by a periodic timer in the background service).
  ///
  /// Returns the number of alerts successfully delivered in this pass.
  Future<int> syncPending({int batchSize = 5}) async {
    if (_isSyncing) {
      debugPrint('OfflineQueue: sync skipped — another run is active');
      return 0;
    }
    _isSyncing = true;

    int delivered = 0;
    try {
      final now = DateTime.now().toUtc();

      final pending = await _db.queuedAlerts
          .filter()
          .statusEqualTo(QueueStatus.pending)
          .sortByCreatedAt()
          .limit(batchSize)
          .findAll();

      for (final row in pending) {
        // Respect exponential backoff between retries.
        if (!_isEligible(row, now)) continue;

        // Optimistic soft lock via status transition.
        await _db.writeTxn(() async {
          row.status = QueueStatus.sending;
          row.lastAttemptAt = now;
          await _db.queuedAlerts.put(row);
        });

        try {
          await AlertsService(_api).createAlert(
            CreateIncidentAlertDto(
              latitud: row.latitud,
              longitud: row.longitud,
              urlAudioContexto: row.urlAudioContexto ?? '',
              fechaHora: row.fechaHora,
              esProactiva: row.esProactiva,
              clientEventId: row.clientEventId,
            ),
          );

          await _db.writeTxn(() async {
            row.status = QueueStatus.sent;
            row.lastError = null;
            await _db.queuedAlerts.put(row);
          });
          delivered++;
          debugPrint('OfflineQueue: delivered eventId=${row.clientEventId}');
        } catch (e) {
          final isPermanent = _isPermanentError(e);
          await _db.writeTxn(() async {
            row.retryCount++;
            row.lastError = e.toString();
            row.lastAttemptAt = DateTime.now().toUtc();

            if (isPermanent || row.retryCount >= _maxRetries) {
              row.status = QueueStatus.failed;
            } else {
              row.status = QueueStatus.pending; // back to pending for retry
            }
            await _db.queuedAlerts.put(row);
          });
          debugPrint(
            'OfflineQueue: send failed eventId=${row.clientEventId} '
            'retry=${row.retryCount} err=$e',
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
    return delivered;
  }

  /// Count of alerts currently waiting to be sent.
  Future<int> pendingCount() {
    return _db.queuedAlerts.filter().statusEqualTo(QueueStatus.pending).count();
  }

  /// Remove rows that were successfully sent more than [retention] ago.
  Future<int> purgeOldSent({
    Duration retention = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(retention);
    return _db.writeTxn(() async {
      return _db.queuedAlerts
          .filter()
          .statusEqualTo(QueueStatus.sent)
          .createdAtLessThan(cutoff)
          .deleteAll();
    });
  }

  /// Reactive stream of pending counts — bind to UI (Riverpod StreamProvider).
  Stream<int> watchPendingCount() {
    return _db.queuedAlerts
        .filter()
        .statusEqualTo(QueueStatus.pending)
        .watch(fireImmediately: true)
        .map((rows) => rows.length);
  }

  // ─── Internals ────────────────────────────────────────────────────────

  bool _isEligible(QueuedAlert row, DateTime now) {
    if (row.retryCount == 0 || row.lastAttemptAt == null) return true;
    final delaySec = (_baseBackoffSec * (1 << row.retryCount)).clamp(
      1,
      _maxBackoffSec,
    );
    final nextAttempt = row.lastAttemptAt!.add(Duration(seconds: delaySec));
    return now.isAfter(nextAttempt);
  }

  bool _isPermanentError(Object e) {
    if (e is ApiException) {
      // 4xx except 408/425/429 are non-retryable.
      if (e.statusCode >= 400 &&
          e.statusCode < 500 &&
          e.statusCode != 408 &&
          e.statusCode != 425 &&
          e.statusCode != 429) {
        return true;
      }
    }
    return false;
  }

  String _generateEventId() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final rng = now.hashCode ^ DateTime.now().millisecond;
    return '${now.toRadixString(36)}-${rng.toRadixString(36)}';
  }
}
