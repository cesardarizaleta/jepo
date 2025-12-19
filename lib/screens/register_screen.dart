import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _register() {
    // Mock register logic
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
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
                  child: const Text(
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
