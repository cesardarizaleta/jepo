import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../services/alert_queue_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API not initialized. Try again.')),
        );
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
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      final auth = AuthService(appApi);
      final resp = await auth.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        password: password,
        tokenFcm: null,
      );
      if (resp['success'] == true) {
        await auth.me();
        await AlertQueueService(appApi).processQueue();
      }

      if (!mounted) {
        return;
      }

      if (resp['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final message = resp['message'] ?? 'Could not create user';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
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
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                NeumorphicTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Phone Field
                NeumorphicTextField(
                  controller: _phoneController,
                  hintText: 'Phone',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 20),

                // Email Field
                NeumorphicTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Field
                NeumorphicTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                NeumorphicTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
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
                          'SIGN UP',
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
