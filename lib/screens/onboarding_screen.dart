import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Bienvenido a JEPO',
      description: 'Tu sistema de asistencia proactiva. Estamos aquí para cuidarte en cada trayecto.',
      icon: Icons.security_outlined,
      color: AppTheme.primary,
    ),
    OnboardingData(
      title: 'Permisos Críticos',
      description: 'Necesitamos acceso a tu ubicación y sensores para detectar impactos automáticamente.',
      icon: Icons.location_on_outlined,
      color: Colors.blue,
      isPermissionPage: true,
    ),
    OnboardingData(
      title: 'Protección Total',
      description: 'Activa "Mostrar sobre otras apps" para que podamos ayudarte incluso si tu móvil está bloqueado.',
      icon: Icons.layers_outlined,
      color: Colors.orange,
      isOverlayPage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          
          // Bottom controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
                
                // Button
                NeumorphicButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'EMPEZAR' : 'SIGUIENTE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data.icon,
            size: 120,
            color: data.color,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          
          const SizedBox(height: 40),
          
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 20),
          
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          
          if (data.isPermissionPage || data.isOverlayPage) ...[
            const SizedBox(height: 40),
            _buildPermissionStatus(data.isOverlayPage),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionStatus(bool isOverlay) {
    return FutureBuilder<PermissionStatus>(
      future: isOverlay ? Permission.systemAlertWindow.status : Permission.location.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? PermissionStatus.denied;
        final isGranted = status.isGranted;

        return NeumorphicButton(
          onPressed: () async {
            if (isOverlay) {
              await Permission.systemAlertWindow.request();
            } else {
              await [
                Permission.location,
                Permission.notification,
                Permission.sensors,
                Permission.phone,
              ].request();
            }
            setState(() {}); // Refresh status
          },
          color: isGranted ? Colors.green.shade50 : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.error_outline,
                color: isGranted ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                isGranted ? 'PERMISO CONCEDIDO' : 'CONFIGURAR AHORA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isGranted ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : AppTheme.textLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onFinished();
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPermissionPage;
  final bool isOverlayPage;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isPermissionPage = false,
    this.isOverlayPage = false,
  });
}
