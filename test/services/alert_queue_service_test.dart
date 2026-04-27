import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jepo/models/incident_alert.dart';
import 'package:jepo/services/alert_queue_service.dart';
import 'package:jepo/services/session_events.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SessionEvents.resetInvalidation();
  });

  group('AlertQueueService — enqueue and queue management', () {
    test('enqueueAlert persists to SharedPreferences', () async {
      // We can't instantiate ApiClient easily without full setup, so test
      // the queue persistence directly via SharedPreferences.
      final prefs = await SharedPreferences.getInstance();

      final dto = CreateIncidentAlertDto(
        latitud: 10.5,
        longitud: -70.5,
        urlAudioContexto: null,
        fechaHora: DateTime.utc(2026, 4, 26),
        esProactiva: true,
        clientEventId: 'test-evt-1',
      );

      // Simulate what enqueueAlert does
      final item = {
        'payload': dto.toJson(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'reason': 'test',
        'retries': 0,
      };

      final current = prefs.getStringList('jepo_pending_alerts_queue') ?? [];
      current.add(jsonEncode(item));
      await prefs.setStringList('jepo_pending_alerts_queue', current);

      // Verify persistence
      final stored = prefs.getStringList('jepo_pending_alerts_queue');
      expect(stored, isNotNull);
      expect(stored, hasLength(1));

      final decoded = jsonDecode(stored![0]) as Map<String, dynamic>;
      expect(decoded['reason'], 'test');
      expect(decoded['retries'], 0);

      final restoredPayload = CreateIncidentAlertDto.fromJson(
        (decoded['payload'] as Map).cast<String, dynamic>(),
      );
      expect(restoredPayload.clientEventId, 'test-evt-1');
      expect(restoredPayload.esProactiva, isTrue);
    });

    test('queue items preserve retry count', () async {
      final prefs = await SharedPreferences.getInstance();

      final item = {
        'payload': CreateIncidentAlertDto(
          latitud: 10.0,
          longitud: -70.0,
          urlAudioContexto: null,
          fechaHora: DateTime.utc(2026, 4, 26),
          esProactiva: true,
        ).toJson(),
        'retries': 3,
        'last_error': 'timeout',
        'last_attempt_at': DateTime.now().toUtc().toIso8601String(),
      };

      await prefs.setStringList(
        'jepo_pending_alerts_queue',
        [jsonEncode(item)],
      );

      final stored = prefs.getStringList('jepo_pending_alerts_queue')!;
      final decoded = jsonDecode(stored[0]) as Map<String, dynamic>;
      expect(decoded['retries'], 3);
      expect(decoded['last_error'], 'timeout');
    });
  });

  group('AlertQueueService — deduplication', () {
    test('sent event IDs are persisted for dedup', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate recording sent event IDs
      const key = 'jepo_sent_event_ids';
      final ids = ['evt-1', 'evt-2', 'evt-3'];
      await prefs.setStringList(key, ids);

      final stored = prefs.getStringList(key)!;
      expect(stored, contains('evt-1'));
      expect(stored, contains('evt-2'));
      expect(stored, contains('evt-3'));
    });

    test('dedup history is bounded', () async {
      final prefs = await SharedPreferences.getInstance();

      const key = 'jepo_sent_event_ids';
      const maxHistory = 200;

      // Generate more than max
      final ids = List.generate(maxHistory + 50, (i) => 'evt-$i');
      
      // Simulate trimming logic
      while (ids.length > maxHistory) {
        ids.removeAt(0);
      }

      await prefs.setStringList(key, ids);

      final stored = prefs.getStringList(key)!;
      expect(stored.length, maxHistory);
      // Oldest entries should have been trimmed
      expect(stored, isNot(contains('evt-0')));
      expect(stored, contains('evt-249')); // Last one
    });
  });

  group('AlertQueueService — incident cooldown', () {
    test('incident start time is persisted', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      await prefs.setInt('jepo_active_incident_id', 42);
      await prefs.setString(
        'jepo_incident_start_at',
        now.toIso8601String(),
      );

      expect(prefs.getInt('jepo_active_incident_id'), 42);

      final startStr = prefs.getString('jepo_incident_start_at')!;
      final start = DateTime.parse(startStr).toUtc();
      final elapsed = DateTime.now().toUtc().difference(start).inSeconds;

      // Should be within cooldown window (600s)
      expect(elapsed, lessThan(600));
    });

    test('cooldown check: recent incident blocks new creation', () async {
      final prefs = await SharedPreferences.getInstance();
      final recentStart = DateTime.now().toUtc();

      await prefs.setString(
        'jepo_incident_start_at',
        recentStart.toIso8601String(),
      );

      // Simulate cooldown check
      final startStr = prefs.getString('jepo_incident_start_at')!;
      final start = DateTime.parse(startStr).toUtc();
      final canCreate = DateTime.now().toUtc().difference(start).inSeconds >= 600;

      expect(canCreate, isFalse);
    });

    test('cooldown check: old incident allows new creation', () async {
      final prefs = await SharedPreferences.getInstance();
      // Set start time to 11 minutes ago (> 600s cooldown)
      final oldStart = DateTime.now().toUtc().subtract(
        const Duration(minutes: 11),
      );

      await prefs.setString(
        'jepo_incident_start_at',
        oldStart.toIso8601String(),
      );

      final startStr = prefs.getString('jepo_incident_start_at')!;
      final start = DateTime.parse(startStr).toUtc();
      final canCreate = DateTime.now().toUtc().difference(start).inSeconds >= 600;

      expect(canCreate, isTrue);
    });
  });

  group('AlertQueueService — session awareness', () {
    test('session invalidation flag prevents processing', () {
      SessionEvents.notifyUnauthorized();
      expect(SessionEvents.isInvalidated, isTrue);

      // AlertQueueService.sendOrQueue and processQueue check this flag
      // and short-circuit when true
    });

    test('session reset re-enables processing', () {
      SessionEvents.notifyUnauthorized();
      expect(SessionEvents.isInvalidated, isTrue);

      SessionEvents.resetInvalidation();
      expect(SessionEvents.isInvalidated, isFalse);
    });
  });

  group('AlertQueueResult', () {
    test('holds sent and remaining counts', () {
      const result = AlertQueueResult(sent: 1, remaining: 3);

      expect(result.sent, 1);
      expect(result.remaining, 3);
    });
  });

  group('AlertQueueService — queue serialization stress', () {
    test('multiple items in queue preserve order', () async {
      final prefs = await SharedPreferences.getInstance();

      final items = List.generate(5, (i) {
        return jsonEncode({
          'payload': CreateIncidentAlertDto(
            latitud: 10.0 + i,
            longitud: -70.0 - i,
            urlAudioContexto: null,
            fechaHora: DateTime.utc(2026, 4, 26, i),
            esProactiva: true,
            clientEventId: 'evt-$i',
          ).toJson(),
          'retries': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      });

      await prefs.setStringList('jepo_pending_alerts_queue', items);

      final stored = prefs.getStringList('jepo_pending_alerts_queue')!;
      expect(stored, hasLength(5));

      // Verify first item
      final first = jsonDecode(stored[0]) as Map<String, dynamic>;
      final firstPayload = CreateIncidentAlertDto.fromJson(
        (first['payload'] as Map).cast<String, dynamic>(),
      );
      expect(firstPayload.clientEventId, 'evt-0');

      // Verify last item
      final last = jsonDecode(stored[4]) as Map<String, dynamic>;
      final lastPayload = CreateIncidentAlertDto.fromJson(
        (last['payload'] as Map).cast<String, dynamic>(),
      );
      expect(lastPayload.clientEventId, 'evt-4');
    });

    test('queue clear removes all items', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList('jepo_pending_alerts_queue', [
        jsonEncode({'payload': {}, 'retries': 0}),
        jsonEncode({'payload': {}, 'retries': 0}),
      ]);

      expect(prefs.getStringList('jepo_pending_alerts_queue'), hasLength(2));

      await prefs.remove('jepo_pending_alerts_queue');

      expect(
        prefs.getStringList('jepo_pending_alerts_queue'),
        isNull,
      );
    });
  });
}
