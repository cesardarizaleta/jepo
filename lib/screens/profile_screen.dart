import 'package:flutter/material.dart';
import '../models/incident_alert.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/metrics_service.dart';
import 'alert_history_screen.dart';
import 'diagnostics_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';
import 'tutorial_screen.dart';
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
  AlertMetrics _metrics = AlertMetrics.empty;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final svc = AuthService(appApi);
      final metricsSvc = MetricsService(appApi);
      final local = await svc.getCurrentUser();
      if (local != null) {
        _user = local;
      } else {
        final me = await svc.me();
        if (me != null) _user = me;
      }
      try {
        _metrics = await metricsSvc.getMetrics();
      } catch (e) {
        debugPrint('Metrics load failed: $e');
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
          : RefreshIndicator(
              onRefresh: _loadUser,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Image
                    Hero(
                      tag: 'profile_image',
                      child: NeumorphicContainer(
                        borderRadius: 100,
                        padding: const EdgeInsets.all(10),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
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
                  _buildMetricsPreview(),
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
                    'Historial y Métricas',
                    Icons.analytics_outlined,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlertHistoryScreen(),
                        ),
                      );
                      if (mounted) await _loadUser();
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
                    'Tutorial de Jepo',
                    Icons.menu_book_outlined,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TutorialScreen(),
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
          ),
    );
  }

  String _displayName() {
    return _user?.fullName ?? 'Usuario';
  }

  Widget _buildMetricsPreview() {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de alertas',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_metrics.totalAlertas} alertas · '
                  '${_metrics.tasaFalsosPositivos.toStringAsFixed(1)}% falsos positivos',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList() {
    if (_user == null) return const SizedBox.shrink();
    
    // We only show safe, relevant information as requested.
    // Sensitive fields like 'id' and 'cedula' are excluded.
    final items = [
      _ProfileInfoItem(label: 'Nombre', value: _user!.nombre ?? '—'),
      _ProfileInfoItem(label: 'Apellido', value: _user!.apellido ?? '—'),
      _ProfileInfoItem(label: 'Correo', value: _user!.email ?? '—'),
      _ProfileInfoItem(label: 'Teléfono', value: _user!.telefono ?? '—'),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: NeumorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

class _ProfileInfoItem {
  final String label;
  final String value;
  _ProfileInfoItem({required this.label, required this.value});
}
