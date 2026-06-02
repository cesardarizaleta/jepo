import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alert_manager.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

const Color _surface = Color(0xFFEEEEEE);
const Color _accent = Color(0xFF7FCCC4);
const Color _danger = Color(0xFFFF5151);
const Color _textPrimary = Color(0xFF747877);

class AlertDetailScreen extends ConsumerStatefulWidget {
  final int? alertId;
  final int countdownSeconds;

  const AlertDetailScreen({
    super.key,
    this.alertId,
    this.countdownSeconds = 15,
  });

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    ref
        .read(alertManagerProvider.notifier)
        .setTriggered(alertId: widget.alertId);
    ref.read(alertManagerProvider.notifier).ensureAlertId();

    ref.listen<AlertState>(alertManagerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        AppToast.error(context, next.error!);
      }

      if (prev?.status != AlertStatus.resolved &&
          next.status == AlertStatus.resolved) {
        AppToast.success(context, 'Alerta cancelada');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertManagerProvider);
    final isExpired = _remainingSeconds <= 0;
    final isResolved = state.status == AlertStatus.resolved;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Alerta Activa',
          style: TextStyle(color: _textPrimary),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Se detecto una posible caida.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si estas bien, cancela la alerta antes de que se complete el conteo.',
              style: TextStyle(
                fontSize: 14,
                color: _textPrimary.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: _danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired ? 'Tiempo agotado' : 'Tiempo restante',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isExpired
                              ? '0 segundos'
                              : '$_remainingSeconds segundos',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isExpired || state.isLoading || isResolved)
                    ? null
                    : _resolveAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ESTOY BIEN / CANCELAR ALERTA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveAlert() async {
    await ref.read(alertManagerProvider.notifier).resolveActiveAlert();
  }
}
