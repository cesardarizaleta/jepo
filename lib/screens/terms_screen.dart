import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _lastUpdated = '11 de mayo de 2026';
  static const String _appName = 'JEPO';
  static const String _companyName = 'JEPO App';
  static const String _jurisdiction = 'República Bolivariana de Venezuela';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
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
            // Header
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
                          Icons.gavel_rounded,
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
                              'Términos y Condiciones de Uso',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Lea cuidadosamente antes de usar la aplicación',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7FCCC4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Última actualización: $_lastUpdated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7FCCC4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              number: '1',
              title: 'Aceptación de los Términos',
              content:
                  'Al descargar, instalar o utilizar la aplicación $_appName ("la Aplicación"), '
                  'usted acepta quedar vinculado por estos Términos y Condiciones de Uso ("Términos"). '
                  'Si no está de acuerdo con alguno de estos Términos, no utilice la Aplicación.\n\n'
                  'El uso continuado de la Aplicación después de cualquier modificación de estos Términos '
                  'constituye su aceptación de dichas modificaciones.',
            ),

            _buildSection(
              number: '2',
              title: 'Descripción del Servicio',
              content:
                  '$_appName es un sistema de asistencia proactiva diseñado para detectar situaciones '
                  'de riesgo potencial mediante sensores del dispositivo móvil (acelerómetro, giroscopio, '
                  'GPS) y notificar a contactos de emergencia previamente designados por el usuario.\n\n'
                  'LA APLICACIÓN NO SUSTITUYE A LOS SERVICIOS DE EMERGENCIA OFICIALES (911, bomberos, '
                  'policía, ambulancias). Es una herramienta complementaria de notificación.',
            ),

            _buildSection(
              number: '3',
              title: 'Requisitos de Uso',
              content:
                  '• Debe ser mayor de 18 años o contar con autorización de un representante legal.\n'
                  '• Debe proporcionar información veraz y actualizada al registrarse.\n'
                  '• Es responsable de mantener la confidencialidad de sus credenciales de acceso.\n'
                  '• Debe contar con un dispositivo compatible con conexión a internet activa.\n'
                  '• Debe otorgar los permisos necesarios (ubicación, notificaciones, sensores) para '
                  'el funcionamiento correcto del sistema.',
            ),

            _buildSection(
              number: '4',
              title: 'Limitación de Responsabilidad',
              content:
                  '$_companyName NO GARANTIZA:\n\n'
                  '• La disponibilidad ininterrumpida del servicio.\n'
                  '• La precisión absoluta en la detección de incidentes.\n'
                  '• La entrega exitosa de notificaciones a contactos de emergencia (depende de '
                  'factores externos como conectividad, disponibilidad del destinatario, operadores '
                  'de telecomunicaciones).\n'
                  '• Que la Aplicación prevenga, mitigue o resuelva situaciones de peligro real.\n\n'
                  'EN NINGÚN CASO $_companyName, SUS DESARROLLADORES, DIRECTORES, EMPLEADOS O '
                  'AFILIADOS SERÁN RESPONSABLES POR:\n\n'
                  '• Daños directos, indirectos, incidentales, especiales, consecuentes o punitivos.\n'
                  '• Lesiones personales, muerte o daños a la propiedad.\n'
                  '• Pérdida de datos, lucro cesante o interrupción de negocio.\n'
                  '• Fallos en la detección de incidentes o falsas alarmas.\n'
                  '• Acciones u omisiones de terceros (contactos de emergencia, servicios de '
                  'telecomunicaciones, proveedores de infraestructura).\n\n'
                  'El usuario reconoce y acepta que utiliza la Aplicación BAJO SU PROPIO RIESGO.',
            ),

            _buildSection(
              number: '5',
              title: 'Exoneración de Responsabilidad',
              content:
                  'El usuario libera y exonera expresamente a $_companyName de toda responsabilidad '
                  'civil, penal o administrativa derivada de:\n\n'
                  '• El uso o la imposibilidad de uso de la Aplicación.\n'
                  '• Fallos técnicos, interrupciones del servicio o errores del sistema.\n'
                  '• Decisiones tomadas con base en la información proporcionada por la Aplicación.\n'
                  '• La no activación o activación tardía de alertas.\n'
                  '• Interferencias de terceros en el funcionamiento del servicio.\n'
                  '• Eventos de fuerza mayor o caso fortuito.',
            ),

            _buildSection(
              number: '6',
              title: 'Privacidad y Datos Personales',
              content:
                  'La Aplicación recopila y procesa los siguientes datos:\n\n'
                  '• Datos de identificación: nombre, cédula, correo electrónico, teléfono.\n'
                  '• Datos de ubicación: coordenadas GPS en tiempo real.\n'
                  '• Datos de sensores: acelerómetro y giroscopio del dispositivo.\n'
                  '• Datos de contactos de emergencia: nombre y teléfono.\n\n'
                  'Estos datos se utilizan EXCLUSIVAMENTE para:\n'
                  '• Detectar posibles situaciones de riesgo.\n'
                  '• Notificar a contactos de emergencia designados.\n'
                  '• Mejorar los algoritmos de detección.\n\n'
                  'No vendemos, alquilamos ni compartimos sus datos personales con terceros '
                  'para fines comerciales o publicitarios.',
            ),

            _buildSection(
              number: '7',
              title: 'Uso Aceptable',
              content:
                  'El usuario se compromete a NO utilizar la Aplicación para:\n\n'
                  '• Generar alertas falsas o fraudulentas.\n'
                  '• Acosar, intimidar o perjudicar a terceros.\n'
                  '• Realizar ingeniería inversa, descompilar o modificar la Aplicación.\n'
                  '• Interferir con el funcionamiento del servicio o sus servidores.\n'
                  '• Suplantar la identidad de otra persona.\n'
                  '• Cualquier actividad ilegal o contraria a la moral y las buenas costumbres.\n\n'
                  'El incumplimiento de estas normas resultará en la suspensión o eliminación '
                  'inmediata de la cuenta sin previo aviso.',
            ),

            _buildSection(
              number: '8',
              title: 'Propiedad Intelectual',
              content:
                  'Todos los derechos de propiedad intelectual sobre la Aplicación, incluyendo '
                  'pero no limitado a: código fuente, diseño, logotipos, marcas, algoritmos y '
                  'documentación, son propiedad exclusiva de $_companyName.\n\n'
                  'Se otorga al usuario una licencia limitada, no exclusiva, intransferible y '
                  'revocable para usar la Aplicación conforme a estos Términos.',
            ),

            _buildSection(
              number: '9',
              title: 'Indemnización',
              content:
                  'El usuario acepta indemnizar, defender y mantener indemne a $_companyName, '
                  'sus desarrolladores, directores, empleados y afiliados, de cualquier '
                  'reclamación, demanda, daño, pérdida, responsabilidad, costo o gasto '
                  '(incluyendo honorarios de abogados) que surja de:\n\n'
                  '• Su uso de la Aplicación.\n'
                  '• Su violación de estos Términos.\n'
                  '• Su violación de derechos de terceros.\n'
                  '• Información inexacta proporcionada por el usuario.',
            ),

            _buildSection(
              number: '10',
              title: 'Modificaciones del Servicio',
              content:
                  '$_companyName se reserva el derecho de:\n\n'
                  '• Modificar, suspender o discontinuar la Aplicación en cualquier momento.\n'
                  '• Actualizar estos Términos sin previo aviso.\n'
                  '• Limitar o restringir el acceso a ciertas funcionalidades.\n'
                  '• Eliminar cuentas inactivas por más de 12 meses.',
            ),

            _buildSection(
              number: '11',
              title: 'Naturaleza Experimental',
              content:
                  'El usuario reconoce que $_appName es un proyecto de desarrollo académico/tecnológico '
                  'y que los algoritmos de detección de incidentes están en constante evolución. '
                  'La precisión del sistema puede variar según las condiciones del entorno, '
                  'el dispositivo utilizado y otros factores externos.\n\n'
                  'NO SE OFRECE GARANTÍA ALGUNA, EXPRESA O IMPLÍCITA, INCLUYENDO PERO NO '
                  'LIMITADO A GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN PROPÓSITO '
                  'PARTICULAR O NO INFRACCIÓN.',
            ),

            _buildSection(
              number: '12',
              title: 'Ley Aplicable y Jurisdicción',
              content:
                  'Estos Términos se rigen por las leyes de la $_jurisdiction. '
                  'Cualquier controversia derivada de estos Términos o del uso de la Aplicación '
                  'será sometida a la jurisdicción exclusiva de los tribunales competentes de '
                  'la $_jurisdiction.\n\n'
                  'Si alguna disposición de estos Términos se considera inválida o inaplicable, '
                  'las disposiciones restantes continuarán en pleno vigor y efecto.',
            ),

            _buildSection(
              number: '13',
              title: 'Contacto',
              content:
                  'Para consultas sobre estos Términos y Condiciones, puede contactarnos a '
                  'través de los canales oficiales disponibles en la Aplicación.\n\n'
                  'Al utilizar $_appName, usted confirma que ha leído, entendido y aceptado '
                  'estos Términos y Condiciones en su totalidad.',
            ),

            const SizedBox(height: 30),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 $_companyName. Todos los derechos reservados.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versión del documento: 1.0 — $_lastUpdated',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF7FCCC4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7FCCC4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textLight,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
