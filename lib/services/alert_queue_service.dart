import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident_alert.dart';
import 'alerts_service.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'diagnostic_log_service.dart';
import 'emergency_contacts_cache.dart';
import 'pre_alert_service.dart';
import 'session_events.dart';
import 'sms_fallback_service.dart';

class AlertQueueResult {
  final int sent;
  final int remaining;

  const AlertQueueResult({required this.sent, required this.remaining});
}

/// Robust alert queue with strict anti-spam controls.
///
/// Key invariants:
/// 1. **1 alert per incident** — only the first alert for a logical incident
///    is dispatched; subsequent events within the cooldown are dropped.
/// 2. **Incident cooldown** — [_incidentCooldownSeconds] (10 min) between
///    independent incident creations.
/// 3. **Deduplication by event_id** — duplicate [clientEventId] values are
///    detected and rejected before network calls.
/// 4. **Backoff exponential + jitter** — queued items retry with increasing
///    delays capped at [_maxBackoffMs].
/// 5. **Retry limit** — items exceeding [_maxRetries] are dropped.
/// 6. **Max 1 active send per cycle** — processQueue sends at most 1 item
///    per invocation to avoid burst traffic.
class AlertQueueService {
  static const String _queueKey = 'jepo_pending_alerts_queue';
  static const String _lastSentKey = 'jepo_last_sent_alert_at';
  static const String _sentEventIdsKey = 'jepo_sent_event_ids';
  static const String _activeIncidentIdKey = 'jepo_active_incident_id';
  static const String _incidentStartKey = 'jepo_incident_start_at';

  /// Prevent concurrent processing/send operations from multiple callers.
  static bool _isProcessing = false;

  /// Incident cooldown: minimum seconds between two independent incident
  /// creations. Location heartbeats during an active incident bypass this.
  static const int _incidentCooldownSeconds = 60; // 1 minute

  /// Maximum number of retries before a queued item is dropped permanently.
  static const int _maxRetries = 5;

  /// Base delay for exponential backoff (ms).
  static const int _baseBackoffMs = 500;

  /// Maximum backoff delay cap (ms).
  static const int _maxBackoffMs = 60000; // 1 minute

  /// Maximum number of event IDs to remember for deduplication.
  static const int _maxDedupeHistory = 200;

  /// In-memory cached last-sent timestamp.
  static DateTime? _lastSentMemory;
  static bool _lastSentMemoryInitialized = false;

  final ApiClient api;

  AlertQueueService(this.api);

