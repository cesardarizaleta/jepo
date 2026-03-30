import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alerts_service.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'pre_alert_service.dart';

class AlertQueueResult {
  final int sent;
  final int remaining;

  const AlertQueueResult({required this.sent, required this.remaining});
}

class AlertQueueService {
  static const String _queueKey = 'jepo_pending_alerts_queue';

  /// Prevent concurrent processing/send operations from multiple callers.
  /// This is a simple in-memory guard to avoid overlapping `processQueue`
  /// or `sendOrQueue` runs that could cause duplicate network requests.
  static bool _isProcessing = false;

  /// Throttle window in seconds. Alerts arriving within this window since the
  /// last successfully sent alert will be enqueued for later delivery.
  static const int _throttleWindowSeconds = 3;

  /// Key used to persist the last sent alert timestamp.
  static const String _lastSentKey = 'jepo_last_sent_alert_at';

  /// In-memory cached last-sent timestamp to avoid repeated async reads and
  /// to make throttle checks atomic across fast incoming events.
  static DateTime? _lastSentMemory;
  static bool _lastSentMemoryInitialized = false;

  final ApiClient api;

  AlertQueueService(this.api);

  Future<void> enqueueAlert(
    Map<String, dynamic> payload, {
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_queueKey) ?? [];

    final item = {
      'payload': payload,
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

  Future<DateTime?> _readLastSent() async {
    // Prefer in-memory cached value if available.
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
    // Update in-memory cache first so quick subsequent calls see the value
    // without awaiting I/O.
    _lastSentMemory = dt.toUtc();
    _lastSentMemoryInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSentKey, _lastSentMemory!.toIso8601String());
  }

  Future<void> _ensureLastSentLoaded() async {
    if (_lastSentMemoryInitialized) return;
    await _readLastSent();
  }

  Future<bool> sendOrQueue(Map<String, dynamic> payload) async {
    // Before notifying anyone, request user confirmation to prevent false positives.
    final shouldSend = await PreAlertService.requestConfirmation(seconds: 10);
    if (!shouldSend) {
      try {
        debugPrint('AlertQueueService: user confirmed safe, dropping alert');
      } catch (_) {}
      return false;
    }

    // Fast-path: avoid races by setting processing flag early so only one
    // caller attempts a direct send at a time; others will enqueue.
    if (_isProcessing) {
      try {
        debugPrint(
          'AlertQueueService: sendOrQueue called while processing; enqueuing',
        );
      } catch (_) {}
      await enqueueAlert(payload, reason: 'concurrent_process');
      return false;
    }

    _isProcessing = true;
    try {
      // Ensure persisted last-sent is available in memory.
      await _ensureLastSentLoaded();

      final now = DateTime.now().toUtc();
      if (_lastSentMemory != null &&
          now.difference(_lastSentMemory!) <
              Duration(seconds: _throttleWindowSeconds)) {
        // Respect client's throttle policy: enqueue for later processing.
        try {
          debugPrint(
            'AlertQueueService: incoming alert throttled; enqueuing (lastSent=$_lastSentMemory)',
          );
        } catch (_) {}
        await enqueueAlert(payload, reason: 'throttled');
        return false;
      }

      final auth = AuthService(api);
      final hasSession = await auth.hasActiveSession();

      if (!hasSession) {
        await enqueueAlert(payload, reason: 'no_active_session');
        return false;
      }

      try {
        await AlertsService(api).createAlert(payload);
        // Record the successful send time to enforce throttling.
        await _writeLastSent(now);
        return true;
      } catch (e) {
        // If this is a client error (400-499) other than 429, it's likely
        // a permanent validation error (e.g. missing/invalid fields). Do
        // not re-enqueue such items as they'll always fail. Re-enqueue on
        // transient errors (network, 5xx, or 429).
        if (e is ApiException &&
            e.statusCode >= 400 &&
            e.statusCode < 500 &&
            e.statusCode != 429) {
          try {
            debugPrint(
              'AlertQueueService: permanent error ${e.statusCode}, dropping alert: ${e.message}',
            );
          } catch (_) {}
          return false;
        }
        await enqueueAlert(payload, reason: e.toString());
        return false;
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<AlertQueueResult> processQueue({int maxItems = 20}) async {
    if (_isProcessing) {
      try {
        debugPrint(
          'AlertQueueService: processQueue skipped because another run is active',
        );
      } catch (_) {}
      return AlertQueueResult(sent: 0, remaining: await pendingCount());
    }

    _isProcessing = true;
    try {
      final auth = AuthService(api);
      if (!await auth.hasActiveSession()) {
        return AlertQueueResult(sent: 0, remaining: await pendingCount());
      }

      // Respect throttle window: if a recent alert was sent, skip processing
      // queued items until the window has elapsed.
      final lastSent = await _readLastSent();
      final now = DateTime.now().toUtc();
      if (lastSent != null &&
          now.difference(lastSent) <
              const Duration(seconds: _throttleWindowSeconds)) {
        try {
          debugPrint(
            'AlertQueueService: processQueue deferred due to throttle (lastSent=$lastSent)',
          );
        } catch (_) {}
        return AlertQueueResult(sent: 0, remaining: await pendingCount());
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_queueKey) ?? [];
      if (raw.isEmpty) {
        return const AlertQueueResult(sent: 0, remaining: 0);
      }

      final toProcess = raw.take(maxItems).toList();
      final toKeep = raw.skip(maxItems).toList();

      int sent = 0;

      for (int i = 0; i < toProcess.length; i++) {
        final encoded = toProcess[i];
        try {
          final item = jsonDecode(encoded) as Map<String, dynamic>;
          final payload = item['payload'] as Map<String, dynamic>;
          await AlertsService(api).createAlert(payload);
          sent++;
          // Update last sent so further items are not sent within the window.
          await _writeLastSent(DateTime.now().toUtc());

          // Re-add any remaining unprocessed items back to keep list.
          for (int j = i + 1; j < toProcess.length; j++) {
            toKeep.add(toProcess[j]);
          }
          break; // Respect throttle: send only one item per processing run
        } catch (e) {
          // If the failure is a permanent client error (400-499 except 429),
          // drop the queued item rather than re-enqueuing it.
          if (e is ApiException &&
              e.statusCode >= 400 &&
              e.statusCode < 500 &&
              e.statusCode != 429) {
            try {
              debugPrint(
                'AlertQueueService: dropping queued alert due to permanent error ${e.statusCode}: ${e.message}',
              );
            } catch (_) {}
            continue;
          }

          // Keep failed item with incremented retries.
          try {
            final item = jsonDecode(encoded) as Map<String, dynamic>;
            final retries = (item['retries'] as int? ?? 0) + 1;
            item['retries'] = retries;
            item['last_error'] = e.toString();
            toKeep.add(jsonEncode(item));
          } catch (_) {
            toKeep.add(encoded);
          }
        }
      }

      await prefs.setStringList(_queueKey, toKeep);

      return AlertQueueResult(sent: sent, remaining: toKeep.length);
    } finally {
      _isProcessing = false;
    }
  }
}
