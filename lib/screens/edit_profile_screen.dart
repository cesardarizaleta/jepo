import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../utils/app_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtl = TextEditingController();
  final _apellidoCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _telefonoCtl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final svc = AuthService(appApi);
      final user = await svc.getCurrentUser();
      if (user != null) {
        _nombreCtl.text = user.nombre ?? '';
        _apellidoCtl.text = user.apellido ?? '';
        _emailCtl.text = user.email ?? '';
        _telefonoCtl.text = user.telefono ?? '';
      }
    } catch (e) {
      debugPrint('EditProfile load failed: $e');
    }
  }

  @override
  void dispose() {
    _nombreCtl.dispose();
    _apellidoCtl.dispose();
    _emailCtl.dispose();
    _telefonoCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updates = UpdateUserDto(
      nombre: _nombreCtl.text.trim(),
      apellido: _apellidoCtl.text.trim(),
      telefono: _telefonoCtl.text.trim(),
    );

    try {
      final svc = AuthService(appApi);
      await svc.updateProfile(updates);
      if (!mounted) return;
      AppToast.success(context, 'Perfil actualizado');
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (!mounted) return;

      String errorMsg = 'Error al actualizar el perfil';
      if (e is ApiException) {
        if (e.errors.isNotEmpty) {
          errorMsg = e.errors.join('\n');
        } else {
          errorMsg = e.message;
        }
      }

      AppToast.error(context, errorMsg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              NeumorphicContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nombreCtl,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _apellidoCtl,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailCtl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _telefonoCtl,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: _saving ? () {} : _save,
                  color: AppTheme.primary,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
        ),
        NeumorphicTextField(
          controller: controller,
          hintText: label,
          icon: icon,
          keyboardType: keyboardType,
          enabled: enabled,
        ),
      ],
    );
  }
}
