import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Structured entry in the local diagnostic log.
///
/// Captures operational events (queue activity, session changes, API errors)
/// without storing sensitive data (no tokens, passwords, or PII beyond what
/// is strictly necessary for correlation).
class DiagnosticEntry {
  final DateTime timestamp;

  /// High-level category: `queue`, `session`, `api`, `incident`, `background`.
  final String category;

  /// Machine-friendly event identifier, e.g. `alert_sent`, `queue_retry_failed`.
  final String event;

  /// Optional human-readable detail string (sanitized — no tokens).
  final String? detail;

  /// Client-side event ID for correlation across queue/incident/background.
  final String? eventId;

  /// Severity: `info`, `warning`, `error`.
  final String severity;

  const DiagnosticEntry({
    required this.timestamp,
    required this.category,
    required this.event,
    this.detail,
    this.eventId,
    this.severity = 'info',
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ts': timestamp.toUtc().toIso8601String(),
    'cat': category,
    'evt': event,
    if (detail != null) 'det': detail,
    if (eventId != null) 'eid': eventId,
    'sev': severity,
  };

  factory DiagnosticEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosticEntry(
      timestamp:
          DateTime.tryParse(json['ts']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      category: json['cat']?.toString() ?? 'unknown',
      event: json['evt']?.toString() ?? 'unknown',
      detail: json['det']?.toString(),
      eventId: json['eid']?.toString(),
      severity: json['sev']?.toString() ?? 'info',
    );
  }
}

/// Local diagnostic log for operational observability.
///
/// Stores a bounded circular buffer of [DiagnosticEntry] instances in
/// [SharedPreferences]. The UI can read these via [getEntries] to display
/// a simple diagnostic panel (queue status, last errors, etc.).
class DiagnosticLogService {
  static const String _logKey = 'jepo_diagnostic_log';

  /// Maximum number of entries retained. Older entries are evicted first.
  static const int maxEntries = 200;

  /// Append a new entry to the log.
  static Future<void> log({
    required String category,
    required String event,
    String? detail,
    String? eventId,
    String severity = 'info',
  }) async {
    try {
      final entry = DiagnosticEntry(
        timestamp: DateTime.now().toUtc(),
        category: category,
        event: event,
        detail: detail,
        eventId: eventId,
        severity: severity,
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_logKey) ?? [];
      raw.add(jsonEncode(entry.toJson()));

      // Trim to max size.
      while (raw.length > maxEntries) {
        raw.removeAt(0);
      }

      await prefs.setStringList(_logKey, raw);
    } catch (e) {
      debugPrint('DiagnosticLogService.log error: $e');
    }
  }

  /// Retrieve all stored entries, newest first.
  static Future<List<DiagnosticEntry>> getEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_logKey) ?? [];
      return raw
          .map((s) {
            try {
              return DiagnosticEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<DiagnosticEntry>()
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('DiagnosticLogService.getEntries error: $e');
      return const <DiagnosticEntry>[];
    }
  }

  /// Clear all diagnostic entries.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }

  // ---------------------------------------------------------------------------
  // Convenience loggers
  // ---------------------------------------------------------------------------

  static Future<void> logAlertSent({String? eventId}) =>
      log(category: 'queue', event: 'alert_sent', eventId: eventId);

  static Future<void> logAlertQueued({String? eventId, String? reason}) => log(
    category: 'queue',
    event: 'alert_queued',
    detail: reason,
    eventId: eventId,
  );

  static Future<void> logAlertDropped({String? eventId, String? reason}) => log(
    category: 'queue',
    event: 'alert_dropped',
    detail: reason,
    eventId: eventId,
    severity: 'warning',
  );

  static Future<void> logQueueProcessed({
    required int sent,
    required int remaining,
  }) => log(
    category: 'queue',
    event: 'queue_processed',
    detail: 'sent=$sent remaining=$remaining',
  );

  static Future<void> logSessionExpired() =>
      log(category: 'session', event: 'session_expired', severity: 'warning');

  static Future<void> logSessionLogout() =>
      log(category: 'session', event: 'logout');

  static Future<void> logSessionLogin() =>
      log(category: 'session', event: 'login');

  static Future<void> logIncidentCreated({
    required int alertId,
    String? eventId,
  }) => log(
    category: 'incident',
    event: 'incident_created',
    detail: 'alertId=$alertId',
    eventId: eventId,
  );

  static Future<void> logIncidentHeartbeat({required int alertId}) =>
      log(category: 'incident', event: 'heartbeat', detail: 'alertId=$alertId');

  static Future<void> logApiError({
    required int statusCode,
    required String message,
    String? path,
  }) => log(
    category: 'api',
    event: 'error',
    detail: '$statusCode $message${path != null ? ' [$path]' : ''}',
    severity: statusCode >= 500 ? 'error' : 'warning',
  );

  static Future<void> logBackgroundEvent(String event, {String? detail}) =>
      log(category: 'background', event: event, detail: detail);

  static Future<void> logSmsSent({String? eventId, required int recipients}) =>
      log(
        category: 'sms',
        event: 'sms_sent',
        detail: 'recipients=$recipients',
        eventId: eventId,
      );

  static Future<void> logSmsFailed({String? eventId, String? reason}) => log(
    category: 'sms',
    event: 'sms_failed',
    detail: reason,
    eventId: eventId,
    severity: 'warning',
  );

  static Future<void> logSmsSkipped({String? eventId, String? reason}) => log(
    category: 'sms',
    event: 'sms_skipped',
    detail: reason,
    eventId: eventId,
  );
}
