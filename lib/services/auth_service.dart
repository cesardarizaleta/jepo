import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AuthService {
  static const String _currentUserIdKey = 'jepo_current_user_id';
  static const String _currentUserKey = 'jepo_current_user';

  final ApiClient api;

  AuthService(this.api);

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    String? tokenFcm,
  }) async {
    final payload = {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'password': password,
      'token_fcm': tokenFcm,
    };

    final resp = await api.post('/api/auth/register', body: payload);
    return _persistSessionFromAuthResponse(resp);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await api.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    return _persistSessionFromAuthResponse(resp);
  }

  Future<Map<String, dynamic>?> me() async {
    final resp = await api.get('/api/auth/me', requiresAuth: true);
    if (resp is Map<String, dynamic> && resp['data'] is Map<String, dynamic>) {
      await _saveCurrentUser(resp['data'] as Map<String, dynamic>);
      return resp['data'] as Map<String, dynamic>;
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

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await api.clearAccessToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUserKey);
  }

  Future<Map<String, dynamic>> _persistSessionFromAuthResponse(
    dynamic resp,
  ) async {
    if (resp is! Map<String, dynamic>) {
      throw ApiException(500, 'Unexpected auth response');
    }

    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(500, 'Auth response without data');
    }

    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Auth response without access token');
    }
    await api.saveAccessToken(token);

    final user = data['user'];
    if (user is Map<String, dynamic>) {
      await _saveCurrentUser(user);
    }

    return resp;
  }

  Future<void> _saveCurrentUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final id = user['id'];
    if (id is int) {
      await prefs.setInt(_currentUserIdKey, id);
    }
    await prefs.setString(_currentUserKey, jsonEncode(user));
  }

  /// Update the current user's profile.
  ///
  /// This attempts to patch the server-side user record if an `id` is available
  /// and the network call succeeds. On any failure the local stored user is
  /// still updated so UI reflects changes immediately.
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    final current = await getCurrentUser();
    if (current == null) {
      throw ApiException(401, 'No current user');
    }

    final merged = <String, dynamic>{}
      ..addAll(current)
      ..addAll(updates);

    final id = current['id'];
    if (id is int) {
      try {
        final resp = await api.patch(
          '/api/usuarios/$id',
          body: updates,
          requiresAuth: true,
        );
        if (resp is Map<String, dynamic> &&
            resp['data'] is Map<String, dynamic>) {
          await _saveCurrentUser(resp['data'] as Map<String, dynamic>);
          return resp['data'] as Map<String, dynamic>;
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
