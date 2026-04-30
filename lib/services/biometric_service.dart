import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();
  
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  static Future<void> setBiometricEnabled(bool enabled, {String? email, String? password}) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
    if (enabled && email != null && password != null) {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
    } else if (!enabled) {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
    }
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Inicia sesión de forma rápida y segura',
      );
    } on PlatformException {
      return false;
    }
  }
}
