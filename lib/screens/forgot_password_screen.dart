import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/jepo_phone_input.dart';
import '../widgets/neumorphic_container.dart';

// ─── Palette ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFEEEEEE);
const Color _accent = Color(0xFF7FCCC4);
const Color _danger = Color(0xFFFF5151);
const Color _textPrimary = Color(0xFF747877);
const Color _shadowDark = Color(0xFFA3B1C6);
const Color _shadowLight = Colors.white;

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () {
            if (state.step == ForgotPasswordStep.confirmOtp) {
              ref
                  .read(forgotPasswordControllerProvider.notifier)
                  .goBackToRequest();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (state.step) {
                ForgotPasswordStep.requestOtp => const _RequestOtpCard(
                  key: ValueKey('request'),
                ),
                ForgotPasswordStep.confirmOtp => const _ConfirmOtpCard(
                  key: ValueKey('confirm'),
                ),
                ForgotPasswordStep.done => const _SuccessCard(
                  key: ValueKey('done'),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Step 1 — Request OTP  (method selector → contextual input)
// ═════════════════════════════════════════════════════════════════════════

class _RequestOtpCard extends ConsumerStatefulWidget {
  const _RequestOtpCard({super.key});

  @override
  ConsumerState<_RequestOtpCard> createState() => _RequestOtpCardState();
}

class _RequestOtpCardState extends ConsumerState<_RequestOtpCard> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _phoneIsValid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isEmail = state.method == 'email';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderIcon(Icons.lock_reset),
        const SizedBox(height: 24),
        const Text(
          'Recuperar contraseña',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige cómo quieres recibir tu código de verificación.',
          style: TextStyle(fontSize: 14, color: _textPrimary, height: 1.5),
        ),
        const SizedBox(height: 28),

        // ─── 1) Method selector (first) ──────────────────────────────
        _buildLabel('Enviar código vía'),
        Row(
          children: [
            Expanded(
              child: _MethodPill(
                label: 'Email',
                icon: Icons.email_outlined,
                selected: isEmail,
                onTap: () => ref
                    .read(forgotPasswordControllerProvider.notifier)
                    .setMethod('email'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MethodPill(
                label: 'WhatsApp',
                icon: Icons.chat_outlined,
                selected: !isEmail,
                onTap: () => ref
                    .read(forgotPasswordControllerProvider.notifier)
                    .setMethod('whatsapp'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ─── 2) Contextual input swaps based on method ───────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: isEmail
              ? Column(
                  key: const ValueKey('email_input'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Email'),
                    NeumorphicTextField(
                      controller: _emailController,
                      hintText: 'correo@ejemplo.com',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('phone_input'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JepoPhoneInput(
                      controller: _phoneController,
                      label: 'Teléfono',
                      onValidityChanged: (valid) {
                        if (_phoneIsValid != valid) {
                          setState(() => _phoneIsValid = valid);
                        }
                      },
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: state.isLoading ? () {} : _submit,
            color: _accent,
            child: state.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ENVIAR CÓDIGO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),

        if (state.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(state.error!),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Future<void> _submit() async {
    final state = ref.read(forgotPasswordControllerProvider);
    final isEmail = state.method == 'email';

    final String identifier;
    if (isEmail) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        AppToast.warning(context, 'Ingresa un email válido');
        return;
      }
      identifier = email;
    } else {
      if (!_phoneIsValid) {
        AppToast.warning(context, 'Completa el teléfono (7 dígitos)');
        return;
      }
      identifier = _phoneController.text.trim();
    }

    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestOtp(identifier);
    if (ok && mounted) {
      AppToast.success(context, 'Código enviado');
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Step 2 — Confirm OTP + New Password
// ═════════════════════════════════════════════════════════════════════════

class _ConfirmOtpCard extends ConsumerStatefulWidget {
  const _ConfirmOtpCard({super.key});

  @override
  ConsumerState<_ConfirmOtpCard> createState() => _ConfirmOtpCardState();
}

class _ConfirmOtpCardState extends ConsumerState<_ConfirmOtpCard> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderIcon(Icons.verified_user_outlined),
        const SizedBox(height: 24),
        const Text(
          'Verificar código',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enviamos un código de 6 dígitos a ${state.emailOrPhone}. '
          'Introdúcelo junto con tu nueva contraseña.',
          style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        _buildLabel('Código OTP'),
        NeumorphicTextField(
          controller: _otpController,
          hintText: '••••••',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 18),

        _buildLabel('Nueva contraseña'),
        NeumorphicTextField(
          controller: _newPasswordController,
          hintText: 'Mínimo 8 caracteres',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 18),

        _buildLabel('Confirmar nueva contraseña'),
        NeumorphicTextField(
          controller: _confirmPasswordController,
          hintText: 'Repite la contraseña',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: state.isLoading ? () {} : _submit,
            color: _accent,
            child: state.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'RESTABLECER CONTRASEÑA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: state.isLoading
                ? null
                : () => ref
                      .read(forgotPasswordControllerProvider.notifier)
                      .goBackToRequest(),
            child: const Text(
              'Volver y reenviar código',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        if (state.error != null) ...[
          const SizedBox(height: 10),
          _buildErrorBox(state.error!),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Future<void> _submit() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppToast.warning(context, 'Las contraseñas no coinciden');
      return;
    }

    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .confirmReset(
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text,
        );
    if (ok && mounted) {
      AppToast.success(context, 'Contraseña actualizada');
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Step 3 — Success
// ═════════════════════════════════════════════════════════════════════════

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeaderIcon(Icons.check_circle_outline, color: _accent),
        const SizedBox(height: 24),
        const Text(
          '¡Todo listo!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu contraseña se actualizó correctamente. Ya puedes iniciar sesión con tus nuevas credenciales.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _textPrimary, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            color: _accent,
            child: const Text(
              'IR A INICIAR SESIÓN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  Shared building blocks
// ═════════════════════════════════════════════════════════════════════════

Widget _buildHeaderIcon(IconData icon, {Color color = _accent}) {
  return Center(
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: _shadowDark, offset: Offset(6, 6), blurRadius: 12),
          BoxShadow(
            color: _shadowLight,
            offset: Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(icon, size: 36, color: color),
    ),
  );
}

Widget _buildLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
  );
}

Widget _buildErrorBox(String message) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: _danger, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: _danger, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _MethodPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _shadowDark.withValues(alpha: 0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: _shadowLight.withValues(alpha: 0.9),
                    offset: const Offset(-2, -2),
                    blurRadius: 5,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: _shadowDark,
                    offset: Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: _shadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _accent : _textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? _accent : _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
