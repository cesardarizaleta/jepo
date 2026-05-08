import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert_queue_service.dart';
import '../services/api_client.dart';
import '../services/pre_alert_service.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';
import '../utils/app_toast.dart';

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final TelemetryService _telemetryService = TelemetryService();

  // Sensor Data
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  UserAccelerometerEvent? _userAccelerometerEvent;
  Position? _currentPosition;

  // Subscriptions
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  StreamSubscription? _userAccelSubscription;
  StreamSubscription? _locationSubscription;

  // Risk Detection State (Simple Threshold for Demo)
  bool _isHighRiskMovement = false;
  String _riskMessage = "Normal";

  // Backend state
  bool _incidentActive = false;
  int _pendingAlerts = 0;
  
  // Sensitivity Management
  double _sensitivityThreshold = 30.0;
  final String _thresholdKey = 'jepo_sensitivity_threshold';

  @override
  void initState() {
    super.initState();
    _initTelemetry();
  }

  Future<void> _initTelemetry() async {
    // Load backend state
    _incidentActive = PreAlertService.isIncidentActive;
    if (appApiInitialized) {
      try {
        _pendingAlerts = await AlertQueueService(appApi).pendingCount();
      } catch (_) {}
    }
    
    // Load saved threshold
    final prefs = await SharedPreferences.getInstance();
    _sensitivityThreshold = prefs.getDouble(_thresholdKey) ?? 30.0;

    final hasPermission = await _telemetryService.requestLocationPermission();
    if (hasPermission) {
      _startListening();
    } else {
      if (mounted) {
        AppToast.error(context, 'Se necesita permiso de ubicación para la telemetría');
      }
    }
    if (mounted) setState(() {});
  }

  void _startListening() {
    _accelSubscription = _telemetryService.accelerometerStream.listen((event) {
      setState(() {
        _accelerometerEvent = event;
        _checkRisk(event);
      });
    });

    _gyroSubscription = _telemetryService.gyroscopeStream.listen((event) {
      setState(() {
        _gyroscopeEvent = event;
      });
    });

    _userAccelSubscription = _telemetryService.userAccelerometerStream.listen((
      event,
    ) {
      setState(() {
        _userAccelerometerEvent = event;
      });
    });

    _locationSubscription = _telemetryService.locationStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  void _checkRisk(AccelerometerEvent event) {
    // Simple threshold logic for demonstration
    // In a real app, this would be a complex ML model (HAR)
    double magnitude = (event.x.abs() + event.y.abs() + event.z.abs());

    // Standard gravity is ~9.8 m/s^2.
    // Significant deviation might indicate a fall or crash.
    if (magnitude > _sensitivityThreshold) {
      setState(() {
        _isHighRiskMovement = true;
        _riskMessage = "IMPACTO CRÍTICO DETECTADO";
      });
      // Reset after a delay for demo purposes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isHighRiskMovement = false;
            _riskMessage = "Normal";
          });
        }
      });
    } else if (magnitude > 15.0) {
      setState(() {
        _riskMessage = "Movimiento Alto";
      });
    } else {
      setState(() {
        _riskMessage = "Normal";
      });
    }
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _userAccelSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Monitor de Telemetría y Riesgo',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildSensitivityCard(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "Acelerómetro (Gravedad)",
              data: _accelerometerEvent != null
                  ? "X: ${_accelerometerEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_accelerometerEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_accelerometerEvent!.z.toStringAsFixed(2)}"
                  : "Esperando...",
              icon: Icons.speed,
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "Acelerómetro de Usuario (Sin Gravedad)",
              data: _userAccelerometerEvent != null
                  ? "X: ${_userAccelerometerEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_userAccelerometerEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_userAccelerometerEvent!.z.toStringAsFixed(2)}"
                  : "Esperando...",
              icon: Icons.directions_run,
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "Giroscopio",
              data: _gyroscopeEvent != null
                  ? "X: ${_gyroscopeEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_gyroscopeEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_gyroscopeEvent!.z.toStringAsFixed(2)}"
                  : "Esperando...",
              icon: Icons.rotate_right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return NeumorphicContainer(
      color: _isHighRiskMovement ? Colors.red.shade100 : AppTheme.background,
      child: Column(
        children: [
          Text(
            "ESTADO DEL SISTEMA",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isHighRiskMovement ? Colors.red : AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _riskMessage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isHighRiskMovement ? Colors.red : AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStatus(
                'Incidente',
                _incidentActive ? 'ACTIVO' : 'Ninguno',
                _incidentActive ? Colors.red : Colors.green,
              ),
              _buildMiniStatus(
                'Cola',
                '$_pendingAlerts pendiente(s)',
                _pendingAlerts > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityCard() {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primary),
              SizedBox(width: 12),
              Text(
                "Sensibilidad de Impacto",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Ajusta el umbral de detección de impactos. Menor valor = más sensible.",
            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("Más Sensible", style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              Expanded(
                child: Slider(
                  value: _sensitivityThreshold,
                  min: 15.0,
                  max: 60.0,
                  divisions: 9,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.primaryLight.withOpacity(0.3),
                  label: _sensitivityThreshold.toStringAsFixed(1),
                  onChanged: (val) => setState(() => _sensitivityThreshold = val),
                  onChangeEnd: _updateThreshold,
                ),
              ),
              const Text("Menos Sensible", style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
            ],
          ),
          Center(
            child: Text(
              "Umbral actual: ${_sensitivityThreshold.toStringAsFixed(1)} G",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateThreshold(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, val);
    
    // Notify Background Service
    if (!kIsWeb) {
      try {
        final service = FlutterBackgroundService();
        service.invoke('setThreshold', {"threshold": val});
      } catch (e) {
        debugPrint('Error notifying background service: $e');
      }
    }
    
    if (mounted) {
      AppToast.success(context, 'Sensibilidad actualizada');
    }
  }

  Widget _buildMiniStatus(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primary),
              SizedBox(width: 12),
              Text(
                "Geolocalización",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white),
          const SizedBox(height: 12),
          if (_currentPosition != null) ...[
            _buildDataRow("Latitud", "${_currentPosition!.latitude}"),
            _buildDataRow("Longitud", "${_currentPosition!.longitude}"),
            _buildDataRow(
              "Altitud",
              "${_currentPosition!.altitude.toStringAsFixed(1)} m",
            ),
            _buildDataRow(
              "Velocidad",
              "${_currentPosition!.speed.toStringAsFixed(1)} m/s",
            ),
            _buildDataRow(
              "Precisión",
              "${_currentPosition!.accuracy.toStringAsFixed(1)} m",
            ),
          ] else
            const Text(
              "Adquiriendo señal GPS...",
              style: TextStyle(color: AppTheme.textLight),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String data,
    required IconData icon,
  }) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white),
          const SizedBox(height: 12),
          Text(
            data,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLight)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
