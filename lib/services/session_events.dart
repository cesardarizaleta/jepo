import 'dart:async';

import 'diagnostic_log_service.dart';

/// Broadcast stream hub for session-related events.
///
/// Components listen to [onUnauthorized] to react when the API reports 401
/// (e.g. show the login screen) and to [onLogout] to tear down background
/// pipelines, clear caches, and stop ongoing work gracefully.
class SessionEvents {
  static final StreamController<void> _unauthorized =
      StreamController<void>.broadcast();

  static final StreamController<void> _logout =
      StreamController<void>.broadcast();

  /// Emitted when the API returns 401 — token expired or revoked.
  static Stream<void> get onUnauthorized => _unauthorized.stream;

  /// Emitted when the user explicitly logs out or the system forces a logout.
  /// Background services, queues, and location streams should stop on this.
  static Stream<void> get onLogout => _logout.stream;

  /// Whether a session invalidation (401 or explicit logout) has already been
  /// broadcast and not yet reset by a successful login. Prevents cascading
  /// multiple 401 reactions from concurrent requests.
  static bool _invalidated = false;

  static bool get isInvalidated => _invalidated;

  static void notifyUnauthorized() {
    if (_invalidated) return; // already handled
    _invalidated = true;
    DiagnosticLogService.logSessionExpired();
    try {
      if (!_unauthorized.isClosed) _unauthorized.add(null);
    } catch (_) {}
  }

  static void notifyLogout() {
    _invalidated = true;
    DiagnosticLogService.logSessionLogout();
    try {
      if (!_logout.isClosed) _logout.add(null);
    } catch (_) {}
  }

  /// Call after a successful login/register to reset the invalidation flag
  /// so future 401s can be detected again.
  static void resetInvalidation() {
    _invalidated = false;
    DiagnosticLogService.logSessionLogin();
  }

  static Future<void> dispose() async {
    try {
      await _unauthorized.close();
    } catch (_) {}
    try {
      await _logout.close();
    } catch (_) {}
  }
}