  bool _isTransientFailure(Object e) {
    if (e is ApiException) {
      return e.isTransient;
    }
    if (e is TimeoutException) {
      return true;
    }
    if (e is http.ClientException) {
      return true;
    }
    if (e is SocketException) {
      return true;
    }
    final text = e.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('timed out') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Attempt to send an alert immediately. If conditions are not met (no
  /// session, cooldown active, duplicate, processing lock), the alert is either
  /// dropped or enqueued for later retry.
  ///
  /// Returns `true` if the alert was sent successfully, `false` otherwise.
  Future<bool> sendOrQueue(
    CreateIncidentAlertDto payload, {
    bool bypassConfirmation = false,
  }) async {
    // If session has been invalidated, don't even attempt.
    if (SessionEvents.isInvalidated) {
      debugPrint('AlertQueueService: session invalidated, enqueuing');
      await enqueueAlert(payload, reason: 'session_invalidated');
      return false;
    }

    // Deduplicate by client event ID
    if (payload.clientEventId != null &&
        payload.clientEventId!.isNotEmpty &&
        await _isEventAlreadySent(payload.clientEventId!)) {
      debugPrint(
        'AlertQueueService: duplicate event_id=${payload.clientEventId}, dropping',
      );
      return false;
    }

    // Before notifying anyone, request user confirmation to prevent false positives.
    if (!bypassConfirmation) {
      final shouldSend = await PreAlertService.requestConfirmation(seconds: 10);
      if (!shouldSend) {
        debugPrint('AlertQueueService: user confirmed safe, dropping alert');
        return false;
      }
    }

    // Incident cooldown check: only allow a new incident if enough time has
    // passed since the last one.
    if (payload.esProactiva) {
      final canCreate = await _canCreateNewIncident();
      if (!canCreate) {
        debugPrint(
          'AlertQueueService: incident cooldown active, dropping proactive alert',
        );
        return false;
      }
    }

    // Acquire processing lock.
    if (_isProcessing) {
      debugPrint(
        'AlertQueueService: sendOrQueue called while processing; enqueuing',
      );
      await enqueueAlert(payload, reason: 'concurrent_process');
      return false;
    }

    _isProcessing = true;
    try {
      await _ensureLastSentLoaded();

      final auth = AuthService(api);
      final hasSession = await auth.hasActiveSession();
      if (!hasSession) {
        await enqueueAlert(payload, reason: 'no_active_session');
        return false;
      }

      try {
        final result = await AlertsService(api).createAlert(payload);
        if (kDebugMode) {
          debugPrint(
            'AlertQueueService: backend alert sent successfully; SMS fallback not needed.',
          );
        }
        try {
          await EmergencyContactsCache.replaceVerifiedContacts(
            result.contactosNotificar,
          );
        } catch (_) {}
        final now = DateTime.now().toUtc();
        await _writeLastSent(now);

        // Record event ID for deduplication.
        if (payload.clientEventId != null &&
            payload.clientEventId!.isNotEmpty) {
          await _recordSentEventId(payload.clientEventId!);
        }

        // Track active incident for cooldown and heartbeat logic.
        if (payload.esProactiva && result.alerta?.id != null) {
          await _setActiveIncident(result.alerta!.id!, now);
          DiagnosticLogService.logIncidentCreated(
            alertId: result.alerta!.id!,
            eventId: payload.clientEventId,
          );
        }

        DiagnosticLogService.logAlertSent(eventId: payload.clientEventId);
        return true;
      } catch (e) {
        final isTransient = _isTransientFailure(e);
        if (isTransient) {
          if (kDebugMode) {
            debugPrint(
              'AlertQueueService: backend failed with transient error, invoking SMS fallback: $e',
            );
          }
          try {
            await SmsFallbackService().trySendFallbackSms(payload);
          } catch (smsError) {
            debugPrint('AlertQueueService: SMS fallback failed: $smsError');
          }
        } else if (kDebugMode) {
          debugPrint(
            'AlertQueueService: backend failed with non-transient error, SMS fallback skipped: $e',
          );
        }

        if (e is ApiException &&
            !e.isTransient &&
            e.statusCode >= 400 &&
            e.statusCode < 500 &&
            e.statusCode != 429) {
          debugPrint(
            'AlertQueueService: permanent error ${e.statusCode}, dropping: ${e.message}',
          );
          DiagnosticLogService.logAlertDropped(
            eventId: payload.clientEventId,
            reason: '${e.statusCode}: ${e.message}',
          );
          return false;
        }
        await enqueueAlert(payload, reason: e.toString());
        DiagnosticLogService.logAlertQueued(
          eventId: payload.clientEventId,
          reason: e.toString(),
        );
        return false;
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Process the pending queue. Sends **at most 1 item** per invocation to
  /// avoid burst traffic, respecting backoff delays and retry limits.
  Future<AlertQueueResult> processQueue({int maxItems = 1}) async {
    if (_isProcessing) {
      debugPrint(
        'AlertQueueService: processQueue skipped — another run is active',
      );
      return AlertQueueResult(sent: 0, remaining: await pendingCount());
    }

    // If session has been invalidated, skip processing entirely.
    if (SessionEvents.isInvalidated) {
      return AlertQueueResult(sent: 0, remaining: await pendingCount());
    }

    _isProcessing = true;
    try {
      final auth = AuthService(api);
      if (!await auth.hasActiveSession()) {
        return AlertQueueResult(sent: 0, remaining: await pendingCount());
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_queueKey) ?? [];
      if (raw.isEmpty) {
        return const AlertQueueResult(sent: 0, remaining: 0);
      }

      // Take a limited batch.
      final toProcess = raw.take(maxItems).toList();
      final toKeep = raw.skip(maxItems).toList();

      int sent = 0;

      for (int i = 0; i < toProcess.length; i++) {
        final encoded = toProcess[i];
        try {
          final item = jsonDecode(encoded) as Map<String, dynamic>;
          final retries = (item['retries'] as int? ?? 0);

          // Drop items that exceeded the retry limit.
          if (retries >= _maxRetries) {
            debugPrint(
              'AlertQueueService: dropping item after $_maxRetries retries',
            );
            continue;
          }

          // Check backoff: this item should not be retried before its
          // computed next-eligible time.
          final lastAttempt = item['last_attempt_at'] as String?;
          if (lastAttempt != null && retries > 0) {
            final lastDt = DateTime.tryParse(lastAttempt)?.toUtc();
            if (lastDt != null) {
              final backoff = _computeBackoff(retries);
              if (DateTime.now().toUtc().difference(lastDt) < backoff) {
                // Not yet eligible — put back and skip.
                toKeep.insert(0, encoded);
                continue;
              }
            }
          }

          final payload = CreateIncidentAlertDto.fromJson(
            (item['payload'] as Map).cast<String, dynamic>(),
          );

          // Deduplication for queued items.
          if (payload.clientEventId != null &&
              payload.clientEventId!.isNotEmpty &&
              await _isEventAlreadySent(payload.clientEventId!)) {
            debugPrint(
              'AlertQueueService: queued duplicate event_id=${payload.clientEventId}, dropping',
            );
            continue;
          }

          await AlertsService(api).createAlert(payload);
          sent++;

          await _writeLastSent(DateTime.now().toUtc());

          if (payload.clientEventId != null &&
              payload.clientEventId!.isNotEmpty) {
            await _recordSentEventId(payload.clientEventId!);
          }

          // Re-add remaining unprocessed items to the keep list.
          for (int j = i + 1; j < toProcess.length; j++) {
            toKeep.add(toProcess[j]);
          }
          break; // 1 send per cycle
        } catch (e) {
          final isTransient = _isTransientFailure(e);
          if (isTransient) {
            if (kDebugMode) {
              debugPrint(
                'AlertQueueService: queued item failed transiently, invoking SMS fallback: $e',
              );
            }
            try {
              final item = jsonDecode(encoded) as Map<String, dynamic>;
              final payload = CreateIncidentAlertDto.fromJson(
                (item['payload'] as Map).cast<String, dynamic>(),
              );
              await SmsFallbackService().trySendFallbackSms(payload);
            } catch (smsError) {
              debugPrint(
                'AlertQueueService: SMS fallback failed while processing queue: $smsError',
              );
            }
          } else if (kDebugMode) {
            debugPrint(
              'AlertQueueService: queued item failed with non-transient error, SMS fallback skipped: $e',
            );
          }

          if (e is ApiException &&
              !e.isTransient &&
              e.statusCode >= 400 &&
              e.statusCode < 500 &&
              e.statusCode != 429) {
            debugPrint(
              'AlertQueueService: dropping queued item, permanent error ${e.statusCode}: ${e.message}',
            );
            continue;
          }

          // Re-enqueue with incremented retries and last attempt timestamp.
          try {
            final item = jsonDecode(encoded) as Map<String, dynamic>;
            final retries = (item['retries'] as int? ?? 0) + 1;
            item['retries'] = retries;
            item['last_error'] = e.toString();
            item['last_attempt_at'] = DateTime.now().toUtc().toIso8601String();
            toKeep.add(jsonEncode(item));
          } catch (_) {
            toKeep.add(encoded);
          }
        }
      }

      await prefs.setStringList(_queueKey, toKeep);
      final result = AlertQueueResult(sent: sent, remaining: toKeep.length);
      if (sent > 0 || toKeep.isNotEmpty) {
        DiagnosticLogService.logQueueProcessed(
          sent: result.sent,
          remaining: result.remaining,
        );
      }
      return result;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> enqueueAlert(
    CreateIncidentAlertDto payload, {
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_queueKey) ?? [];

    final item = {
      'payload': payload.toJson(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'reason': reason,
      'retries': 0,
    };

    current.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, current);
  }

  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }

  /// Clear the queue entirely (e.g. on logout).
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Returns true if there is an active incident whose cooldown has not
  /// yet expired. Used by background service to decide whether to send
  /// location heartbeats rather than new incidents.
  Future<bool> hasActiveIncident() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_incidentStartKey);
    if (startStr == null) return false;
    final start = DateTime.tryParse(startStr)?.toUtc();
    if (start == null) return false;
    return DateTime.now().toUtc().difference(start).inSeconds <
        _incidentCooldownSeconds;
  }

  /// Returns the active incident ID, or null if no active incident.
  Future<int?> get activeIncidentId async {
    final prefs = await SharedPreferences.getInstance();
    if (!await hasActiveIncident()) return null;
    return prefs.getInt(_activeIncidentIdKey);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Whether a new incident can be created (cooldown has elapsed).
  Future<bool> _canCreateNewIncident() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_incidentStartKey);
    if (startStr == null) return true;
    final start = DateTime.tryParse(startStr)?.toUtc();
    if (start == null) return true;
    return DateTime.now().toUtc().difference(start).inSeconds >=
        _incidentCooldownSeconds;
  }

  Future<void> _setActiveIncident(int alertId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeIncidentIdKey, alertId);
    await prefs.setString(_incidentStartKey, at.toUtc().toIso8601String());
  }

  /// Compute backoff duration for attempt [retryCount] using exponential
  /// backoff with random jitter, capped at [_maxBackoffMs].
  Duration _computeBackoff(int retryCount) {
    final rng = Random();
    final expMs = _baseBackoffMs * (1 << retryCount);
    final capped = expMs.clamp(0, _maxBackoffMs);
    final jitter = rng.nextInt((capped * 0.3).round().clamp(1, _maxBackoffMs));
    return Duration(milliseconds: capped + jitter);
  }

  Future<bool> _isEventAlreadySent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_sentEventIdsKey) ?? [];
    return ids.contains(eventId);
  }

  Future<void> _recordSentEventId(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_sentEventIdsKey) ?? [];
    ids.add(eventId);
    // Trim history to avoid unbounded growth.
    while (ids.length > _maxDedupeHistory) {
      ids.removeAt(0);
    }
    await prefs.setStringList(_sentEventIdsKey, ids);
  }

  Future<void> _ensureLastSentLoaded() async {
    if (_lastSentMemoryInitialized) return;
    await _readLastSent();
  }

  Future<DateTime?> _readLastSent() async {
    if (_lastSentMemory != null) return _lastSentMemory;
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_lastSentKey);
    if (s == null || s.isEmpty) return null;
    try {
      final dt = DateTime.parse(s).toUtc();
      _lastSentMemory = dt;
      _lastSentMemoryInitialized = true;
      return dt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLastSent(DateTime dt) async {
    _lastSentMemory = dt.toUtc();
    _lastSentMemoryInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSentKey, _lastSentMemory!.toIso8601String());
  }
}
