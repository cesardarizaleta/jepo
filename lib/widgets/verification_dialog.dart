import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/emergency_contacts_service.dart';
import '../utils/app_toast.dart';
import 'neumorphic_container.dart';

// ─── Palette ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFEEEEEE);
const Color _accent = Color(0xFF7FCCC4);
const Color _warning = Color(0xFFFFB74D);
const Color _warningDark = Color(0xFFB97A10);
const Color _textPrimary = Color(0xFF747877);

/// Shows the neumorphic verification dialog for a contact that is still
/// in PENDING state.
///
/// Returns `true` if the contact was successfully verified, `false`
/// otherwise (user cancelled, error, or closed by tapping outside).
Future<bool> showVerificationDialog({
  required BuildContext context,
  required int contactId,
  required String contactName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => VerificationDialogWidget(
      contactId: contactId,
      contactName: contactName,
    ),
  );
  return result ?? false;
}

/// Neumorphic modal to submit the 6-digit OTP that the contact received
/// via WhatsApp, with a built-in 60-second resend cooldown.
class VerificationDialogWidget extends StatefulWidget {
  final int contactId;
  final String contactName;

  const VerificationDialogWidget({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<VerificationDialogWidget> createState() =>
      _VerificationDialogWidgetState();
}

class _VerificationDialogWidgetState extends State<VerificationDialogWidget> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  /// Remaining seconds of the resend cooldown.  Matches the backend's 60s
  /// cooldown between resend-code requests.
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  EmergencyContactsService get _service => EmergencyContactsService(appApi);

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        t.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _handleConfirm() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppToast.warning(context, 'El código debe tener 6 dígitos');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await _service.verifyContact(widget.contactId, otp);
      if (!mounted) return;
      AppToast.success(context, 'Contacto verificado');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      // A 401 here means "invalid OTP", NOT "session expired". Show the
      // error message without triggering the global unauthorized handler.
      final msg = _formatError(e, fallback: 'Código incorrecto o expirado');
      AppToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_isResending || _cooldownSeconds > 0) return;

    setState(() => _isResending = true);
    try {
      await _service.resendContactCode(widget.contactId);
      if (!mounted) return;
      AppToast.success(context, 'Código reenviado por WhatsApp');
      _startCooldown();
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
    final insets = MediaQuery.of(context).viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24 + insets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 10),
              blurRadius: 24,
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
                _WarnIconBadge(),
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
            const SizedBox(height: 18),
            Text(
              'Tu contacto recibió un código de 6 dígitos por WhatsApp. '
              'Pídeselo y escríbelo aquí para activarlo.',
              style: TextStyle(
                fontSize: 13,
                color: _textPrimary.withValues(alpha: 0.85),
                height: 1.5,
              ),
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
            const SizedBox(height: 20),

            // ─── Confirm (primary) ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                onPressed: _isVerifying ? () {} : _handleConfirm,
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
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Resend (secondary, with countdown) ───────────────────
            SizedBox(
              width: double.infinity,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: _cooldownSeconds > 0
                                ? _textPrimary.withValues(alpha: 0.5)
                                : _accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _cooldownSeconds > 0
                                ? 'Reenviar en ${_cooldownSeconds}s'
                                : 'REENVIAR CÓDIGO',
                            style: TextStyle(
                              color: _cooldownSeconds > 0
                                  ? _textPrimary.withValues(alpha: 0.5)
                                  : _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // ─── Close ────────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Verificar más tarde',
                  style: TextStyle(
                    color: _textPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

/// Small circular warning icon that matches the neomorphic style.
class _WarnIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: _warning.withValues(alpha: 0.55), width: 1),
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        color: _warningDark,
        size: 26,
      ),
    );
  }
}
