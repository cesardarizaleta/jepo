import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_container.dart';

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

  @override
  void initState() {
    super.initState();
    _initTelemetry();
  }

  Future<void> _initTelemetry() async {
    final hasPermission = await _telemetryService.requestLocationPermission();
    if (hasPermission) {
      _startListening();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission needed for telemetry'),
          ),
        );
      }
    }
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
    // This is a VERY basic simplification.
    if (magnitude > 30.0) {
      setState(() {
        _isHighRiskMovement = true;
        _riskMessage = "CRITICAL IMPACT DETECTED";
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
        _riskMessage = "High Movement";
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
          'Telemetry & Risk Monitor',
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
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "Accelerometer (Gravity)",
              data: _accelerometerEvent != null
                  ? "X: ${_accelerometerEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_accelerometerEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_accelerometerEvent!.z.toStringAsFixed(2)}"
                  : "Waiting...",
              icon: Icons.speed,
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "User Accelerometer (No Gravity)",
              data: _userAccelerometerEvent != null
                  ? "X: ${_userAccelerometerEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_userAccelerometerEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_userAccelerometerEvent!.z.toStringAsFixed(2)}"
                  : "Waiting...",
              icon: Icons.directions_run,
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              title: "Gyroscope",
              data: _gyroscopeEvent != null
                  ? "X: ${_gyroscopeEvent!.x.toStringAsFixed(2)}\n"
                        "Y: ${_gyroscopeEvent!.y.toStringAsFixed(2)}\n"
                        "Z: ${_gyroscopeEvent!.z.toStringAsFixed(2)}"
                  : "Waiting...",
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
            "SYSTEM STATUS",
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
        ],
      ),
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
                "Geolocation",
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
            _buildDataRow("Latitude", "${_currentPosition!.latitude}"),
            _buildDataRow("Longitude", "${_currentPosition!.longitude}"),
            _buildDataRow(
              "Altitude",
              "${_currentPosition!.altitude.toStringAsFixed(1)} m",
            ),
            _buildDataRow(
              "Speed",
              "${_currentPosition!.speed.toStringAsFixed(1)} m/s",
            ),
            _buildDataRow(
              "Accuracy",
              "${_currentPosition!.accuracy.toStringAsFixed(1)} m",
            ),
          ] else
            const Text(
              "Acquiring GPS signal...",
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
