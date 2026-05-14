import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/api_client.dart';
import 'services/alert_queue_service.dart';
import 'services/auth_service.dart';
import 'services/session_events.dart';
import 'services/pre_alert_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'theme/app_theme.dart';
import 'widgets/neumorphic_container.dart';
import 'screens/telemetry_screen.dart';
import 'screens/family_screen.dart';
import 'screens/family_map_screen.dart';
import 'screens/profile_screen.dart';
import 'services/background_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pre_alert_screen.dart';
import 'models/user.dart';
import 'utils/app_toast.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client (loads env and seeds secure storage if provided)
  try {
    await initApi();
  } catch (e, st) {
    debugPrint('initApi() failed: $e');
    debugPrint('$st');
  }

  await _initializePlatformServices();

  runApp(const ProviderScope(child: MainApp()));
}

Future<void> _initializePlatformServices() async {
  // Web does not support these mobile-only permission flows/services.
  if (kIsWeb) {
    return;
  }

  final bool isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (!isMobile) {
    return;
  }

  try {
    await _requestStartupPermissions();
    await initializeService();

    // Only start the background service if user already has an active session.
    // Otherwise it will be started after login/register in AuthService.
    if (appApiInitialized) {
      final token = await appApi.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final bgService = FlutterBackgroundService();
        await bgService.startService();
        debugPrint('Main: Background service started (existing session).');
      }
    }
  } catch (e, st) {
    // Never block app bootstrap because of optional background features.
    debugPrint('Startup init failed: $e');
    debugPrint('$st');
  }
}

