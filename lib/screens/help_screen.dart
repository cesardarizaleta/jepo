import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _contactSupport() async {
    final Uri mail = Uri(
      scheme: 'mailto',
      path: 'support@jepo.app',
      query: 'subject=Help%20request',
    );
    if (!await launchUrl(mail)) {
      // ignore: avoid_print
      print('Could not launch $mail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayuda y Soporte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Si necesita asistencia con la aplicación, primero intente reiniciarla. Si el problema persiste, contacte con soporte técnico usando el botón de abajo.',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.email),
              label: const Text('Contactar con Soporte'),
            ),
          ],
        ),
      ),
    );
  }
}
