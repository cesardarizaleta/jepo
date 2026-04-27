import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Privacidad y Políticas',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Política de Privacidad',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta aplicación recopila los datos personales mínimos requeridos para proporcionar servicios de asistencia proactiva. Los datos de ubicación y sensores se utilizan para detectar peligros potenciales. Los datos pueden transmitirse a contactos de confianza cuando se generan alertas. Almacenamos los datos de forma segura y seguimos las mejores prácticas de privacidad.\n\nPara obtener detalles, reemplace este marcador de posición con su política de privacidad completa.',
              style: TextStyle(color: AppTheme.textLight),
            ),
            SizedBox(height: 20),
            Text(
              'Términos de Servicio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Reemplace este marcador de posición con los términos y condiciones de su aplicación.',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