Future<void> _requestStartupPermissions() async {
  // 1. Request Notification Permission first (Android 13+)
  await Permission.notification.request();

  // 2. Request Phone Call Permission
  await Permission.phone.request();

  // 3. Request Location Permissions in order
  // Android requires "When In Use" before "Always"
  var status = await Permission.locationWhenInUse.request();

  if (status.isGranted) {
    // Only ask for Always if WhenInUse is granted
    var alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  // 4. Request System Alert Window (Display over other apps)
  // This is critical for bringing the app to foreground on Android 10+
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SessionGate(),
    );
  }

  // User summary helpers moved to HomeScreen state
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  late final Future<bool> _hasSession;
  StreamSubscription? _unauthorizedSub;
  StreamSubscription? _logoutSub;
  StreamSubscription<PreAlertRequest>? _preAlertSub;
  StreamSubscription? _serviceSub;
  FlutterBackgroundService? _backgroundService;
  static const _foregroundChannel = MethodChannel(
    'com.example.jepo/foreground',
  );
  bool _onboardingDone = false;
  bool _preAlertRouteActive = false;
  bool _uiReady = false;
  bool _appInForeground = true; // Tracks whether Activity is currently visible
  final Completer<void> _uiReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasSession = _determineSession();

    if (_supportsBackgroundService) {
      _backgroundService = FlutterBackgroundService();
    }

    // -----------------------------------------------------------------------
    // CRITICAL: Register MethodChannel handler for native -> Flutter calls.
    // When the fullScreenIntent notification wakes the screen and launches
    // MainActivity, the native code calls 'showPreAlert' on this channel.
    // This is the PRIMARY path for showing the pre-alert on Android 10+.
    // -----------------------------------------------------------------------
    _foregroundChannel.setMethodCallHandler((call) async {
      debugPrint(
        'MainApp: Native MethodChannel call: ${call.method} args=${call.arguments}',
      );
      if (call.method == 'showPreAlert') {
        final seconds = (call.arguments as Map?)?['seconds'] as int? ?? 5;
        debugPrint('MainApp: Native triggered showPreAlert ($seconds s)');
        await _awaitUiReady(const Duration(seconds: 2));
        await _presentPreAlert(seconds: seconds, notifyBackgroundService: true);
      }
    });

    // -----------------------------------------------------------------------
    // Initialize flutter_local_notifications to capture notification taps.
    // When the user taps the pre-alert notification, the payload 'pre_alert:N'
    // triggers showing the pre-alert screen directly.
    // -----------------------------------------------------------------------
    _initNotificationTapHandler();

    // Listen for unauthorized events (401) and force navigate to login.
    _unauthorizedSub = SessionEvents.onUnauthorized.listen((_) async {
      if (!mounted) return;
      try {
        await appApi.clearAccessToken();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });

    // Listen for explicit logout events (user-initiated or forced).
    _logoutSub = SessionEvents.onLogout.listen((_) async {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });

    // Fallback path: PreAlertService stream (for in-process requests from
    // AlertQueueService when the app is already in the foreground).
    _preAlertSub = PreAlertService.onRequest.listen((request) async {
      debugPrint('MainApp: PreAlertService.onRequest received');
      if (!mounted) {
        debugPrint('MainApp: Not mounted, resolving as unsafe');
        request.resolveAsSafe(false);
        return;
      }
      if (_preAlertRouteActive) {
        debugPrint(
          'MainApp: Pre-alert route already active, resolving as unsafe',
        );
        request.resolveAsSafe(false);
        return;
      }
      _preAlertRouteActive = true;
      try {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreAlertScreen(request: request),
            fullscreenDialog: true,
          ),
        );
        await request.isSafeDecision;
      } catch (e) {
        debugPrint('MainApp: Error in PreAlertService listener: $e');
        request.resolveAsSafe(false);
      } finally {
        _preAlertRouteActive = false;
      }
    });

    // Fallback path: background service IPC event.
    // IMPORTANT: Only show the pre-alert screen if the app is ALREADY in the
    // foreground. If the app is in the background, the fullScreenIntent
    // notification is the UI — showing a Flutter route in the background just
    // runs an invisible 5s countdown that fires the alert before the user can
    // ever see it. When the user opens the app via the notification,
    // didChangeAppLifecycleState(resumed) fires _recoverPendingPreAlert().
    if (_supportsBackgroundService) {
      _serviceSub = _backgroundService?.on('show_pre_alert').listen((
        event,
      ) async {
        debugPrint(
          'MainApp: show_pre_alert IPC received. appInForeground=$_appInForeground',
        );
        final seconds = (event?['seconds'] as num?)?.toInt() ?? 5;

        if (!_appInForeground) {
          debugPrint(
            'MainApp: App is in background — attempting to bring to foreground natively.',
          );
          try {
            await _foregroundChannel.invokeMethod('bringToForeground');
          } catch (e) {
            debugPrint('MainApp: Failed to bring to foreground: $e');
          }
          return;
        }

        if (!await _awaitUiReady(const Duration(seconds: 2))) {
          debugPrint('MainApp: UI not ready for IPC show_pre_alert');
          return;
        }
        debugPrint(
          'MainApp: App in foreground — showing pre-alert screen ($seconds s)',
        );
        await _presentPreAlert(seconds: seconds, notifyBackgroundService: true);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('MainApp: Post-frame callback — UI ready');
      if (!_uiReadyCompleter.isCompleted) {
        _uiReady = true;
        _uiReadyCompleter.complete();
      }
      await _recoverPendingPreAlert();
    });
  }

  void _initNotificationTapHandler() {
    final plugin = FlutterLocalNotificationsPlugin();
    // Check if the app was opened from a notification tap (cold start).
    plugin.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp == true) {
        final payload = details!.notificationResponse?.payload ?? '';
        debugPrint('MainApp: Launched from notification, payload=$payload');
        if (payload.startsWith('pre_alert:')) {
          final secondsStr = payload.split(':').last;
          final seconds = int.tryParse(secondsStr) ?? 5;
          // Defer until after initState completes
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _awaitUiReady(const Duration(seconds: 3));
            await _presentPreAlert(
              seconds: seconds,
              notifyBackgroundService: true,
            );
          });
        }
      }
    });

    // Handle notification tap while app is running (warm/hot state).
    plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload ?? '';
        debugPrint('MainApp: Notification tapped, payload=$payload');
        if (payload.startsWith('pre_alert:')) {
          final secondsStr = payload.split(':').last;
          final seconds = int.tryParse(secondsStr) ?? 5;
          await _presentPreAlert(
            seconds: seconds,
            notifyBackgroundService: true,
          );
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('MainApp: Lifecycle → $state');
    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      // App just came to foreground (e.g. user tapped the pre-alert notification).
      // Check if there's a pending pre-alert stored and show it.
      _recoverPendingPreAlert();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _appInForeground = false;
    }
  }

  Future<bool> _awaitUiReady(Duration timeout) async {
    if (_uiReady) {
      debugPrint('MainApp: UI already ready');
      return mounted;
    }

    debugPrint('MainApp: Waiting for UI to be ready (timeout: $timeout)');
    try {
      await _uiReadyCompleter.future.timeout(timeout);
      debugPrint('MainApp: UI became ready');
    } catch (_) {
      debugPrint('MainApp: UI ready wait timed out');
      // If the UI is still not ready, let the pending-prealert recovery path
      // handle it when the app finally mounts.
    }

    return mounted && _uiReady;
  }

  Future<void> _recoverPendingPreAlert() async {
    debugPrint('MainApp: Checking for pending pre-alert recovery...');
    if (!mounted || _preAlertRouteActive) {
      debugPrint(
        'MainApp: Recovery skipped (mounted=$mounted, routeActive=$_preAlertRouteActive)',
      );
      return;
    }

    final seconds = await PreAlertService.takePendingPreAlert();
    if (seconds == null || !mounted || _preAlertRouteActive) {
      debugPrint('MainApp: No pending pre-alert to recover (seconds=$seconds)');
      return;
    }

    // Use at least 10 seconds so the user has a clear window to respond,
    // even if some time elapsed while the app was opening.
    final displaySeconds = seconds < 10 ? 10 : seconds;
    debugPrint(
      'MainApp: Recovering pending pre-alert (display=${displaySeconds}s, original=${seconds}s)',
    );
    await _presentPreAlert(
      seconds: displaySeconds,
      notifyBackgroundService: true,
    );
  }

  Future<void> _presentPreAlert({
    required int seconds,
    required bool notifyBackgroundService,
  }) async {
    if (!mounted || _preAlertRouteActive) {
      debugPrint(
        'MainApp: _presentPreAlert skipped (mounted=$mounted, routeActive=$_preAlertRouteActive)',
      );
      return;
    }

    debugPrint('MainApp: Presenting pre-alert screen ($seconds s)');
    _preAlertRouteActive = true;
    final request = PreAlertRequest(seconds: seconds);

    try {
      // Start listening for the decision immediately, before the navigation
      // completes. The PreAlertScreen resolves the request's Completer and
      // then pops itself, so we need to capture the decision as soon as it
      // fires, not after Navigator.push returns.
      final decisionFuture = request.isSafeDecision;

      // Push the pre-alert screen (non-blocking await — we also listen on
      // decisionFuture which fires when the screen resolves).
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreAlertScreen(request: request),
          fullscreenDialog: true,
        ),
      );

      // Wait for the user's decision (or timeout from PreAlertScreen)
      final isSafe = await decisionFuture.timeout(
        Duration(seconds: seconds + 4),
        onTimeout: () {
          debugPrint('MainApp: Pre-alert decision timed out, assuming unsafe');
          return false;
        },
      );

      debugPrint('MainApp: Pre-alert decision received: isSafe=$isSafe');

      if (notifyBackgroundService) {
        _backgroundService?.invoke('pre_alert_response', {"isSafe": isSafe});
        debugPrint('MainApp: Sent pre_alert_response to background service');
      }
    } catch (e) {
      debugPrint('MainApp: Error in _presentPreAlert: $e');
      // On any error, notify background to proceed with the alert (safe=false)
      if (notifyBackgroundService) {
        _backgroundService?.invoke('pre_alert_response', {"isSafe": false});
      }
    } finally {
      _preAlertRouteActive = false;
    }
  }

  bool get _supportsBackgroundService =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unauthorizedSub?.cancel();
    _logoutSub?.cancel();
    _preAlertSub?.cancel();
    _serviceSub?.cancel();
    super.dispose();
  }

  Future<bool> _determineSession() async {
    // Wait briefly for `appApi` to initialize (in case initApi took a moment).
    // If it doesn't become ready, fall back to "no session" so UI can render
    // and the user can still log in.
    int attempts = 0;
    while (!appApiInitialized && attempts < 15) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (!appApiInitialized) {
      debugPrint('appApi not initialized after wait; assuming no session');
      return false;
    }

    return await AuthService(appApi).hasActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<bool>>(
      future: Future.wait([_hasSession, _checkOnboarding()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSession = snapshot.data![0];
        final onboardingDone = snapshot.data![1];

        if (!onboardingDone) {
          return OnboardingScreen(
            onFinished: () => setState(() => _onboardingDone = true),
          );
        }

        if (hasSession) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      final svc = AuthService(appApi);
      final local = await svc.getCurrentUser();
      if (local != null) {
        _user = local;
      } else {
        final me = await svc.me();
        if (me != null) _user = me;
      }
    } catch (e) {
      debugPrint('Home user load failed: $e');
    }
    if (mounted) setState(() => _loadingUser = false);
  }

  void _shareLocation(BuildContext context) {
    _shareRealLocation(context);
  }

  Future<void> _shareRealLocation(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            AppToast.error(context, 'Permiso de ubicación denegado');
          }
          return;
        }
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 30,
                    ),
                    borderRadius: 30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1200.ms, color: Colors.white24),
                        const SizedBox(height: 25),
                        const Text(
                          'PREPARANDO',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu Ubicación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.9, 0.9)),
      );

      final pos = await Geolocator.getCurrentPosition();
      final url = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

      if (context.mounted) Navigator.of(context).pop();

      // ignore: deprecated_member_use
      Share.share('¡Ayuda! Necesito asistencia. Mi ubicación actual es: $url');
    } catch (e) {
      debugPrint('Error obtaining location: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        AppToast.error(context, 'No se pudo obtener la ubicación');
      }
    }
  }

  Future<void> _callEmergency(BuildContext context) async {
    const number = '911'; // Emergency number

    // Check and request phone permission if needed
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      final request = await Permission.phone.request();
      if (!request.isGranted) {
        if (context.mounted) {
          AppToast.error(
            context,
            'Permiso de llamada denegado. Por favor, marque 911 manualmente.',
          );
        }
        return;
      }
    }

    bool? res = await FlutterPhoneDirectCaller.callNumber(number);

    if (res != true && context.mounted) {
      AppToast.error(
        context,
        'No se pudo iniciar la llamada directa. Por favor, marque 911 manualmente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'JEPO',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors, color: AppTheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelemetryScreen(),
                ),
              );
            },
            tooltip: 'Monitor de Telemetría',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User summary
            _loadingUser
                ? const SizedBox(
                    height: 64,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(),
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userSummaryLine(),
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuCard(
                        context,
                        title: 'Familia',
                        icon: Icons.people_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FamilyScreen(),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                        context,
                        title: 'Emergencia',
                        icon: Icons.sos,
                        color: Colors.red,
                        iconColor: Colors.white,
                        onTap: () => _callEmergency(context),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                        context,
                        title: 'Perfil',
                        icon: Icons.person_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                        context,
                        title: 'Mapa',
                        icon: Icons.map_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FamilyMapScreen(),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                        context,
                        title: 'Compartir',
                        icon: Icons.share_location,
                        onTap: () => _shareLocation(context),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .scale(curve: Curves.easeOutBack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return NeumorphicButton(
      onPressed: onTap,
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          title == 'Perfil'
              ? Hero(
                  tag: 'profile_image',
                  child: Icon(
                    icon,
                    size: 40,
                    color: iconColor ?? AppTheme.primary,
                  ),
                )
              : Icon(icon, size: 40, color: iconColor ?? AppTheme.primary),
          const SizedBox(height: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor ?? AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName() {
    return _user?.fullName ?? 'Usuario';
  }

  String _userSummaryLine() {
    if (_user == null) return 'Todo se ve bien hoy.';
    final email = _user!.email;
    final phone = _user!.telefono;
    final parts = <String>[];
    if (email != null) parts.add(email);
    if (phone != null) parts.add(phone);
    if (parts.isEmpty) return 'Todo se ve bien hoy.';
    return parts.join(' • ');
  }
}
