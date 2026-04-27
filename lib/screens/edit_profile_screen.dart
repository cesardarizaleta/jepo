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
              NeumorphicContainer(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreCtl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apellidoCtl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoCtl,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
