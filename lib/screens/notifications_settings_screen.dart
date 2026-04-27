import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  static const _prefsKey = 'jepo_notifications_enabled';
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool(_prefsKey);
    setState(() {
      _enabled = val ?? true;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, v);
    setState(() => _enabled = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Habilitar notificaciones de la aplicación'),
                  value: _enabled,
                  onChanged: (v) => _setEnabled(v),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cuando se deshabilita, la aplicación evitará mostrar notificaciones locales. Las alertas automáticas importantes seguirán intentando la entrega por red.',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
    );
  }
}
