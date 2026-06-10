import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Tutorial de Jepo',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Guía de Uso',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const _TutorialSection(
              title: 'Qué es Jepo',
              icon: Icons.lightbulb_outline,
              child: Text(
                'Jepo es un sistema inteligente de asistencia proactiva y seguridad personal diseñado para protegerte a ti y a tus seres queridos. A través de sensores en segundo plano y botones de acceso rápido, Jepo detecta anomalías y te permite reportar emergencias de manera inmediata y automatizada.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
              ),
            ),
            const _TutorialSection(
              title: 'Alerta Proactiva Automática',
              icon: Icons.notifications_active_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Este modo monitorea constantemente los sensores de tu dispositivo en segundo plano para detectar caídas críticas o accidentes de forma automática.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Intervalo de Pre-Alerta (5 segundos):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Al detectarse una anomalía, se inicia una cuenta regresiva de 5 segundos:\n'
                    '• Segundos 1 al 3: Se graba audio de contexto de forma silenciosa (el teléfono solo vibra) para registrar el ambiente sin alertar a posibles atacantes.\n'
                    '• Segundos 4 y 5: Se activa una alarma sonora fuerte de advertencia.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Envío de Alerta:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Si no desactivas la cuenta regresiva antes de que termine, la alerta se clasifica como REAL y se envía tu ubicación junto con el audio grabado a tus contactos de emergencia vía WhatsApp.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
            const _TutorialSection(
              title: 'Asistencia Manual (SOS)',
              icon: Icons.sos_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Si te encuentras en una situación de riesgo inmediato, puedes tocar el botón de "Asistencia" en la pantalla principal para disparar una alerta de forma manual.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Límites e Intervalos de Cooldown:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Se permite un máximo de 3 presiones consecutivas del botón de asistencia en un intervalo de 1 minuto.\n'
                    '• Si se sobrepasa este límite, el botón se bloquea temporalmente (cooldown) durante 1 minuto para evitar falsas alertas accidentales o de tipo spam.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
            const _TutorialSection(
              title: 'Modo Protegido (A Salvo)',
              icon: Icons.health_and_safety_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Este botón se encuentra en la pantalla de inicio (con el icono de cruz de salud) y te permite notificar rápidamente a tu familia que te encuentras a salvo.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Utilidad y Funcionamiento:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Si se disparó una alerta por error o accidente, puedes tocar este botón en lugar de enviar mensajes de texto individuales a cada familiar.\n'
                    '• El sistema envía de manera inmediata un mensaje a todos tus contactos de emergencia verificados indicando que te encuentras bien y en excelentes condiciones.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
            const _TutorialSection(
              title: 'Llamada de Emergencia',
              icon: Icons.local_phone_outlined,
              child: Text(
                'El botón de "Emergencia" (de color rojo con el texto SOS) inicia una llamada directa con el número nacional de emergencias (911) de forma instantánea.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
              ),
            ),
            const _TutorialSection(
              title: 'Familia y Monitoreo',
              icon: Icons.people_alt_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El apartado de "Familia" te permite gestionar a tus contactos de confianza para mantenerlos informados.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gestión y Métricas:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Puedes registrar hasta 5 contactos. Recibirán un código OTP de WhatsApp para verificar su número.\n'
                    '• Si tus contactos también instalan Jepo, podrás revisar su historial de alertas y tasa de precisión desde el apartado de Historial y Métricas.\n'
                    '• Si tienes el permiso verificado, podrás ver su posición geográfica en tiempo real a través de la pantalla del "Mapa".',
                    style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
            const _TutorialSection(
              title: 'Sensores y Segundo Plano',
              icon: Icons.sensors_outlined,
              child: Text(
                'Para garantizar tu protección, Jepo monitorea el acelerómetro y giroscopio de tu teléfono en segundo plano. Esto permite que el detector de colisiones funcione de forma ininterrumpida incluso con la pantalla apagada o con otras aplicaciones abiertas.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TutorialSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _TutorialSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  State<_TutorialSection> createState() => _TutorialSectionState();
}

class _TutorialSectionState extends State<_TutorialSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicContainer(
        useAnimation: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(widget.icon, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textLight,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: widget.child,
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
