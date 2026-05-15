import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_alert.dart';
import 'ai_telemetry_validator.dart';
import 'alert_queue_service.dart';
import 'api_client.dart';
import 'alerts_service.dart';
import 'diagnostic_log_service.dart';
import 'location_reporter.dart';
import 'pre_alert_service.dart';
import 'session_events.dart';
import 'package:url_launcher/url_launcher.dart';

/// Notification ID for the pre-alert fullscreen intent notification.
const int preAlertNotificationId = 997;

// Notification Channel IDs
const String monitoringChannelId = 'jepo_monitoring';
const String alertChannelId = 'jepo_alerts_v2';
const int monitoringNotificationId = 888;
const int alertNotificationId = 999;

/// Heartbeat interval for location updates during an active incident.
const Duration _heartbeatInterval = Duration(seconds: 30);

/// Default minimum G-force magnitude to trigger an impact detection.
double _impactThreshold = 30.0;

/// Debounce window for sensor-triggered impacts.
const int _impactDebounceSeconds = 3;

/// Key to persist last impact timestamp for debounce across events.
const String _lastImpactKey = 'jepo_last_impact_at';

/// Key to persist the sensitivity threshold.
const String _thresholdKey = 'jepo_sensitivity_threshold';

/// In-memory flag to strictly prevent race conditions during impacts
bool _isConfirmingMemory = false;
DateTime? _lastImpactMemory;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Monitoring Channel (Silent, Low Importance)
  const AndroidNotificationChannel monitoringChannel =
      AndroidNotificationChannel(
        monitoringChannelId,
        'Monitoreo de Jepo',
        description: 'Monitoreo continuo en segundo plano.',
        importance: Importance.low,
        playSound: false,
        showBadge: false,
      );

  // 2. Alert Channel (High Importance, Sound, Vibration)
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    alertChannelId,
    'Alertas de Jepo',
    description: 'Alertas de seguridad críticas.',
    importance: Importance.max, // Max importance for heads-up display
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(monitoringChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(alertChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: monitoringChannelId, // Default to monitoring
      initialNotificationTitle: 'Jepo Activo',
      initialNotificationContent: 'Inicializando sistemas de seguridad...',
      foregroundServiceNotificationId: monitoringNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS Background Handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Main Background Task
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // Initialize Local Notifications for updates
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Listen for confirmation response from UI (via background service IPC)
  Completer<bool>? confirmationCompleter;
  service.on('pre_alert_response').listen((event) {
    debugPrint('BackgroundService: received pre_alert_response: $event');
    if (confirmationCompleter != null && !confirmationCompleter!.isCompleted) {
      final isSafe = event?['isSafe'] ?? false;
      confirmationCompleter!.complete(!isSafe); // shouldSend = !isSafe
    }
  });

  /// Show a fullScreenIntent notification that wakes the screen and launches
  /// MainActivity with SHOW_PRE_ALERT=true. This is the ONLY reliable way
  /// on Android 10+ to display UI from the background.
  Future<void> showPreAlertNotification(int seconds) async {
    final AndroidNotificationDetails details = AndroidNotificationDetails(
      alertChannelId,
      'Alertas de Jepo',
      channelDescription: 'Alertas de seguridad críticas.',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ticker: 'ALERTA DE IMPACTO',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Colors.red,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        '¡IMPACTO DETECTADO! Toca para confirmar que estás bien o se alertará a tus contactos en $seconds segundos.',
        contentTitle: '⚠️ ¿ESTÁS BIEN?',
        summaryText: 'Protocolo de Emergencia Activo',
      ),
    );
    try {
      await flutterLocalNotificationsPlugin.show(
        preAlertNotificationId,
        '⚠️ ¿ESTÁS BIEN?',
        'Toca AHORA para cancelar la alerta — $seconds segundos restantes',
        NotificationDetails(android: details),
        payload: 'pre_alert:$seconds',
      );
      debugPrint(
        'BackgroundService: Pre-alert fullScreenIntent notification shown',
      );
    } catch (e) {
      debugPrint('BackgroundService: Error showing pre-alert notification: $e');
    }
  }

  /// Request confirmation from the user.
  /// Uses a fullScreenIntent notification to wake the screen and bring the app
  /// to front — the ONLY mechanism that works reliably on Android 10+.
  Future<bool> requestConfirmationViaUI(int seconds) async {
    confirmationCompleter = Completer<bool>();

    // Store pending pre-alert FIRST (for recovery if app was killed)
    await PreAlertService.storePendingPreAlert(seconds);

    // 1. Show the fullScreenIntent notification — this wakes the screen and
    //    launches MainActivity via the system-level fullScreenIntent mechanism,
    //    bypassing Android 10+ background activity restrictions.
    await showPreAlertNotification(seconds);

    // 2. FORCE launch the app via Deep Link intent from the background.
    //    This guarantees Android brings the app to the foreground even if the
    //    screen is ON, completely bypassing the Heads-Up Notification limit!
    try {
      await launchUrl(
        Uri.parse('jepo://alert'),
        mode: LaunchMode.externalApplication,
      );
      debugPrint(
        'BackgroundService: Forced app to foreground via jepo://alert',
      );
    } catch (e) {
      debugPrint('BackgroundService: URL launch failed: $e');
    }

    // 3. Also ping the UI isolate in case the app is already in the foreground
    //    and doesn't need the fullScreenIntent to bring it up.
    service.invoke('show_pre_alert', {"seconds": seconds});

    // 3. Wait for the user's response. Timeout = seconds + 25s to give enough
    //    time for the notification to appear, user to see it, and respond.
    //    If no response, default to sending the alert (assume unsafe).
    try {
      return await confirmationCompleter!.future.timeout(
        Duration(seconds: seconds + 25),
        onTimeout: () {
          debugPrint(
            'BackgroundService: Confirmation timed out, assuming unsafe.',
          );
          return true; // shouldSend = true
        },
      );
    } catch (_) {
      return true;
    } finally {
      _isConfirmingMemory = false;
      confirmationCompleter = null;
      // Clear pending pre-alert now that we have a decision
      await PreAlertService.clearPendingPreAlert();
      // Cancel the pre-alert notification
      try {
        await flutterLocalNotificationsPlugin.cancel(preAlertNotificationId);
      } catch (_) {}
    }
  }

  // Initialise the API client for background work.
  try {
    await initApi();
    await AlertQueueService(appApi).processQueue();

    // Load initial threshold
    final prefs = await SharedPreferences.getInstance();
    _impactThreshold = prefs.getDouble(_thresholdKey) ?? 30.0;

    // Start the periodic location reporter (15-min ticks). It is
    // self-contained and silently no-ops when there is no session.
    LocationReporter.start();
  } catch (e) {
    debugPrint('Background API init failed: $e');
  }

  // Listen for stop command
  service.on('stopService').listen((event) {
    LocationReporter.stop();
    PreAlertService.clearIncident();
    service.stopSelf();
  });

  // Listen for threshold updates
  service.on('setThreshold').listen((event) {
    if (event != null && event['threshold'] != null) {
      _impactThreshold = (event['threshold'] as num).toDouble();
      debugPrint('BackgroundService: threshold updated to $_impactThreshold');
    }
  });

  // Listen for session logout to stop ourselves cleanly.
  SessionEvents.onLogout.listen((_) {
    PreAlertService.clearIncident();
    service.stopSelf();
  });

  // Force show initial notification immediately to avoid delay
  try {
    await flutterLocalNotificationsPlugin.show(
      monitoringNotificationId,
      'Jepo Activo',
      'Sistemas de seguridad en línea. Monitoreando...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          monitoringChannelId,
          'Monitoreo de Jepo',
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ongoing: true,
          autoCancel: false,
          showWhen: true,
          usesChronometer: true,
        ),
      ),
    );
  } catch (e) {
    debugPrint("Error showing initial notification: $e");
  }

  // -------------------------------------------------------------------------
  // Phase 1: Location Tracking
  // -------------------------------------------------------------------------

  final locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 15, // Update only after moving 15 meters
    forceLocationManager: true,
    intervalDuration: const Duration(seconds: 10),
  );

  Position? lastKnownPosition;

  final locationStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  );

  locationStream.listen((Position position) {
    lastKnownPosition = position;

    // Update notification content to show latest activity
    try {
      flutterLocalNotificationsPlugin.show(
        monitoringNotificationId,
        'Jepo Activo',
        PreAlertService.isIncidentActive
            ? 'INCIDENTE ACTIVO — Rastreo de ubicación...'
            : 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            monitoringChannelId,
            'Monitoreo de Jepo',
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            ongoing: true,
            autoCancel: false,
            usesChronometer: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error updating location notification: $e");
    }

    // Send data to UI if needed
    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
      "speed": position.speed,
      "incident_active": PreAlertService.isIncidentActive,
    });
  });

  // -------------------------------------------------------------------------
  // Phase 2: Sensor Monitoring — AI-Based Fall Detection (Sliding Window)
  // -------------------------------------------------------------------------

  // Initialize the TFLite AI model for fall detection.
  final aiValidator = AiTelemetryValidator();
  await aiValidator.initialize();

  // Sliding window buffer: accumulates sensor readings for inference.
  // Each entry: {'ax': ..., 'ay': ..., 'az': ..., 'gx': ..., 'gy': ..., 'gz': ...}
  final List<Map<String, double>> _sensorWindow = [];
  double _latestGx = 0, _latestGy = 0, _latestGz = 0;

  // Subscribe to gyroscope to keep latest reading available.
  gyroscopeEventStream().listen((GyroscopeEvent gEvent) {
    _latestGx = gEvent.x;
    _latestGy = gEvent.y;
    _latestGz = gEvent.z;
  });

  accelerometerEventStream().listen(
    (AccelerometerEvent event) async {
      // Accumulate sample into sliding window.
      _sensorWindow.add({
        'ax': event.x,
        'ay': event.y,
        'az': event.z,
        'gx': _latestGx,
        'gy': _latestGy,
        'gz': _latestGz,
      });

      // Keep only the latest WINDOW_SIZE samples (sliding window).
      if (_sensorWindow.length > AiTelemetryValidator.windowSize) {
        _sensorWindow.removeAt(0);
      }

      // Only run inference when we have a full window.
      if (_sensorWindow.length < AiTelemetryValidator.windowSize) return;

      // ─── SESSION GUARD: Skip if user is NOT authenticated ───
      if (!appApiInitialized) return;
      try {
        final token = await appApi.getAccessToken();
        if (token == null || token.isEmpty) {
          debugPrint(
            'BackgroundService: No active session — ignoring impact.',
          );
          return;
        }
      } catch (_) {
        return;
      }
      // ─── END SESSION GUARD ──────────────────────────────────

      // Fast memory check to strictly prevent async race conditions.
      final now = DateTime.now().toUtc();
      if (_isConfirmingMemory) {
        return; // Already waiting for user response
      }
      if (_lastImpactMemory != null &&
          now.difference(_lastImpactMemory!) <
              const Duration(seconds: _impactDebounceSeconds)) {
        return;
      }

      // ─── AI INFERENCE: Run TFLite model on the sliding window ───
      // Map user sensitivity slider (15.0–60.0) to AI confidence threshold.
      // Lower slider value = more sensitive = lower confidence required.
      // Slider 15 → confidence 0.60 | Slider 37.5 → confidence 0.80 | Slider 60 → confidence 0.95
      double aiConfidence = AiTelemetryValidator.defaultConfidenceThreshold;
      try {
        final prefs = await SharedPreferences.getInstance();
        final sensitivity = prefs.getDouble(_thresholdKey) ?? 30.0;
        // Linear mapping: sensitivity [15..60] → confidence [0.60..0.95]
        aiConfidence = 0.60 + ((sensitivity - 15.0) / (60.0 - 15.0)) * (0.95 - 0.60);
        aiConfidence = aiConfidence.clamp(0.60, 0.95);
      } catch (_) {}

      final isRealFall = await aiValidator.isRealFall(
        List<Map<String, double>>.from(_sensorWindow),
        confidenceThreshold: aiConfidence,
      );

      if (!isRealFall) return; // Model says NOT a fall → ignore.
      // ─── END AI INFERENCE ───────────────────────────────────────

      _lastImpactMemory = now;

      // Debounce: sync to SharedPreferences for cross-isolate persistence.
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastImpactStr = prefs.getString(_lastImpactKey);
        if (lastImpactStr != null && lastImpactStr.isNotEmpty) {
          try {
            final lastImpact = DateTime.parse(lastImpactStr).toUtc();
            if (now.difference(lastImpact) <
                const Duration(seconds: _impactDebounceSeconds)) {
              return; // within debounce window
            }
          } catch (_) {}
        }
        await prefs.setString(_lastImpactKey, now.toIso8601String());
      } catch (e) {
        debugPrint('BackgroundService: debounce error: $e');
      }

      // Notify UI of risk detection.
      final magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      service.invoke('risk_detected', {
        "type": "AI_FALL_DETECTED",
        "magnitude": magnitude,
      });

      // ---------------------------------------------------------------
      // Phase 3: Incident Dispatch Pipeline
      //
      // If an incident is already active, we DON'T create a new one.
      // The location heartbeat timer handles ongoing updates.
      // ---------------------------------------------------------------

      if (lastKnownPosition == null) return;
      if (!appApiInitialized) return;

      if (PreAlertService.isIncidentActive) {
        debugPrint(
          'BackgroundService: incident active, sending impact data as update (heartbeat)',
        );
        final eventId = _generateEventId();
        final payload = CreateIncidentAlertDto(
          latitud: lastKnownPosition!.latitude,
          longitud: lastKnownPosition!.longitude,
          urlAudioContexto: appApi.baseUrl,
          fechaHora: DateTime.now().toUtc(),
          esProactiva: false, // Heartbeat: updates current incident
          clientEventId: eventId,
        );
        try {
          await AlertQueueService(
            appApi,
          ).sendOrQueue(payload, bypassConfirmation: true);
        } catch (e) {
          debugPrint('Heartbeat update failed: $e');
        }
        return;
      }

      // Show critical alert notification immediately.
      _showCriticalNotification(flutterLocalNotificationsPlugin);

      // NEW: Wait for user confirmation (False Positive check)
      debugPrint('BackgroundService: Requesting confirmation via UI (5s)...');
      _isConfirmingMemory = true;
      final shouldSend = await requestConfirmationViaUI(5);
      debugPrint(
        'BackgroundService: Confirmation result: shouldSend=$shouldSend',
      );
      if (!shouldSend) {
        debugPrint(
          'BackgroundService: User confirmed safe, alert cancelled.',
        );
        // Remove the critical notification if user confirmed safe
        await flutterLocalNotificationsPlugin.cancel(alertNotificationId);
        return;
      }

      // Generate a client event ID for deduplication.
      final eventId = _generateEventId();

      final payload = CreateIncidentAlertDto(
        latitud: lastKnownPosition!.latitude,
        longitud: lastKnownPosition!.longitude,
        urlAudioContexto: appApi.baseUrl,
        fechaHora: DateTime.now().toUtc(),
        esProactiva: true,
        clientEventId: eventId,
      );

      try {
        final sent = await AlertQueueService(
          appApi,
        ).sendOrQueue(payload, bypassConfirmation: true);
        if (sent) {
          // Alert was created successfully.
          final incId = await AlertQueueService(appApi).activeIncidentId;
          if (incId != null) {
            PreAlertService.activateIncident(incId);
          }
        }
      } catch (e) {
        debugPrint('Background alert send/queue failed: $e');
      }

      DiagnosticLogService.logBackgroundEvent(
        'ai_fall_detected',
        detail: 'magnitude=${magnitude.toStringAsFixed(1)} eventId=$eventId',
      );

      // Notification was already shown at the start of the confirmation window.
    },
    onError: (e) {
      debugPrint("Error in accelerometer stream: $e");
    },
  );

  // -------------------------------------------------------------------------
  // Phase 4: Periodic Tasks — Queue Retry + Location Heartbeat
  // -------------------------------------------------------------------------

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    // Skip processing if API client wasn't initialized successfully.
    if (!appApiInitialized) return;

    // Don't process if session is invalidated.
    if (SessionEvents.isInvalidated) return;

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Process queued alerts (max 1 per cycle).
        try {
          await AlertQueueService(appApi).processQueue(maxItems: 1);
        } catch (e) {
          debugPrint('Queue retry tick failed: $e');
        }
      }
    }
  });

  // Heartbeat timer: during an active incident, send location updates
  // as non-proactive alerts (es_proactiva=false) so backend receives
  // updated coordinates WITHOUT re-notifying emergency contacts.
  Timer.periodic(_heartbeatInterval, (timer) async {
    if (!appApiInitialized) return;
    if (SessionEvents.isInvalidated) return;
    if (!PreAlertService.isIncidentActive) return;
    if (lastKnownPosition == null) return;

    final incidentId = PreAlertService.activeIncidentId;
    if (incidentId == null) return;

    try {
      debugPrint(
        'BackgroundService: heartbeat location update for incident $incidentId',
      );
      await AlertsService(appApi).updateAlert(
        incidentId,
        UpdateIncidentAlertDto(
          latitud: lastKnownPosition!.latitude,
          longitud: lastKnownPosition!.longitude,
          fechaHora: DateTime.now().toUtc(),
          esProactiva: false, // Don't re-notify contacts
        ),
      );
      DiagnosticLogService.logIncidentHeartbeat(alertId: incidentId);
    } catch (e) {
      debugPrint('BackgroundService: heartbeat update failed: $e');
    }
  });
}

/// Generate a simple UUID-like event ID for deduplication.
String _generateEventId() {
  final now = DateTime.now().toUtc().microsecondsSinceEpoch;
  final rng = now.hashCode ^ DateTime.now().millisecond;
  return '${now.toRadixString(36)}-${rng.toRadixString(36)}';
}

/// Show the critical impact alert notification.
void _showCriticalNotification(FlutterLocalNotificationsPlugin plugin) {
  try {
    plugin.show(
      alertNotificationId,
      'ALERTA CRÍTICA',
      '¡IMPACTO DETECTADO! Iniciando protocolo de emergencia...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          alertChannelId,
          'Alertas Críticas de Jepo',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: false,
          autoCancel: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          ticker: 'ALERTA CRÍTICA',
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: Colors.red,
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(
            '¡IMPACTO DETECTADO! Iniciando protocolo de emergencia...\n\nPor favor, confirme que está a salvo o se solicitará ayuda automáticamente.',
            contentTitle: 'ALERTA CRÍTICA',
            summaryText: 'Riesgo Detectado',
          ),
        ),
      ),
    );
  } catch (e) {
    debugPrint("Error showing alert notification: $e");
  }
}
