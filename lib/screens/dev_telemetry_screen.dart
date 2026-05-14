import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

/// Hidden developer screen used to record labeled sensor data for ML training.
///
/// Hold a button to start sampling `userAccelerometerEventStream` and
/// `gyroscopeEventStream`. On release, the buffered samples are POSTed to
/// the backend along with the label.
class DevTelemetryScreen extends StatefulWidget {
  const DevTelemetryScreen({super.key});

  @override
  State<DevTelemetryScreen> createState() => _DevTelemetryScreenState();
}

class _DevTelemetryScreenState extends State<DevTelemetryScreen> {
  static const String _endpoint =
      'http://172.16.11.43:3000/api/telemetria/recolectar';

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final List<Map<String, dynamic>> _buffer = [];
  String? _activeLabel;
  DateTime? _recordingStartedAt;
  bool _isSending = false;
  String _statusMsg = 'Listo';

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  void _startRecording(String label) {
    if (_activeLabel != null || _isSending) return;

    _buffer.clear();
    _activeLabel = label;
    _recordingStartedAt = DateTime.now();

    // Latest gyro reading; merged with each accelerometer sample so each
    // entry has both signals at the same instant.
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
      _statusMsg = 'Grabando $label...';
    });
  }

  Future<void> _stopAndSend() async {
    if (_activeLabel == null) return;

    final label = _activeLabel!;
    final samples = List<Map<String, dynamic>>.from(_buffer);
    final startedAt = _recordingStartedAt;

    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _activeLabel = null;
    _recordingStartedAt = null;

    if (samples.isEmpty) {
      setState(() => _statusMsg = 'Sin muestras, no se envió.');
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

    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(
          () => _statusMsg =
              'OK ${res.statusCode} — ${samples.length} muestras enviadas ($label)',
        );
      } else {
        setState(
          () => _statusMsg =
              'Error ${res.statusCode}: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Fallo red: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Telemetry')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _statusMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_activeLabel != null)
                Text(
                  'Buffer: ${_buffer.length} muestras',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RecordButton(
                      label: 'NORMAL',
                      color: Colors.green,
                      enabled: !_isSending,
                      onPressStart: () => _startRecording('NORMAL'),
                      onPressEnd: _stopAndSend,
                    ),
                    _RecordButton(
                      label: 'CAMINAR',
                      color: Colors.blue,
                      enabled: !_isSending,
                      onPressStart: () => _startRecording('CAMINAR'),
                      onPressEnd: _stopAndSend,
                    ),
                    _RecordButton(
                      label: 'CAIDA',
                      color: Colors.red,
                      enabled: !_isSending,
                      onPressStart: () => _startRecording('CAIDA'),
                      onPressEnd: _stopAndSend,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mantén presionado para grabar. Suelta para enviar.',
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

class _RecordButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressStart;
  final Future<void> Function() onPressEnd;

  const _RecordButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onPressStart() : null,
      onTapUp: enabled ? (_) => onPressEnd() : null,
      onTapCancel: enabled ? () => onPressEnd() : null,
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: enabled ? color : color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          'GRABAR $label',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
