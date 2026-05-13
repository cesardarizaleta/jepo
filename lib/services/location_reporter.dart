import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api_client.dart';
import 'users_service.dart';

/// Battery-efficient periodic location reporter.
///
/// Every [_reportInterval] (default 15 min), reads the current GPS position
/// and PATCHes it to `/api/usuarios/me/ubicacion`. Runs as a standalone
/// isolate-safe timer that the background service wires up via
/// [LocationReporter.start].
///
/// Design choices:
///  - 15-minute cadence → stays well under Android Doze / App Standby limits.
///  - Accuracy: `LocationAccuracy.medium` (~100 m) — enough for "where is
///    my family now?" without burning GPS.
///  - Skips if there is no active session or if the previous tick is still
///    running (reentrance guard).
///  - Catches all errors silently so a bad network doesn't kill the timer.
class LocationReporter {
  static const Duration _reportInterval = Duration(minutes: 15);
  static const Duration _fixTimeout = Duration(seconds: 20);

  static Timer? _timer;
  static bool _inFlight = false;

  /// Starts the periodic reporter. Calling twice is a no-op.
  static void start() {
    if (_timer != null) return;

    // Fire one immediate report so the user's location is fresh right
    // after login, then tick every 15 min.
    _reportOnce();

    _timer = Timer.periodic(_reportInterval, (_) => _reportOnce());
  }

  /// Stops the reporter (e.g. on logout).
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Manual trigger, useful for testing or for forcing a fresh location
  /// when the user opens the map screen.
  static Future<void> reportNow() => _reportOnce();

  // ─── Internals ────────────────────────────────────────────────────────

  static Future<void> _reportOnce() async {
    if (_inFlight) return;
    _inFlight = true;

    try {
      // Guard: need an initialized API + an active session.
      if (!appApiInitialized) return;
      final token = await appApi.getAccessToken();
      if (token == null || token.isEmpty) return;

      // Guard: location service must be enabled and permission granted.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _fixTimeout,
        ),
      );

      await UsersService(appApi).updateMyLocation(
        latitud: position.latitude,
        longitud: position.longitude,
      );

      debugPrint(
        'LocationReporter: reported ${position.latitude.toStringAsFixed(4)}, '
        '${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('LocationReporter: tick failed: $e');
    } finally {
      _inFlight = false;
    }
  }
}
