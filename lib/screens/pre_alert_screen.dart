import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/pre_alert_service.dart';

class PreAlertScreen extends StatefulWidget {
  final PreAlertRequest request;

  const PreAlertScreen({super.key, required this.request});

  @override
  State<PreAlertScreen> createState() => _PreAlertScreenState();
}

class _PreAlertScreenState extends State<PreAlertScreen> with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.request.seconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _startTimer();
    _triggerHapticFeedback();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            HapticFeedback.mediumImpact();
          } else {
            _timer?.cancel();
            _resolve(false); // Alert will be sent
          }
        });
      }
    });
  }

  void _triggerHapticFeedback() {
    // Initial warning vibration
    HapticFeedback.vibrate();
  }

  void _resolve(bool isSafe) {
    _timer?.cancel();
    _pulseController.dispose();
    widget.request.resolveAsSafe(isSafe);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_pulseController.isAnimating) {
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _resolve(true);
        },
        child: Stack(
          children: [
            // Background Pulse
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withOpacity(0.4 + (_pulseController.value * 0.3)),
                        Colors.black,
                      ],
                      center: Alignment.center,
                      radius: 0.8 + (_pulseController.value * 0.4),
                    ),
                  ),
                );
              },
            ),

            // Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 120,
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 400.ms, duration: 1.seconds)
                  .shake(hz: 4, curve: Curves.easeInOut),
                  
                  const SizedBox(height: 40),
                  
                  const Text(
                    'PROTOCOLO DE EMERGENCIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    '¿ESTÁS BIEN?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 24),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      'Toca en cualquier lugar para cancelar la alerta a tus contactos.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 80),
                  
                  // Progress Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      
                      // Smooth Progress
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 1),
                          tween: Tween(begin: (_remainingSeconds + 1) / widget.request.seconds, end: _remainingSeconds / widget.request.seconds),
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 15,
                              color: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      
                      // Text
                      Column(
                        children: [
                          Text(
                            '$_remainingSeconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'SEG',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 80),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'PULSA PARA CANCELAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2.seconds)
                    .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 800.ms, curve: Curves.easeInOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
