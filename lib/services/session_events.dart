import 'dart:async';

/// Simple broadcast stream for session-related events (unauthorized, logout).
/// Other parts of the app can listen to `onUnauthorized` to react (e.g. show
/// the login screen) when the API reports 401.
class SessionEvents {
  static final StreamController<void> _unauthorized =
      StreamController<void>.broadcast();

  static Stream<void> get onUnauthorized => _unauthorized.stream;

  static void notifyUnauthorized() {
    try {
      if (!_unauthorized.isClosed) _unauthorized.add(null);
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _unauthorized.close();
    } catch (_) {}
  }
}
