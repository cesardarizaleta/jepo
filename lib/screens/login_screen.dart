import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../services/api_client.dart';
import '../services/alert_queue_service.dart';
import '../services/auth_service.dart';
import '../utils/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() {
    if (_isLoading) return;
    _performLogin();
  }

  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Ensure API client is ready before attempting network calls
    final ready = await _ensureApiReady();
    if (!ready) {
      if (mounted) {
        AppToast.error(context, 'API no inicializada. Inténtalo de nuevo.');
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final auth = AuthService(appApi);
      await auth.login(email: email, password: password);
      await auth.me();
      await AlertQueueService(appApi).processQueue();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String errorMsg = 'Error al iniciar sesión';
      if (e is ApiException) {
        if (e.errors.isNotEmpty) {
          errorMsg = e.errors.join('\n');
        } else {
          errorMsg = e.message;
        }
      } else {
        errorMsg = e.toString();
      }

      AppToast.error(context, errorMsg);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensureApiReady() async {
    if (appApiInitialized) return true;
    int attempts = 0;
    while (!appApiInitialized && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (appApiInitialized) return true;

    try {
      await initApi();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Area
                NeumorphicContainer(
                  borderRadius: 100, // Circular
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/jepo.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.security,
                        size: 60,
                        color: AppTheme.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                // Email Field
                NeumorphicTextField(
                  controller: _emailController,
                  hintText: 'Correo electrónico',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Field
                NeumorphicTextField(
                  controller: _passwordController,
                  hintText: 'Contraseña',
                  obscureText: true,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 40),

                // Login Button
                NeumorphicButton(
                  onPressed: _login,
                  color: AppTheme.primary,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),

                const SizedBox(height: 30),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(color: AppTheme.textLight),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
