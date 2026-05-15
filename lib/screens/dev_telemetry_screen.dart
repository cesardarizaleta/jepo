import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

/// Hidden developer screen for recording labeled sensor data (ML training).
///
/// Tap a button to START recording. Tap again to STOP and POST the samples.
class DevTelemetryScreen extends StatefulWidget {
  const DevTelemetryScreen({super.key});

  @override
  State<DevTelemetryScreen> createState() => _DevTelemetryScreenState();
}

class _DevTelemetryScreenState extends State<DevTelemetryScreen> {
  static String get _endpoint =>
      '${dotenv.env['BASE_URL']}/api/telemetria/recolectar';

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final List<Map<String, dynamic>> _buffer = [];

  bool isRecording = false;
  String? currentLabel;
  DateTime? _recordingStartedAt;
  bool _isSending = false;
  String _statusMsg = 'Listo. Toca un botón para iniciar grabación.';

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  void _toggleRecording(String label) {
    if (_isSending) return;

    if (isRecording && currentLabel == label) {
      // STOP recording and send
      _stopAndSend();
    } else if (!isRecording) {
      // START recording
      _startRecording(label);
    }
  }

  void _startRecording(String label) {
    _buffer.clear();
    currentLabel = label;
    isRecording = true;
    _recordingStartedAt = DateTime.now();

    double gx = 0, gy = 0, gz = 0;

    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent e) {
      gx = e.x;
      gy = e.y;
      gz = e.z;
    });

    _accelSub = userAccelerometerEventStream().listen((
      UserAccelerometerEvent e,
    ) {
      _buffer.add({
        't': DateTime.now().millisecondsSinceEpoch,
        'ax': e.x,
        'ay': e.y,
        'az': e.z,
        'gx': gx,
        'gy': gy,
        'gz': gz,
      });
    });

    setState(() {
      _statusMsg = 'Grabando $label... Toque para detener.';
    });
  }

  Future<void> _stopAndSend() async {
    if (!isRecording || currentLabel == null) return;

    final label = currentLabel!;
    final samples = List<Map<String, dynamic>>.from(_buffer);
    final startedAt = _recordingStartedAt;

    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;

    setState(() {
      isRecording = false;
      currentLabel = null;
      _recordingStartedAt = null;
    });

    if (samples.isEmpty) {
      setState(() => _statusMsg = 'Sin muestras capturadas, no se envió.');
      return;
    }

    setState(() {
      _isSending = true;
      _statusMsg = 'Enviando ${samples.length} muestras ($label)...';
    });

    final body = jsonEncode({
      'etiqueta': label,
      'inicio': startedAt?.toUtc().toIso8601String(),
      'fin': DateTime.now().toUtc().toIso8601String(),
      'cantidad': samples.length,
      'muestras': samples,
    });

    // Build headers with API Key from .env
    final apiKey = dotenv.env['API_KEY'] ?? '';
    final apiKeyHeader = dotenv.env['API_KEY_HEADER_NAME'] ?? 'x-api-key';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      apiKeyHeader: apiKey,
    };

    try {
      final res = await http
          .post(Uri.parse(_endpoint), headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(
          () => _statusMsg =
              '✓ ${res.statusCode} — ${samples.length} muestras enviadas ($label)',
        );
      } else {
        setState(
          () => _statusMsg =
              '✗ Error ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = '✗ Fallo de red: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Telemetry (Oculto)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.red.shade50
                      : (_isSending ? Colors.orange.shade50 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _statusMsg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isRecording ? Colors.red.shade800 : Colors.black87,
                      ),
                    ),
                    if (isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Buffer: ${_buffer.length} muestras',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _RecordToggleButton(
                        label: 'NORMAL',
                        color: Colors.green,
                        isActive: isRecording && currentLabel == 'NORMAL',
                        enabled: !_isSending && (!isRecording || currentLabel == 'NORMAL'),
                        onTap: () => _toggleRecording('NORMAL'),
                      ),
                      const SizedBox(height: 12),
                      _RecordToggleButton(
                        label: 'CAMINAR',
                        color: Colors.blue,
                        isActive: isRecording && currentLabel == 'CAMINAR',
                        enabled: !_isSending && (!isRecording || currentLabel == 'CAMINAR'),
                        onTap: () => _toggleRecording('CAMINAR'),
                      ),
                      const SizedBox(height: 12),
                      _RecordToggleButton(
                        label: 'CORRER',
                        color: Colors.orange,
                        isActive: isRecording && currentLabel == 'CORRER',
                        enabled: !_isSending && (!isRecording || currentLabel == 'CORRER'),
                        onTap: () => _toggleRecording('CORRER'),
                      ),
                      const SizedBox(height: 12),
                      _RecordToggleButton(
                        label: 'CAIDA',
                        color: Colors.red,
                        isActive: isRecording && currentLabel == 'CAIDA',
                        enabled: !_isSending && (!isRecording || currentLabel == 'CAIDA'),
                        onTap: () => _toggleRecording('CAIDA'),
                      ),
                      const SizedBox(height: 12),
                      _RecordToggleButton(
                        label: 'ESCALERAS',
                        color: Colors.teal.shade700,
                        isActive: isRecording && currentLabel == 'ESCALERAS',
                        enabled: !_isSending && (!isRecording || currentLabel == 'ESCALERAS'),
                        onTap: () => _toggleRecording('ESCALERAS'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca para iniciar. Toca de nuevo para detener y enviar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordToggleButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _RecordToggleButton({
    required this.label,
    required this.color,
    required this.isActive,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: enabled
              ? (isActive ? color : color.withOpacity(0.85))
              : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isActive ? '⏺ GRABANDO $label — TOCA PARA DETENER' : 'GRABAR $label',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontSize: isActive ? 15 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
