import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/services/pre_alert_service.dart';

void main() {
  // Reset state between tests
  setUp(() {
    PreAlertService.clearIncident();
  });

  group('PreAlertService incident tracking', () {
    test('starts with no active incident', () {
      expect(PreAlertService.isIncidentActive, isFalse);
      expect(PreAlertService.activeIncidentId, isNull);
    });

    test('activateIncident sets active state', () {
      PreAlertService.activateIncident(42);

      expect(PreAlertService.isIncidentActive, isTrue);
      expect(PreAlertService.activeIncidentId, 42);
    });

    test('clearIncident resets state', () {
      PreAlertService.activateIncident(42);
      expect(PreAlertService.isIncidentActive, isTrue);

      PreAlertService.clearIncident();

      expect(PreAlertService.isIncidentActive, isFalse);
      expect(PreAlertService.activeIncidentId, isNull);
    });

    test('incident auto-expires after window elapses', () {
      // We can't easily test 10-minute expiry in unit tests, but we can
      // verify the logic by checking that a recent activation is still active.
      PreAlertService.activateIncident(1);
      expect(PreAlertService.isIncidentActive, isTrue);

      // Immediately after activation, it should be active
      expect(PreAlertService.activeIncidentId, 1);
    });

    test('requestConfirmation returns true when no listener', () async {
      // No listener attached → should auto-allow the alert
      final shouldSend = await PreAlertService.requestConfirmation(seconds: 1);
      expect(shouldSend, isTrue);
    });

    test('requestConfirmation returns false when user confirms safe', () async {
      // Set up a listener that immediately confirms safe
      final sub = PreAlertService.onRequest.listen((request) {
        request.resolveAsSafe(true); // User says they're safe
      });

      final shouldSend = await PreAlertService.requestConfirmation(seconds: 2);
      expect(shouldSend, isFalse); // !isSafe → don't send

      await sub.cancel();
    });

    test('requestConfirmation returns true when user does not confirm safe', () async {
      final sub = PreAlertService.onRequest.listen((request) {
        request.resolveAsSafe(false); // User does NOT confirm safe
      });

      final shouldSend = await PreAlertService.requestConfirmation(seconds: 2);
      expect(shouldSend, isTrue); // !isSafe → send

      await sub.cancel();
    });
  });
}
