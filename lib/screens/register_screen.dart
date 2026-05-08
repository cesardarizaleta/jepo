import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/jepo_phone_input.dart';
import '../services/alert_queue_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/app_toast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_isLoading) return;

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
      final fullName = _nameController.text.trim();
      final parts = fullName.split(' ');
      final nombre = parts.isNotEmpty ? parts.first : fullName;
      final apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final email = _emailController.text.trim();
      final telefono = _phoneController.text.trim();
      final cedula = _cedulaController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (cedula.isEmpty) {
        throw Exception('La cédula es requerida');
      }

      if (password != confirmPassword) {
        throw Exception('Las contraseñas no coinciden');
      }

      if (password.length < 8) {
        throw Exception('La contraseña debe tener al menos 8 caracteres');
      }

      final auth = AuthService(appApi);
      final resp = await auth.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        cedula: cedula,
        password: password,
        tokenFcm: null,
      );
      if (resp.success) {
        await auth.me();
        await AlertQueueService(appApi).processQueue();
      }

      if (!mounted) {
        return;
      }

      if (resp.success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // Display backend validation errors if available.
        final message = resp.errors.isNotEmpty
            ? resp.errors.join('\n')
            : resp.message;
        AppToast.error(context, message);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      String errorMsg = 'Error al registrarse';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                NeumorphicContainer(
                  borderRadius: 100,
                  padding: const EdgeInsets.all(15),
                  child: Image.asset(
                    'assets/jepo.png',
                    height: 80,
                    width: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_add,
                        size: 50,
                        color: AppTheme.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Crear Cuenta',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                NeumorphicTextField(
                  controller: _nameController,
                  hintText: 'Nombre Completo',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Cedula Field
                NeumorphicTextField(
                  controller: _cedulaController,
                  hintText: 'Cédula',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                JepoPhoneInput(
                  controller: _phoneController,
                  label: 'Numero de telefono',
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 20),

                // Confirm Password Field
                NeumorphicTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar Contraseña',
                  obscureText: true,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 40),

                // Register Button
                NeumorphicButton(
                  onPressed: _register,
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
                          'REGISTRARSE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
