import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    // Mock login logic
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

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
                const SizedBox(height: 40),

                // Login Button
                NeumorphicButton(
                  onPressed: _login,
                  color: AppTheme.primary,
                  child: const Text(
                    'LOGIN',
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
                      "Don't have an account? ",
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
                        'Sign Up',
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
