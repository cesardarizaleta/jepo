import 'dart:async';

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

  static Stream<PreAlertRequest> get onRequest => _controller.stream;

  /// Whether an incident is currently active (detection confirmed, waiting
  /// for cooldown to expire). Background service checks this to decide
  /// whether to send heartbeats or attempt a new incident creation.
  static bool _incidentActive = false;

  /// Timestamp when the current incident was activated.
  static DateTime? _incidentActivatedAt;

  /// The incident ID returned by the backend after creation.
  static int? _activeIncidentId;

  /// Duration of the incident window. After this period, the incident is
  /// considered resolved and new detections can create fresh incidents.
  static const Duration incidentWindow = Duration(minutes: 10);

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

  /// Returns true when alert should be sent, false when user confirmed safe.
  ///
  /// If there is no active UI listener (e.g. screen is off / background),
  /// the alert is allowed through to avoid blocking time-critical alarms.
  static Future<bool> requestConfirmation({int seconds = 10}) async {
    // If there is no active UI listener, allow send to avoid blocking alarms.
    if (!_controller.hasListener) {
      return true;
    }

    final request = PreAlertRequest(seconds: seconds);
    _controller.add(request);

    final isSafe = await request.isSafeDecision.timeout(
      Duration(seconds: seconds + 2),
      onTimeout: () => false,
    );

    return !isSafe;
  }
}
