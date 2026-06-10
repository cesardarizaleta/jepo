import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
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
  bool _resolved = false;
  AudioPlayer? _audioPlayer;
  final Record _recorder = Record();
  String? _audioPath;
  String? _audioBase64;

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
    // In Option A, we do not play the alert sound immediately to record clean audio
    _notifyUIActive();
    _startAudioRecording();
    debugPrint('PreAlertScreen: SHOWN with ${widget.request.seconds}s countdown');
  }

  Future<void> _playAlertSound() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('alertSound.mp3'));
      debugPrint('PreAlertScreen: Alert sound playing in loop');
    } catch (e) {
      debugPrint('PreAlertScreen: Error playing alert sound: $e');
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        debugPrint('PreAlertScreen: No recording permission');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/alert_audio_${DateTime.now().millisecondsSinceEpoch}.ogg';
      
      await _recorder.start(
        path: _audioPath,
        encoder: AudioEncoder.opus,
        bitRate: 24000,
        samplingRate: 16000,
      );
      debugPrint('PreAlertScreen: Audio recording started');
    } catch (e) {
      debugPrint('PreAlertScreen: Error starting audio recording: $e');
    }
  }

  Future<void> _stopAndEncodeAudio() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
        debugPrint('PreAlertScreen: Audio recording stopped');
        
        if (_audioPath != null) {
          final file = File(_audioPath!);
          final bytes = await file.readAsBytes();
          _audioBase64 = 'data:audio/ogg;base64,${base64Encode(bytes)}';
          debugPrint('PreAlertScreen: Audio encoded to base64 (${_audioBase64!.length} chars)');
          
          // Clean up temp file
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('PreAlertScreen: Error stopping/encoding audio: $e');
    }
  }

  void _notifyUIActive() {
    try {
      FlutterBackgroundService().invoke('pre_alert_ui_mounted');
      debugPrint('PreAlertScreen: Notified background service that UI is mounted');
    } catch (e) {
      debugPrint('PreAlertScreen: Failed to invoke pre_alert_ui_mounted IPC: $e');
    }
  }

  void _stopAlertSound() {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = null;
      debugPrint('PreAlertScreen: Alert sound stopped');
    } catch (e) {
      debugPrint('PreAlertScreen: Error stopping alert sound: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            HapticFeedback.mediumImpact();
            
            // Option A: With 2 seconds remaining, stop recording and play the alarm sound
            if (_remainingSeconds == 2) {
              _stopAndEncodeAudio();
              _playAlertSound();
            }
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

  void _resolve(bool isSafe) async {
    if (_resolved) return; // Prevent double resolution
    _resolved = true;
    _stopAlertSound();
    await _stopAndEncodeAudio();
    debugPrint('PreAlertScreen: resolved isSafe=$isSafe');
    _timer?.cancel();
    
    // Pass audio base64 to background service if not safe
    if (!isSafe && _audioBase64 != null) {
      try {
        FlutterBackgroundService().invoke('pre_alert_response', {
          'isSafe': isSafe,
          'audio_base64': _audioBase64,
        });
        debugPrint('PreAlertScreen: Sent audio to background service');
      } catch (e) {
        debugPrint('PreAlertScreen: Failed to send audio to background service: $e');
      }
    } else {
      widget.request.resolveAsSafe(isSafe);
    }
    
    if (mounted) {
      Navigator.of(context).pop(isSafe);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _stopAlertSound();
    _recorder.dispose(); // Clean up audio recorder resources
    // Safety: if screen is disposed without resolution (e.g. system back nav),
    // resolve as unsafe so the alert still fires.
    if (!_resolved) {
      debugPrint('PreAlertScreen: disposed without resolution, resolving as unsafe');
      widget.request.resolveAsSafe(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing without resolution
      child: Scaffold(
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
      ),
    );
  }
}
