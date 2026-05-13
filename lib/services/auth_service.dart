import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_response.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'session_events.dart';
import '../utils/phone_utils.dart';

class AuthService {
  static const String _currentUserIdKey = 'jepo_current_user_id';
  static const String _currentUserKey = 'jepo_current_user';

  final ApiClient api;

  AuthService(this.api);

  Future<ApiResponse<AuthSession>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    String? cedula,
    String? tokenFcm,
  }) async {
    final payload = RegisterDto(
      cedula: cedula,
      nombre: nombre,
      apellido: apellido,
      email: email,
      telefono: normalizePhoneForApi(telefono),
      password: password,
      tokenFcm: tokenFcm,
    ).toJson();

    final envelope = await api.postEnvelope(
      '/api/auth/register',
      body: payload,
    );
    return _persistSessionFromAuthResponse(envelope.raw);
  }

  Future<ApiResponse<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final payload = LoginDto(email: email, password: password).toJson();
    final envelope = await api.postEnvelope('/api/auth/login', body: payload);
    return _persistSessionFromAuthResponse(envelope.raw);
  }

  /// Request a password-reset OTP to be delivered via [method] ('email' or
  /// 'whatsapp') to the account owning [emailOrPhone].
  ///
  /// The backend always replies `200` to prevent account enumeration, so
  /// this method returns a boolean indicating whether the request was
  /// accepted (not whether the account exists).
  Future<bool> forgotPassword({
    required String emailOrPhone,
    required String method,
  }) async {
    assert(
      method == 'email' || method == 'whatsapp',
      'method must be "email" or "whatsapp"',
    );

    final normalized = emailOrPhone.contains('@')
        ? emailOrPhone.trim()
        : normalizePhoneForApi(emailOrPhone);

    final envelope = await api.postEnvelope(
      '/api/auth/forgot-password',
      body: {'email_or_phone': normalized, 'method': method},
    );
    return envelope.success;
  }

  /// Consume the OTP and rotate the user's password. All previously issued
  /// JWTs for this user are invalidated server-side.
  Future<void> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    final normalized = emailOrPhone.contains('@')
        ? emailOrPhone.trim()
        : normalizePhoneForApi(emailOrPhone);

    await api.postEnvelope(
      '/api/auth/reset-password',
      body: {
        'email_or_phone': normalized,
        'otp': otp,
        'new_password': newPassword,
      },
    );
  }

  Future<User?> me() async {
    final envelope = await api.getEnvelope('/api/auth/me', requiresAuth: true);
    final response = ApiResponse<User>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) return User.fromJson(value);
        if (value is Map) return User.fromJson(value.cast<String, dynamic>());
        return null;
      },
    );

    if (response.data != null) {
      await _saveCurrentUser(response.data!);
      return response.data;
    }
    return null;
  }

  Future<bool> hasActiveSession() async {
    final token = await api.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentUserIdKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return User.fromJson(decoded);
    }
    if (decoded is Map) {
      return User.fromJson(decoded.cast<String, dynamic>());
    }
    return null;
  }

  Future<void> logout() async {
    // Broadcast logout so background pipelines, queues, and location streams
    // can tear down immediately.
    SessionEvents.notifyLogout();

    await api.clearAccessToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUserKey);

    // Best-effort: stop background service to halt sensor/location streams.
    if (!kIsWeb) {
      try {
        final bgService = FlutterBackgroundService();
        bgService.invoke('stopService');
      } catch (_) {}
    }
  }

  Future<ApiResponse<AuthSession>> _persistSessionFromAuthResponse(
    Map<String, dynamic> resp,
  ) async {
    final response = ApiResponse<AuthSession>.fromJson(
      resp,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return AuthSession.fromJson(value);
        }
        if (value is Map) {
          return AuthSession.fromJson(value.cast<String, dynamic>());
        }
        return null;
      },
    );

    final session = response.data;
    if (session == null || session.accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        message: 'Auth response without access token',
      );
    }
    await api.saveAccessToken(session.accessToken);
    await _saveCurrentUser(session.user);

    // Allow future 401 events to be detected again now that we have a valid session.
    SessionEvents.resetInvalidation();

    return response;
  }

  Future<void> _saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.id != null) {
      await prefs.setInt(_currentUserIdKey, user.id!);
    }

    final normalized = user.telefono == null
        ? null
        : normalizePhoneForApi(user.telefono!);

    final toStore = user.copyWith(telefono: normalized);
    await prefs.setString(_currentUserKey, jsonEncode(toStore.toJson()));
  }

  /// Update the current user's profile.
  ///
  /// This attempts to patch the server-side user record if an `id` is available
  /// and the network call succeeds. On any failure the local stored user is
  /// still updated so UI reflects changes immediately.
  Future<User> updateProfile(UpdateUserDto updates) async {
    final current = await getCurrentUser();
    if (current == null) {
      throw const ApiException(statusCode: 401, message: 'No current user');
    }

    final merged = current.copyWith(
      nombre: updates.nombre ?? current.nombre,
      apellido: updates.apellido ?? current.apellido,
      telefono: updates.telefono ?? current.telefono,
      tokenFcm: updates.tokenFcm ?? current.tokenFcm,
    );

    final id = current.id;
    if (id != null) {
      try {
        final payload = updates.toJson();
        if (payload.containsKey('telefono')) {
          payload['telefono'] = normalizePhoneForApi(
            payload['telefono']?.toString() ?? '',
          );
        }

        final envelope = await api.patchEnvelope(
          '/api/usuarios/$id',
          body: payload,
          requiresAuth: true,
        );

        final response = ApiResponse<User>.fromJson(
          envelope.raw,
          dataParser: (value) {
            if (value is Map<String, dynamic>) return User.fromJson(value);
            if (value is Map)
              return User.fromJson(value.cast<String, dynamic>());
            return null;
          },
        );

        if (response.data != null) {
          await _saveCurrentUser(response.data!);
          return response.data!;
        }
      } catch (e) {
        // Best-effort: ignore network error and persist locally.
        debugPrint('updateProfile remote failed: $e');
      }
    }

    await _saveCurrentUser(merged);
    return merged;
  }
}
