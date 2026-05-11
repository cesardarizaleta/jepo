import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import 'terms_screen.dart';

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
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7FCCC4).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF7FCCC4),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Política de Privacidad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Última actualización: 11 de mayo de 2026',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildPolicySection(
              title: 'Datos que Recopilamos',
              content:
                  '• Información personal: nombre, cédula, correo electrónico, teléfono.\n'
                  '• Datos de ubicación: coordenadas GPS cuando la aplicación está activa.\n'
                  '• Datos de sensores: lecturas del acelerómetro y giroscopio.\n'
                  '• Contactos de emergencia: nombres y teléfonos que usted registra.',
            ),

            _buildPolicySection(
              title: 'Cómo Usamos sus Datos',
              content:
                  '• Detección proactiva de situaciones de riesgo mediante análisis de sensores.\n'
                  '• Envío de alertas a sus contactos de emergencia designados.\n'
                  '• Mejora continua de los algoritmos de detección.\n'
                  '• Autenticación y seguridad de su cuenta.',
            ),

            _buildPolicySection(
              title: 'Almacenamiento y Seguridad',
              content:
                  '• Sus datos se almacenan en servidores seguros con cifrado en tránsito y en reposo.\n'
                  '• Las contraseñas se almacenan con hash criptográfico (nunca en texto plano).\n'
                  '• Los tokens de sesión tienen expiración automática.\n'
                  '• Implementamos medidas de seguridad estándar de la industria.',
            ),

            _buildPolicySection(
              title: 'Compartición de Datos',
              content:
                  '• NO vendemos sus datos a terceros.\n'
                  '• NO compartimos información con fines publicitarios.\n'
                  '• Sus datos de ubicación SOLO se comparten con sus contactos de emergencia '
                  'cuando se activa una alerta.\n'
                  '• Podemos compartir datos si es requerido por ley o autoridad competente.',
            ),

            _buildPolicySection(
              title: 'Sus Derechos',
              content:
                  '• Acceder a sus datos personales almacenados.\n'
                  '• Rectificar información incorrecta.\n'
                  '• Solicitar la eliminación de su cuenta y datos asociados.\n'
                  '• Revocar permisos de ubicación y sensores en cualquier momento '
                  '(esto limitará la funcionalidad de la aplicación).',
            ),

            _buildPolicySection(
              title: 'Retención de Datos',
              content:
                  '• Los datos de alertas se conservan por 90 días.\n'
                  '• Los datos de cuenta se conservan mientras la cuenta esté activa.\n'
                  '• Al eliminar su cuenta, todos los datos se eliminan en un plazo de 30 días.',
            ),

            const SizedBox(height: 20),

            // Link to Terms
            NeumorphicButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF7FCCC4), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Ver Términos y Condiciones',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Center(
              child: Text(
                '© 2026 JEPO App. Todos los derechos reservados.',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
