import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class PreAlertRequest {
  final int seconds;
  final Completer<bool> _completer = Completer<bool>();

  PreAlertRequest({required this.seconds});

  Future<bool> get isSafeDecision => _completer.future;

  void resolveAsSafe(bool isSafe) {
    if (!_completer.isCompleted) {
      _completer.complete(isSafe);
    }
  }
}

/// Manages the pre-alert confirmation flow and tracks active incident state.
///
/// The separation of responsibilities:
/// - **Detection** — BackgroundService detects an impact event.
/// - **Pre-confirmation** — PreAlertService asks the user if they are safe.
/// - **Incident creation** — If user does not confirm safe, the incident is
///   created via AlertQueueService (proactive alert).
/// - **Heartbeats** — During an active incident, location updates are sent
///   as `es_proactiva=false` (no re-notification of contacts).
class PreAlertService {
  static final StreamController<PreAlertRequest> _controller =
      StreamController<PreAlertRequest>.broadcast();

  static const String _pendingSecondsKey = 'jepo_pending_pre_alert_seconds';
  static const String _pendingExpiresAtKey =
      'jepo_pending_pre_alert_expires_at';

  static Stream<PreAlertRequest> get onRequest => _controller.stream;

  /// Whether an incident is currently active (detection confirmed, waiting
  /// for cooldown to expire). Background service checks this to decide
  /// whether to send heartbeats or attempt a new incident creation.
  static bool _incidentActive = false;

  /// Timestamp when the current incident was activated.
  static DateTime? _incidentActivatedAt;

  /// The incident ID returned by the backend after creation.
  static int? _activeIncidentId;

  /// Tracks an ongoing UI request to avoid popping multiple screens if pinged multiple times
  static Future<bool>? _currentRequestFuture;

  /// Duration of the incident window. After this period, the incident is
  /// considered resolved and new detections can create fresh incidents.
  static const Duration incidentWindow = Duration(minutes: 1);

  static bool get isIncidentActive {
    if (!_incidentActive) return false;
    if (_incidentActivatedAt == null) return false;
    // Auto-expire incident if the window has elapsed.
    if (DateTime.now().toUtc().difference(_incidentActivatedAt!) >
        incidentWindow) {
      _incidentActive = false;
      _incidentActivatedAt = null;
      _activeIncidentId = null;
      return false;
    }
    return true;
  }

  static int? get activeIncidentId =>
      isIncidentActive ? _activeIncidentId : null;

  /// Mark the beginning of an active incident. Called by the alert queue
  /// after a proactive alert is successfully created.
  static void activateIncident(int incidentId) {
    _incidentActive = true;
    _incidentActivatedAt = DateTime.now().toUtc();
    _activeIncidentId = incidentId;
  }

  /// Explicitly clear the active incident (e.g. on logout or user cancel).
  static void clearIncident() {
    _incidentActive = false;
    _incidentActivatedAt = null;
    _activeIncidentId = null;
  }

  static Future<void> storePendingPreAlert(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep the pending alert alive long enough for the user to see the notification
    // and open the app. Must be >= background service timeout (seconds + 25).
    final expiresAt = DateTime.now().toUtc().add(
      Duration(seconds: seconds + 35),
    );
    await prefs.setInt(_pendingSecondsKey, seconds);
    await prefs.setString(_pendingExpiresAtKey, expiresAt.toIso8601String());
  }

  static Future<int?> takePendingPreAlert() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_pendingSecondsKey);
    final expiresAtRaw = prefs.getString(_pendingExpiresAtKey);

    await clearPendingPreAlert();

    if (seconds == null || expiresAtRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
    if (expiresAt == null) {
      return null;
    }

    if (DateTime.now().toUtc().isAfter(expiresAt)) {
      return null;
    }

    return seconds;
  }

  static Future<void> clearPendingPreAlert() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSecondsKey);
    await prefs.remove(_pendingExpiresAtKey);
  }

  /// Returns true when alert should be sent, false when user confirmed safe.
  ///
  /// If there is no active UI listener (e.g. screen is off / background),
  /// the alert is allowed through to avoid blocking time-critical alarms.
  static Future<bool> requestConfirmation({int seconds = 10}) async {
    // If there is no active UI listener, allow send to avoid blocking alarms.
    if (!_controller.hasListener) {
      print('PreAlertService: No active listeners for confirmation requests!');
      return true;
    }

    if (_currentRequestFuture != null) {
      print(
        'PreAlertService: Request already in progress, ignoring duplicate trigger.',
      );
      return _currentRequestFuture!;
    }

    _currentRequestFuture = _doRequestConfirmation(seconds: seconds);
    final result = await _currentRequestFuture!;
    _currentRequestFuture = null;
    return result;
  }

  static Future<bool> _doRequestConfirmation({required int seconds}) async {
    print('PreAlertService: Dispatching confirmation request ($seconds s)...');
    final request = PreAlertRequest(seconds: seconds);
    _controller.add(request);

    final isSafe = await request.isSafeDecision.timeout(
      Duration(seconds: seconds + 2),
      onTimeout: () {
        print('PreAlertService: Request timed out, assuming unsafe.');
        return false;
      },
    );

    print('PreAlertService: Request resolved. isSafe=$isSafe');
    return !isSafe;
  }
}
