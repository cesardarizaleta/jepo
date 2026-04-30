import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_alert.dart';
import 'alert_queue_service.dart';
import 'api_client.dart';
import 'alerts_service.dart';
import 'diagnostic_log_service.dart';
import 'pre_alert_service.dart';
import 'session_events.dart';

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
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: monitoringChannelId, // Default to monitoring
      initialNotificationTitle: 'Jepo Activo',
      initialNotificationContent: 'Inicializando sistemas de seguridad...',
      foregroundServiceNotificationId: monitoringNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
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

  // Listen for confirmation response from UI
  Completer<bool>? confirmationCompleter;
  service.on('pre_alert_response').listen((event) {
    if (confirmationCompleter != null && !confirmationCompleter!.isCompleted) {
      final isSafe = event?['isSafe'] ?? false;
      confirmationCompleter!.complete(!isSafe); // shouldSend = !isSafe
    }
  });

  // Helper to request confirmation via UI
  Future<bool> requestConfirmationViaUI(int seconds) async {
    confirmationCompleter = Completer<bool>();
    
    // Give the system a moment to bring the activity to front via the UI isolate's native call.
    await Future.delayed(const Duration(milliseconds: 500));
    
    service.invoke('show_pre_alert', {"seconds": seconds});
    
    // Wait for response or timeout (safety margin)
    try {
      return await confirmationCompleter!.future.timeout(
        Duration(seconds: seconds + 5),
        onTimeout: () => true, // Default to send if UI doesn't respond
      );
    } catch (_) {
      return true;
    } finally {
      confirmationCompleter = null;
    }
  }

  // Initialise the API client for background work.
  try {
    await initApi();
    await AlertQueueService(appApi).processQueue();
    
    // Load initial threshold
    final prefs = await SharedPreferences.getInstance();
    _impactThreshold = prefs.getDouble(_thresholdKey) ?? 30.0;
  } catch (e) {
    debugPrint('Background API init failed: $e');
  }

  // Listen for stop command
  service.on('stopService').listen((event) {
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
  // Phase 2: Sensor Monitoring — Impact Detection
  // -------------------------------------------------------------------------

  accelerometerEventStream().listen(
    (AccelerometerEvent event) async {
      // Calculate G-force magnitude.
      double magnitude = (event.x.abs() + event.y.abs() + event.z.abs());

      if (magnitude > _impactThreshold) {
        // Debounce: ignore impacts within the debounce window.
        try {
          final prefs = await SharedPreferences.getInstance();
          final lastImpactStr = prefs.getString(_lastImpactKey);
          final now = DateTime.now().toUtc();
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
        service.invoke('risk_detected', {
          "type": "IMPACT",
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
            await AlertQueueService(appApi).sendOrQueue(
              payload,
              bypassConfirmation: true,
            );
          } catch (e) {
            debugPrint('Heartbeat update failed: $e');
          }
          return;
        }

        // Show critical alert notification immediately.
        _showCriticalNotification(flutterLocalNotificationsPlugin);

        // NEW: Wait for user confirmation (False Positive check)
        debugPrint('BackgroundService: Requesting confirmation via UI (5s)...');
        final shouldSend = await requestConfirmationViaUI(5);
        debugPrint('BackgroundService: Confirmation result: shouldSend=$shouldSend');
        if (!shouldSend) {
          debugPrint('BackgroundService: User confirmed safe, alert cancelled.');
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
          final sent = await AlertQueueService(appApi).sendOrQueue(
            payload,
            bypassConfirmation: true,
          );
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
          'impact_detected',
          detail: 'magnitude=${magnitude.toStringAsFixed(1)} eventId=$eventId',
        );

        // Notification was already shown at the start of the confirmation window.
      }
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
void _showCriticalNotification(
  FlutterLocalNotificationsPlugin plugin,
) {
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
