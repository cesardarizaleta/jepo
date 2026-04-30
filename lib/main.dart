import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
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
import 'screens/profile_screen.dart';
import 'services/background_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pre_alert_screen.dart';
import 'models/user.dart';
import 'models/incident_alert.dart';
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

  runApp(const MainApp());
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

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _hasSession;
  StreamSubscription? _unauthorizedSub;
  StreamSubscription? _logoutSub;
  StreamSubscription<PreAlertRequest>? _preAlertSub;
  StreamSubscription? _serviceSub;
  static const _foregroundChannel = MethodChannel('com.example.jepo/foreground');
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _hasSession = _determineSession();

    // Listen for unauthorized events (401) and force navigate to login.
    // Note: AuthService.logout() is NOT called here because the 401 handler
    // in ApiClient already cleared the token and SessionEvents prevents
    // cascading reactions.
    _unauthorizedSub = SessionEvents.onUnauthorized.listen((_) async {
      if (!mounted) return;
      // Clear local session data without re-broadcasting logout.
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

    _preAlertSub = PreAlertService.onRequest.listen((request) async {
      if (!mounted) {
        request.resolveAsSafe(false);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreAlertScreen(request: request),
          fullscreenDialog: true,
        ),
      );
    });

    // Bridge messages from Background Service to PreAlertService
    final service = FlutterBackgroundService();
    _serviceSub = service.on('show_pre_alert').listen((event) async {
      debugPrint('MainApp: Received show_pre_alert event from background service');
      if (!mounted) {
        debugPrint('MainApp: SessionGate not mounted, ignoring pre-alert');
        return;
      }
      final seconds = event?['seconds'] ?? 5;
      debugPrint('MainApp: Received request for $seconds seconds pre-alert');
      
      // Force app to foreground on Android via MethodChannel
      // The logs show the UI isolate is active, so we can trigger the native wakeup here.
      _foregroundChannel.invokeMethod('bringToForeground').catchError((e) {
        debugPrint('MainApp: bringToForeground failed: $e');
      });

      // Use microtask to ensure we don't block the listener isolate
      Future.microtask(() async {
        debugPrint('MainApp: Triggering PreAlertService.requestConfirmation...');
        final result = await PreAlertService.requestConfirmation(seconds: seconds);
        debugPrint('MainApp: Confirmation result: $result');
        service.invoke('pre_alert_response', {"isSafe": !result});
      });
    });
  }

  @override
  void dispose() {
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

      // Show premium loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: NeumorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            borderRadius: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
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
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
      );

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final url = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      Share.share('¡Ayuda! Necesito asistencia. Mi ubicación actual es: $url');
    } catch (e) {
      debugPrint('Error obtaining location: $e');
      if (context.mounted) {
        // Ensure dialog is closed if it was opened
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
          AppToast.error(context, 'Permiso de llamada denegado. Por favor, marque 911 manualmente.');
        }
        return;
      }
    }

    bool? res = await FlutterPhoneDirectCaller.callNumber(number);

    if (res != true && context.mounted) {
      AppToast.error(context, 'No se pudo iniciar la llamada directa. Por favor, marque 911 manualmente.');
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
                  ).animate().fadeIn(delay: 100.ms).scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                    context,
                    title: 'Emergencia',
                    icon: Icons.sos,
                    color: Colors.red,
                    iconColor: Colors.white,
                    onTap: () => _callEmergency(context),
                  ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack),
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
                  ).animate().fadeIn(delay: 300.ms).scale(curve: Curves.easeOutBack),
                  _buildMenuCard(
                    context,
                    title: 'Compartir Ubicación',
                    icon: Icons.share_location,
                    onTap: () => _shareLocation(context),
                  ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack),
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
                  child: Icon(icon, size: 40, color: iconColor ?? AppTheme.primary),
                )
              : Icon(icon, size: 40, color: iconColor ?? AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor ?? AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
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
