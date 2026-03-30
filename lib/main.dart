import 'package:flutter/material.dart';
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
import 'theme/app_theme.dart';
import 'widgets/neumorphic_container.dart';
import 'screens/telemetry_screen.dart';
import 'screens/family_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pre_alert_confirmation_screen.dart';
import 'services/background_service.dart';
import 'screens/login_screen.dart';
import 'dart:async';

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
  StreamSubscription<PreAlertRequest>? _preAlertSub;

  @override
  void initState() {
    super.initState();
    _hasSession = _determineSession();
    // Listen for unauthorized events and force a logout -> login screen.
    _unauthorizedSub = SessionEvents.onUnauthorized.listen((_) async {
      if (!mounted) return;
      try {
        await AuthService(appApi).logout();
      } catch (_) {}
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

      final result = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PreAlertConfirmationScreen(seconds: request.seconds),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      request.resolveAsSafe(result == true);
    });
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    _preAlertSub?.cancel();
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
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSession = snapshot.data ?? false;
        if (hasSession) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final url = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

      final payload = <String, dynamic>{
        'latitud': pos.latitude,
        'longitud': pos.longitude,
        'url_audio_contexto': appApi.baseUrl,
        'fecha_hora': DateTime.now().toUtc().toIso8601String(),
        'es_proactiva': true,
      };

      try {
        final sent = await AlertQueueService(appApi).sendOrQueue(payload);
        if (!sent && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Alert queued locally and will be retried after login/connectivity.',
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to send/queue alert: $e');
      }

      Share.share('Help! I need assistance. My current location is: $url');
    } catch (e) {
      debugPrint('Error obtaining location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not obtain location')),
        );
      }
    }
  }

  Future<void> _callEmergency(BuildContext context) async {
    const number = '123'; // Emergency number
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);

    if (res != true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not initiate direct call. Please dial 123 manually.',
          ),
          backgroundColor: Colors.red,
        ),
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
            tooltip: 'Telemetry Monitor',
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
                    title: 'Family',
                    icon: Icons.people_outline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FamilyScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Emergency',
                    icon: Icons.sos,
                    color: Colors.red,
                    iconColor: Colors.white,
                    onTap: () => _callEmergency(context),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Profile',
                    icon: Icons.person_outline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Share Location',
                    icon: Icons.share_location,
                    onTap: () => _shareLocation(context),
                  ),
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
          Icon(icon, size: 40, color: iconColor ?? AppTheme.primary),
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
    if (_user == null) return 'Usuario';
    final n = _user!['nombre'] ?? _user!['name'] ?? _user!['first_name'];
    final a = _user!['apellido'] ?? _user!['last_name'] ?? _user!['surname'];
    final nstr = n?.toString() ?? '';
    final astr = a?.toString() ?? '';
    final full = [nstr, astr].where((s) => s.isNotEmpty).join(' ').trim();
    if (full.isNotEmpty) return full;
    return _user!['email']?.toString() ?? 'Usuario';
  }

  String _userSummaryLine() {
    if (_user == null) return 'Everything looks good today.';
    final email = _findField(['email']);
    final phone = _findField([
      'telefono',
      'telefono_movil',
      'telefono_contacto',
      'phone',
      'mobile',
      'celular',
    ]);
    final parts = <String>[];
    if (email != null) parts.add(email);
    if (phone != null) parts.add(phone);
    if (parts.isEmpty) return 'Everything looks good today.';
    return parts.join(' • ');
  }

  String? _findField(List<String> keys) {
    if (_user == null) return null;
    for (final k in keys) {
      final v = _user![k];
      if (v != null) return v.toString();
    }
    return null;
  }
}
