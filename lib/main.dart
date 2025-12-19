import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'theme/app_theme.dart';
import 'widgets/neumorphic_container.dart';
import 'screens/telemetry_screen.dart';
import 'screens/family_screen.dart';
import 'screens/profile_screen.dart';
import 'services/background_service.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 4. Initialize Service immediately after permissions
  await initializeService();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _shareLocation(BuildContext context) {
    // Mock location for now, in real app use Geolocator
    Share.share(
      'Help! I need assistance. My current location is: https://maps.google.com/?q=10.96854,-74.78132',
    );
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
            Text(
              'Hello, Elianis',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everything looks good today.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16),
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
}
