import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jepo/services/diagnostic_log_service.dart';

void main() {
  setUp(() async {
    // Initialize SharedPreferences with empty values for testing
    SharedPreferences.setMockInitialValues({});
    await DiagnosticLogService.clear();
  });

  group('DiagnosticLogService', () {
    test('logs and retrieves entries', () async {
      await DiagnosticLogService.log(
        category: 'test',
        event: 'test_event',
        detail: 'hello world',
        severity: 'info',
      );

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(1));
      expect(entries[0].category, 'test');
      expect(entries[0].event, 'test_event');
      expect(entries[0].detail, 'hello world');
      expect(entries[0].severity, 'info');
    });

    test('returns entries in reverse chronological order', () async {
      await DiagnosticLogService.log(
        category: 'test',
        event: 'first',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await DiagnosticLogService.log(
        category: 'test',
        event: 'second',
      );

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(2));
      expect(entries[0].event, 'second'); // newest first
      expect(entries[1].event, 'first');
    });

    test('clear removes all entries', () async {
      await DiagnosticLogService.log(category: 'a', event: 'b');
      await DiagnosticLogService.clear();

      final entries = await DiagnosticLogService.getEntries();
      expect(entries, isEmpty);
    });

    test('trims entries beyond max limit', () async {
      // Log more than maxEntries
      for (int i = 0; i < DiagnosticLogService.maxEntries + 10; i++) {
        await DiagnosticLogService.log(
          category: 'test',
          event: 'event_$i',
        );
      }

      final entries = await DiagnosticLogService.getEntries();

      // Should be capped at maxEntries
      expect(entries.length, lessThanOrEqualTo(DiagnosticLogService.maxEntries));
    });

    test('convenience logAlertSent works', () async {
      await DiagnosticLogService.logAlertSent(eventId: 'evt-123');

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(1));
      expect(entries[0].category, 'queue');
      expect(entries[0].event, 'alert_sent');
      expect(entries[0].eventId, 'evt-123');
    });

    test('convenience logSessionExpired works', () async {
      await DiagnosticLogService.logSessionExpired();

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(1));
      expect(entries[0].category, 'session');
      expect(entries[0].event, 'session_expired');
      expect(entries[0].severity, 'warning');
    });

    test('convenience logApiError includes status and path', () async {
      await DiagnosticLogService.logApiError(
        statusCode: 500,
        message: 'Internal Server Error',
        path: '/api/test',
      );

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(1));
      expect(entries[0].category, 'api');
      expect(entries[0].event, 'error');
      expect(entries[0].severity, 'error'); // 500+ → error
      expect(entries[0].detail, contains('500'));
      expect(entries[0].detail, contains('/api/test'));
    });

    test('400-level API errors have warning severity', () async {
      await DiagnosticLogService.logApiError(
        statusCode: 400,
        message: 'Bad Request',
      );

      final entries = await DiagnosticLogService.getEntries();
      expect(entries[0].severity, 'warning');
    });

    test('convenience logIncidentCreated includes alertId', () async {
      await DiagnosticLogService.logIncidentCreated(
        alertId: 42,
        eventId: 'evt-999',
      );

      final entries = await DiagnosticLogService.getEntries();

      expect(entries, hasLength(1));
      expect(entries[0].category, 'incident');
      expect(entries[0].detail, contains('42'));
      expect(entries[0].eventId, 'evt-999');
    });
  });

  group('DiagnosticEntry serialization', () {
    test('toJson and fromJson round-trip', () {
      final entry = DiagnosticEntry(
        timestamp: DateTime.utc(2026, 4, 26, 10),
        category: 'queue',
        event: 'alert_sent',
        detail: 'test detail',
        eventId: 'abc-123',
        severity: 'warning',
      );

      final json = entry.toJson();
      final restored = DiagnosticEntry.fromJson(json);

      expect(restored.category, 'queue');
      expect(restored.event, 'alert_sent');
      expect(restored.detail, 'test detail');
      expect(restored.eventId, 'abc-123');
      expect(restored.severity, 'warning');
      expect(restored.timestamp.isUtc, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'ts': '2026-04-26T10:00:00.000Z',
        'cat': 'test',
        'evt': 'minimal',
      };

      final entry = DiagnosticEntry.fromJson(json);

      expect(entry.detail, isNull);
      expect(entry.eventId, isNull);
      expect(entry.severity, 'info'); // default
    });
  });
}
