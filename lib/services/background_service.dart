import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_queue_service.dart';
import 'api_client.dart';

// Notification Channel IDs
const String monitoringChannelId = 'jepo_monitoring';
const String alertChannelId = 'jepo_alerts';
const int monitoringNotificationId = 888;
const int alertNotificationId = 999;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Monitoring Channel (Silent, Low Importance)
  const AndroidNotificationChannel monitoringChannel =
      AndroidNotificationChannel(
        monitoringChannelId,
        'Jepo Monitoring',
        description: 'Continuous background monitoring.',
        importance: Importance.low,
        playSound: false,
        showBadge: false,
      );

  // 2. Alert Channel (High Importance, Sound, Vibration)
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    alertChannelId,
    'Jepo Alerts',
    description: 'Critical safety alerts.',
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
      initialNotificationTitle: 'Jepo Active',
      initialNotificationContent: 'Initializing safety systems...',
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

  try {
    await initApi();
    await AlertQueueService(appApi).processQueue();
  } catch (e) {
    debugPrint('Background API init failed: $e');
  }

  // Listen for stop command
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Force show initial notification immediately to avoid delay
  try {
    await flutterLocalNotificationsPlugin.show(
      monitoringNotificationId,
      'Jepo Active',
      'Safety systems online. Monitoring...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          monitoringChannelId,
          'Jepo Monitoring',
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

  // --- Telemetry Logic ---

  // 1. Location Tracking (Optimized for Battery)
  // We use AndroidSettings to set an interval, allowing the GPS to sleep.
  // Accuracy is kept High for speed detection, but we don't need updates every second if not moving much.

  final locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 15, // Update only after moving 15 meters
    forceLocationManager: true,
    intervalDuration: const Duration(
      seconds: 10,
    ), // Minimum interval between updates
    // foregroundNotificationConfig: ... // We handle notification manually
  );

  Position? lastKnownPosition;

  final locationStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  );

  locationStream.listen((Position position) {
    lastKnownPosition = position;
    // Here we would process the location (Graph Theory, Safe Zones)
    // For now, we just update the notification to show we are alive

    // Update notification content to show latest activity
    try {
      flutterLocalNotificationsPlugin.show(
        monitoringNotificationId,
        'Jepo Active',
        'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            monitoringChannelId,
            'Jepo Monitoring',
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
    });
  });

  // 2. Sensor Monitoring (HAR)
  // Accelerometer for falls/impacts
  // We can throttle this if needed, but for impact detection we need real-time.
  // The logic is lightweight (simple math).
  // Persistent key to store the last impact timestamp, in UTC ISO8601
  const String lastImpactKey = 'jepo_last_impact_at';
  const int throttleWindowSeconds = 3;

  accelerometerEventStream().listen(
    (AccelerometerEvent event) async {
      // Calculate G-force
      double magnitude = (event.x.abs() + event.y.abs() + event.z.abs());

      // Simple Threshold for "Risk" (>30 m/s^2 is roughly 3G)
      if (magnitude > 30.0) {
        // Debounce/Throttle sensor-triggered alerts: ignore impacts that occur
        // within `throttleWindowSeconds` of the last accepted impact.
        try {
          final prefs = await SharedPreferences.getInstance();
          final lastImpactStr = prefs.getString(lastImpactKey);
          final now = DateTime.now().toUtc();
          if (lastImpactStr != null && lastImpactStr.isNotEmpty) {
            try {
              final lastImpact = DateTime.parse(lastImpactStr).toUtc();
              if (now.difference(lastImpact) <
                  Duration(seconds: throttleWindowSeconds)) {
                debugPrint(
                  'BackgroundService: impact ignored due to throttle (lastImpact=$lastImpact)',
                );
                return;
              }
            } catch (_) {}
          }
          await prefs.setString(lastImpactKey, now.toIso8601String());
        } catch (e) {
          debugPrint('BackgroundService: error reading/writing lastImpact: $e');
        }
        // TRIGGER ALERT!
        // In a real app, this would call the Alert Module

        service.invoke('risk_detected', {
          "type": "IMPACT",
          "magnitude": magnitude,
        });

        // Try API alert first, or queue locally for retry.
        if (lastKnownPosition != null) {
          final payload = <String, dynamic>{
            'latitud': lastKnownPosition!.latitude,
            'longitud': lastKnownPosition!.longitude,
            'url_audio_contexto': appApi.baseUrl,
            'fecha_hora': DateTime.now().toUtc().toIso8601String(),
            'es_proactiva': true,
          };

          try {
            await AlertQueueService(appApi).sendOrQueue(payload);
          } catch (e) {
            debugPrint('Background alert send/queue failed: $e');
          }
        }

        // Update notification to warn user
        try {
          flutterLocalNotificationsPlugin.show(
            alertNotificationId,
            'CRITICAL ALERT',
            'IMPACT DETECTED! Initiating emergency protocol...',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                alertChannelId,
                'Jepo Alerts',
                importance: Importance.max,
                priority: Priority.max,
                ongoing: false,
                autoCancel: true,
                icon: '@mipmap/ic_launcher',
                largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                color: Colors.red,
                enableVibration: true,
                playSound: true,
                styleInformation: BigTextStyleInformation(
                  'IMPACT DETECTED! Initiating emergency protocol...\n\nPlease confirm you are safe or help will be requested automatically.',
                  contentTitle: 'CRITICAL ALERT',
                  summaryText: 'Risk Detected',
                ),
              ),
            ),
          );
        } catch (e) {
          debugPrint("Error showing alert notification: $e");
        }
      }
    },
    onError: (e) {
      debugPrint("Error in accelerometer stream: $e");
    },
  );

  // Keep the service alive
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    // Skip processing if API client wasn't initialized successfully
    if (!appApiInitialized) {
      return;
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          await AlertQueueService(appApi).processQueue(maxItems: 5);
        } catch (e) {
          debugPrint('Queue retry tick failed: $e');
        }

        // Ensure notification is up to date
        // flutterLocalNotificationsPlugin.show(...)
      }
    }
  });
}
