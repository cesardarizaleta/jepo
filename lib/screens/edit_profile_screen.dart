import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/neumorphic_container.dart';

// ─── Palette ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFEEEEEE);
const Color _teal = Color(0xFF26A69A);
const Color _textPrimary = Color(0xFF747877);
const Color _textLight = Color(0xFF90A4AE);
const Color _shadowDark = Color(0xFFA3B1C6);
const Color _shadowLight = Colors.white;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nombreCtl = TextEditingController();
  final _apellidoCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _telefonoCtl = TextEditingController();

  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final svc = AuthService(appApi);
      final user = await svc.getCurrentUser();
      if (user != null && mounted) {
        _nombreCtl.text = user.nombre ?? '';
        _apellidoCtl.text = user.apellido ?? '';
        _emailCtl.text = user.email ?? '';
        // Convert E.164 to local display format
        _telefonoCtl.text = _toLocalDisplay(user.telefono ?? '');
        setState(() => _loaded = true);
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
    if (_saving) return;

    final nombre = _nombreCtl.text.trim();
    final apellido = _apellidoCtl.text.trim();
    final telefono = _telefonoCtl.text.trim();

    if (nombre.isEmpty || apellido.isEmpty) {
      AppToast.warning(context, 'Nombre y apellido son requeridos');
      return;
    }

    setState(() => _saving = true);

    try {
      final svc = AuthService(appApi);
      await svc.updateProfile(
        UpdateUserDto(
          nombre: nombre,
          apellido: apellido,
          telefono: telefono.isNotEmpty ? telefono : null,
        ),
      );
      if (!mounted) return;
      AppToast.success(context, 'Perfil actualizado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Error al actualizar el perfil';
      if (e is ApiException) {
        msg = e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
      }
      AppToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Section: Personal Info ─────────────────────────
                  _SectionHeader(
                    icon: Icons.person_outline,
                    title: 'Información Personal',
                  ),
                  const SizedBox(height: 20),

                  _NeuInput(
                    controller: _nombreCtl,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                    hint: 'Tu nombre',
                  ),
                  const SizedBox(height: 22),

                  _NeuInput(
                    controller: _apellidoCtl,
                    label: 'Apellido',
                    icon: Icons.person_outline,
                    hint: 'Tu apellido',
                  ),
                  const SizedBox(height: 22),

                  _NeuInput(
                    controller: _emailCtl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    hint: 'correo@ejemplo.com',
                    enabled: false,
                  ),
                  const SizedBox(height: 22),

                  _NeuInput(
                    controller: _telefonoCtl,
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                    hint: '04121234567',
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 36),

                  // ─── Save Button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: NeumorphicButton(
                      onPressed: _saving ? () {} : _save,
                      color: _teal,
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
                                fontSize: 15,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── Section: Security ──────────────────────────────
                  _SectionHeader(
                    icon: Icons.shield_outlined,
                    title: 'Seguridad',
                  ),
                  const SizedBox(height: 20),

                  _ChangePasswordPill(onTap: () => _showChangePasswordDialog()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ChangePasswordDialog(
        userPhone: _telefonoCtl.text.trim(),
        userEmail: _emailCtl.text.trim(),
      ),
    );
  }

  String _toLocalDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('58')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 11 && digits.startsWith('0')) return digits;
    if (digits.length == 10) return '0$digits';
    return digits;
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Reusable Neumorphic Input (normalized, consistent)
// ═════════════════════════════════════════════════════════════════════════

class _NeuInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _NeuInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _shadowDark.withValues(alpha: 0.25),
                offset: const Offset(3, 3),
                blurRadius: 6,
              ),
              const BoxShadow(
                color: _shadowLight,
                offset: Offset(-3, -3),
                blurRadius: 6,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: enabled ? AppTheme.textDark : _textLight,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(color: _textLight.withValues(alpha: 0.7)),
              prefixIcon: Icon(icon, color: _teal, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Section Header
// ═════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _teal, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Change Password Pill Button
// ═════════════════════════════════════════════════════════════════════════

class _ChangePasswordPill extends StatefulWidget {
  final VoidCallback onTap;
  const _ChangePasswordPill({required this.onTap});

  @override
  State<_ChangePasswordPill> createState() => _ChangePasswordPillState();
}

class _ChangePasswordPillState extends State<_ChangePasswordPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: _shadowLight.withValues(alpha: 0.9),
                    offset: const Offset(-1, -1),
                    blurRadius: 3,
                  ),
                ]
              : [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  const BoxShadow(
                    color: _shadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline, color: _teal, size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verificación por WhatsApp',
                    style: TextStyle(fontSize: 11, color: _textLight),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _textLight.withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Change Password Dialog (OTP via WhatsApp)
// ═════════════════════════════════════════════════════════════════════════

enum _PasswordStep { request, confirm, done }

class _ChangePasswordDialog extends StatefulWidget {
  final String userPhone;
  final String userEmail;

  const _ChangePasswordDialog({
    required this.userPhone,
    required this.userEmail,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  _PasswordStep _step = _PasswordStep.request;
  bool _isLoading = false;

  final _otpCtl = TextEditingController();
  final _newPassCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();

  @override
  void dispose() {
    _otpCtl.dispose();
    _newPassCtl.dispose();
    _confirmPassCtl.dispose();
    super.dispose();
  }

  /// Step 1: Request OTP via WhatsApp to the user's phone.
  Future<void> _requestCode() async {
    setState(() => _isLoading = true);
    try {
      final identifier = widget.userPhone.isNotEmpty
          ? widget.userPhone
          : widget.userEmail;
      final method = widget.userPhone.isNotEmpty ? 'whatsapp' : 'email';

      await AuthService(
        appApi,
      ).forgotPassword(emailOrPhone: identifier, method: method);
      if (!mounted) return;
      setState(() {
        _step = _PasswordStep.confirm;
        _isLoading = false;
      });
      AppToast.success(context, 'Código enviado por WhatsApp');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, _formatErr(e));
    }
  }

  /// Step 2: Submit OTP + new password.
  Future<void> _confirmChange() async {
    final otp = _otpCtl.text.trim();
    final newPass = _newPassCtl.text;
    final confirmPass = _confirmPassCtl.text;

    if (otp.length != 6) {
      AppToast.warning(context, 'El código debe tener 6 dígitos');
      return;
    }
    if (newPass.length < 8) {
      AppToast.warning(context, 'Mínimo 8 caracteres');
      return;
    }
    if (newPass != confirmPass) {
      AppToast.warning(context, 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final identifier = widget.userPhone.isNotEmpty
          ? widget.userPhone
          : widget.userEmail;

      await AuthService(
        appApi,
      ).resetPassword(emailOrPhone: identifier, otp: otp, newPassword: newPass);
      if (!mounted) return;
      setState(() {
        _step = _PasswordStep.done;
        _isLoading = false;
      });
      AppToast.success(context, 'Contraseña actualizada');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.error(context, _formatErr(e));
    }
  }

  String _formatErr(Object e) {
    if (e is ApiException) {
      return e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
    }
    return 'Error inesperado';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 8),
              blurRadius: 20,
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: switch (_step) {
            _PasswordStep.request => _buildRequestStep(),
            _PasswordStep.confirm => _buildConfirmStep(),
            _PasswordStep.done => _buildDoneStep(),
          },
        ),
      ),
    );
  }

  Widget _buildRequestStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dialogIcon(Icons.lock_reset),
        const SizedBox(height: 18),
        const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Te enviaremos un código de verificación por WhatsApp al número '
          '${_maskPhone(widget.userPhone)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: _isLoading ? () {} : _requestCode,
            color: _teal,
            child: _isLoading
                ? const _SmallSpinner()
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'SOLICITAR CÓDIGO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        _cancelButton(),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _dialogIcon(Icons.verified_user_outlined)),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Ingresa el código',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _NeuInput(
          controller: _otpCtl,
          label: 'Código OTP',
          icon: Icons.pin_outlined,
          hint: '••••••',
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 18),
        _NeuInput(
          controller: _newPassCtl,
          label: 'Nueva contraseña',
          icon: Icons.lock_outline,
          hint: 'Mínimo 8 caracteres',
        ),
        const SizedBox(height: 18),
        _NeuInput(
          controller: _confirmPassCtl,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outline,
          hint: 'Repite la contraseña',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: _isLoading ? () {} : _confirmChange,
            color: _teal,
            child: _isLoading
                ? const _SmallSpinner()
                : const Text(
                    'CONFIRMAR CAMBIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        _cancelButton(),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dialogIcon(Icons.check_circle_outline, color: _teal),
        const SizedBox(height: 18),
        const Text(
          '¡Contraseña actualizada!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tu contraseña se cambió correctamente. La próxima vez que inicies sesión, usa la nueva.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _textPrimary, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => Navigator.of(context).pop(),
            color: _teal,
            child: const Text(
              'CERRAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogIcon(IconData icon, {Color color = _teal}) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _shadowDark.withValues(alpha: 0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          const BoxShadow(
            color: _shadowLight,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, size: 30, color: color),
    );
  }

  Widget _cancelButton() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: _textPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return phone;
    return '${digits.substring(0, 4)}***${digits.substring(digits.length - 3)}';
  }
}

// ─── Small spinner for buttons ───────────────────────────────────────────

class _SmallSpinner extends StatelessWidget {
  const _SmallSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}
