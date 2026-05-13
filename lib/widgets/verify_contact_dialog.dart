import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/contacts_provider.dart';
import '../services/api_client.dart';
import '../utils/app_toast.dart';
import 'neumorphic_container.dart';

// ─── Palette ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFEEEEEE);
const Color _accent = Color(0xFF7FCCC4);
const Color _danger = Color(0xFFFF5151);
const Color _warning = Color(0xFFFFB74D);
const Color _textPrimary = Color(0xFF747877);
const Color _shadowDark = Color(0xFFA3B1C6);
const Color _shadowLight = Colors.white;

/// Show the neumorphic verification dialog for a PENDING contact.
///
/// Returns `true` if the contact was successfully verified, `false` if the
/// user cancelled or verification failed.
Future<bool> showVerifyContactDialog({
  required BuildContext context,
  required int contactId,
  required String contactName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) =>
        _VerifyContactDialog(contactId: contactId, contactName: contactName),
  );
  return result ?? false;
}

class _VerifyContactDialog extends ConsumerStatefulWidget {
  final int contactId;
  final String contactName;

  const _VerifyContactDialog({
    required this.contactId,
    required this.contactName,
  });

  @override
  ConsumerState<_VerifyContactDialog> createState() =>
      _VerifyContactDialogState();
}

class _VerifyContactDialogState extends ConsumerState<_VerifyContactDialog> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppToast.warning(context, 'El código debe tener 6 dígitos');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref.read(contactsMutationsProvider).verify(widget.contactId, otp);
      if (!mounted) return;
      AppToast.success(context, 'Contacto verificado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = _formatError(e, fallback: 'Código incorrecto');
      AppToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_isResending || _cooldownSeconds > 0) return;

    setState(() => _isResending = true);
    try {
      await ref.read(contactsMutationsProvider).resend(widget.contactId);
      if (!mounted) return;
      AppToast.success(context, 'Código reenviado');
      _startCooldown(60); // Backend cooldown: 60s
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _formatError(e, fallback: 'No se pudo reenviar'));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _formatError(Object e, {required String fallback}) {
    if (e is ApiException) {
      return e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24 + viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: _shadowDark,
              offset: Offset(8, 8),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: _shadowLight,
              offset: Offset(-8, -8),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _warning.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFFB97A10),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verificar contacto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.contactName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Pídele a tu contacto el código de 6 dígitos que recibió por '
              'WhatsApp y escríbelo aquí.',
              style: TextStyle(fontSize: 13, color: _textPrimary, height: 1.5),
            ),
            const SizedBox(height: 20),

            // ─── OTP input ────────────────────────────────────────────
            NeumorphicTextField(
              controller: _otpController,
              hintText: '••••••',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 22),

            // ─── Confirm + Resend ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: NeumorphicButton(
                    onPressed: _isVerifying ? () {} : _handleVerify,
                    color: _accent,
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CONFIRMAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: NeumorphicButton(
                    onPressed: (_isResending || _cooldownSeconds > 0)
                        ? () {}
                        : _handleResend,
                    child: _isResending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: _accent,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _cooldownSeconds > 0
                                ? '${_cooldownSeconds}s'
                                : 'REENVIAR',
                            style: TextStyle(
                              color: _cooldownSeconds > 0
                                  ? _textPrimary.withValues(alpha: 0.6)
                                  : _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
