import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TelemetryService {
  // Streams for sensors
  Stream<AccelerometerEvent> get accelerometerStream =>
      accelerometerEventStream();
  Stream<GyroscopeEvent> get gyroscopeStream => gyroscopeEventStream();
  Stream<UserAccelerometerEvent> get userAccelerometerStream =>
      userAccelerometerEventStream();

  // Stream for location
  Stream<Position> get locationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition();
  }
}
