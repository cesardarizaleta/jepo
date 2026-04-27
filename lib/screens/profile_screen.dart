import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'diagnostics_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final svc = AuthService(appApi);
      final local = await svc.getCurrentUser();
      if (local != null) {
        _user = local;
      } else {
        // Try fetching latest from server
        final me = await svc.me();
        if (me != null) _user = me;
      }
    } catch (e) {
      debugPrint('Profile load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Profile Image
                  NeumorphicContainer(
                    borderRadius: 100,
                    padding: const EdgeInsets.all(10),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _displayName(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_user?.email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _user!.email!,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Full details
                  const Text(
                    'Detalles del perfil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailsList(),

                  const SizedBox(height: 24),
                  // Options
                  _buildProfileOption(
                    context,
                    'Editar Perfil',
                    Icons.edit,
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      if (res == true) {
                        await _loadUser();
                      }
                    },
                  ),
                  _buildProfileOption(
                    context,
                    'Notificaciones',
                    Icons.notifications,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsSettingsScreen(),
                      ),
                    ),
                  ),
                  _buildProfileOption(
                    context,
                    'Privacidad y Seguridad',
                    Icons.security,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  _buildProfileOption(
                    context,
                    'Ayuda y Soporte',
                    Icons.help,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    ),
                  ),
                  _buildProfileOption(
                    context,
                    'Diagnósticos',
                    Icons.bug_report,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiagnosticsScreen(),
                      ),
                    ),
                  ),
                  _buildProfileOption(
                    context,
                    'Cerrar Sesión',
                    Icons.logout,
                    isDestructive: true,
                    onPressed: () async {
                      await AuthService(appApi).logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  String _displayName() {
    if (_user == null) return 'Usuario';
    final n = _user!.nombre ?? '';
    final a = _user!.apellido ?? '';
    final full = [n, a].where((s) => s.isNotEmpty).join(' ').trim();
    return full.isNotEmpty ? full : (_user!.email ?? 'Usuario');
  }

  Widget _buildDetailsList() {
    if (_user == null) return const SizedBox.shrink();
    final entries = _user!.toJson().entries.toList();
    return Column(
      children: entries.map((e) {
        final key = e.key.toString();
        final val = e.value == null ? '—' : e.value.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  _humanizeKey(key),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  val,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _humanizeKey(String k) {
    return k
        .replaceAll('_', ' ')
        .splitMapJoin(
          RegExp(r'\b'),
          onMatch: (m) => m.group(0)!.toUpperCase(),
          onNonMatch: (s) => s,
        );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon, {
    bool isDestructive = false,
    VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicButton(
        onPressed: onPressed ?? () {},
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : AppTheme.textDark),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
